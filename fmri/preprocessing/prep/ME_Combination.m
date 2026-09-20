function PP = ME_Combination(PP)
%% Multi-Echo Combination Pipeline

fprintf('\nMulti-Echo fMRI Combination Starting ...\n');

%% ===== Initialize =====
original_DataList = PP.DataList;
original_FunPath = PP.FunPath;

[d, f, ~] = fileparts(original_FunPath);
cb_path = [d filesep f 'Cb'];
if exist(cb_path, 'dir')
    rmdir(cb_path, 's');
end
mkdir(cb_path);

Parameters = MEC_Para(PP, cb_path, original_DataList);

%% ===== ME-Combine =====
if isempty(Parameters.echo_files)
    fprintf('ERROR: No valid multi-echo groups found!\n');
    return;
end

% Process each group
num_groups = length(Parameters.echo_files);

parfor i = 1:num_groups
    if length(Parameters.echo_files{i}) ~= PP.Enum
        fprintf('ERROR: Group %d incorrect echoes. Skipping...\n', i);
        continue;
    end 
    
    % Build command
    echo_times_ms = Parameters.echo_times{i} * 1000;
    [outputDir, output_name, c] = fileparts(Parameters.output_names{i});
    result = runComb( ...
                     'echo_files',Parameters.echo_files{i}, ... 
                     'echo_times',echo_times_ms, ...
                     'outputDir', outputDir,...
                     'outputname', [output_name c]);
end


PP = UpdatePPAndDataList(PP, cb_path, original_DataList, Parameters);

fprintf('Multi-Echo fMRI Combination Completed！\n');
end

function Parameters = MEC_Para(PP, cb_path, original_DataList)
%% Generate parameters for MECombed_command.exe

Parameters = struct();

% Calculate total number of files and groups
total_files = length(original_DataList.Sublist);
num_groups = total_files / PP.Enum;

Parameters.echo_files = cell(1, num_groups);
Parameters.echo_times = cell(1, num_groups);
Parameters.output_names = cell(1, num_groups);
Parameters.clean_sublists = cell(1, num_groups); 
Parameters.clean_filenames = cell(1, num_groups); 

for i = 1:num_groups
    % Calculate indices for this echo group using mathematical relationship
    echo_indices = (i-1)*PP.Enum + (1:PP.Enum);
    
    echo_files = cell(1, PP.Enum);
    echo_times = zeros(1, PP.Enum);
    
    for j = 1:PP.Enum
        idx = echo_indices(j);
        data_path = fullfile(original_DataList.dataroot_path, original_DataList.FunFolder_Name, original_DataList.Sublist{idx});
        echo_files{j} = fullfile(data_path, original_DataList.filename{idx});
        echo_times(j) = original_DataList.TE(idx);
    end
    
    % Get first echo info for output path
    first_idx = echo_indices(1);
    first_sublist = original_DataList.Sublist{first_idx};
    first_filename = original_DataList.filename{first_idx};
    
    % Remove EchoX_ prefix from filename
    [~, first_name, first_ext] = fileparts(first_filename);
    clean_name = regexprep(first_name, '^Echo\d+_', '');
    clean_filename = ['Cb' clean_name first_ext];
    
    % Remove Echo level from sublist path
    sublist_parts = strsplit(first_sublist, filesep);
    echo_mask = contains(sublist_parts, 'Echo');
    if any(echo_mask)
        clean_sublist_parts = sublist_parts(~echo_mask);
        clean_sublist = strjoin(clean_sublist_parts, filesep);
    else
        clean_sublist = first_sublist;
    end
    
    % Build output path in Cb folder
    output_fullpath = fullfile(cb_path, clean_sublist, clean_filename);
    
    % Ensure output directory exists
    output_dir = fileparts(output_fullpath);
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end
    
    Parameters.echo_files{i} = echo_files;
    Parameters.echo_times{i} = echo_times;
    Parameters.output_names{i} = output_fullpath;
    Parameters.clean_sublists{i} = clean_sublist;
    Parameters.clean_filenames{i} = clean_filename;
end
end

function PP = UpdatePPAndDataList(PP, cb_path, original_DataList, Parameters)

% Initialize new DataList
NewDataList = struct();
NewDataList.dataroot_path = original_DataList.dataroot_path;
[d, f, ~] = fileparts(PP.FunPath);
NewDataList.FunFolder_Name = [f 'Cb']; 
NewDataList.Sublist = {};
NewDataList.filename = {};
NewDataList.json_name = {};
NewDataList.TR = [];
NewDataList.TE = [];
for i = 1:length(Parameters.output_names)

    output_path = Parameters.output_names{i};
    sublist = Parameters.clean_sublists{i};
    filename = Parameters.clean_filenames{i};
    jsonfile = PP.DataList.json_name{PP.RefEcho + (i-1)*PP.Enum};
    
    if ~exist(output_path, 'file')
        fprintf('WARNING: Combined file not found: %s\n', output_path);
        continue;
    end
    
    original_idx = (i-1) * PP.Enum + 1;
    if original_idx <= length(original_DataList.TR)
        tr_value = original_DataList.TR(original_idx);
    else
        tr_value = original_DataList.TR(1);
    end
    
    NewDataList.Sublist{end+1, 1} = sublist;
    NewDataList.filename{end+1, 1} = filename;
    NewDataList.json_name{end+1, 1} = jsonfile;
    NewDataList.TR(end+1, 1) = tr_value;
    NewDataList.TE(end+1, 1) = NaN;
    json_oldpath = fullfile(PP.DataList.dataroot_path,PP.DataList.FunFolder_Name, sublist, ['Echo' num2str(PP.RefEcho)], jsonfile);
    json_newpath = fullfile(PP.DataList.dataroot_path,NewDataList.FunFolder_Name, sublist);
    [status, message] = copyfile(json_oldpath, json_newpath);
    if status
        fprintf('\nSuccessfully copied all files from %s to %s\n', json_oldpath, json_newpath);
    else
        fprintf('\n[ERROR] Copy failed: %s\n', message);
    end
    if exist(output_path, 'file')
        try
            if ~exist(PP.RP_Path, 'dir')
                mkdir(PP.RP_Path);
            end
            RP_sub_path = fullfile(PP.RP_Path,sublist);
            if ~exist(RP_sub_path, 'dir')
                mkdir(RP_sub_path);
            end
            mean_filename = fullfile(PP.RP_Path,sublist,['mean' filename]);
            MeanCalc(output_path, mean_filename)
            fprintf('Mean image created: %s\n', mean_filename);
        catch ME
            fprintf('\n[WARNING] Mean image creation failed for %s: %s\n', filename, ME.message);
        end
    end
end
NewDataList.Sublist = NewDataList.Sublist(:);
NewDataList.filename = NewDataList.filename(:);
NewDataList.json_name = NewDataList.json_name(:);
NewDataList.TR = NewDataList.TR(:);
NewDataList.TE = NewDataList.TE(:);

PP.DataList = NewDataList;
PP.FunPath = cb_path;

fprintf('DataList updated: %d entries\n', length(NewDataList.Sublist));
fprintf('PP.FunPath updated to: %s\n', cb_path);
end