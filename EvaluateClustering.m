%% Script to analyse the data in mountainview

%%%% USER %%%%%%%%%
view_tetrode=15; %which tetrode to look at
Animal = 'P35';
Date = '2017-03-22';%for multiple sessions, Animals must be of same length
%%%%%%%%%%%%%%%%%%

%%%%% PATHS %%%%%%%
serverpathbase =  '/media/confidence/Data/';% source path to nlx files
datapathbase = '/hdd/Data/Paul/'; %where to store mda files (big files). recommend HDD.
sortingpathbase = '/home/hoodoo/mountainsort/'; %where to store mountainlab sorting results (small(er) files). recommend SSD.
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