% nlx2mda(file) converts a neuralynx continous recording file (.ncs) to a
% MountainLab .mda file and returns a MATLAB header struct.

% Requires input to have 1 channel, 512 samples, same sample frequency per
% record (see Neuralynx documentation)

% input:     filename of source file, destination filename
% output:     header struct, saves mda file to destination

% dependencies: requires writemda16i.m obtained from
% https://mountainlab.vbulletin.net/articles/16-multi-dimensional-array-format-mda
% and Nlx2MatCSC_v3.m obtained from
% http://neuralynx.com/research_software/file_converters_afilend_utilities/


% Torben Ott, CSHL, September 2016
%                   May 2017
%                   check for full time stamp match, save log, cut
%                   timestamps, and used timestamps.

function [header] = nlx2mda(pathname,file,pathnamesave,filesave)

T=cell(1,length(file));
for i = 1 : length(file)
    T{i} = Nlx2MatCSC_v3(fullfile(pathname,file{i}),[1,0,0,0,0],0,1);
end
Tintersect=T{1};
for i = 1 : length(file)-1
    Tintersect = intersect(Tintersect,T{i+1});
end
Cut = cellfun(@setxor,T,repmat({Tintersect},1,length(file)),'UniformOutput',false);
CutN=cellfun(@numel,Cut);
log = repmat({''},1,length(file));
for i = 1:length(CutN)
    if CutN(i)>0
        log{i} = sprintf('%s: Removed %i timestamps between %0.0f and %0.0f.\n',file{i},CutN(i),Cut{i}(1)/10^6,Cut{i}(end)/10^6);
    else
        log{i} = sprintf('%s: Included all timestamps.\n',file{i});
    end
end
CutTimeStamps = struct('FileName',file,'CutTimeStamps',Cut);

for i = 1 : length(file)
    
    try
        [TimeStamps, ChannelNumbers, SampleFrequencies,NumberOfValidSamples, Samples, Header] = ...
            Nlx2MatCSC_v3(fullfile(pathname,file{i}),[1,1,1,1,1],1,1);
    catch
        error('Neuralynx file could not be read. see Nlx2MatCSC.m for details.')
    end
    
    %correct for intersection (used as proof)
    [TimeStamps,idx] = intersect(TimeStamps,Tintersect);
    ChannelNumbers = ChannelNumbers(idx);
    SampleFrequencies = SampleFrequencies(idx);
    NumberOfValidSamples = NumberOfValidSamples(idx);
    Samples = Samples(:,idx);
    
    %test
    if length(unique(NumberOfValidSamples))>1
        if length(unique(NumberOfValidSamples(1:end-1)))>1
            error('Number of samples not the same for each record.');
        else
            warning('Number of valid samples for last record low.');
        end
    end
    if unique(NumberOfValidSamples)~=512
        error('Number of samples per record not 512.');
    end
    if length(unique(SampleFrequencies))>1
        error('Number of sample frequencies not the same for each record.');
    end
    if length(unique(ChannelNumbers))>1
        error('Number of channels not the same for each record.');
    end
    if length(unique(ChannelNumbers))~=1
        error('More than one channel per record.');
    end
    if ~isempty(setxor(TimeStamps,Tintersect))
        error('Intersection timestamps do not match up with corrected file time stamps');
    end
    
    SampleFreq = unique(SampleFrequencies);
    NSample = unique(NumberOfValidSamples(1:end-1));
    NRecord = size(Samples,2);
    header(i) = struct('NLXHeader',{Header},'SampleFreq',SampleFreq,'NSample',NSample,...
        'NRecord',NRecord,'Tstart',Tintersect(1),'log',log{i},'TimeStamps',Tintersect,'CutTimeStamps',Cut{i});
    
    
    SamplesAll{i} = Samples;
    
end
clear TimeStamps ChannelNumbers SampleFrequencies NumberOfValidSamples  Samples Header TimeStampsCorr CorrIndex

% convert nlx data to MxN array with M channels and N timepoints
for i =1 : length(SamplesAll)
    array(i,:) = reshape(SamplesAll{i},1,NSample*NRecord);
    SamplesAll{i}=[];
end

%write mda file
writemda16i(array,fullfile(pathnamesave,filesave));
save(fullfile(pathnamesave,[filesave(1:end-4),'header.mat']),'header')
logtxt = fopen(fullfile(pathnamesave,'log.txt'),'w');
fprintf(logtxt,cell2mat(log),pathnamesave);
fclose(logtxt);
fprintf('Done.\n',fullfile(pathnamesave,filesave));

end


