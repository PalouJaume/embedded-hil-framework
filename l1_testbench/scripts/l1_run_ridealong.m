% l1_run_ridealong.m  — ejecuta la simulacion ridealong y exporta a Excel
l1_init;

out = sim('l1_ridealong');
fprintf('Simulacion Ridealong completada.\n');

% Exportacion comparativa MIL / SoftSIL / PIL
filepath = l1_ridealong_export(out);