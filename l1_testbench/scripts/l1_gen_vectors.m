function l1_gen_vectors(varargin)
% l1_gen_vectors  — Genera l1_test_vectors_YYYYMMDD_HHMMSS.h
%
% Uso:
%   l1_gen_vectors()
%   l1_gen_vectors('TSamples', [0, 30, 60])
%   l1_gen_vectors('TSamples', [0, 50, 200], 'NRandom', 50)
%   l1_gen_vectors('TSamples', [10, 20], 'NRandom', 0, 'Seed', 42)
%
% Parametros opcionales:
%   'TSamples' — vector de instantes [s] para muestras concretas (#define)
%                Por defecto: [0, 30, 60]
%   'NRandom'  — numero de muestras aleatorias por trayectoria (arrays C)
%                Por defecto: 20. Usar 0 para desactivar.
%   'Seed'     — semilla del generador aleatorio (reproducibilidad)
%                Por defecto: 12345

  % --- Parser de argumentos ---
  p = inputParser;
  addParameter(p, 'TSamples', [0, 30, 60], @(x) isnumeric(x) && isvector(x));
  addParameter(p, 'NRandom',  20,           @(x) isnumeric(x) && x >= 0);
  addParameter(p, 'Seed',     12345,        @isnumeric);
  parse(p, varargin{:});

  t_samples = p.Results.TSamples;
  n_random  = p.Results.NRandom;
  seed      = p.Results.Seed;

  % Generar tags automaticamente: T0, T50, T200, ...
  t_tags = arrayfun(@(t) sprintf('T%d', round(t)), t_samples, 'UniformOutput', false);

  % --- Nombre de fichero con timestamp ---
  timestamp   = datestr(now, 'yyyymmdd_HHMMSS');
  output_name = sprintf('l1_test_vectors_%s.h', timestamp);
  output_path = fullfile('results', 'vectors', output_name);

  scenarios = {
    'circle',   'CIRCLE';
    'line',     'LINE';
    'sinusoid', 'SINUSOID';
  };
  
  evalin('base', 'l1_init;');

  rng(seed);

  fid = fopen(output_path, 'w');
  if fid == -1
    error('No se pudo abrir %s para escritura', output_path);
  end

  % --- Cabecera del fichero ---
  [~, git_hash] = system('git rev-parse --short HEAD');
  git_hash = strtrim(git_hash);

  guard = upper(strrep(output_name, '.', '_'));

  fprintf(fid, '/* =================================================================== */\n');
  fprintf(fid, '/* l1_test_vectors — Ground truth para tests Unity                     */\n');
  fprintf(fid, '/* Generado automaticamente por l1_gen_vectors.m                       */\n');
  fprintf(fid, '/* NO EDITAR — regenerar desde MATLAB cuando cambien los parametros    */\n');
  fprintf(fid, '/* =================================================================== */\n\n');

  fprintf(fid, '/* --- Trazabilidad --- */\n');
  fprintf(fid, '/* Fecha:           %s */\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
  fprintf(fid, '/* Git hash:        %s */\n', git_hash);
  fprintf(fid, '/* MATLAB version:  %s */\n', version);
  fprintf(fid, '\n');

  fprintf(fid, '/* --- Configuracion del generador --- */\n');
  fprintf(fid, '/* Muestras concretas:  [%s] s */\n', ...
          strjoin(arrayfun(@(t) sprintf('%g', t), t_samples, 'UniformOutput', false), ', '));
  fprintf(fid, '/* Muestras aleatorias: %d (semilla: %d) */\n', n_random, seed);
  fprintf(fid, '\n');

  fprintf(fid, '/* --- Parametros del vehiculo --- */\n');
  fprintf(fid, '/* V              = %g m/s */\n',  evalin('base', 'V'));
  fprintf(fid, '/* a_max          = %g m/s^2 */\n', evalin('base', 'a_max'));
  fprintf(fid, '\n');

  fprintf(fid, '/* --- Ley de guiado L1 --- */\n');
  fprintf(fid, '/* k              = %g */\n', evalin('base', 'k'));
  fprintf(fid, '\n');

  fprintf(fid, '/* --- Simulacion --- */\n');
  fprintf(fid, '/* dt_sim         = %g s */\n', evalin('base', 'dt_sim'));
  fprintf(fid, '/* t_final        = %g s */\n', evalin('base', 't_final'));
  fprintf(fid, '\n');

  fprintf(fid, '/* --- Realismo del banco --- */\n');
  fprintf(fid, '/* tau_ctrl       = %g s    (retardo actuador) */\n', evalin('base', 'tau_ctrl'));
  fprintf(fid, '/* tau_gps        = %g s    (retardo GPS) */\n',      evalin('base', 'tau_gps'));
  fprintf(fid, '/* sigma_pos      = %g m    (ruido posicion) */\n',   evalin('base', 'sigma_pos'));
  fprintf(fid, '/* sigma_vel      = %g m/s  (ruido velocidad) */\n',  evalin('base', 'sigma_vel'));
  wind = evalin('base', 'wind_vector');
  fprintf(fid, '/* wind_vector    = [%g, %g] m/s */\n', wind(1), wind(2));
  fprintf(fid, '\n');

  fprintf(fid, '/* --- Trayectorias --- */\n');
  circ_O = evalin('base', 'traj_circle_center');
  fprintf(fid, '/* circle:    R = %g m, center = [%g, %g] */\n', ...
          evalin('base', 'traj_circle_R'), circ_O(1), circ_O(2));
  line_O = evalin('base', 'traj_line_origin');
  line_d = evalin('base', 'traj_line_dir');
  fprintf(fid, '/* line:      origin = [%g, %g], dir = [%g, %g] */\n', ...
          line_O(1), line_O(2), line_d(1), line_d(2));
  sin_O = evalin('base', 'traj_sin_origin');
  sin_d = evalin('base', 'traj_sin_dir');
  fprintf(fid, '/* sinusoid:  origin = [%g, %g], dir = [%g, %g], A = %g, f = %g */\n', ...
          sin_O(1), sin_O(2), sin_d(1), sin_d(2), ...
          evalin('base', 'traj_sin_Amp'), evalin('base', 'traj_sin_freq'));
  fprintf(fid, '\n');

  fprintf(fid, '#ifndef %s\n', guard);
  fprintf(fid, '#define %s\n\n', guard);

  fprintf(fid, '#define K %g // Ganancia Ley de Guiado \n', evalin('base', 'k'));
  fprintf(fid, '\n');

  for s = 1:size(scenarios, 1)
    traj_name = scenarios{s, 1};
    traj_tag  = scenarios{s, 2};

    fprintf('Generando vectores para trayectoria: %s\n', traj_name);

    assignin('base', 'ACTIVE_TRAJECTORY', traj_name);
    evalin('base', 'l1_init;');

    out = sim('l1_mil');

    t     = out.tout;
    r_f   = out.r_f_log.Data;
    v_f   = out.v_f_log.Data;
    r_p   = out.r_p_log.Data; 
    a_cmd = out.a_cmd_log.Data;

    if any(t_samples > t(end))
      warning('l1_gen_vectors:tSampleOutOfRange', ...
              'Algun TSample excede t_final=%.1fs en %s. Se clamea al ultimo paso.', ...
              t(end), traj_name);
    end

    % --- Bloque 1: muestras concretas (#define) ---
    fprintf(fid, '/* =========================================== */\n');
    fprintf(fid, '/* %s — muestras concretas (regresion)         */\n', traj_name);
    fprintf(fid, '/* =========================================== */\n\n');

    for k = 1:numel(t_samples)
      t_target = t_samples(k);
      t_tag    = t_tags{k};
      [~, idx] = min(abs(t - t_target));

      fprintf(fid, '/* %s — t = %.1fs */\n', traj_name, t_target);
      fprintf(fid, '#define R_F_%s_%s_X     %.10ff\n', traj_tag, t_tag, r_f(idx, 1));
      fprintf(fid, '#define R_F_%s_%s_Y     %.10ff\n', traj_tag, t_tag, r_f(idx, 2));
      fprintf(fid, '#define V_F_%s_%s_X     %.10ff\n', traj_tag, t_tag, v_f(idx, 1));
      fprintf(fid, '#define V_F_%s_%s_Y     %.10ff\n', traj_tag, t_tag, v_f(idx, 2));
      fprintf(fid, '#define R_P_%s_%s_X     %.10ff\n', traj_tag, t_tag, r_p(idx, 1));
      fprintf(fid, '#define R_P_%s_%s_Y     %.10ff\n', traj_tag, t_tag, r_p(idx, 2));
      fprintf(fid, '#define A_CMD_%s_%s_X   %.10ff\n', traj_tag, t_tag, a_cmd(idx, 1));
      fprintf(fid, '#define A_CMD_%s_%s_Y   %.10ff\n', traj_tag, t_tag, a_cmd(idx, 2));
      fprintf(fid, '\n');
    end

    % --- Bloque 2: muestras aleatorias (arrays C iterables) ---
    if n_random > 0
      idx_min = max(2, floor(0.1 * numel(t)));
      idx_max = numel(t) - 1;
      rand_indices = sort(randi([idx_min, idx_max], n_random, 1));

      fprintf(fid, '/* =========================================== */\n');
      fprintf(fid, '/* %s — muestras aleatorias (cobertura)        */\n', traj_name);
      fprintf(fid, '/* =========================================== */\n\n');

      fprintf(fid, '#define N_SAMPLES_%s %d\n\n', traj_tag, n_random);

      fprintf(fid, 'static const float R_F_%s_SAMPLES[N_SAMPLES_%s][2] = {\n', traj_tag, traj_tag);
      for j = 1:n_random
        idx = rand_indices(j);
        fprintf(fid, '  {%.10ff, %.10ff}', r_f(idx, 1), r_f(idx, 2));
        if j < n_random, fprintf(fid, ','); end
        fprintf(fid, '   /* t=%.3fs */\n', t(idx));
      end
      fprintf(fid, '};\n\n');

      fprintf(fid, 'static const float V_F_%s_SAMPLES[N_SAMPLES_%s][2] = {\n', traj_tag, traj_tag);
      for j = 1:n_random
        idx = rand_indices(j);
        fprintf(fid, '  {%.10ff, %.10ff}', v_f(idx, 1), v_f(idx, 2));
        if j < n_random, fprintf(fid, ','); end
        fprintf(fid, '\n');
      end
      fprintf(fid, '};\n\n');

      fprintf(fid, 'static const float R_P_%s_SAMPLES[N_SAMPLES_%s][2] = {\n', traj_tag, traj_tag);
      for j = 1:n_random
          idx = rand_indices(j);
          fprintf(fid, '  {%.10ff, %.10ff}', r_p(idx, 1), r_p(idx, 2));
          if j < n_random, fprintf(fid, ','); end
          fprintf(fid, '   /* t=%.3fs */\n', t(idx));
      end
      fprintf(fid, '};\n\n');

      fprintf(fid, 'static const float A_CMD_%s_SAMPLES[N_SAMPLES_%s][2] = {\n', traj_tag, traj_tag);
      for j = 1:n_random
        idx = rand_indices(j);
        fprintf(fid, '  {%.10ff, %.10ff}', a_cmd(idx, 1), a_cmd(idx, 2));
        if j < n_random, fprintf(fid, ','); end
        fprintf(fid, '\n');
      end
      fprintf(fid, '};\n\n');
    end
  end

  fprintf(fid, '#endif /* %s */\n', guard);
  fclose(fid);

  fprintf('\nVectores generados en: %s\n', output_path);
  fprintf('  - %d muestras concretas por trayectoria (#define)\n', numel(t_samples));
  fprintf('  - %d muestras aleatorias por trayectoria (arrays)\n', n_random);
end