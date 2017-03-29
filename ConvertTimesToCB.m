function NewSpikes = ConvertTimesToCB(ncs_file,clusters)
% Converts the MountainView timestamps to cellbase


[time,data]=getRawCSCTimestamps(ncs_file);

SampFreq=clusters.header(1).SampleFreq;
NSample=clusters.header(1).NSample;
NRecord=clusters.header(1).NRecord;

MVSpikes=clusters.firings(2,:);
NewSpikes=zeros(size(MVSpikes));

% Initialize the spik counter
spikeindex=0;
spikenums=zeros(data,1);
maxspike=length(MVSpikes);

for i=1:data
   
startpoint=((i-1)*NSample+1); % Set beginning of segment
endpoint=(i*NSample); % set end of segment

Beforeend= MVSpikes(spikeindex+1:min(spikeindex+51,maxspike))<endpoint;
GoodSpikes= Beforeend==1;
spikenums(i)=sum(GoodSpikes);

if spikenums(i)~=0
NewSpikes(spikeindex+1:spikeindex+spikenums(i))=time(i)+(MVSpikes(spikeindex+1:spikeindex+spikenums(i))-startpoint)/SampFreq*1000000;
end


spikeindex=spikeindex+sum(GoodSpikes);
spikenums(i)=sum(GoodSpikes);

end



NewSpikes=NewSpikes/100;


end

