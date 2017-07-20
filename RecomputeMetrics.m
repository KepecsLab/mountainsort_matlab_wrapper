%% RECOMPUTE METRICS
%recompute metrics for all clustered sessions
%assumes kron folder structure in sortingpathbase: clustered in
%output/dataset
%identifies clustered session based on firings.mda
% recomputes specified metrics

Animals = {'P35','P36','P37','P39'};
Dates = {'all'};%for multiple sessions,
Notify={'Torben'}; %cell with names; names need to be associated with email in MailAlert.m
sortingpathbase = '/home/hoodoo/mountainsort/'; %where to look for mountainlab sorting results (small(er) files)
tempfolderbase = '/home/hoodoo/mountainsort_temp/';
WhichMetrics = {'kepecs.mclust_metrics','kepecs.refractory_metrics','kepecs.histogram_metrics'}; %for kepecs metrics
compute_mountainlab_metrics = true; %for built-in mountainlab metrics
compute_template_waveforms = true; %compute template waveforms (based on filt data)
OutName = 'RecomputeAllMetrics'; %determines file name output
restart=false; %when true, does not consider recomputed sessions

% metrics parameters
params = struct('clip_size',50,'refractory_period',1.5,'samplerate',32556);
% filter parameters
params_filt = struct('samplerate',params.samplerate,'freq_min',300,'freq_max',6000);


%% MAIN
%find clustered session.
Condition = 'firings.mda'; %condition to identify clustered sessions
AllDatasets = FindClusteredDatasets(sortingpathbase,Animals,Dates,Condition);

%make temp folder
if ~isdir(fullfile(tempfolderbase,OutName))
    mkdir(fullfile(tempfolderbase,OutName));
end

%load recomputed datasets
if exist(fullfile(tempfolderbase,OutName,'finished.mat'),'file')==2 && ~restart
    load(fullfile(tempfolderbase,OutName,'finished.mat'));
else
    finished = struct('datasets',[],'processors',[]);
end

%main loop through datasets
for s = 1:length(AllDatasets)
    if ~isFinished(AllDatasets{s},{finished.datasets})
        
        %firings
        firings = fullfile(AllDatasets{s},'firings.mda');
        
        %timeseries raw
        timeseries_raw=loadjson(fullfile(AllDatasets{s},'raw.mda.prv')); timeseries_raw=timeseries_raw.original_path;
        %if not at original path anymore, use prv file (slower)
        if exist(timeseries_raw,'file')~=2
            timeseries_raw = fullfile(AllDatasets{s},'raw.mda.prv');
        end
        
        %make filtered timeseries
        timeseries_filt = fullfile(tempfolderbase,OutName,'filt.tmp.mda');
        mp_run_process('mountainsort.bandpass_filter',struct('timeseries',timeseries_raw),struct('timeseries_out',timeseries_filt),params_filt);
        
        %make whitened timeseries
        timeseries_pre = fullfile(tempfolderbase,OutName,'pre.tmp.mda');
        mp_run_process('mountainsort.whiten',struct('timeseries',timeseries_filt),struct('timeseries_out',timeseries_pre),struct('quantization_unit',0));
        
        % run kepecs metric processors
        metrics_list={};
        inputs = struct('firings',firings,'timeseries_pre',timeseries_pre,'timeseries_filt',timeseries_filt);
        for m = 1:length(WhichMetrics)
            metrics_list{m} = fullfile(tempfolderbase,OutName,[WhichMetrics{m},'.json']);
            outputs = struct('cluster_metrics_out',metrics_list{m});
            mp_run_process(WhichMetrics{m},inputs,outputs,params);
        end
        
        if compute_mountainlab_metrics
            %run mountainlab metric processors
            metrics_list{end+1}=fullfile(tempfolderbase,OutName,'cluster_metrics_1.json');
            mp_run_process('mountainsort.cluster_metrics',...
                struct('timeseries',timeseries_pre, 'firings',firings),...
                struct('cluster_metrics_out',metrics_list{end}),...
                struct('samplerate',params.samplerate));
            
            metrics_list{end+1}=fullfile(tempfolderbase,OutName,'cluster_metrics_2.json');
            mp_run_process('mountainsort.isolation_metrics',...
                struct('timeseries',timeseries_pre, 'firings',firings),...
                struct('metrics_out',metrics_list{end}),...
                struct('samplerate',params.samplerate));
        end
        
        %waveforms
        if compute_template_waveforms
            templates_out = fullfile(dataset,[OutName,'_templates.mda']);
            mp_run_process('mountainsort.compute_templates',...
                struct('timeseries',timeseries_filt, 'firings',firings),...
                struct('templates_out',templates_out),...
                struct('clip_size',100));
        end
        
        %stitch outputs together
        metrics_out = fullfile(dataset,[OutName,'.json']);
        mp_run_process('mountainsort.combine_cluster_metrics',...
            struct('metrics_list',{metrics_list}),...
            struct('metrics_out',metrics_out),...
            struct());
        
        %delete tmp metrics files
        for k = 1:length(metrics_list)
            delete(metrics_list{k});
        end
        
        %save which dataets have been recomputed
        idx = length(finished);
        finished(idx+1).datasets=AllDatasets{s};
        finished(idx+1).processors=finished_processors;
        save(fullfile(tempfolderbase,OutName,'finished.mat'),'finished');
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