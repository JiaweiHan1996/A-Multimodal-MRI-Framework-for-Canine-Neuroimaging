function T1DataList = T1DataList_sort(PP)
% T1DataList_sort - Create T1DataList structure with required variables

T1DataList = struct();

if endsWith(PP.T1Path, 'Seg')
    T1_out_Path = PP.T1Path;
    raw_T1_path = strrep(PP.T1Path, 'Seg', '');
else
    raw_T1_path = PP.T1Path;
    [d1, f1, ~] = fileparts(PP.T1Path);
    T1_out_Path = [d1 filesep f1 'Seg'];
    
    if exist(T1_out_Path, 'dir')
        rmdir(T1_out_Path, 's');
    end
    mkdir(T1_out_Path);
    
    copyfile(raw_T1_path, T1_out_Path);
    fprintf('Copied from %s to %s\n', raw_T1_path, T1_out_Path);
end

[~, T1DataList.T1Folder_Name, ~] = fileparts(T1_out_Path);

raw_files = dir([raw_T1_path filesep '*']);
raw_dirs = {raw_files([raw_files.isdir]).name};
T1DataList.Sublist = (raw_dirs(~ismember(raw_dirs, {'.', '..'})))';


T1DataList.filename = cell(length(T1DataList.Sublist), 1);
T1DataList.T1_List = cell(length(T1DataList.Sublist), 1);

for i = 1:length(T1DataList.Sublist)
    sub_dir = T1DataList.Sublist{i};
    
    raw_sub_path = [T1_out_Path filesep sub_dir];
    t1_file = dir([raw_sub_path filesep 'co*']);
    t1_file = fullfile(raw_sub_path, t1_file(1).name);
    if strcmpi(t1_file(end-6:end), '.nii.gz')  
        gunzip(t1_file, raw_sub_path);
        t1_file = t1_file(1:end-3);  
    elseif ~strcmpi(t1_file(end-3:end), '.nii')
        error('Could not find a .nii or .nii.gz file starting with "co"');
    end
    if ~isempty(t1_file) && isfile(t1_file)
        [~, a, b]=fileparts(t1_file);
        T1DataList.filename{i} = [a, b];
        T1DataList.T1_List{i} = fullfile(raw_sub_path, [a, b]);
        fprintf('  %s: %s\n', t1_file);
    else
        fprintf('Warning: No T1 file found for %s\n', sub_dir);
        T1DataList.filename{i} = '';
        T1DataList.T1_List{i} = '';
    end
end

empty_idx = cellfun(@isempty, T1DataList.T1_List);
if any(empty_idx)
    fprintf('Removing %d empty entries\n', sum(empty_idx));
    T1DataList.Sublist(empty_idx) = [];
    T1DataList.filename(empty_idx) = [];
    T1DataList.T1_List(empty_idx) = [];
end


if isfield(PP, 'Step_W') && isfield(PP.Step_W, 'IsT1_BET') && PP.Step_W.IsT1_BET == 1
    T1DataList.brain_filename = cell(length(T1DataList.Sublist), 1);
    T1DataList.T1brain_List = cell(length(T1DataList.Sublist), 1);
    
    for i = 1:length(T1DataList.Sublist)
        [~, name, ext] = fileparts(T1DataList.filename{i});
        T1DataList.brain_filename{i} = [name '_brain' ext];
        T1DataList.T1brain_List{i} = [fileparts(T1DataList.T1_List{i}) filesep T1DataList.brain_filename{i}];
    end
end

fprintf('T1DataList created with %d subjects.\n', length(T1DataList.Sublist));
end