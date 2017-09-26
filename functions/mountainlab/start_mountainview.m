%start mountainview from matlab
function start_mountainview(params)

if ~isfield(params, 'basepath'), params.basepath='/home/hoodoo/mountainsort'; end
if ~isfield(params, 'animal'), params.animal='P36'; end
if ~isfield(params, 'date'), params.date='2017-07-10'; end
if ~isfield(params, 'tetrode'), params.tetrode=1; end
if ~isfield(params, 'session'), params.session=1; end
if ~isfield(params, 'metrics'), params.metrics='cluster_metrics_annotated.json'; end

sessions = findSessions(params.basepath,params.animal,params.date);

if length(sessions) > 1
    fprintf('Warning: Multiple sessions found. Specify session index. Starting session 1...');
end

dataset = fullfile(params.basepath,params.animal,sessions{params.session},'output',['ms3--t',num2str(params.tetrode)]);

params = struct(...
    'raw',fullfile(dataset,'raw.mda.prv'),... 
    'filt',fullfile(dataset,'filt.mda.prv'),...
    'pre',fullfile(dataset,'pre.mda.prv'),...
    'firings',fullfile(dataset,'firings.mda'),...
    'samplerate',30000,...
    'cluster_metrics',fullfile(dataset,params.metrics)...
);

% Launch the viewer
mountainview(params);


function mountainview(A)
ld_library_str='LD_LIBRARY_PATH=/usr/local/lib';
args='';
keys=fieldnames(A);
for j=1:length(keys)
    args=sprintf('%s--%s=%s ',args,keys{j},num2str(A.(keys{j})));
end;
cmd=sprintf('%s mountainview %s &',ld_library_str,args);
fprintf('%s\n',cmd);
system(cmd);
