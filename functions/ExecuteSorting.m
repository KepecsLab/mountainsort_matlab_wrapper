function ExecuteSorting(Params)
% ExecuteSorting(...)

% 1) runs clustering pipeline
% 2) saves clustering result
% 3) converts clustering results back to matlab array and combined with
%    original header info, also converts event timestamps from neuralynx
%    (us) in seconds and cellbase times (has to add offset and divide by 10e4)

%inputs are: A struct PARAMS with required fields
%            Animal: subject id, eg P32
%            Date:   session date, eg 2016-08-30 (format as seen)
%            Trodes: array of trodes to be converted
%            ServerPathBase: path to folder containing recording sessions
%                            (server recommended)
%            DataPathBase: path to folder where converted files will be
%                            stored (local recommended)
%            SortingPathBase: path to folder where clustering results are
%                              stored (local recommended)
%            ParamsPath: path to parameter file (json)
%            CurationPath: path to curation file 
%            ScriptPath: path to script file (javascript, run by mountainlab)

%dependencies: readmda()
%              mountainlab-js software package 

% Torben Ott, CSHL, May 2018

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
animal = Params.Animal;
date = Params.Date;
trodes=Params.Trodes;
datapathbase = Params.DataPathBase;
sortingpathbase = Params.SortingPathBase;
paramssourcepath = Params.ParamsPath;
curationsourcepath = Params.CurationPath;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sessions_found = findSessions(datapathbase,animal,date);

Errors = [' '];
for s = 1:length(sessions_found)%sessions of day
    
    % sessions
    session = sessions_found{s};
    
    % used tetrodes
    use_trode = true(1,length(trodes));
    
    %raw mda file full paths
    package_path = fileparts(fileparts(mfilename('fullpath')));
    engine_path = fullfile(package_path,'LoadingEngines',Params.LoadingEngine);
    addpath(engine_path);    
    fun = str2func(Params.LoadingEngine);
    MDAFiles = feval(fun,'path','',fullfile(datapathbase,animal,session),Params);
    
    
    for d = 1:length(trodes) %datasets (n-trodes)
        
        tr = trodes(d);
        
        %mda file full path
        sourcefilefull = MDAFiles{d};
        
        tr_folder = fullfile(sortingpathbase,animal,session,'ms4',strcat('NT',num2str(tr)));
        
        %assemble files for each session, dataset
        if ~isdir(tr_folder)
            mkdir(tr_folder);
        end
        
        %curation script
        curationdestpath = fullfile(tr_folder,'annotation.script');
        copyfile(curationsourcepath,curationdestpath);
        
        %params file
        paramsdestpath = fullfile(tr_folder,'params.json');
        copyfile(paramssourcepath,paramsdestpath) 
        
        %raw data prv
        if exist(sourcefilefull,'file')~=2
            fprintf('Skipped session %s trode %s (no mda-file).ExecuteSorting.\n',session,num2str(tr));
            use_trode(d)=false;
            continue
        end
        
        %create prv for raw file
        mlsystem(['ml-prv-create ',sourcefilefull,' ',fullfile(tr_folder,'raw.mda.prv')]);
        
        %% RUN SORTING PIPELINE
        inputs.timeseries = fullfile(tr_folder,'raw.mda.prv');
        outputs.firings_out = fullfile(tr_folder,'firings.mda');
        outputs.filt_out = fullfile(tr_folder,'filt.mda.prv');
        outputs.pre_out = fullfile(tr_folder,'pre.mda.prv');
        params = loadjson(paramsdestpath);
        
        %filter
        if params.filter
            ml_run_process('ms3.bandpass_filter',struct('timeseries',inputs.timeseries),struct('timeseries_out',outputs.filt_out),...
                struct('samplerate',params.samplerate,'freq_min',params.freq_min,'freq_max',params.freq_max))
        else
            outputs.filt_out = inputs.timeseries;
        end
        
        %mask out artifacts
        if params.mask_out_artifacts
            ml_run_process('ms3.mask_out_artifacts',struct('timeseries',outputs.filt_out),struct('timeseries_out',outputs.filt_out),...
                struct('threshold',6,'interval_size',2000))
        end
          
        %whiten
        if params.whiten
            ml_run_process('ms3.whiten',struct('timeseries',outputs.filt_out),struct('timeseries_out',outputs.pre_out),...
                struct())
        else
            outputs.pre_out = outputs.filt_out;
        end
          
        %sort
        if isfield(Params,'GeomPath') && ~isempty(Params.GeomPath)
            if exist(Params.GeomPath,'file') == 2
                Input = struct('timeseries',outputs.pre_out,'geom',Params.GeomPath );
            else
                warning('Geom file not found at %s.\n',Params.GeomPath);
            end
        else
            Input = struct('timeseries',outputs.pre_out);
        end
        ml_run_process('ms4alg.sort',Input,struct('firings_out',outputs.firings_out),...
            struct('adjacency_radius',params.adjacency_radius,...
            'detect_sign',params.detect_sign,...
            'detect_threshold',params.detect_threshold,...
            'detect_interval',params.detect_interval,...
            'clip_size',params.clip_size,...
            'num_workers',params.num_workers));
        
        
        
        %convert results back to mat
        %There is now a firings.mda in sortingpathbase,session,animal,ms4,NT*
        %(tr_folder) folder with sorting results
        
        %convert to matlab array
        firings = readmda(fullfile(tr_folder,'firings.mda'));
        
        %add recording file header info and convert firings timestamps to seconds
        %(by loading engine, optional) 
        try
            add = feval(fun,'header','',fullfile(datapathbase,animal,session),Params,fullfile(tr_folder,'firings.mda'));
            fields = fieldnames(add);
            for f = 1:length(fields)
                clusters.(fields{f}) = add.(fields{f});
            end
        catch
            warning('ExecuteSorting:No header mode in Loading Engine. No header written to clusters.mat.\n');
        end
        
        
        %save firings to result struct
        clusters.firings=firings;
        
        %save as mat in output folder
        save(fullfile(tr_folder,'clusters.mat'),'clusters');
        
        %         %save relevant results on server
        %         if ~isdir(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4)))
        %             mkdir(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4)));
        %         end
        %         try
        %             save(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4),'clusters.mat'),'clusters');
        %             save(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4),'header.mat'),'header');
        %         catch
        %             ('WARNING: ExecuteSortingKron: Copying files to server failed.\n');
        %         end
    end
    
end%sessions

fprintf(Errors)

