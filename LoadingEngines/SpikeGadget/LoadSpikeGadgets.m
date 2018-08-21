function out = LoadSpikeGadgets(mode,recfilepath,mdafilepath,Params)
%LoadingEngine to convert Spikegadet .rec files to mda files using a bash
%script.

%INPUTS: mode - 3 options: 'write' for writing mda files.
%                          'path' for returning path and name of previously
%                                  written mda files for a session
%                          'header' OPTIONAL mode to return a header struct
%                                   with all info you want to inherit to
%                                   cluster results saved in clusters.mat
%                                   (see ExecuteSorting.m)
%        recfilepath - path to .rec files of specific session
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
        [~,session] = fileparts(mdafilepath);
        for t = 1:length(trodes)
                ndx = regexp(session,'.mda');
                mdafilename = strcat(session(1:ndx-1),'.nt',num2str(tr),'.mda');
                out{t} = fullfile(mdafilepath,mdafilename);
        end
    case 'write'
        
        try
            [~,sessionname] = fileparts(recfilepath);
            str = ['./exportmda -rec ' fullfile(recfilepath,sessionname) '.rec -outputdirectory ' mdafilepath];
            opts.working_dir = fileparts(mfilename('fullpath'));
            mlsystem(str,opts) %uses system call wrapper from this repo
        catch
            error('Make sure exportmda function is on bash path. Download function from Trodes bitbucket repository to a local directory, then add that directory to your ~/.profile file')
        end%try_catch
        
    otherwise
        error('Loading Engine unknown mode\n');
end