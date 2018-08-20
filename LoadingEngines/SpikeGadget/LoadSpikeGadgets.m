function LoadSpikeGadgets(sessionpath,outpath,Params)
%LoadingEngine to convert Spikegadet .rec files to mda files using a bash
%script.

%INPUTS: sessionpath - path to .rec files of specific session
%        outpath - base path to store mda files
%        Params - struct with original sorting wrapper Params (see
%                 StartClustering.m)

try
    [~,sessionname] = fileparts(sessionpath);
    str = ['./exportmda -rec ' fullfile(sessionpath,sessionname) '.rec -outputdirectory ' outpath];
    opts.working_dir = fileparts(mfilename('fullpath'));
    mlsystem(str,opts) %uses system call wrapper from this repo
catch
    error('Make sure exportmda function is on bash path. Download function from Trodes bitbucket repository to a local directory, then add that directory to your ~/.profile file')
end%try_catch