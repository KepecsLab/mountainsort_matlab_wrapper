%%RECOMPUTE METRICS

%recompute metrics for all clustered sessions

Animals = {'P35','P36'};
Dates = {'all'};%for multiple sessions, 
Notify={'Torben'}; %cell with names; names need to be associated with email in MailAlert.m
sortingpathbase = '/home/hoodoo/mountainsort/'; %where to store mountainlab sorting results (small(er) files)
tempfolderbase = '/home/hoodoo/mountainsort_temp/';
WhichMetrics = {'kepecs.mclust_metrics','kepecs.refractory_metrics'};


AllDatasets = FindClusteredDatasets(sortingpathbase,Animals,Dates);
if ~isdir(fullfile(tempfolderbase,'RecomputeMetrics'))
    mkdir(fullfile(tempfolderbase,'RecomputeMetrics'));
end
if exist(fullfile(tempfolderbase,'RecomputeMetrics','finished.mat'),'file')==2
    load(fullfile(tempfolderbase,'RecomputeMetrics','finished.mat'));
else
    finished = [];
end
for s = 1:length(AllDatasets)
    if ~isFinished(AllDatasets{s},finished)
        
    timeseries_raw=loadjson(fullfile(AllDatasets{s},'raw.mda.prv'));timeseries_raw=timeseries_raw.original_path;
    timeseries_filt = fullfile(tempfolderbase,'RecomputeMetrics','filt.tmp.mda');
    mp_run_process('mountainsort.bandpass_filter',struct('timeseries',timeseries_raw),struct('timeseries_out',timeseries_filt),struct('samplerate',32556,'freq_min',300,'freq_max',6000));
    timeseries_pre = fullfile(tempfolderbase,'RecomputeMetrics','pre.tmp.mda');
    mp_run_process('mountainsort.whiten',struct('timeseries',timeseries_filt),struct('timeseries_out',timeseries_pre),struct('quantization_unit',0));
    
    
    inputs = struct('firings',fullfile(AllDatasets{s},'firings.mda'),'timeseries_pre',timeseries_pre,'timeseries_filt',timeseries_filt);
    params = struct('clip_size',50,'refractory_period',1.5,'samplerate',32556);
    for m = 1:length(WhichMetrics)
        cluster_metrics_out = fullfile(tempfolderbase,'RecomputeMetrics',[WhichMetrics{m},'.json']);
        outputs = struct('cluster_metrics_out',cluster_metrics_out);
        mp_run_process(WhichMetrics{m},inputs,outputs,params);
    end
    %stitch outputs together
    firings=readmda(inputs.firings);
    ids=unique(firings(3,:));
    if exist(fullfile(AllDatasets{s},'RecomputedMetrics.json'),'file')==2
        AllMetrics = loadjson(fullfile(AllDatasets{s},'RecomputedMetrics.json'));
    else
        AllMetrics = struct('clusters',[]);
    end
    
    for m = 1:length(WhichMetrics)
        cluster_metrics_out = fullfile(tempfolderbase,'RecomputeMetrics',[WhichMetrics{m},'.json']);
        metrics = loadjson(cluster_metrics_out);
        delete(cluster_metrics_out)
        for i = 1 : length(ids)
            if ids(i) == metrics.clusters{i}.label
                AllMetrics.clusters{i}.label=ids(i);
                fields = fieldnames(metrics.clusters{i}.metrics);
                for f = 1:length(fields)
                    AllMetrics.clusters{i}.metrics.(fields{f}) = metrics.clusters{i}.metrics.(fields{f});
                end
            else
                fprintf('Warning: Cluster labels do not match.\m');
            end
        end
    end
    savejson('',AllMetrics,fullfile(AllDatasets{s},'RecomputedMetrics.json'));
    
    finished=[finished;AllDatasets(s)];
    save(fullfile(tempfolderbase,'RecomputeMetrics','finished.mat'),'finished');
    end
end


function AllDatasets = FindClusteredDatasets(sortingpathbase,Animals,Dates)

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
                clustered = exist(fullfile(sortingpathbase,animal,session,'output',dataset,'firings.mda'),'file');
                if clustered == 2
                    AllDatasets = [AllDatasets;{fullfile(sortingpathbase,animal,session,'output',dataset)}];
                end
            end
        end
    end
end

end

function fi = isFinished(name,db)
fi = false;
for i = 1:length(db)
    if strcmp(name,db{i})
        fi = true;
        break
    end
end
end