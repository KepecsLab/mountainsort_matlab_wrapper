function ml_run_process(processor_name,inputs,outputs,params)

% Example:
% ml_run_process('ms3.bandpass_filter',struct('timeseries','tetrode6.mda'),struct('timeseries_out','tetrode6_filt.mda'),struct('samplerate',32556,'freq_min',300,'freq_max',6000));

if nargin<4, params=struct; end;

cmd='ml-run-process';
cmd=[cmd,' ',processor_name];
cmd=[cmd,' --inputs',create_arg_string(inputs)];
cmd=[cmd,' --outputs',create_arg_string(outputs)];
if ~isempty(params) &&  ~isempty(fieldnames(params))
cmd=[cmd,' --parameters',create_arg_string(params)];
end
mlsystem(cmd);


function str=create_arg_string(params)
list={};
keys=fieldnames(params);
for i=1:length(keys)
    key=keys{i};
    val=params.(key);
    if (iscell(val))
        for cc=1:length(val)
            list{end+1}=sprintf(' %s:%s',key,create_val_string(val{cc}));
        end;
    else
        list{end+1}=sprintf(' %s:%s',key,create_val_string(val));
    end;
end;
str=strjoin(list,' ');

function str=create_val_string(val)
str=num2str(val);
