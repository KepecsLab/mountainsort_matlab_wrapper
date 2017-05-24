function Tetrode2MDALocal(animal,date,tetrodes,tetrodes_config,sourcepathbase,destpathbase)
%Tetrode2MDA(...) converts Neuralynx continuous recording files to mountainlab
%readable mda-files.
%inputs are: animal: subject id, eg P32
%            data:   session date, eg 2016-08-30 (format as seen)
%            tetrodes: array of tetrodes to be converted
%            sourcepathbase: path to folder containing recording sessions

%Tetrode2MDA assumes that tetrodes are paired in 4-groups beginning with
%1-4,...% mda file will be saved in sourcepathbase/SESSION/TETRODE#. 

%dependencies: nlx2mda()
%                  subdependencies: writemda16i(), Nlx2MatCSC_v3()

% Torben Ott, CSHL, September 2016


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sessions_found = findSessions(sourcepathbase,animal,date);

for f = 1:length(sessions_found)
    
    fold = sessions_found{f};
    
    for i = 1:length(tetrodes)
        
        tet = tetrodes(i);
        
        rawdatafiles_index = (tet-1)*4+1:tet*4; %default: all 4 tetrodes
        rawdatafiles_index = rawdatafiles_index(tetrodes_config{tetrodes(i)});%adjust for leads to use
        rawdatapath=fullfile(sourcepath,fold);
        rawdatafiles=cell(1,length(rawdatafiles_index));
        
        for k = 1 : length(rawdatafiles_index)
            rawdatafiles{k} = strcat('CSC',num2str(rawdatafiles_index(k)),'.ncs');
        end
        
        %skip tetrode if size very small (happens when started multiple nlx
        %sessions but no recordings)
        testfile = dir(fullfile(rawdatapath,rawdatafiles{1}));
        if testfile.bytes < 10^6 % < ~1MB
            fprintf('Skipped session %s Tetrode %s (file size small).Tetrode2MDA.\n',fold,num2str(tet));
            continue
        end
        
        %file destination
        destinationpath = fullfile(destpathbase,animal,fold,['tetrode',num2str(tet)]);
        m=mkdir(destinationpath);
        destinationfile = strcat('tetrode',num2str(tet),'.mda');
        
        h=nlx2mda(rawdatapath,rawdatafiles,destinationpath,destinationfile);
        
    end%tetrodes
    
end%folders