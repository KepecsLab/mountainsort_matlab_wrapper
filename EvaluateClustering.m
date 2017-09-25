%% Script to analyse the data in mountainview

%%%% USER %%%%%%%%%
view_tetrode=8; %which tetrode to look at
Animal = 'TG020';
Date = '20170921';%for multiple sessions, Animals must be of same length
%%%%%%%%%%%%%%%%%%

%%%%% PATHS %%%%%%%
serverpathbase =  '/media/thiagoatserver/Neurodata/Spikegadgets';% source path to original recording files
datapathbase = '/home/thiago/Neurodata/Spikegadgets'; %where to store mda files (big files). recommend HDD.
sortingpathbase = '/shorthand/Neurodata/mountainsort/'; %where to store mountainlab sorting results (small(er) files). recommend SSD.
%%%%%%%%%%%%%%%%%%

%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


%execute this to clean cache AFTER evaluating clusters. this will delete
%temp-files needed to evaluate clusters! (filtered + whitened timeseries)

% mlsystem('mountainprocess cleanup-cache')