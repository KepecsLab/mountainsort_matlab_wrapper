function Trode2MDALocal(Params)
%Trode2MDA(...) converts Neuralynx or SpikeGadget continuous recording files to mountainlab
%readable mda-files.
%inputs is a config strcut PARAMS with required fields
%            Animal: animal if (determines folder name containing sessions)
%            Date:   session date, eg 2016-08-30 (format as seen, determines session folder name)
%            Trodes: array of trodes to be converted
%            ServerPathBase: path to folder containing recording sessions
%                            (server recommended)
%            DataPathBase: path to folder where converted files will be
%                            stored (local recommended)

%For Neuralynx data, Trode2MDA assumes that trodes are tetrodes paired in 4-groups beginning with
%1-4,...

% mda file will be saved in sourcepathbase/SUBJECT/SESSION/TRODE#.

%dependencies: nlx2mda()
%                  subdependencies: writemda16i(), Nlx2MatCSC_v3()

% Torben Ott, CSHL, September 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
animal = Params.Animal;
date = Params.Date;
trodes=Params.Trodes;
trodes_config = Params.TrodesConfig;
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
            end%try_catch
        case 'neuralynx'
            for i = 1:length(trodes)
                
                tr = trodes(i);
                
                rawdatafiles_index = (tr-1)*4+1:tr*4; %default: all 4 trodes
                rawdatafiles_index = rawdatafiles_index(trodes_config{trodes(i)});%adjust for leads to use
                rawdatapath=fullfile(serverpathbase,animal,fold);
                rawdatafiles=cell(1,length(rawdatafiles_index));
                
                for k = 1 : length(rawdatafiles_index)
                    rawdatafiles{k} = strcat('CSC',num2str(rawdatafiles_index(k)),'.ncs');
                end
                
                %skip trode if size very small (happens when started multiple nlx
                %sessions but no recordings)
                testfile = dir(fullfile(rawdatapath,rawdatafiles{1}));
                if testfile.bytes < 10^6 % < ~1MB
                    fprintf('Skipped session %s Trode %s (file size small).Trode2MDA.\n',fold,num2str(tr));
                    continue
                end
                
                %file destination
                destinationpath = fullfile(datapathbase,animal,fold,['trode',num2str(tr)]);
                if ~isdir(destinationpath)
                    mkdir(destinationpath);
                end
                destinationfile = strcat('trode',num2str(tr),'.mda');
                if exist(fullfile(destinationpath,destinationfile),'file')==2
                    fprintf('WARNING: Converted mda-file %s already exists. Will overwrite.\n',fullfile(destinationpath,destinationfile));
                end
                
                fprintf('Converting to destination file %s...',fullfile(destinationpath,destinationfile));
                nlx2mda(rawdatapath,rawdatafiles,destinationpath,destinationfile);
                
            end%trodes
    end%switch
end%folders
