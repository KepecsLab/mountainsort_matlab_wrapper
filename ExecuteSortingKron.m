function ExecuteSortingKron(animal,date,tetrodes,datapathbase,sortingpathbase,serverpathbase)
% ExecuteSorting()

% 1) runs clustering pipeline on server
% 2) saves clustering result on data server
% 3) converts clustering results back to matlab array and combined with
%    original header info, also converts event timestamps from neuralynx
%    (us) in cellbase times (has to add offset and divide by 10e4)

%inputs are: animal: subject id, eg P32
%            data:   session date, eg 2016-08-30 (format as seen)
%            tetrodes: array of tetrodes to be converted
%            datasourcepath: path to folder containing mountainsort_002recording sessions

%dependencies: readmda()
%              mountainlab software package with
%                        params file, specify location here
%                        script file, specify location here
%                        view_results script file, specify location here






%params file location
paramssourcepath = '/home/hoodoo/mountainlab_scripts/params_default_20170710.json';
%curation script
curationsourcepath = '/home/hoodoo/mountainlab_scripts/curation_default_20161201.script';

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
    mkdir(fullfile(sortingpathbase,animal,session));
    pipelines_txt = fopen(fullfile(sortingpathbase,animal,session,'pipelines.txt'),'w');
    fprintf(pipelines_txt,'ms3 ms3.pipeline --curation=curation.script --refractory_period=1.5 --generate_pre=1 --generate_filt=1 --_nodaemon \n');
    fclose(pipelines_txt);
    %datasets spec
    datasets_txt = fopen(fullfile(sortingpathbase,animal,session,'datasets.txt'),'w');
    %curation script
    copyfile(curationsourcepath,fullfile(sortingpathbase,animal,session,'curation.script'));
    
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
        mkdir(fullfile(sortingpathbase,animal,session,'datasets',sourcefilename(1:end-4)));
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
        sourcefilename = strcat('tetrode',num2str(tetrodes_used(t)),'.mda');
        %convert to matlab array
        firings = readmda(fullfile(sortingpathbase,animal,session,'output',strcat('ms3--t',num2str(tetrodes_used(t))),'firings.mda'));
        
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
        %save as mat in output folder
        save(fullfile(sortingpathbase,animal,session,'output',strcat('ms3--t',num2str(tetrodes_used(t))),'clusters.mat'),'clusters');
        
        %save relevant results on server
        mkdir(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4)));
        save(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4),'clusters.mat'),'clusters');
        save(fullfile(serverpathbase,animal,session,sourcefilename(1:end-4),'header.mat'),'header');
    end 
    
end%sessions

fprintf(Errors)

