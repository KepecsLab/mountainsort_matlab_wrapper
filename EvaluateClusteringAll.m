%% Script to analyse the data in mountainview

%%%% USER %%%%%%%%%
Animal = 'P32';
Date = '2016-10-28';%for multiple sessions, Animals must be of same length
%%%%%%%%%%%%%%%%%%

%%%%% PATHS %%%%%%%
serverpathbase =  '/media/confidence/Data/';% source path to nlx files
datapathbase = '/hdd/Data/Paul/'; %where to store mda files (big files). recommend HDD.
sortingpathbase = '/home/hoodoo/mountainsort/'; %where to store mountainlab sorting results (small(er) files). recommend SSD.
%%%%%%%%%%%%%%%%%%

view_tetrode=1; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=2; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=3; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=4; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=5; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=6; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=7; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=8; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=9; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=10; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=11; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=12; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=13; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=14; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=15; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%


view_tetrode=16; %which tetrode to look at
%%%% RUN %%%%%%%%%
params=struct('basepath',sortingpathbase,'animal',Animal,'date',Date,'tetrode',view_tetrode,...
    'metrics','cluster_metrics_annotated.json','session',1);
% ALL MOUNTAINVIEW
 start_mountainview(params);
%%%%%%%%%%%%%%%%%%



%execute this to clean cache AFTER evaluating clusters. this will delete
%temp-files needed to evaluate clusters! (filtered + whitened timeseries)

% mlsystem('mountainprocess cleanup-cache')