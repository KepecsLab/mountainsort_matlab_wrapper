% wrapper script to convert nlx recording files to mda files
% and start mountainlab sorting pipeline

% Torben Ott, CSHL, September 2016
Animals = {'P36'};
Dates = {'2017-03-09'};
Tetrodes={[1:16]};
Notify={'Torben','Paul'}; %cell with names; names need to be associated with email in MailAlert.m
serverpathbase =  '/media/confidence/Data/';% source path to nlx files

EXTRACTTIME = zeros(1,length(Animals)); SORTINGTIME=zeros(1,length(Animals));
for session = 1:length(Animals)
    %
    animal = Animals{session};
    date = Dates{session};
    tetrodes = Tetrodes{session};
    
    %which leads to use
    %default: all 4
    tetrodes_config = num2cell(repmat(1:4,tetrodes(end),1),2);
    
    %load animal-specific config file
    switch animal
        case 'P36'
            load('P36Config.mat');
        case 'P35'
            load('P35Config.mat');
        otherwise
    end
        
    
    %folder stuff
    datapathbase = '/media/hoodoo/Data/Animals/'; %where to store mda files (big files)
    sortingpathbase = '/home/hoodoo/mountainsort/'; %where to store mountainlab sorting results (small files)
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%
    
    
    % convert ncs to mda
    tic
    try
        Tetrode2MDALocal(animal,date,tetrodes,tetrodes_config,serverpathbase,datapathbase);
    catch
        MailAlert(Notify,'Hoodoo:SortingWrapperKron','Error:Tetrode2MDALocal.');
    end
    EXTRACTTIME(session) = toc;
    
    % start analysis pipeline
    tic
    try
        ExecuteSortingKron(animal,date,tetrodes,datapathbase,sortingpathbase,serverpathbase);
    catch
        MailAlert(Notify,'Hoodoo:SortingWrapperKron','Error:ExecuteSortingKron.');
    end
    SORTINGTIME(session) = toc;
end%session

save('EXTRACTTIME.mat','EXTRACTTIME');
save('SORTINGTIME.mat','SORTINGTIME');

%send slack notification
MailAlert(Notify,'Hoodoo:SortingWrapperKron','Sorting Done.');


