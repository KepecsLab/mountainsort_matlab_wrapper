function ExecuteSortingKron(Params)
% ExecuteSorting(...)

% 1) runs clustering pipeline 
% 2) saves clustering result 
% 3) converts clustering results back to matlab array and combined with
%    original header info, also converts event timestamps from neuralynx
%    (us) in seconds and cellbase times (has to add offset and divide by 10e4)

%inputs are: A struct PARAMS with required fields
%            Animal: subject id, eg P32
%            Date:   session date, eg 2016-08-30 (format as seen)
%            Tetrodes: array of tetrodes to be converted
%            ServerPathBase: path to folder containing recording sessions
%                            (server recommended)
%            DataPathBase: path to folder where converted files will be
%                            stored (local recommended)
%            SortingPathBase: path to folder where clustering results are
%                              stored (local recommended)
%                          

%dependencies: readmda()
%              mountainlab software package with

% Torben Ott, CSHL, September 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
animal = Params.Animal;
date = Params.Date;
tetrodes=Params.Tetrodes;
serverpathbase=Params.ServerPathBase;
datapathbase = Params.DataPathBase;
sortingpathbase = Params.SortingPathBase;
paramssourcepath = Params.ParamsPath;
curationsourcepath = Params.CurationPath;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sessions_found = findSessions(datapathbase,animal,date);

%start daemon
mlsystem('mp-set-default-daemon admin');
mlsystem('mp-daemon-start admin');

Errors = [' '];
for s = 1:length(sessions_found)%sessions of day
    
    session = sessions_found{s};
    
    %for each session, create a sorting folder with specs for pipeline and
    %datasets (tetrodes)
    %pipeline spec
    if ~isdir(fullfile(sortingpathbase,animal,session))
        mkdir(fullfile(sortingpathbase,animal,session));
    end
    pipelines_txt = fopen(fullfile(sortingpathbase,animal,session,'pipelines.txt'),'w');
    fprintf(pipelines_txt,'ms3 ms3.pipeline --generate_pre=1 --generate_filt=1 --_nodaemon \n');
    fclose(pipelines_txt);
    %datasets spec
    datasets_txt = fopen(fullfile(sortingpathbase,animal,session,'datasets.txt'),'w');
    %curation script
    copyfile(curationsourcepath,fullfile(sortingpathbase,animal,session,'annotation.script'));
    
    %used tetrodes
    use_tetrode = true(1,length(tetrodes));
    
    for t = 1:length(tetrodes)%tetrodes in session of day
        
        tet = tetrodes(t);
        sourcefilename = strcat('tetrode',num2str(tet),'.mda');
        sourcefilepath = fullfile(datapathbase,animal,session,sourcefilename(1:end-4));
        sourcefilefull = fullfile(sourcefilepath,sourcefilename);
        
        if exist(sourcefilefull,'file')~=2
            fprintf('Skipped session %s Tetrode %s (no mda-file).ExecuteSorting.\n',session,num2str(tet));
            use_tetrode(t)=false;
            continue
        end
        
        %create dataset folder, copy default params and create entry for dataset
        if ~isdir(fullfile(sortingpathbase,animal,session,'datasets',sourcefilename(1:end-4)))
            mkdir(fullfile(sortingpathbase,animal,session,'datasets',sourcefilename(1:end-4)));
        end
        paramsdestpath = fullfile(sortingpathbase,animal,session,'datasets',sourcefilename(1:end-4),'params.json');
        copyfile(paramssourcepath,paramsdestpath);
        fprintf(datasets_txt,['t', num2str(tet),' datasets/tetrode',num2str(tet),' --_iff=',session,'\n']);
        %create prv for raw file
        mlsystem(['prv-create ',sourcefilefull,' ',fullfile(sortingpathbase,animal,session,'datasets',sourcefilename(1:end-4),'raw.mda.prv')]);   

    end%tetrodes in session
    fclose(datasets_txt);
    
    %run sorting jobErrors = [];
    tetrodes_used = tetrodes(use_tetrode);
    t_str=[];
    for t = 1:length(tetrodes_used)
        t_str = [t_str,'t',num2str(tetrodes_used(t)),','];
    end
    t_str(end)=[];
    mlsystem(['kron-run ms3 ',t_str],struct('working_dir',fullfile(sortingpathbase,animal,session)));
    

    
    %convert resuts back to mat
    %There is now a firings.mda in sortingpathbase,session,animal,output,tetrode folder with sorting
        %results
    for t = 1:length(tetrodes_used) 
        
        dataout=fullfile(sortingpathbase,animal,session,'output',strcat('ms3--t',num2str(tetrodes_used(t))));
        
        %run annotation script
        script_fname=fullfile(sortingpathbase,animal,session,'annotation.script');
        mp_run_process('mountainsort.run_metrics_script',...
            struct('metrics',fullfile(dataout,'cluster_metrics.json'),'script',script_fname),...
            struct('metrics_out',fullfile(dataout,'cluster_metrics_annotated.json')),...
            struct());
        
        %compute waveforms
        templates_out = fullfile(dataout,'templates.mda');
        mp_run_process('mountainsort.compute_templates',...
            struct('timeseries',fullfile(dataout,'filt.mda.prv'), 'firings',fullfile(dataout,'firings.mda')),...
            struct('templates_out',templates_out),...
            struct('clip_size',100));
        
        
        sourcefilename = strcat('tetrode',num2str(tetrodes_used(t)),'.mda');
        %convert to matlab array
        firings = readmda(fullfile(dataout,'firings.mda'));
        
        %add original nlx header info
        header = load(fullfile(datapathbase,animal,session,sourcefilename(1:end-4),[sourcefilename(1:end-4),'header.mat']));
        
        %save firings and header to result struct
        clusters.header=header.header;
        clusters.firings=firings;
        
        %cellbase conversion
        try
            NewSpikes = ConvertTimesToCB(clusters);
            clusters.firings_cellbase = NewSpikes;
        catch
            clusters.firings_cellbase = 'ExecuteSortingKron:spike times could not be re-aligned for cellbase.';
            Errors = [Errors,'ExecuteSortingKron:spike times could not be re-aligned for cellbase for tetrode ',num2str(tetrodes_used(t)),'.\n'];
        end
        
        %conversion to seconds
        inRecord = mod( clusters.firings(2,:),clusters.header(1).NSample);
        iRecord = floor( clusters.firings(2,:)./clusters.header(1).NSample)+1;
        NewSpikes = clusters.header(1).TimeStamps(iRecord)*10^-6 + inRecord/clusters.header(1).SampleFreq;
        clusters.firings_seconds = NewSpikes;
        
        %save as mat in output folder
        save(fullfile(sortingpathbase,animal,session,'output',strcat('ms3--t',num2str(tetrodes_used(t))),'clusters.mat'),'clusters');
        
        %save relevant results on server
        if ~isdir(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4)))
            mkdir(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4)));
        end
        try
            save(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4),'clusters.mat'),'clusters');
            save(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4),'header.mat'),'header');
        catch
            ('WARNING: ExecuteSortingKron: Copying files to server failed.\n');
        end
    end 
    
end%sessions

fprintf(Errors)

