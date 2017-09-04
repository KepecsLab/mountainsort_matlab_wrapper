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
recompute = 'RecomputeAllMetrics.json';
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
    curation_data = loadjson(fullfile(dataset,curationmv2));
    recomputed_data=loadjson(fullfile(dataset,recompute));
    nClust = length(recomputed_data.clusters);
    if  any(~ismember(cellfun(@(x) x.label,recomputed_data.clusters), cellfun(@(x) str2double(x(3:end)),fieldnames(curation_data.cluster_attributes))'))
        fprintf('Warning: Recomputed metrics and curation.mv2 do not match for %s.\nDataset skipped.\n',dataset);
        firings=readmda(fullfile(dataset,'firings.mda'));
        continue
    end
    for c= 1:nClust
        clust_metrics = recomputed_data.clusters{c}.metrics; %from recomputed
        clust_label = recomputed_data.clusters{c}.label; %from recomputed
        if isfield(curation_data.cluster_attributes.(['x_',num2str(clust_label)]),'tags')
            clust_tags = curation_data.cluster_attributes.(['x_',num2str(clust_label)]).tags; %from curation.mv2
        else
            clust_tags=[];
        end
        if isfield(clust_metrics,'num_events') && clust_metrics.num_events<10%cluster with extrem low nr of events
            continue
        end
        ii=ii+1;
        
        %add metrics
        Metrics.dataset{ii}=dataset;
        Metrics.cluster(ii) = clust_label;
        ff = fieldnames(clust_metrics);
        for f =  1:length(ff)
           Metrics.metrics.(ff{f})(ii)=clust_metrics.(ff{f});
        end
        
        %tags & determine rejected
        if isempty(clust_tags)
            Metrics.rejected(ii) = false;
            Metrics.tags{ii} = [];
        else
            Metrics.rejected(ii) = any(cellfun(@strcmp,clust_tags,repmat({'rejected'},1,length(clust_tags))));
            Metrics.tags{ii} = clust_tags;
        end
    end
end

figure
noise_overlap = Metrics.metrics.noise_overlap;
completeness1 = Metrics.metrics.completeness1;
isolation = Metrics.metrics.isolation;
p_ref=Metrics.metrics.p_refractory;
l_ratio = Metrics.metrics.l_ratio;
id = Metrics.metrics.isolation_distance;
accepted = ~Metrics.rejected;
subplot(1,2,1)
hold on
plot (noise_overlap(accepted),isolation(accepted),'ok')
plot (noise_overlap(~accepted),isolation(~accepted),'or')
ylim([0.8,1]);xlim([0,0.2])
subplot(1,2,2)
hold on
plot (l_ratio(accepted),id(accepted),'ok')
plot (l_ratio(~accepted),id(~accepted),'or')
% xlim([0,20]),ylim([0,50])
figure
subplot(1,2,1)
plot3(noise_overlap(accepted),isolation(accepted),completeness1(accepted),'ok')
hold on
plot3 (noise_overlap(~accepted),isolation(~accepted),completeness1(~accepted),'or')
xlabel('noise_ov');ylabel('iso');zlabel('comp1')
view(2)
subplot(1,2,2)
plot3(noise_overlap(accepted),isolation(accepted),p_ref(accepted),'ok')
hold on
plot3 (noise_overlap(~accepted),isolation(~accepted),p_ref(~accepted),'or')
xlabel('noise_ov');ylabel('iso');zlabel('pref')
view(2)

figure
subplot(1,2,1)
boxplot(l_ratio,accepted,'ExtremeMode','clip')
ylim([-2,8])
xlabel('l-ratio');set(gca,'XtickLabel',{'rej','acc'});
subplot(1,2,2)
boxplot(id,accepted,'ExtremeMode','clip')
ylim([0,50])
xlabel('iso dist');set(gca,'XtickLabel',{'rej','acc'});
%% INCLUDE METERICS
ff = fieldnames(Metrics.metrics); 
include_metrics = {'peak_snr','isolation','noise_overlap','l_ratio','isolation_distance','p_refractory','completeness1'};
ffname=           {'SNR','iso',      'noise-ov',          'l-ratio','id',                'p-ref',       'comp'}; %MANUAL
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
RedoTicks(gcf)
% subplot(1,2,2)
% imagesc(abs(Cin)); colorbar()
% set(gca,'YDir','normal')
% set(gca,'YTick',1:length(ff),'XTick',1:length(ff))
% labels = cellfun(@(x) [x(1:min(length(x),3)),x(min(1,end-3):end)],ff,'UniformOutput',0);
% set(gca,'XTickLabel',labels)
% set(gca,'YTicklabel',ff)

%lda
acc=[];
weights=[];
% for i =1:100
% split=randperm(size(D,1),ceil(size(D,1)/2));
% split2=setxor(1:size(D,1),split);
% D1=D(split,:);
% D2=D(split2,:);
% lda = fitcdiscr(D1,accepted(split)');
% [pred_c] = predict(lda,D2);
% acc(i) = mean(pred_c==accepted(split2)');
% weights(:,i)=lda.Coeffs(2,1).Linear;
% end
% figure,hist(acc,10);
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
include_metrics = {'SNR','isolation','noise_overlap','l_ratio','isolation_distance','p_refractory','completeness1'};
ffname=           {'SNR','iso',      'noise-ov',      'l-ratio','id',                'p-ref',       'comp'}; %MANUAL
subsets = nchoosek(1:length(include_metrics),3);
acc=[];
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
xlabel('triplet')
ylabel('accuracy')

best_subsets=subsets(sortidx,:);
for i =1:5
ffname(best_subsets(end-i+1,:))
end

figure
subplot(1,2,1)
hold on
plot (noise_overlap(~accepted),isolation(~accepted),'.k')
plot(noise_overlap(accepted),isolation(accepted),'.r')

xlabel('noise-overlap');ylabel('isolation');
subplot(1,2,2)
hold on
plot(noise_overlap(accepted),isolation(accepted),'.r')
plot (noise_overlap(~accepted),isolation(~accepted),'.k')

xlabel('noise-overlap');ylabel('isolation');
xlim([0,0.1]); ylim([0.85,1]);
RedoTicks(gcf)

figure
subplot(1,2,1)
hold on
plot3(noise_overlap(accepted),isolation(accepted),completeness1(accepted),'.r')
plot3 (noise_overlap(~accepted),isolation(~accepted),completeness1(~accepted),'.k')
xlabel('noise-overlap');ylabel('isolation');zlabel('completeness')
xlim([0,0.1]); ylim([0.85,1]);zlim([0.8,1])
view(2)
subplot(1,2,2)
hold on
plot3(noise_overlap(accepted),isolation(accepted),completeness1(accepted),'.r')
plot3 (noise_overlap(~accepted),isolation(~accepted),completeness1(~accepted),'.k')
xlabel('noise-overlap');ylabel('isolation');zlabel('completeness')
xlim([0,0.1]); ylim([0.85,1]);zlim([0.8,1])
view(2)
RedoTicks(gcf)

% subplot(2,2,4)
% hold on
% plot3(noise_overlap(accepted),isolation(accepted),completeness1(accepted),'.r')
% plot3 (noise_overlap(~accepted),isolation(~accepted),completeness1(~accepted),'.k')
% xlabel('noise-overlap');ylabel('isolation');zlabel('completeness')
% view(2)
% xlim([0,0.1]); ylim([0.85,1]);zlim([0.8,1])
% set(gca,'ZDir','reverse')
RedoTicks(gcf)