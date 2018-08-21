function NLXPolyTrode_2shank_32(sessionpath,outpath,Params)
%LoadingEngine to convert Neuralynx .ncs files to mda files assuming
%tetrode organization of raw recording files.

%INPUTS: sessionpath - path to .ncs files of specific session
%        outpath - base path to store mda files
%        Params - struct with original sorting wrapper Params (see
%                 StartClustering.m)

trodes = Params.Trodes;
trodes_config = Params.TrodesConfig;
animal = Params.Animal;

for i = 1:length(trodes)
    
    tr = trodes(i);
    
    %construct 4 file names and paths
    rawdatafiles_index = (tr-1)*16+1:tr*4; %default: all 4 trodes
    rawdatafiles_index = rawdatafiles_index(trodes_config{trodes(i)});%adjust for leads to use
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