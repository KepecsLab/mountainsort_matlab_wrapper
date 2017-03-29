%script to copy curated firing.mda and mvs2 files back to server

DATABASE = '/home/hoodoo/mountainsort/';
SERVERBASE = '/media/confidence/Data/';
%assumes animal folders in DATABASE containing session folders containing
%standard kron folder structure with an output folder containing datasets
%and same structure on SERBERVASE

%%%%%%
animalfolders = dir(DATABASE);animalfolders={animalfolders.name};

for a = 1:length(animalfolders)
    if length(animalfolders{a})>2
        sessionfolders = dir(fullfile(DATABASE,animalfolders{a})); sessionfolders={sessionfolders.name};
        for s = 1:length(sessionfolders)
            if length(sessionfolders{s})>2
                datasetfolders = dir(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output'));
                datasetfolders = {datasetfolders.name};
                if ~isdir(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},'curated')), mkdir(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},'curated')); end
                for t = 1 : length(datasetfolders)
                    if length(datasetfolders{t})>2
                        files = dir(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t}));
                        files = {files.name};
                        tet = datasetfolders{t}(end-1:end); if strcmp(tet(1),'t'),tet(1)=[];end
                        if ~isdir(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},strcat('tetrode',num2str(tet))))
                            mkdir(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},strcat('tetrode',num2str(tet))));
                        end
                        for f = 1:length(files)
                            if length(files{f})>2
                                %mv2 file
                                if strcmp(files{f}(end-2:end),'mv2')
                                    if exist(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},strcat('tetrode',num2str(tet)),files{f}),'file')~=2
                                        copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},strcat('tetrode',num2str(tet)),files{f}));
                                    end
                                    %curation firings file
                                elseif strcmp(files{f},'firings.curated.mda')
                                    if exist(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},strcat('tetrode',num2str(tet)),files{f}),'file')~=2
                                        copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},strcat('tetrode',num2str(tet)),files{f}));
                                        copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},'curated',strcat('firings',num2str(tet),'.curated.mda')));
                                    end
                                    %original firings file
                                elseif strcmp(files{f},'firings.mda')
                                    if exist(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},strcat('tetrode',num2str(tet)),files{f}),'file')~=2
                                        copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},strcat('tetrode',num2str(tet)),files{f}));
                                    end
                                    %cluster mat file
                                elseif strcmp(files{f},'clusters.mat')
                                    if exist(fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},'curated',strcat('clusters',num2str(tet),'.mat')),'file')~=2
                                        copyfile(fullfile(DATABASE,animalfolders{a},sessionfolders{s},'output',datasetfolders{t},files{f}),fullfile(SERVERBASE,animalfolders{a},sessionfolders{s},'curated',strcat('clusters',num2str(tet),'.mat')));
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