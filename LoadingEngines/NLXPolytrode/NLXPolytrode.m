function NLXPolyTrode(mode,recfilepath,mdafilepath,Params,firingspath)
%LoadingEngine to convert Neuralynx .ncs files to mda file
% requires a Params.TrodesConfig to define the mapping or ordering and
% composition of .ncs files into trodes such that they match the geom.csv
% file that defines the probe site geometry for each trode
% Fitz Sturgill, 2018

%INPUTS: sessionpath - path to .ncs files of specific session
%INPUTS: mode - 3 options: 'write' for writing mda files.
%                          'path' for returning path and name of previously
%                                  written mda files for a session
%                          'header' OPTIONAL mode to return a header struct
%                                   with all info you want to inherit to
%                                   cluster results saved in clusters.mat
%                                   (see ExecuteSorting.m)
%        recfilepath - path to .ncs files of specific session
%        mdafilepath - path to .mda files of specific session
%        Params - struct with original sorting wrapper Params (see
%                 StartClustering.m)
%        firingspath - path to firings.mda. only used by header mode
%
%OUTPUTS: out - in mode='path' will return cell with list of paths to
%               mda files. in mode='header' must be struct. all fieldnames will
%               be written to clusters.mat

%Note that this function is supposed write a mda-file per dataset/trode.
%
%It can optionally have a header-mode to return recording header info or
%convert firings info into seconds, add anything you want to cluster.mat

%Torben Ott, CSHL, 2018
switch mode
    case 'path'
        trodes = Params.Trodes;
        out=cell(1,length(trodes));
        for t = 1:length(trodes)
            out{t} = fullfile(mdafilepath,strcat('trode',num2str(trodes(t))),strcat('trode',num2str(trodes(t)),'.mda'));
        end        
    case 'write'
        trodes = Params.Trodes;
        trodes_config = Params.TrodesConfig;
        animal = Params.Animal;

        for i = 1:length(trodes)

            tr = trodes(i);

            % example- hard coded mapping for cambridge neurotech P2 probe
%             mapping = [
%                 16    17;...
%                 12    21;...
%                 10    23;...
%                  9    24;...
%                  7    26;...
%                  8    25;...
%                 14    19;...
%                 15    18;...
%                  5    28;...
%                  4    29;...
%                  2    31;...
%                  1    32;...
%                  3    30;...
%                  6    27;...
%                 13    20;...
%                 11    22;...
%                 ];
%             trodes_config = {mapping(:,1), mapping(:,2)};

            rawdatafiles_index = trodes_config{trodes(i)}; % maps NCS files into mc4 site number and geom.csv file indices
            rawdatapath=sessionpath;
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
            [~,sessionname] = fileparts(sessionpath);
            destinationpath = fullfile(outpath,animal,sessionname,['trode',num2str(tr)]);
            if ~isdir(destinationpath)
                mkdir(destinationpath);
            end
            destinationfile = strcat('trode',num2str(tr),'.mda');
            if exist(fullfile(destinationpath,destinationfile),'file')==2
                fprintf('WARNING: Converted mda-file %s already exists. Will overwrite.\n',fullfile(destinationpath,destinationfile));
            end

            fprintf('Converting to destination file %s...',fullfile(destinationpath,destinationfile));

            %convert list of ncs files from one tetrode to a single mda file
            nlx2mda(rawdatapath,rawdatafiles,destinationpath,destinationfile);

        end%trodes
        out = true;
    case 'header'
        firings = readmda(firingspath);
        [~,tr]=fileparts(fileparts(firingspath));
        tr = str2num(tr(3:end));
        header = load(fullfile(mdafilepath,strcat('trode',num2str(tr)),'header.mat'));
        out.header=header.header;
        %conversion to seconds
        inRecord = mod( firings(2,:),header.header(1).NSample);
        iRecord = floor( firings(2,:)./header.header(1).NSample)+1;
        NewSpikes = header.header(1).TimeStamps(iRecord)*10^-6 + inRecord/header.header(1).SampleFreq;
        out.firings_seconds = NewSpikes;        
    otherwise
        error('Loading Engine unknown mode\n');
end