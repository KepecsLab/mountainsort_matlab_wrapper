function Tetrode2MDALocal(Params)
%Tetrode2MDA(...) converts Neuralynx continuous recording files to mountainlab
%readable mda-files.
%inputs is a config strcut PARAMS with required fields
%            Animal: animal if (determines folder name containing sessions)
%            Date:   session date, eg 2016-08-30 (format as seen, determines session folder name)
%            Tetrodes: array of tetrodes to be converted
%            ServerPathBase: path to folder containing recording sessions
%                            (server recommended)
%            DataPathBase: path to folder where converted files will be
%                            stored (local recommended)

%Tetrode2MDA assumes that tetrodes are paired in 4-groups beginning with
%1-4,...% mda file will be saved in sourcepathbase/SESSION/TETRODE#. 

%dependencies: nlx2mda()
%                  subdependencies: writemda16i(), Nlx2MatCSC_v3()

% Torben Ott, CSHL, September 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
animal = Params.Animal;
date = Params.Date;
tetrodes=Params.Tetrodes;
tetrodes_config = Params.TetrodesConfig;
serverpathbase=Params.ServerPathBase;
datapathbase = Params.DataPathBase;
recsys = Params.RecSys;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sessions_found = findSessions(serverpathbase,animal,date);

for f = 1:length(sessions_found)
    
    fold = sessions_found{f};
    switch recsys
      case 'spikegadgets'
        try
          str = ['./exportmda -rec ' fullfile(serverpathbase,animal,fold,fold) '.rec -outputdirectory ' fullfile(datapathbase,animal)];
          opts.working_dir = fileparts(which('nlx2mda'));
          mlsystem(str,opts)
        catch
          error('Make sure exportmda function is on bash path. Download function from Trodes bitbucket repository to a local directory, then add that directory to your ~/.profile file')
        end_try_catch       
      case 'neuralynx'
        for i = 1:length(tetrodes)
            
            tet = tetrodes(i);
            
            rawdatafiles_index = (tet-1)*4+1:tet*4; %default: all 4 tetrodes
            rawdatafiles_index = rawdatafiles_index(tetrodes_config{tetrodes(i)});%adjust for leads to use
            rawdatapath=fullfile(serverpathbase,animal,fold);
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
            destinationpath = fullfile(datapathbase,animal,fold,['tetrode',num2str(tet)]);
            if ~isdir(destinationpath)
                mkdir(destinationpath);
            end
            destinationfile = strcat('tetrode',num2str(tet),'.mda');
            if exist(fullfile(destinationpath,destinationfile),'file')==2
                fprintf('WARNING: Converted mda-file %s already exists. Will overwrite.\n',fullfile(destinationpath,destinationfile));
            end
            
            fprintf('Converting to destination file %s...',fullfile(destinationpath,destinationfile));
            nlx2mda(rawdatapath,rawdatafiles,destinationpath,destinationfile);
            
        end%tetrodes
    endswitch
end%folders