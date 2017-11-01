%Script to copy clustering results to server with ame folder structure

% copies - *.mv2 files (containing clustering annotations and metrics)
%        - firings.mda (original mountainlab clustering output)
%        - firings.curated.mda (curated firings only containing accepted
%           clusters)
%        - waveform* (mda-file containing waveform templates)
%        - clusters.mat file (output from ExecuteSortingKron) containing
%           header info and firings.mda in matlab readable format, and
%           timestamps converted to seconds and in cellbase format
%        - TTData folder (created by CreateTT.mat)

%script to copy curated firing.mda and mv2 files back to server
%assumes animal folders in DATABASE containing session folders containing
%standard kron folder structure with an output folder containing datasets
%and same structure on SERBERVASEMClust

%Torben Ott, CSHL, 2017

%%%%%%%%%% USER %%%%%%%%%%%%%%%%%%%%
DATABASE = '/home/hoodoo/mountainsort/';
SERVERBASE = '/media/confidence/Data/';
PIPELINE = 'ms3'; %puts files in pipeline subfolder on server
% CopyCond = [1,1,1,1,1,1];
CopyCond = [0,0,0,0,0,1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%
animalfolders = dir(DATABASE);animalfolders={animalfolders.name};

for a = 1:length(animalfolders)
    if ~strncmp(animalfolders{a},'.',1)
        sessionfolders = dir(fullfile(DATABASE,animalfolders{a})); sessionfolders={sessionfolders.name};
        for s = 1:length(sessionfolders)
            if ~strncmp(sessionfolders{s},'.',1)
                datasetfolders = dir(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output'));
                datasetfolders = {datasetfolders.name};
                if ~isdir(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,'curated')), mkdir(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,'curated')); end
                for t = 1 : length(datasetfolders)
                    if ~strncmp(datasetfolders{t},'.',1)
                        %check pipeline
                        pipe = strtok(datasetfolders{t},'-');
                        if strcmp(pipe,PIPELINE)
                            files = dir(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t}));
                            files = {files.name};
                            tet = datasetfolders{t}(end-1:end); if strcmp(tet(1),'t'),tet(1)=[];end
                            if ~isdir(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet))))
                                mkdir(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet))));
                            end
                            for f = 1:length(files)
                                if length(files{f})>2
                                    %mv2 file
                                    if strcmp(files{f}(end-2:end),'mv2')
                                        if exist(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet)),files{f}),'file')~=2
                                            copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet)),files{f}));
                                        end
                                        %curation firings file
                                    elseif strcmpi(files{f},'firings.curated.mda')
                                        if exist(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet)),files{f}),'file')~=2
                                            copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet)),files{f}));
                                            copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,'curated',strcat('firings',num2str(tet),'.curated.mda')));
                                        end
                                        %original firings file
                                    elseif strcmpi(files{f},'firings.mda')
                                        if exist(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet)),files{f}),'file')~=2
                                            copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet)),files{f}));
                                        end
                                        %cluster mat file
                                    elseif strcmpi(files{f},'clusters.mat')
                                        if exist(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,'curated',strcat('clusters',num2str(tet),'.mat')),'file')~=2
                                            copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet)),files{f}));
                                            copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,'curated',strcat('clusters',num2str(tet),'.mat')));
                                        end
                                        % Waveforms file
                                    elseif strncmpi(files{f},'waveform',8)
                                        if exist(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet)),files{f}),'file')~=2
                                            copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,'curated',strcat('waveform',num2str(tet),'.mda')));
                                            copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},PIPELINE,strcat('tetrode',num2str(tet)),files{f}));
                                            
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end