% Compilación del bloque S-function de GuidanceLaw
root = fileparts(fileparts(mfilename('fullpath')));  % raíz del proyecto

src_wrapper = fullfile(root, 'mex',    'GuidanceLaw_sfcn.c');
src_law     = fullfile(root, 'src',    'GuidanceSystem', 'GuidanceLaw.c');
inc_dir     = fullfile(root, 'include','GuidanceSystem');
out_dir     = fullfile(root, 'build');

if ~exist(out_dir, 'dir'), mkdir(out_dir); end

mex(src_wrapper, src_law, ['-I' inc_dir], '-outdir', out_dir);
disp('[MEX] GuidanceLaw_sfcn compilado correctamente.');