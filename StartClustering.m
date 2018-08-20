% wrapper script to convert recording filesto mda files
% and run mountainlab sorting pipeline, compute metrics

% Torben Ott, CSHL, 2018

%%%%%PARAMS%%%%%%%%%%%%%
Animals = {'M2'};
Dates = {'2017-10-17'};%for multiple sessions, Animals must be of same length
Trodes={[1:16]}; %which tetrodes to include, cell of same length as Animals and Dates
Notify={'Torben'}; %cell with names; names need to be associated with email in MailAlert.m
ServerPathBase =  '/media/confidence/Data/';% source path to rec files
DataPathBase = '/hdd/Data/Paul/'; %where to store mda files (big files). recommend HDD.
SortingPathBase = '/home/hoodoo/mountainsort/'; %where to store mountainlab sorting results (small(er) files). recommend SSD.
ParamsPath = '/home/hoodoo/Documents/MATLAB/mountainsort_matlab_wrapper/params/params_default_ms4.json'; %default params file location
CurationPath = '/home/hoodoo/Documents/MATLAB/mountainsort_matlab_wrapper/params/annotation_ms4.script'; %default curation script location
Convert2MDA = true; %if set to false, uses converted mda file if present
RunClustering = true; %if set to false, does not run clustering
ComputeMetrics = true; %if set to false, does not compute metrics
Convert2MClust = false; %if set to false, does not convert to MClust readable cluster file (large!)
LoadingEngine = 'NLXTetrode'; %user loading engine to convert rec sys data to mda file. See /LoadingEngines/
%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%this prepareas mountainview function for in-matlab call (execute only
%after soring)

% view_tetrode=11;
% params=struct('basepath',sortingpathbase,'animal',Animals{1},'date',Dates{1},'tetrode',view_tetrode,...
%     'metrics','cluster_metrics_annotated.json');
% % ALL MOUNTAINVIEW
%  start_mountainview(params);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%CLUSTERING PIPELINE
EXTRACTTIME = zeros(1,length(Animals)); SORTINGTIME=zeros(1,length(Animals)); MCLUSTCONVERTTIME=zeros(1,length(Animals));
for session = 1:length(Animals)
    %
    animal = Animals{session};
    date = Dates{session};
    trodes = Trodes{session};
    
    %which leads to use
    %default: all 4
    trodes_config = num2cell(repmat(1:4,trodes(end),1),2);
    
    %load animal-specific config file
    TrodeConfigFile = strcat(animal,'Config.mat');
    if exist(TrodeConfigFile,'file')==2
        load(TrodeConfigFile);
    else
        warning('No animal config file found. Using all leads of all tetrodes.');
    end
    
    %build params struct
    Params.Date = date;
    Params.Animal = animal;
    Params.Trodes = trodes;
    Params.TrodesConfig = trodes_config;
    Params.ServerPathBase = ServerPathBase;
    Params.DataPathBase = DataPathBase;
    Params.SortingPathBase = SortingPathBase;
    Params.ParamsPath = ParamsPath;
    Params.CurationPath = CurationPath;
    Params.ScriptPath = ScriptPath;
    Params.RecSys = RecSys;
    Params.LoadingEngine = LoadingEngine;
    
    % convert ncs to mda
    if Convert2MDA
        tic
        try
            Trode2MDA(Params);
        catch
            MailAlert(Notify,'Hoodoo:SortingWrapperKron','Error:Trode2MDALocal.');
        end
        EXTRACTTIME(session) = toc;
    end
    
    
    % start analysis pipeline
    if RunClustering
        tic
        try
            ExecuteSorting(Params);
        catch
            MailAlert(Notify,'Hoodoo:SortingWrapperKron','Error:ExecuteSorting.');
        end
        SORTINGTIME(session) = toc;
    end
    
    % compute metrics
    if ComputeMetrics
        tic
        try
            ComputeMetrics_ms3(Params)
        catch
            MailAlert(Notify, 'Hoodoo:SortingWrapperKron','Error:CopmuteMetrics');
        end
        METRICSTIME(session) = toc;
    end
    
    % convert to  MClust tetrode data and cluster object
    if Convert2MClust
        tic
        try
            ConvertToMClust(animal,date,trodes,DataPathBase,SortingPathBase);
        catch
            MailAlert(Notify,'Hoodoo:SortingWrapperKron','Error:ConvertToMClust.');
        end
        MCLUSTCONVERTTIME(session) = toc;
    end
    
end%session

TIME = sum((EXTRACTTIME + SORTINGTIME + METRICSTIME + MCLUSTCONVERTTIME))/60;
fprintf('Overall Time: %2.1f min (session average %2.1f min).\n',TIME,TIME/length(Animals));

save('EXTRACTTIME.mat','EXTRACTTIME');
save('SORTINGTIME.mat','SORTINGTIME');
save('METRICSTIME.mat','METRICSTIME');
save('MCLUSTCONVERTTIME.mat','MCLUSTCONVERTTIME');

%send slack notification
MailAlert(Notify,'Hoodoo:SortingWrapperKron','Sorting Done.');


