function keepCoNiiAndJson(targetPath)
% keepCoNiiAndJson  Deletes all files under the specified path except .nii files
%                    starting with "co" and all .json files
% Input:
%   targetPath - Target folder path (optional, defaults to the current folder)
%
% Compatibility: Does not use containers.Map; works with all MATLAB versions.

if nargin < 1
    targetPath = pwd;
end


items = dir(targetPath);
items = items(~[items.isdir]);         

keepFiles = {};

for k = 1:length(items)
    [~, name, ext] = fileparts(items(k).name);
    if strcmpi(ext, '.nii') && numel(name) >= 2 && strcmpi(name(1:2), 'co')
        keepFiles{end+1} = items(k).name;
    elseif strcmpi(ext, '.json')
        keepFiles{end+1} = items(k).name;
    end
end

filesToDelete = {};
for k = 1:length(items)
    if ~ismember(items(k).name, keepFiles)
        filesToDelete{end+1} = fullfile(targetPath, items(k).name);
    end
end


for k = 1:length(filesToDelete)
    delete(filesToDelete{k});
end

end