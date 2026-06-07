% l1_run_mil.m  — ejecuta el soft-SiL y encadena validacion + plot
%

l1_init;

out = sim('l1_soft_sil');

fprintf('Simulacion MIL completada.\n');

results = l1_validate(out, 'Mode', 'soft_sil');
l1_plot(out)