%extracts Waveforms from mda-file (mountainlab) and creates MClust cluster readable
%tetrode data file and MClust cluster objects

% path to DATA.mda file, firings.mda file, and header file containng
% timestamp information is required.

%to load data in MClust, loading engine LoadTT_mda() is required

%Torben Ott, CSHL, 2017
%tott@cshl.edu

function ConvertToMClust(animal,date,tetrodes,datapathbase,sortingpathbase)

sessions_found = findSessions(datapathbase,animal,date);
for s = 1:length(sessions_found)
    session = sessions_found{s};
    for t = 1:length(tetrodes)
        
        tetrode=tetrodes(t);
        %source path to files
        %raw data mda, firings mda, nlx header file
        firings_path = fullfile(sortingpathbase,animal,session,'output',strcat('ms3--t',num2str(tetrode)));
        header_path = fullfile(datapathbase,animal,session,strcat('tetrode',num2str(tetrode)));
        
        %mda file firings
        mda_sorted = fullfile(firings_path,'firings.mda');
        %prv file tetrode data
        prv_file = fullfile(firings_path,'filt.mda.prv');
        %header file from Tetrode2MDALocal
        mda_header = fullfile(header_path,strcat('tetrode',num2str(tetrode),'header.mat'));
        
        %load firings
        firings = readmda(mda_sorted); %in "samples"
        events = firings(2,:);events(events<8)=[];
        %load data
        prv = loadjson(prv_file); %in "samples"
        data = readmda(prv.original_path);
        %load header
        load(mda_header);
        
        Timestamps = header(1).TimeStamps*10^6;%in sec
        
        TTdata = struct('header',header,'firings',firings,'Waveforms',zeros(length(events),size(data,1),32),'Timestamps',Timestamps);
        
        for f = 1:size(data,1)
            for i = 1:length(events)
                TTdata.Waveforms(i,f,:) = data(f,events(i)-7:events(i)+24)';
            end
        end
        
        %save waveform data in mat file. to be read by loading engine in MClust
        save(fullfile(firings_path,'TTDataMClust.dat'),'TTdata','-mat');
        
        %%CREATE MCLUST OBJECTS
        
        MClust_Colors = [0.5,0.5,0.5;1,0,0;1,1,0;0,1,1;0,0,1;1,0,1;0.5,0,1;0,0.5,1;1,0,0.5;1,0.5,0;1,0.333333333333333,1;1,0.666666666666667,1;0.166666666666667,0,0;0.333333333333333,0,0;0.500000000000000,0,0;0.666666666666667,0,0;0.833333333333333,0,0;1,0,0;0,0.166666666666667,0;0,0.333333333333333,0;0,0.500000000000000,0;0,0.666666666666667,0;0,0.833333333333333,0;0,1,0;0,0,0.166666666666667;0,0,0.333333333333333;0,0,0.500000000000000;0,0,0.666666666666667;0,0,0.833333333333333;0,0,1;0,0,0;0.142857142857143,0.142857142857143,0.142857142857143;0.285714285714286,0.285714285714286,0.285714285714286;0.428571428571429,0.428571428571429,0.428571428571429;0.571428571428571,0.571428571428571,0.571428571428571;0.714285714285714,0.714285714285714,0.714285714285714;0.857142857142857,0.857142857142857,0.857142857142857;1,1,1];
        
        %cluster identity in 3th row of firings matrix
        
        cluster = firings(3,:);
        cluster_id = unique(cluster);
        MClust_Clusters = cell(1,length(cluster_id));
        for c = 1:length(cluster_id)
            if c<10
                add = '0';
            else
                add=[];
            end
            MCC = mccluster(['Cluster ',add,num2str(c)]);
            MCC.myOrigPoints = find(cluster==cluster_id(c));
            MClust_Clusters{c} = MCC;
        end
        
        %save MCLust readable cluster objects
        save(fullfile(firings_path,'TTMDA.clusters'),'MClust_Clusters','MClust_Colors','-v7');
    end
end