function mlsystem(str,opts)

if nargin<2, opts=struct; end;

str=sprintf('LD_LIBRARY_PATH=/usr/local/lib %s',str);

if isfield(opts,'working_dir')
    str=sprintf('cd %s; %s',opts.working_dir,str);
end;

system(str);