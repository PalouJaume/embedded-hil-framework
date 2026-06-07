% l1_run_mil.m  — ejecuta el MIL y encadena validacion + plot
%

l1_init;

out = sim('l1_mil');

fprintf('Simulacion MIL completada.\n');

results = l1_validate(out, 'Mode', 'mil');
l1_plot(out)