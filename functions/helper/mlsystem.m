function mlsystem(str,opts)

if nargin<2, opts=struct; end;

PATH = getenv('PATH');
setenv('PATH', [PATH ':/home/hoodoo/anaconda3/bin:/home/hoodoo/mountainlab-js/bin:/home/hoodoo/.mountainlab/packages/qt-mountainview/bin']);

str=sprintf('source activate ml-env; %s',str);

if isfield(opts,'working_dir')
    str=sprintf('cd %s; %s',opts.working_dir,str);
end;

return_code = system(str);

if (return_code~=0)
    error('Error running system command: %s',str);
end
