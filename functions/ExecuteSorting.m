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
recsys = Params.RecSys;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sessions_found = findSessions(datapathbase,animal,date);

Errors = [' '];
for s = 1:length(sessions_found)%sessions of day
    
    % sessions
    session = sessions_found{s};
    
    % used tetrodes
    use_trode = true(1,length(trodes));
    
    for d = 1:length(trodes) %datasets (n-trodes)
        
        tr = trodes(d);
        
        switch recsys
            case 'neuralynx'
                sourcefilename = strcat('trode',num2str(tr),'.mda');
                sourcefilepath = fullfile(datapathbase,animal,session,sourcefilename(1:end-4));
            case 'spikegadgets'
                ndx = regexp(session,'.mda');
                sourcefilename = strcat(session(1:ndx-1),'.nt',num2str(tr),'.mda');
                sourcefilepath = fullfile(datapathbase,animal,session);
        end%switch
        
        
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
        sourcefilefull = fullfile(sourcefilepath,sourcefilename);
        
        if exist(sourcefilefull,'file')~=2
            fprintf('Skipped session %s trode %s (no mda-file).ExecuteSorting.\n',session,num2str(tr));
            use_trode(d)=false;
            continue
        end
        
        %create prv for raw file
        mlsystem(['ml-prv-create ',sourcefilefull,' ',fullfile(tr_folder,'raw.mda.prv')]);
        
        %%RUN SORTING PIPELINE
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
          
        %whiten
        if params.whiten
            ml_run_process('ms3.whiten',struct('timeseries',outputs.filt_out),struct('timeseries_out',outputs.pre_out),...
                struct())
        else
            outputs.pre_out = outputs.filt_out;
        end
          
        %sort
        ml_run_process('ms4alg.sort',struct('timeseries',outputs.pre_out),struct('firings_out',outputs.firings_out),...
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
        
        %add original nlx header info
        header = load(fullfile(datapathbase,animal,session,sourcefilename(1:end-4),[sourcefilename(1:end-4),'header.mat']));
        
        %save firings and header to result struct
        clusters.header=header.header;
        clusters.firings=firings;
        
        %conversion to seconds
        inRecord = mod( clusters.firings(2,:),clusters.header(1).NSample);
        iRecord = floor( clusters.firings(2,:)./clusters.header(1).NSample)+1;
        NewSpikes = clusters.header(1).TimeStamps(iRecord)*10^-6 + inRecord/clusters.header(1).SampleFreq;
        clusters.firings_seconds = NewSpikes;
        
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

