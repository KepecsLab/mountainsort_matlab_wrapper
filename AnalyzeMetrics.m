Animals = {'P35','P36','P37','P39'};
% Animals={'P37'};
Dates = {'all'};%for multiple sessions, 
Notify={'Torben'}; %cell with names; names need to be associated with email in MailAlert.m
sortingpathbase = '/home/hoodoo/mountainsort/'; %where to look for mountainlab sorting results (small(er) files)

%all clustered datasets
Condition='firings.mda';
AllDatasets = FindClusteredDatasets(sortingpathbase,Animals,Dates,Condition);

%filter datasets: 1) curated 2) recomputed metrics 3) curation.mv2
curated = 'firings.curated.mda';
recompute = 'RecomputeMetrics.json';
curationmv2 = 'curation.mv2';
include=false(1,length(AllDatasets));
for s=1:length(AllDatasets)
    dataset=AllDatasets{s};
    if (exist(fullfile(dataset,curated),'file')==2||isempty(curated)) && (exist(fullfile(dataset,recompute),'file')==2||isempty(recompute)) && (exist(fullfile(dataset,curationmv2),'file')==2||isempty(curationmv2))
        include(s)=true;
    end
end

%
AllDatasets = AllDatasets(include);

Metrics = struct('dataset',[],'cluster',[],'metrics',struct(),'tags',cell(1,1));
ii=0;
for s= 1:length(AllDatasets)
    dataset=AllDatasets{s};
    curated_mda = readmda(fullfile(dataset,curated));
    if ~isempty(curated_mda)
    curated_clusters=unique(curated_mda(3,:));
    curation_data = loadjson(fullfile(dataset,curationmv2));
    recomputed_data=loadjson(fullfile(dataset,recompute));
    Cluster = fieldnames(curation_data.cluster_attributes);
    for c= 1:length(Cluster)
        clust = str2double(Cluster{c}(3:end)); 
        att = curation_data.cluster_attributes.(Cluster{c});
        if isfield(att.metrics,'num_events') && att.metrics.num_events<10%cluster with extrem low nr of events
            continue
        end
        ii=ii+1;
        tmp = [recomputed_data.clusters{:}]; rec = [tmp.label]; rec_idx = find(rec==clust);
        if ~isempty(rec_idx)
            rec_metrics = fieldnames(recomputed_data.clusters{rec_idx}.metrics);
            for r = 1:length(rec_metrics)
                att.metrics.(rec_metrics{r}) = recomputed_data.clusters{rec_idx}.metrics.(rec_metrics{r});
            end
        else
            rec_metrics = fieldnames(recomputed_data.clusters{1}.metrics);
            for r = 1:length(rec_metrics)
                att.metrics.(rec_metrics{r}) = NaN;
            end
        end
        Metrics.dataset{ii}=dataset;
        Metrics.cluster(ii) = clust;
        ffprevious = fieldnames(Metrics.metrics);for f =  1:length(ffprevious), if ~isfield(att.metrics,ffprevious{f}), att.metrics.(ffprevious{f})=NaN; end,end
        ff = fieldnames(att.metrics); for f =  1:length(ff), if ~isfield(Metrics.metrics,ff{f}),Metrics.metrics.(ff{f})(1:ii)=NaN; end, Metrics.metrics.(ff{f})(ii)=att.metrics.(ff{f});  end

        if ~isfield(att,'tags') || isempty(att.tags)
            Metrics.rejected(ii) = false;
            Metrics.tags{ii} = [];
        else
            Metrics.rejected(ii) = any(cellfun(@strcmp,att.tags,repmat({'rejected'},1,length(att.tags))));
            Metrics.tags{ii} = att.tags;
        end
    end
    end
end

figure
noise_overlap = Metrics.metrics.noise_overlap;
completeness1 = Metrics.metrics.completeness1;
isolation = Metrics.metrics.isolation;
l_ratio = Metrics.metrics.l_ratio;
id = Metrics.metrics.isolation_distance;
accepted = ~Metrics.rejected;
subplot(1,2,1)
hold on
plot (noise_overlap(accepted),isolation(accepted),'ok')
plot (noise_overlap(~accepted),isolation(~accepted),'or')
subplot(1,2,2)
hold on
plot (l_ratio(accepted),id(accepted),'ok')
plot (l_ratio(~accepted),id(~accepted),'or')
% xlim([0,20]),ylim([0,50])


%% DISCARD METERICS
ff = fieldnames(Metrics.metrics); 
include_metrics = {'SNR','isolation','noise_overlap','peak_amp','peak_noise','l_ratio','isolation_distance','p_refractory','completeness1','completeness2'};
ffname=           {'SNR','iso',      'noise-ov',     'amp',     'noise',     'l-ratio','id',                'p-ref',       'comp1',        'comp2'}; %MANUAL
% include_metrics={'SNR','p_refractory'};
% ffname=           {'peak_amp','p_refractory'};
idx=[];
for i =1 :length(include_metrics)
    ixx = find(cellfun(@strcmp,ff,repmat(include_metrics(i),length(ff),1))==1);
    if ~isempty(ixx)
        idx = [idx,ixx];
    end
end
ff=ff(idx);

%roc
auroc=zeros(1,length(ff));
for f = 1 : length(ff)
    tmp = Metrics.metrics.(ff{f});
    auroc(f) = nfz_AUROC2(tmp(accepted),tmp(~accepted));
end
barplots=figure;
subplot(1,2,1)
normauroc=(auroc-0.5)*2;
[~,sortidx]=sort(abs(normauroc)); sortname=ffname(sortidx);
bar(normauroc(sortidx),'k')
set(gca,'XTick',1:length(ff),'XTickLabel',sortname)
ylabel('norm auc')


%cov
%sort fields?
ffsorted=ff(sortidx);
D=zeros(length(Metrics.dataset),length(ffsorted));
Din=zeros(sum(accepted),length(ffsorted));
for f = 1 : length(ffsorted)
    D(:,f) = Metrics.metrics.(ffsorted{f});
    tmp = Metrics.metrics.(ffsorted{f});
    Din(:,f) = tmp(accepted);
end
%normalize
D = (D - nanmean(D,1))./nanstd(D,0,1);
Din=(Din-nanmean(Din,1))./nanstd(Din,0,1);
C=cov(D,'partialrows');C(eye(size(C))~=0)=0;
Cin=cov(Din,'partialrows');Cin(eye(size(Cin))~=0)=0;
figure
% subplot(1,2,1)
imagesc(abs(C)); colorbar()
set(gca,'YDir','normal')
set(gca,'YTick',1:length(ff),'XTick',1:length(ff))
ff2=cellfun(@(x) replace(x,'_','-'),ff,'UniformOutput',0);
labels = cellfun(@(x) [x(1:min(length(x),3)),'-',x(max(1,end-3):end)],ff2,'UniformOutput',0);
set(gca,'XTickLabel',sortname)
set(gca,'YTicklabel',sortname)
% subplot(1,2,2)
% imagesc(abs(Cin)); colorbar()
% set(gca,'YDir','normal')
% set(gca,'YTick',1:length(ff),'XTick',1:length(ff))
% labels = cellfun(@(x) [x(1:min(length(x),3)),x(min(1,end-3):end)],ff,'UniformOutput',0);
% set(gca,'XTickLabel',labels)
% set(gca,'YTicklabel',ff)

%lda
lda = fitcdiscr(D,accepted');
[pred_c] = predict(lda,D);
acc = mean(pred_c==accepted');
hit = mean(pred_c(accepted)==accepted(accepted)');
cr = mean(pred_c(~accepted)==accepted(~accepted)');
miss = 1-hit;
fa=1-cr;
% acc = 1-kfoldLoss(lda);

weights=lda.Coeffs(2,1).Linear;
figure(barplots)
subplot(1,2,2)
bar(weights,'k')
set(gca,'XTick',1:length(ff),'XTickLabel',sortname)
ylabel('coeff')



%% reduce metric test
ff = fieldnames(Metrics.metrics); 
include_metrics = {'SNR','isolation','noise_overlap','peak_amp','peak_noise','l_ratio','isolation_distance','p_refractory','completeness1','completeness2'};
ffname=           {'SNR','iso',      'noise-ov',     'amp',     'noise',     'l-ratio','id',                'p-ref',       'comp1',        'comp2'}; %MANUAL
subsets = nchoosek(1:length(include_metrics),3);
for k =1:size(subsets,1)
include_me=include_metrics(subsets(k,:));
ffn=           ffname(subsets(k,:));
idx=[];
for i =1 :length(include_me)
    ixx = find(cellfun(@strcmp,ff,repmat(include_me(i),length(ff),1))==1);
    if ~isempty(ixx)
        idx = [idx,ixx];
    end
end
ffpair=ff(idx);
D=zeros(length(Metrics.dataset),length(ffpair));
for f = 1 : length(ffpair)
    D(:,f) = Metrics.metrics.(ffpair{f});
end
%normalize
D = (D - nanmean(D,1))./nanstd(D,0,1);
%lda
lda = fitcdiscr(D,accepted');
[pred_c] = predict(lda,D);
acc(k) = mean(pred_c==accepted');
end

[~,sortidx]=sort(acc);
figure,
plot(acc(sortidx),'k')

