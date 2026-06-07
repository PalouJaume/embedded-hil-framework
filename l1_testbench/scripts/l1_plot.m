function l1_plot(out)
% l1_plot_mil — plot de la trayectoria del vehiculo contra la referencia
%
% La referencia se dibuja:
%   - Circulo:    completo (siempre)
%   - Recta:      en el rango longitudinal recorrido por el vehiculo
%   - Sinusoide:  en el rango longitudinal recorrido por el vehiculo

active = evalin('base', 'ACTIVE_TRAJECTORY');
r_f    = out.r_m_log.Data;
r_nav  = out.r_f_log.Data;    

margin = 50;   % margen [m] que se anade al rango recorrido

figure('Position', [100 100 700 700]);
hold on;

switch active
    case 'circle'
        traj_R = evalin('base', 'traj_circle_R');
        traj_O = evalin('base', 'traj_circle_center');
        theta = linspace(0, 2*pi, 200);
        ref_x = traj_O(1) + traj_R * cos(theta);
        ref_y = traj_O(2) + traj_R * sin(theta);
        plot(ref_x, ref_y, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5, ...
            'DisplayName', 'Trayectoria de referencia');
        title_str = sprintf('Circulo (R = %d m)', traj_R);

    case 'line'
        O     = evalin('base', 'traj_line_origin');
        d_hat = evalin('base', 'traj_line_dir');
        d_hat = d_hat / norm(d_hat);

        % Proyeccion del vehiculo sobre la recta para hallar el rango
        s_proj = (r_f - O') * d_hat;
        s_min = min(s_proj) - margin;
        s_max = max(s_proj) + margin;

        s_range = [s_min, s_max];
        ref_x = O(1) + s_range * d_hat(1);
        ref_y = O(2) + s_range * d_hat(2);
        plot(ref_x, ref_y, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5, ...
            'DisplayName', 'Trayectoria de referencia');
        title_str = 'Recta';

    case 'sinusoid'
        O = evalin('base', 'traj_sin_origin');
        d = evalin('base', 'traj_sin_dir');
        f = evalin('base', 'traj_sin_freq');
        A = evalin('base', 'traj_sin_Amp');

        d = d / norm(d);

        % Proyeccion del vehiculo sobre la direccion principal
        s_proj = (r_f - O') * d;
        s_min = min(s_proj) - margin;
        s_max = max(s_proj) + margin;

        N = 1000;
        l = linspace(s_min, s_max, N)';

        p = [-d(2); d(1)];
        p = p / norm(p);

        linea = O.' + l * d.';
        pert  = A * sin(2*pi*f*l);
        tray  = linea + pert * p.';

        ref_x = tray(:,1);
        ref_y = tray(:,2);
        plot(ref_x, ref_y, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5, ...
            'DisplayName', 'Trayectoria de referencia');
        title_str = 'Sinusoide';

    otherwise
        title_str = 'MIL';
end

plot(r_nav(:,1), r_nav(:,2), 'r-', 'LineWidth', 1.5, ...
    'DisplayName', 'Datos navegación');

plot(r_f(:,1), r_f(:,2), 'b-', 'LineWidth', 1.5, ...
    'DisplayName', 'Trayectoria del vehiculo');

plot(r_f(1,1),   r_f(1,2),   'go', 'MarkerSize', 10, ...
    'MarkerFaceColor', 'g', 'DisplayName', 'Inicio');
plot(r_f(end,1), r_f(end,2), 'rs', 'MarkerSize', 10, ...
    'MarkerFaceColor', 'r', 'DisplayName', 'Final');

hold off;
axis equal;
grid on;
xlabel('x [m]');
ylabel('y [m]');
title(title_str);
legend('Location', 'best');
end