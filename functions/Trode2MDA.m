function Trode2MDALocal(Params)
%Trode2MDA(...) converts Recording files (e.g. Neuralynx or SpikeGadget continuous recording files) to mountainlab
%readable mda-files.
%
%inputs is a config struct PARAMS with required fields
%            Animal: animal id (determines folder name containing sessions)
%            Date:   session date, eg 2016-08-30 (format as seen, determines session folder name)
%            Trodes: array of trodes to be converted
%            ServerPathBase: path to folder containing recording sessions
%                            (server recommended)
%            DataPathBase: path to folder where converted files will be
%                            stored (local recommended)
%            LoadingEngine: 

% mda file will be saved in sourcepathbase/SUBJECT/SESSION/TRODE#.

%dependencies: nlx2mda()
%                  subdependencies: writemda16i(), Nlx2MatCSC_v3()

% Torben Ott, CSHL, September 2018

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
animal = Params.Animal;
date = Params.Date;
serverpathbase=Params.ServerPathBase;
datapathbase = Params.DataPathBase;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sessions_found = findSessions(serverpathbase,animal,date);

for f = 1:length(sessions_found)
    
    sessionname = sessions_found{f};
    
    package_path = fileparts(fileparts(mfilename('fullpath')));
    engine_path = fullfile(package_path,'LoadingEngines',Params.LoadingEngine);
    addpath(engine_path);
    
    %% Run Loading Engine
    
    %Loading Engine needs to be a function (Params.LoadingEngine).m in
    %/LoadingEngines/Params.LoadingEngine folder with:
    % input: sessionpath - path to recording session data
    %        outpath - base path to destination (for mda files)
    %        Params struct for itnernal function usage of parameters
    %(Params.LoadingEngine).m needs to write session mda file for all datasets
    %required for that session (e.g. all tetrodes). See example template
    %Loading Engines.
    
    sessionpath = fullfile(serverpathbase,animal,sessionname);
    outpath = datapathbase;
    
    fun = str2func(Params.LoadingEngine);
    feval(fun,sessionpath,outpath,Params)
    
end%folders
