
%Finds all datasets with a firings.mda in
%sortingpathbase/animal/session/output/ over Animals and Dates
%optional: 4th input determining which files needs to be present to include
%dataset. default: firings.mda
sortingpathbase='/media/confidence/Data';
Animals={'P35','P32','P36','P30','P37'};
Dates={'all'};
Condition = 'pre2.mda';%pre1b.mda, 
AllDatasets=cell(0,1);
if strcmp(Animals{1},'all')
    Animals = dir(sortingpathbase); Animals={Animals(:).name}; Animals = Animals(cellfun(@length,Animals)>2);
end
for a = 1:length(Animals)
    animal=Animals{a};
    if strcmp(Dates{1},'all')
        DatesAnimal = dir(fullfile(sortingpathbase,animal)); DatesAnimal={DatesAnimal(:).name}; DatesAnimal = DatesAnimal(cellfun(@length,DatesAnimal)>2);
    else
        DatesAnimal=Dates;
    end
    for d = 1 : length(DatesAnimal)
        date = DatesAnimal{d};
        if length(date)>10
            Sessions={date};
        else
            Sessions = findSessions(sortingpathbase,animal,date);
        end
        for s= 1:length(Sessions)
            session=Sessions{s};
            Datasets = dir(fullfile(sortingpathbase,animal,session)); Datasets={Datasets(:).name}; Datasets = Datasets(cellfun(@length,Datasets)>=7); Datasets(cellfun(@(x) ~strcmp(x(1:7),'tetrode'),Datasets))=[];
            for t = 1:length(Datasets)
                dataset=Datasets{t};
                FILETODELETE = fullfile(sortingpathbase,animal,session,dataset,Condition);
                clustered = exist(FILETODELETE,'file');
                if clustered == 2
                    delete(FILETODELETE);
                    fprintf('Deleted %s.\n',FILETODELETE);
                end
            end
        end
    end
end
