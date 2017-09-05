function AllDatasets = FindClusteredDatasets(sortingpathbase,Animals,Dates,Condition)
%Finds all datasets with a firings.mda in
%sortingpathbase/animal/session/output/ over Animals and Dates
%optional: 4th input determining which files needs to be present to include
%dataset. default: firings.mda
if nargin<4
    Condition = 'firings.mda';
end
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
            Datasets = dir(fullfile(sortingpathbase,animal,session,'output')); Datasets={Datasets(:).name}; Datasets = Datasets(cellfun(@length,Datasets)>2);
            for t = 1:length(Datasets)
                dataset=Datasets{t};
                clustered = exist(fullfile(sortingpathbase,animal,session,'output',dataset,Condition),'file');
                if clustered == 2
                    AllDatasets = [AllDatasets;{fullfile(sortingpathbase,animal,session,'output',dataset)}];
                end
            end
        end
    end
end

end