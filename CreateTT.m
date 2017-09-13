%% Convert curated firings file from mountainsort to CellBase tetrodes
% Input:
%       firings.curated.mda
%       cluster.mat
% Output:
%	TT_x.i.mat for each tetrode and cluster in folder
%	/path/to/session/TTData
%Torben/Paul, Sept 2017

%%%%%%%%%%%%%%% PARAMS%%%%%%%%%%%%%%%%
SortingPathBase = '/home/hoodoo/mountainsort/'; %where to store mountainlab sorting results (small(er) files). recommend SSD.
Animal = 'P37';
Date = '2016-10-32';
cellbase_times=true; %if false, uses time in seconds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%sessions
sessions_found = findSessions(SortingPathBase,Animal,Date);

%loop over sessions
for s = 1 : length(sessions_found)
    session = sessions_found{s};
    tt_dir_path = fullfile(SortingPathBase,Animal,session,'output');
    ff = dir(tt_dir_path);folders={ff.name}; tt_dir=folders([ff.isdir]);
    
    %loop over tetrodes
    for tt = 1:length(tt_dir)
        
        tt_name = tt_dir{tt};
        split = strsplit(tt_name,'t');
        
        if length(split) == 2
        tetnum=str2double(split{2});
        
        
        ClusterFile=fullfile(SortingPathBase,Animal,session,'output',tt_name,'clusters.mat');
        CuratedFiringFile=fullfile(SortingPathBase,Animal,session,'output',tt_name,'firings.curated.mda');
        WaveFormFile=fullfile(SortingPathBase,Animal,session,'output',tt_name,'waveform');
        
        
        if exist(ClusterFile,'file')==2 && exist(CuratedFiringFile,'file')==2
            if ~isdir(fullfile(SortingPathBase,Animal,session,'TTData'))
                mkdir(fullfile(SortingPathBase,Animal,session,'TTData'));
            end
            load(ClusterFile);
            MDAfile=readmda(CuratedFiringFile);
            if ~isempty(MDAfile)
                cells=unique(MDAfile(3,:));
                numcells=length(cells);
                
                for nc=1:numcells
                    Index=(MDAfile(3,:)==cells(nc));
                    Times=ismember(clusters.firings(2,:),MDAfile(2,Index));
                    if cellbase_times
                        TS=clusters.firings_cellbase(Times);
                    else
                        TS=clusters.firings_seconds(Times);
                    end
                    
                    TetrodeName=fullfile(SortingPathBase,Animal,session,'TTData',strcat('TT',num2str(tetnum),'_',num2str(nc)));
                    
                    save(TetrodeName,'TS');
                    
                end
            end
        end
        
        if exist (WaveFormFile,'file')==2
            MDAWave=readmda(WaveFormFile);
            if ~isempty(MDAWave)
                for nc=1:numcells
                    MaxPoints=max(abs(squeeze(MDAWave(:,:,nc))),[],2);
                    [MaxVal,MaxLead]=max(MaxPoints);
                    WV=squeeze(MDAWave(MaxLead,:,nc));
                    WaveName=fullfile(SortingPathBase,Animal,session,'output',tt_name,strcat('WV',num2str(tetnum),'_',num2str(nc)));
                    save(WaveName,'WV');
                end
            end
        end
        
        end
        
    end %tet
end%session
