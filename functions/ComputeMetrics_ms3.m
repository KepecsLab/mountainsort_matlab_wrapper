function ComputeMetrics_ms3(Params)
% ComputeMetrics(...)

% 1) computes metrics of clustered data using ms4
% 2) saves metrics


%inputs are: A struct PARAMS with required fields
%            Animal: subject id, eg P32
%            Date:   session date, eg 2016-08-30 (format as seen)
%            Trodes: array of trodes to be converted
%            ServerPathBase: path to folder containing recording sessions
%                            (server recommended)
%            DataPathBase: path to folder where converted files will be
%                            stored (local recommended)
%            SortingPathBase: path to folder where clustering results are
%                              stored (local recommended)
%            ParamsPath: path to parameter file (json)
%            CurationPath: path to curation file 
%            ScriptPath: path to script file (javascript, run by mountainlab)

%dependencies: readmda()
%              mountainlab-js software package 

% Torben Ott, CSHL, May 2018

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
animal = Params.Animal;
date = Params.Date;
trodes=Params.Trodes;
sortingpathbase = Params.SortingPathBase;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% not yet as param input
compute_mountainlab_metrics = true;
compute_template_waveforms = true;
compute_kepecs_metrics = true;
tempfolderbase = '/home/hoodoo/mountainsort_temp/';
OutName = 'ComputeMetrics'; %determines file name output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sessions_found = findSessions(sortingpathbase,animal,date);
%make temp folder
if ~isdir(fullfile(tempfolderbase,OutName))
    mkdir(fullfile(tempfolderbase,OutName));
end
Errors = [' '];
for s = 1:length(sessions_found)%sessions of day
    
    % sessions
    session = sessions_found{s};
 
    for d = 1:length(trodes) %datasets (n-trodes)
        
        tr = trodes(d);
       
        tr_folder = fullfile(sortingpathbase,animal,session,'ms4',strcat('NT',num2str(tr)));
        
        %files
        paramspath = fullfile(tr_folder,'params.json');
        timeseries_filt =  fullfile(tr_folder,'filt.mda.prv');
        timeseries_pre =  fullfile(tr_folder,'pre.mda.prv');
        firings = fullfile(tr_folder,'firings.mda');
        
        sortparams = loadjson(paramspath);
        params = struct('clip_size',sortparams.clip_size,'refractory_period',1.5,'samplerate',sortparams.samplerate);
        
        metrics_list = {};
        % kepecslab metrics
        if compute_kepecs_metrics
            %refractory metric
            metrics_list{end+1} = fullfile(tempfolderbase,OutName,'cluster_metrics_kepecs_1.json');
            ml_run_process('kepecs.refractory_metrics',struct('firings',firings),struct('metrics_out',metrics_list{end}),...
                struct('samplerate',params.samplerate,'refractory_period',params.refractory_period));
            
            %histogram metrics
            metrics_list{end+1} = fullfile(tempfolderbase,OutName,'cluster_metrics_kepecs_2.json');
            ml_run_process('kepecs.histogram_metrics',struct('timeseries',timeseries_pre,'firings',firings),struct('metrics_out',metrics_list{end}),...
                struct());
        end
        
        %mountainlab metrics
        if compute_mountainlab_metrics
            %run mountainlab metric processors
            metrics_list{end+1}=fullfile(tempfolderbase,OutName,'cluster_metrics_1.json');
            ml_run_process('ms3.cluster_metrics',...
                struct('timeseries',timeseries_pre, 'firings',firings),...
                struct('cluster_metrics_out',metrics_list{end}),...
                struct('samplerate',params.samplerate));
            
            metrics_list{end+1}=fullfile(tempfolderbase,OutName,'cluster_metrics_2.json');
            ml_run_process('ms3.isolation_metrics',...
                struct('timeseries',timeseries_pre, 'firings',firings),...
                struct('metrics_out',metrics_list{end},'pair_metrics_out',fullfile(tr_folder,'cluster_pair_metrics.json')),...
                struct('compute_bursting_parents',true));
        end
        
        %waveforms
        if compute_template_waveforms
            templates_out = fullfile(tr_folder,'templates.mda');
            ml_run_process('ms3.compute_templates',...
                struct('timeseries',timeseries_filt, 'firings',firings),...
                struct('templates_out',templates_out),...
                struct('clip_size',100));
        end
        
        %stitch outputs together
        metrics_out = fullfile(tr_folder,'cluster_metrics.json');
        ml_run_process('ms3.combine_cluster_metrics',...
            struct('metrics_list',{metrics_list}),...
            struct('metrics_out',metrics_out),...
            struct());
        
        %run annotation script
        script_fname=fullfile(tr_folder,'annotation.script');
        ml_run_process('ms3.run_metrics_script',...
            struct('metrics',fullfile(tr_folder,'cluster_metrics.json'),'script',script_fname),...
            struct('metrics_out',fullfile(tr_folder,'cluster_metrics_annotated.json')),...
            struct());
        
        %delete tmp metrics files
        for k = 1:length(metrics_list)
            delete(metrics_list{k});
        end
        
        
        
        
    end
    
end%sessions

fprintf(Errors)

