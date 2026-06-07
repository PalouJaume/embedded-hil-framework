function results = l1_validate(out, varargin)
% l1_validate — Valida resultados de simulaciones L1 (MIL / SoftSIL / PIL).
%
% USO
%   results = l1_validate(out)
%   results = l1_validate(out, 'Mode', 'pil')
%   results = l1_validate(out, 'Mode', 'soft_sil', 'Verbose', false)
%   results = l1_validate(out, 'Mode', 'mil', 'Tolerances', custom_struct)
%
% NAME-VALUE
%   'Mode'        'mil' | 'soft_sil' | 'pil'   (default: 'mil')
%                 Selecciona el set de tolerancias por defecto.
%   'Verbose'     true | false                 (default: true)
%                 Imprime resultados en consola.
%   'Tolerances'  Struct con tolerancias       (default: por modo)
%                 Permite override completo o parcial del set por defecto.
%
% SALIDA
%   results.mode      modo aplicado
%   results.scenario  trayectoria activa
%   results.checks    array de structs por criterio
%   results.passed    bool global (todos los checks OK)
%   results.n_passed  numero de checks OK
%   results.n_total   numero total de checks
%
% SEÑALES UTILIZADAS (logged del bus de simulacion)
%   out.r_m_log    Posicion real del vehiculo (truth) — usado para tracking
%   out.v_f_log    Velocidad filtrada (entrada del algoritmo)
%   out.a_cmd_log  Comando de aceleracion lateral (salida del algoritmo)
%   out.r_f_log    Posicion estimada por navegacion (no usado en checks)
%   out.r_p_log    Punto de referencia L1 (no usado en checks)
%

  % ---------------------------------------------------------------------
  % Parser
  % ---------------------------------------------------------------------
  p = inputParser;
  addParameter(p, 'Mode',       'mil',  @(s) ischar(s) || isstring(s));
  addParameter(p, 'Verbose',    true,   @(x) islogical(x) || ismember(x,[0 1]));
  addParameter(p, 'Tolerances', [],     @(x) isempty(x) || isstruct(x));
  parse(p, varargin{:});

  mode    = lower(char(p.Results.Mode));
  verbose = logical(p.Results.Verbose);
  tol_in  = p.Results.Tolerances;

  validModes = {'mil','soft_sil','pil'};
  if ~ismember(mode, validModes)
    error('l1_validate:invalidMode', ...
      'Mode debe ser uno de: %s', strjoin(validModes, ', '));
  end

  tol = merge_tolerances(default_tolerances(mode), tol_in);

  % ---------------------------------------------------------------------
  % Parametros y señales
  % ---------------------------------------------------------------------
  V      = evalin('base', 'V');
  a_max  = evalin('base', 'a_max');
  active = evalin('base', 'ACTIVE_TRAJECTORY');

  r_m   = out.r_m_log.Data;     % posicion real (truth)
  v_f   = out.v_f_log.Data;     % velocidad filtrada
  a_cmd = out.a_cmd_log.Data;   % comando de aceleracion

  n_samples  = size(a_cmd, 1);
  idx_steady = floor(0.8 * n_samples) : n_samples;

  v_norm = sqrt(sum(v_f.^2,  2));
  a_norm = sqrt(sum(a_cmd.^2, 2));

  % ---------------------------------------------------------------------
  % Inicializa el contenedor de resultados
  % ---------------------------------------------------------------------
  results = init_results(mode, active);

  if verbose
    fprintf('\n=== Validacion L1 [%s / %s] ===\n\n', upper(mode), active);
  end

  % ---------------------------------------------------------------------
  % Check 1 — ESC-RF-1: a_cmd perpendicular a v_f
  % ---------------------------------------------------------------------
  % Se normaliza por |a|*|v| para que el criterio sea adimensional
  % (coseno del angulo entre ambos vectores). Asi la tolerancia es
  % comparable entre modos sin depender de la magnitud de a_cmd.
  dot_av  = sum(a_cmd .* v_f, 2);
  denom   = max(v_norm .* a_norm, 1e-9);
  max_cos = max(abs(dot_av ./ denom));

  results = add_check(results, ...
    'ESC-RF-1: max |cos(a_cmd, v_f)|', ...
    max_cos, tol.perpendicularity, '<', 'FAIL');

  % ---------------------------------------------------------------------
  % Check 2 — ESC-RF-2: |a_cmd| consistente con la curvatura del path
  % ---------------------------------------------------------------------
  % IMPORTANTE: Park 2004 explicita que el algoritmo L1 usa la velocidad
  % inercial instantanea, no una velocidad nominal. Bajo viento, la ground
  % speed |v_f| difiere de V (airspeed nominal). La centripeta esperada se
  % calcula con la |v_f| medida, no con V:
  %   a_centripetal = |v_f|^2 / R
  v_mean_steady = mean(v_norm(idx_steady));
  a_mean_steady = mean(a_norm(idx_steady));

  switch active
    case 'circle'
      R          = evalin('base', 'traj_circle_R');
      a_expected = v_mean_steady^2 / R;
      err_rel    = abs(a_mean_steady - a_expected) / a_expected;
      results = add_check(results, ...
        sprintf('ESC-RF-2: |a_cmd| ~ |v_f|^2/R (%.3f m/s^2)', a_expected), ...
        err_rel, tol.curvature_accel_rel, '<', 'WARN', ...
        sprintf('medido %.3f m/s^2, |v_f| medio %.2f m/s (err %.1f%%)', ...
                a_mean_steady, v_mean_steady, err_rel*100));

    case 'line'
      results = add_check(results, ...
        'ESC-RF-2: |a_cmd| ~ 0 en recta', ...
        a_mean_steady, tol.line_accel_abs, '<', 'WARN', ...
        sprintf('medido %.3f m/s^2', a_mean_steady));

    case 'sinusoid'
      % Cota superior basada en la curvatura maxima de y = A sin(2*pi*f*x):
      %   kappa_max = A*(2*pi*f)^2.
      % El comando deberia estar acotado por |v_f|^2*kappa_max con margen.
      A = evalin('base', 'traj_sin_Amp');
      f = evalin('base', 'traj_sin_freq');
      kappa_max = A * (2*pi*f)^2;
      a_cap     = v_mean_steady^2 * kappa_max * (1 + tol.sinusoid_margin);
      results = add_check(results, ...
        sprintf('ESC-RF-2: |a_cmd| medio < cota sinusoide (%.2f m/s^2)', a_cap), ...
        a_mean_steady, a_cap, '<', 'WARN', ...
        sprintf('medido %.3f m/s^2', a_mean_steady));
  end

  % ---------------------------------------------------------------------
  % Check 3 — Convergencia: |d_lateral| medio en regimen
  % ---------------------------------------------------------------------
  d_lat        = compute_d_lateral(r_m, active);
  d_lat_steady = mean(abs(d_lat(idx_steady)));
  results = add_check(results, ...
    'Convergencia: |d_lateral| medio (truth)', ...
    d_lat_steady, tol.lateral_error, '<', 'WARN', ...
    sprintf('medido %.2f m', d_lat_steady));

  % ---------------------------------------------------------------------
  % Check 4 — Saturacion: porcentaje de muestras con |a_cmd| ~ a_max
  % ---------------------------------------------------------------------
  pct_sat = 100 * sum(a_norm > 0.99 * a_max) / numel(a_norm);
  results = add_check(results, ...
    sprintf('Saturacion: %% muestras |a_cmd| > 0.99*a_max (%.1f m/s^2)', a_max), ...
    pct_sat, tol.saturation_pct, '<', 'WARN', ...
    sprintf('%.2f%% saturadas', pct_sat));

  % ---------------------------------------------------------------------
  % Check 5 — Cinematica: airspeed (|v_f - wind|) ~ V en regimen
  % ---------------------------------------------------------------------
  % Con viento, la ground speed |v_f| difiere de la airspeed V (que es lo
  % que el modelo de planta mantiene constante). La invariante cinematica
  % del modelo es entonces:
  %   |v_f - wind_vector| ~ V
  % Una deriva aqui delata fallo del integrador o del modelo dinamico.
  if evalin('base', 'exist(''wind_vector'',''var'')')
    wind = evalin('base', 'wind_vector');
    wind = wind(:).';                                  % 1x2
  else
    wind = [0 0];
  end

  v_air      = v_f - wind;                             % Nx2
  v_air_norm = sqrt(sum(v_air.^2, 2));
  v_air_mean = mean(v_air_norm(idx_steady));
  err_v_rel  = abs(v_air_mean - V) / V;
  results = add_check(results, ...
    sprintf('Cinematica: airspeed |v_f-wind| ~ V (%.1f m/s)', V), ...
    err_v_rel, tol.speed_rel, '<', 'FAIL', ...
    sprintf('airspeed medio %.3f m/s (err %.2f%%), wind = [%g %g]', ...
            v_air_mean, err_v_rel*100, wind(1), wind(2)));

  % ---------------------------------------------------------------------
  % Resumen
  % ---------------------------------------------------------------------
  passed_arr      = [results.checks.passed];
  results.passed  = all(passed_arr);
  results.n_total = numel(passed_arr);
  results.n_passed = sum(passed_arr);

  if verbose
    print_results(results);
  end
end

% =====================================================================
% Helpers internos
% =====================================================================

function tol = default_tolerances(mode)
% Tolerancias por nivel. Las de PIL son las mas relajadas: se acumulan
% errores de float32, quantizacion serie, jitter del enlace UART y ruido
% de la navegacion entrando en el lazo cerrado.
  switch mode
    case 'mil'
      tol.perpendicularity   = 1e-3;
      tol.curvature_accel_rel = 0.05;
      tol.line_accel_abs     = 0.5;
      tol.sinusoid_margin    = 0.20;   % 20% sobre la cota teorica
      tol.lateral_error      = 5;      % m
      tol.saturation_pct     = 1;      % %
      tol.speed_rel          = 0.01;
    case 'soft_sil'
      tol.perpendicularity   = 5e-3;   % float32 vs double
      tol.curvature_accel_rel = 0.08;
      tol.line_accel_abs     = 0.5;
      tol.sinusoid_margin    = 0.25;
      tol.lateral_error      = 5;
      tol.saturation_pct     = 2;
      tol.speed_rel          = 0.01;
    case 'pil'
      tol.perpendicularity   = 1e-2;   % +jitter, +serializacion
      tol.curvature_accel_rel = 0.15;
      tol.line_accel_abs     = 1.0;
      tol.sinusoid_margin    = 0.35;
      tol.lateral_error      = 10;     % +ruido del lazo cerrado
      tol.saturation_pct     = 5;
      tol.speed_rel          = 0.05;
  end
end

function out_tol = merge_tolerances(base, override)
% Permite override parcial: solo los campos presentes en override se
% sobreescriben; el resto se conserva del set base.
  out_tol = base;
  if isempty(override), return; end
  f = fieldnames(override);
  for i = 1:numel(f)
    out_tol.(f{i}) = override.(f{i});
  end
end

function r = init_results(mode, scenario)
  r.mode     = mode;
  r.scenario = scenario;
  r.checks   = struct('name', {}, 'value', {}, 'threshold', {}, ...
                      'op', {}, 'passed', {}, 'severity', {}, 'detail', {});
  r.passed   = false;
  r.n_passed = 0;
  r.n_total  = 0;
end

function results = add_check(results, name, value, threshold, op, severity, detail)
  if nargin < 7, detail = ''; end

  switch op
    case '<',  passed = value <  threshold;
    case '<=', passed = value <= threshold;
    case '>',  passed = value >  threshold;
    case '>=', passed = value >= threshold;
    otherwise
      error('l1_validate:badOp', 'Operador no soportado: %s', op);
  end

  k = numel(results.checks) + 1;
  results.checks(k).name      = name;
  results.checks(k).value     = value;
  results.checks(k).threshold = threshold;
  results.checks(k).op        = op;
  results.checks(k).passed    = passed;
  results.checks(k).severity  = severity;
  results.checks(k).detail    = detail;
end

function print_results(results)
  for k = 1:numel(results.checks)
    c = results.checks(k);
    if c.passed
      tag = '[PASS]';
    else
      tag = sprintf('[%s]', c.severity);
    end
    line = sprintf('%s %s', tag, c.name);
    if ~isempty(c.detail)
      line = sprintf('%s — %s', line, c.detail);
    end
    if ~c.passed
      line = sprintf('%s   (umbral: %s %.4g)', line, c.op, c.threshold);
    end
    fprintf('  %s\n', line);
  end
  if results.passed
    summary_tag = '[OK]';
  else
    summary_tag = '[X]';
  end
  fprintf('\n  %s %d/%d checks superados\n\n', ...
          summary_tag, results.n_passed, results.n_total);
end

function d = compute_d_lateral(r_pos, active)
% Calcula el error lateral firmado (Nx1) entre la posicion del vehiculo
% (r_pos, Nx2) y la trayectoria activa.
%
%   circle:    distancia radial al circulo
%              d > 0 -> fuera del circulo
%              d < 0 -> dentro
%   line:      proyeccion sobre la normal a la recta
%              d > 0 -> a la izquierda del sentido de avance
%   sinusoid:  distancia firmada al punto de la sinusoide a la misma
%              proyeccion longitudinal (lectura local del error).

  switch active
    case 'circle'
      O     = evalin('base', 'traj_circle_center');
      R     = evalin('base', 'traj_circle_R');
      O_row = O(:).';                                  % 1x2
      OM    = r_pos - O_row;                           % Nx2
      d     = sqrt(sum(OM.^2, 2)) - R;                 % Nx1

    case 'line'
      O     = evalin('base', 'traj_line_origin');
      d_hat = evalin('base', 'traj_line_dir');
      O_row = O(:).';                                  % 1x2
      d_col = d_hat(:) / norm(d_hat);                  % 2x1
      n_col = [-d_col(2); d_col(1)];                   % 2x1
      d     = (r_pos - O_row) * n_col;                 % Nx1

    case 'sinusoid'
      O     = evalin('base', 'traj_sin_origin');
      d_hat = evalin('base', 'traj_sin_dir');
      f     = evalin('base', 'traj_sin_freq');
      A     = evalin('base', 'traj_sin_Amp');
      O_row = O(:).';                                  % 1x2
      d_col = d_hat(:) / norm(d_hat);                  % 2x1
      p_col = [-d_col(2); d_col(1)];                   % 2x1

      OM     = r_pos - O_row;                          % Nx2
      s_proj = OM * d_col;                             % Nx1
      pert   = A * sin(2*pi*f*s_proj);                 % Nx1

      % Punto de la sinusoide a la misma proyeccion longitudinal:
      r_path = O_row + s_proj * d_col.' + pert .* p_col.';   % Nx2

      % Error firmado, proyectado sobre la normal:
      d = (r_pos - r_path) * p_col;                    % Nx1

    otherwise
      d = nan(size(r_pos, 1), 1);
  end
end