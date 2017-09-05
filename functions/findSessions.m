function sessions_found = findSessions(sourcepathbase,animal,date)
%% find folders
sourcepath=fullfile(sourcepathbase,animal);
folders = dir(sourcepath);
folders = {folders.name};
findfolder = cellfun(@strfind,folders,repmat({date},1,length(folders)),'UniformOutput',0);
findfolder = ~cellfun(@isempty,findfolder);

sessions_found = folders(findfolder);
if isempty(sessions_found)
    fprintf('No Sessions found.\n');
end
end