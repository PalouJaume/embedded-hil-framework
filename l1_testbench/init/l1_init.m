% l1_init.m  — parametros nominales del escenario L1

% --- Seleccion de trayectoria activa ---
ACTIVE_TRAJECTORY = 'circle';   % 'circle' | 'line' | 'sinusoid'

% --- Parametros del vehiculo ---
V       = 30;
a_max   = 15;

% --- Parametros de la ley de guiado ---
k       = 2;

% --- Parametros de simulacion ---
dt_sim  = 0.02;
t_final = 3600;

% --- Parametros de la planta
% Viento % m/s
wind_vector = [10; 0];

% --- Parametros Systema de Control
tau_ctrl = 0.4;

if tau_ctrl > 0
    ctrl_num = dt_sim / (tau_ctrl + dt_sim);
    ctrl_den = [1, -tau_ctrl/(tau_ctrl + dt_sim)];
else
    ctrl_num = 1;
    ctrl_den = 1;
end

% --- Parametros Systema de Navegación

% Delay [DONE]
tau_gps = 0.4;
delay_samples_gps = max(1, round(tau_gps / dt_sim));

% Ruido
seed_r = 1234;
seed_v = 2465;

sigma_pos  = 1.0;     % m, desviacion tipica del ruido de posicion
sigma_vel  = 0.4;     % m/s, desviacion tipica del ruido de velocidad

% --- Parametros geometricos por trayectoria ---
% Circulo [DONE]
traj_circle_center = [0, 500];
traj_circle_R      = 500;

% Recta [DONE]
traj_line_origin = [0; 0];
traj_line_dir    = [-1; 1];

% Sinusoide [REVIEW]
traj_sin_origin    = [0; 0];
traj_sin_dir      = [1; 1];
traj_sin_freq     = 0.0001;
traj_sin_Amp      = 1000;

% --- Condiciones iniciales por trayectoria ---
switch ACTIVE_TRAJECTORY
  case 'circle'
    r0 = [550; 0];
    v0 = [0; V];
  case 'line'
    r0 = [50; 0];
    v0 = [0; V];
  case 'sinusoid'
    r0 = [0; 80];
    v0 = [V; 0];
  otherwise
    error('ACTIVE_TRAJECTORY desconocida: %s', ACTIVE_TRAJECTORY);
end

% --- Variantes para el Variant Subsystem ---
VAR_CIRCLE   = Simulink.VariantExpression('strcmp(ACTIVE_TRAJECTORY,''circle'')');
VAR_LINE     = Simulink.VariantExpression('strcmp(ACTIVE_TRAJECTORY,''line'')');
VAR_SINUSOID = Simulink.VariantExpression('strcmp(ACTIVE_TRAJECTORY,''sinusoid'')');