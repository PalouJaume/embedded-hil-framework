root = fileparts(fileparts(mfilename('fullpath')));

src_wrapper = fullfile(root, 'mex',     'PiL_sfcn.c');
inc_dir     = fullfile(root, 'include', 'GuidanceSystem');
out_dir     = fullfile(root, 'build');

if ~exist(out_dir, 'dir'), mkdir(out_dir); end

mex(src_wrapper, ['-I' inc_dir], '-lws2_32', '-lmswsock', '-ladvapi32', '-outdir', out_dir);

disp('[MEX] PiL_sfcn compilado correctamente.');