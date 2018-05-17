% wrapper script to convert nlx recording files (*.ncs) to mda files
% and start mountainlab sorting pipeline.

% Torben Ott, CSHL, 2017

%%%%%PARAMS%%%%%%%%%%%%%
Animals = {'M2'};
Dates = {'2017-01-26'};%for multiple sessions, Animals must be of same length
Tetrodes={[1:16]}; %which tetrodes to include, cell of same length as Animals and Dates
Notify={''}; %cell with names; names need to be associated with email in MailAlert.m
ServerPathBase =  '/media/confidence/Data/';% source path to nlx files
DataPathBase = '/hdd/Data/Paul/'; %where to store mda files (big files). recommend HDD.
SortingPathBase = '/home/hoodoo/mountainsort/'; %where to store mountainlab sorting results (small(er) files). recommend SSD.
ParamsPath = '/home/hoodoo/Documents/MATLAB/mountainsort_matlab_wrapper/params/params_default.json'; %default params file location
CurationPath = '/home/hoodoo/Documents/MATLAB/mountainsort_matlab_wrapper/params/annotation.script'; %default curation script location
Convert2MDA = true; %if set to false, uses converted mda file if present
RunClustering = true; %if set to false, does not run clustering
Convert2MClust = false; %if set to false, does not convert to MClust readable cluster file (large!)
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
    tetrodes = Tetrodes{session};
    
    %which leads to use
    %default: all 4
    tetrodes_config = num2cell(repmat(1:4,tetrodes(end),1),2);
    
    %load animal-specific config file
    TetrodeConfigFile = strcat(animal,'Config.mat');
    if exist(TetrodeConfigFile,'file')==2
        load(TetrodeConfigFile);
    else
        warning('No animal config file found. Using all leads of all tetrodes.');
    end
    
    %build params struct
    Params.Date = date;
    Params.Animal = animal;
    Params.Tetrodes = tetrodes;
    Params.TetrodesConfig = tetrodes_config;
    Params.ServerPathBase = ServerPathBase;
    Params.DataPathBase = DataPathBase;
    Params.SortingPathBase = SortingPathBase;
    Params.ParamsPath = ParamsPath;
    Params.CurationPath = CurationPath;
    
    % convert ncs to mda
    if Convert2MDA
        tic
        try
            Tetrode2MDALocal(Params);
        catch
            MailAlert(Notify,'Hoodoo:SortingWrapperKron','Error:Tetrode2MDALocal.');
        end
        EXTRACTTIME(session) = toc;
    end
    
    
    % start analysis pipeline
    if RunClustering
        tic
        try
            ExecuteSortingKron(Params);
        catch
            MailAlert(Notify,'Hoodoo:SortingWrapperKron','Error:ExecuteSortingKron.');
        end
        SORTINGTIME(session) = toc;
    end
    
    
    % convert to  MClust tetrode data and cluster object
    if Convert2MClust
        tic
        try
            ConvertToMClust(animal,date,tetrodes,DataPathBase,SortingPathBase);
        catch
            MailAlert(Notify,'Hoodoo:SortingWrapperKron','Error:ConvertToMClust.');
        end
        MCLUSTCONVERTTIME(session) = toc;
    end
    
end%session

TIME = sum((EXTRACTTIME + SORTINGTIME + MCLUSTCONVERTTIME))/60;
fprintf('Overall Time: %2.1f min (session average %2.1f min).\n',TIME,TIME/length(Animals));

save('EXTRACTTIME.mat','EXTRACTTIME');
save('SORTINGTIME.mat','SORTINGTIME');
save('MCLUSTCONVERTTIME.mat','MCLUSTCONVERTTIME');

%send slack notification
MailAlert(Notify,'Hoodoo:SortingWrapperKron','Sorting Done.');


