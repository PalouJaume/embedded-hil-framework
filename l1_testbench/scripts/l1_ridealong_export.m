function filepath = l1_ridealong_export(out, varargin)
% l1_ridealong_export — Exporta a Excel los datos de l1_ridealong.
%
% La simulacion ridealong ejecuta en paralelo las tres implementaciones
% de la ley de guiado L1 (MIL en Simulink, SoftSIL via S-function, PIL via
% UART al target) inyectandoles los mismos inputs de navegacion. Cualquier
% diferencia entre sus salidas se atribuye exclusivamente a la implementacion,
% no a divergencia en la trayectoria.
%
% USO
%   l1_ridealong_export(out)
%   l1_ridealong_export(out, 'Output', 'mi_excel.xlsx')
%   l1_ridealong_export(out, 'IncludeRaw', false)
%
% NAME-VALUE
%   'Output'      Ruta del fichero de salida.
%                 Default: results/ridealong/l1_ridealong_<scenario>_<ts>.xlsx
%   'IncludeRaw'  Incluye hoja "Series" con datos punto a punto. Default: true.
%
% SALIDA
%   filepath  Ruta del fichero generado.
%
% HOJAS GENERADAS
%   Metadata    Trazabilidad de la ejecucion.
%   Parametros  Parametros del workspace utilizados.
%   Resumen     Estadisticas agregadas + diferencias vs MIL.
%   Series      Datos punto a punto (si IncludeRaw=true).
%
% SE�ALES ESPERADAS EN out
%   out.tout                  Vector de tiempo
%   out.r_truth_log.Data      Posicion truth del vehiculo (Nx2)
%   out.v_truth_log.Data      Velocidad truth de la planta (Nx2)
%   out.r_f_log.Data          Posicion estimada por navegacion (Nx2)
%   out.v_f_log.Data          Velocidad estimada por navegacion (Nx2)
%   out.r_p_log.Data          Punto de referencia L1 (Nx2)
%   out.a_cmd_log.Data        Comando de aceleracion MIL (Nx2)
%   out.a_cmd_log_soft_SiL    Comando de aceleracion SoftSIL (Nx2)
%   out.a_cmd_log_PiL         Comando de aceleracion PIL (Nx2)

  % ---------------------------------------------------------------------
  % Parser de argumentos
  % ---------------------------------------------------------------------
  p = inputParser;
  addParameter(p, 'Output',     '',   @(s) ischar(s) || isstring(s));
  addParameter(p, 'IncludeRaw', true, @(x) islogical(x) || ismember(x,[0 1]));
  parse(p, varargin{:});

  include_raw = logical(p.Results.IncludeRaw);

  % ---------------------------------------------------------------------
  % Ruta del fichero de salida
  % ---------------------------------------------------------------------
  active = evalin('base', 'ACTIVE_TRAJECTORY');

  if isempty(p.Results.Output)
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    filename  = sprintf('l1_ridealong_%s_%s.xlsx', active, timestamp);
    out_dir   = fullfile('results', 'ridealong');
    if ~exist(out_dir, 'dir'), mkdir(out_dir); end
    filepath = fullfile(out_dir, filename);
  else
    filepath = char(p.Results.Output);
  end

  % Evita conflicto si el fichero existe y esta abierto en Excel
  if exist(filepath, 'file')
    try
      delete(filepath);
    catch
      error('l1_ridealong_export:fileLocked', ...
        'No se pudo sobrescribir %s. Cierralo en Excel y reintenta.', filepath);
    end
  end

  % ---------------------------------------------------------------------
  % Extraccion de se�ales (con fallback a NaN si alguna no existe)
  % ---------------------------------------------------------------------
  t = out.tout;
  N = numel(t);

  r_truth   = get_signal_safe(out, 'r_truth_log',       N);
  v_truth   = get_signal_safe(out, 'v_truth_log',       N);
  r_nav     = get_signal_safe(out, 'r_f_log',           N);
  v_nav     = get_signal_safe(out, 'v_f_log',           N);
  r_ref     = get_signal_safe(out, 'r_p_log',           N);
  a_mil     = get_signal_safe(out, 'a_cmd_log',         N);
  a_softsil = get_signal_safe(out, 'a_cmd_log_soft_SiL', N);
  a_pil     = get_signal_safe(out, 'a_cmd_log_PiL',      N);

  fprintf('Exportando ridealong (%d muestras, escenario %s) a:\n  %s\n', ...
          N, active, filepath);

  % ---------------------------------------------------------------------
  % Generacion de hojas
  % ---------------------------------------------------------------------
  write_metadata(filepath, active, N);
  write_params(filepath);
  write_summary(filepath, a_mil, a_softsil, a_pil);
  if include_raw
    write_series(filepath, t, r_truth, v_truth, r_nav, v_nav, r_ref, ...
                 a_mil, a_softsil, a_pil);
  end

  if include_raw
    sheets = 'Metadata, Parametros, Resumen, Series';
  else
    sheets = 'Metadata, Parametros, Resumen';
  end
  fprintf('Hojas generadas: %s\n', sheets);
end

% =====================================================================
% Helpers de extraccion
% =====================================================================

function data = get_signal_safe(out, sig_name, N)
% Devuelve la matriz Nx2 de la se�al logged. Si no existe o falla, devuelve
% NaN(N,2) para no romper el script aguas abajo (los deltas y estadisticas
% se calculan ignorando NaN).
  default = nan(N, 2);
  try
    raw = out.(sig_name);
    if isa(raw, 'timeseries') || (isstruct(raw) && isfield(raw, 'Data'))
      data = raw.Data;
    elseif isnumeric(raw)
      data = raw;
    else
      data = default;
      return;
    end
    if isvector(data), data = data(:); end
    if size(data, 1) ~= N
      warning('l1_ridealong_export:sizeMismatch', ...
        'La se�al %s tiene %d muestras (esperadas %d). Se rellena con NaN.', ...
        sig_name, size(data,1), N);
      data = default;
    end
    if size(data, 2) == 1
      data = [data, nan(size(data,1), 1)];
    end
  catch
    warning('l1_ridealong_export:missingSignal', ...
      'Se�al %s no encontrada en out. Se rellena con NaN.', sig_name);
    data = default;
  end
end

% =====================================================================
% Hoja: Metadata
% =====================================================================

function write_metadata(filepath, active, N)
  [~, git_hash] = system('git rev-parse --short HEAD');
  git_hash = strtrim(git_hash);
  if isempty(git_hash) || contains(git_hash, 'fatal')
    git_hash = '<no git>';
  end

  rows = {
    'Campo',             'Valor';
    'Fecha generacion',  datestr(now, 'yyyy-mm-dd HH:MM:SS');
    'Git hash',          git_hash;
    'MATLAB version',    version;
    'Modelo Simulink',   'l1_ridealong';
    'Trayectoria',       active;
    'Muestras',          N;
    't_final [s]',       safe_eval('t_final');
    'dt_sim [s]',        safe_eval('dt_sim');
  };

  writecell(rows, filepath, 'Sheet', 'Metadata');
end

% =====================================================================
% Hoja: Parametros
% =====================================================================

function write_params(filepath)
% Vuelca los parametros conocidos del workspace. Los que no existen se omiten
% silenciosamente.
  param_list = { ...
    'V',                   'Vehiculo: airspeed nominal [m/s]'; ...
    'a_max',               'Vehiculo: aceleracion maxima [m/s^2]'; ...
    'k',                   'L1: ganancia de la ley de guiado'; ...
    'dt_sim',              'Simulacion: paso de integracion [s]'; ...
    't_final',             'Simulacion: tiempo final [s]'; ...
    'tau_ctrl',            'Realismo: retardo del actuador [s]'; ...
    'tau_gps',             'Realismo: retardo GPS [s]'; ...
    'sigma_pos',           'Realismo: ruido posicion (sigma) [m]'; ...
    'sigma_vel',           'Realismo: ruido velocidad (sigma) [m/s]'; ...
    'wind_vector',         'Realismo: vector viento [m/s]'; ...
    'traj_circle_R',       'Trayectoria circle: radio [m]'; ...
    'traj_circle_center',  'Trayectoria circle: centro [m]'; ...
    'traj_line_origin',    'Trayectoria line: origen [m]'; ...
    'traj_line_dir',       'Trayectoria line: direccion [-]'; ...
    'traj_sin_origin',     'Trayectoria sinusoid: origen [m]'; ...
    'traj_sin_dir',        'Trayectoria sinusoid: direccion [-]'; ...
    'traj_sin_Amp',        'Trayectoria sinusoid: amplitud [m]'; ...
    'traj_sin_freq',       'Trayectoria sinusoid: frecuencia [1/m]'; ...
  };

  rows = {'Parametro', 'Valor', 'Descripcion'};
  for i = 1:size(param_list, 1)
    name = param_list{i, 1};
    desc = param_list{i, 2};
    if evalin('base', sprintf('exist(''%s'',''var'')', name))
      val = evalin('base', name);
      rows(end+1, :) = {name, format_value(val), desc}; %#ok<AGROW>
    end
  end

  writecell(rows, filepath, 'Sheet', 'Parametros');
end

% =====================================================================
% Hoja: Resumen
% =====================================================================

function write_summary(filepath, a_mil, a_softsil, a_pil)
% Tres bloques: estadisticas por implementacion, deltas absolutos vs MIL,
% deltas relativos vs MIL + correlacion.

  rows = cell(0, 4);

  % --- Bloque 1: estadisticas por implementacion ---
  rows(end+1, :) = {'=== ESTADISTICAS POR IMPLEMENTACION ===', '', '', ''};
  rows(end+1, :) = {'Implementacion', 'mean |a_cmd| [m/s^2]', ...
                    'max |a_cmd| [m/s^2]', 'std |a_cmd| [m/s^2]'};

  impls = {'MIL', a_mil; 'Soft-SIL', a_softsil; 'PIL', a_pil};
  for k = 1:size(impls, 1)
    label = impls{k, 1};
    a     = impls{k, 2};
    if all(isnan(a(:)))
      rows(end+1, :) = {label, 'N/D', 'N/D', 'N/D'}; %#ok<AGROW>
    else
      a_norm = sqrt(sum(a.^2, 2));
      rows(end+1, :) = {label, ...
                        mean(a_norm, 'omitnan'), ...
                        max(a_norm, [], 'omitnan'), ...
                        std(a_norm, 'omitnan')}; %#ok<AGROW>
    end
  end

  rows(end+1, :) = {'', '', '', ''};

  % --- Bloque 2: diferencias absolutas vs MIL ---
  rows(end+1, :) = {'=== DIFERENCIAS vs MIL (absolutas) ===', '', '', ''};
  rows(end+1, :) = {'Pareja', 'max |delta a| [m/s^2]', ...
                    'mean |delta a| [m/s^2]', 'RMS |delta a| [m/s^2]'};

  pairs = {'Soft-SIL vs MIL', a_softsil; 'PIL vs MIL', a_pil};
  for k = 1:size(pairs, 1)
    label = pairs{k, 1};
    a_oth = pairs{k, 2};
    if all(isnan(a_oth(:))) || all(isnan(a_mil(:)))
      rows(end+1, :) = {label, 'N/D', 'N/D', 'N/D'}; %#ok<AGROW>
    else
      delta = a_oth - a_mil;
      delta_norm = sqrt(sum(delta.^2, 2));
      rms_val = sqrt(mean(delta_norm.^2, 'omitnan'));
      rows(end+1, :) = {label, ...
                        max(delta_norm, [], 'omitnan'), ...
                        mean(delta_norm, 'omitnan'), ...
                        rms_val}; %#ok<AGROW>
    end
  end

  rows(end+1, :) = {'', '', '', ''};

  % --- Bloque 3: diferencias relativas + correlacion ---
  rows(end+1, :) = {'=== DIFERENCIAS vs MIL (relativas) ===', '', '', ''};
  rows(end+1, :) = {'Pareja', 'RMS|delta|/mean|a_mil| [%]', ...
                    'max(|delta|/|a_mil|) filtrado [%]', 'correlacion media'};

  a_mil_norm  = sqrt(sum(a_mil.^2, 2));
  mean_a_mil  = mean(a_mil_norm, 'omitnan');
  % Mascara para descartar muestras donde |a_mil| esta cerca de cero
  % (cruces por cero, transitorios); evita divide-by-near-zero spurious.
  threshold   = 0.01 * mean_a_mil;
  mask        = a_mil_norm > threshold;

  for k = 1:size(pairs, 1)
    label = pairs{k, 1};
    a_oth = pairs{k, 2};
    if all(isnan(a_oth(:))) || all(isnan(a_mil(:)))
      rows(end+1, :) = {label, 'N/D', 'N/D', 'N/D'}; %#ok<AGROW>
    else
      delta_norm = sqrt(sum((a_oth - a_mil).^2, 2));
      % RMS relativo: una sola cifra robusta para todo el registro
      rel_rms = sqrt(mean(delta_norm.^2, 'omitnan')) / mean_a_mil;
      % Max pointwise solo donde |a_mil| es significativo
      if any(mask)
        rel_filtered = delta_norm(mask) ./ a_mil_norm(mask);
        max_rel = max(rel_filtered, [], 'omitnan');
      else
        max_rel = NaN;
      end
      % Correlacion componente a componente
      C_x = corrcoef(a_oth(:,1), a_mil(:,1), 'Rows', 'complete');
      C_y = corrcoef(a_oth(:,2), a_mil(:,2), 'Rows', 'complete');
      corr_mean = mean([C_x(1,2), C_y(1,2)]);
      rows(end+1, :) = {label, ...
                        rel_rms*100, ...
                        max_rel*100, ...
                        corr_mean}; %#ok<AGROW>
    end
  end

  writecell(rows, filepath, 'Sheet', 'Resumen');
end

% =====================================================================
% Hoja: Series (datos punto a punto)
% =====================================================================

function write_series(filepath, t, r_truth, v_truth, r_nav, v_nav, r_ref, ...
                      a_mil, a_softsil, a_pil)
  d_softsil      = a_softsil - a_mil;
  d_softsil_norm = sqrt(sum(d_softsil.^2, 2));
  d_pil          = a_pil - a_mil;
  d_pil_norm     = sqrt(sum(d_pil.^2, 2));

  T = table( ...
    t, ...
    r_truth(:,1),   r_truth(:,2), ...
    v_truth(:,1),   v_truth(:,2), ...
    r_nav(:,1),     r_nav(:,2), ...
    v_nav(:,1),     v_nav(:,2), ...
    r_ref(:,1),     r_ref(:,2), ...
    a_mil(:,1),     a_mil(:,2), ...
    a_softsil(:,1), a_softsil(:,2), ...
    a_pil(:,1),     a_pil(:,2), ...
    d_softsil(:,1), d_softsil(:,2), d_softsil_norm, ...
    d_pil(:,1),     d_pil(:,2),     d_pil_norm, ...
    'VariableNames', { ...
      't_s', ...
      'r_truth_x', 'r_truth_y', ...
      'v_truth_x', 'v_truth_y', ...
      'r_nav_x',   'r_nav_y', ...
      'v_nav_x',   'v_nav_y', ...
      'r_ref_x',   'r_ref_y', ...
      'a_mil_x',     'a_mil_y', ...
      'a_softsil_x', 'a_softsil_y', ...
      'a_pil_x',     'a_pil_y', ...
      'd_softsil_x', 'd_softsil_y', 'd_softsil_norm', ...
      'd_pil_x',     'd_pil_y',     'd_pil_norm'});

  writetable(T, filepath, 'Sheet', 'Series');
end

% =====================================================================
% Utilidades
% =====================================================================

function v = safe_eval(name)
% Lee una variable del workspace base devolviendo '<no def>' si no existe.
  if evalin('base', sprintf('exist(''%s'',''var'')', name))
    v = evalin('base', name);
  else
    v = '<no def>';
  end
end

function s = format_value(v)
% Convierte un valor del workspace en string legible para Excel.
  if isnumeric(v)
    if isscalar(v)
      s = v;                                    % numero -> Excel lo trata como numero
    elseif isvector(v)
      s = ['[' strjoin(arrayfun(@(x) sprintf('%g',x), v(:).', ...
            'UniformOutput', false), ', ') ']'];
    else
      s = mat2str(v);
    end
  elseif ischar(v) || isstring(v)
    s = char(v);
  else
    s = '<no numerico>';
  end
end