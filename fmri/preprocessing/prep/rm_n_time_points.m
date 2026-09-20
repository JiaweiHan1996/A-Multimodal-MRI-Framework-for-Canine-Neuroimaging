function PP = rm_n_time_points(PP)


fprintf(['\nRemove First n Timepoints Starting   ||    ' spm('time') '\n']);

PP = rm_vols_batch(PP);

% Only update DataList if there are successful files
if ~isempty(PP.DataList.Sublist)
    PP = OutputCommPara(PP);
    fprintf(['\nRemove First n Timepoints Completed    ||    ' spm('time') '\n']);
else
    fprintf('\n[ERROR] No files successfully processed. Pipeline stopped.\n');
end

end

function PP = rm_vols_batch(PP)

% ===== Load PP =====
DataList = PP.DataList;
DelIndex = PP.Step_T.Del_Tps;

[d, f, ~] = fileparts(PP.FunPath);
FilePath = d;
out_dir_name_Fun = [f 'T'];
Fun_out_Path = [FilePath filesep out_dir_name_Fun];
if exist(Fun_out_Path, 'dir')
    rmdir(Fun_out_Path, 's');
end
mkdir(Fun_out_Path);

% Copy data
[status, message] = copyfile(PP.FunPath, Fun_out_Path);
if ~status
    fprintf('[ERROR] Copy failed: %s\n', message);
    return;
end

DataList.FunFolder_Name = out_dir_name_Fun;

scans_list = cell(length(DataList.Sublist), 1);
for i = 1:length(DataList.Sublist)
    scans_list{i} = fullfile(DataList.dataroot_path, ...
                                DataList.FunFolder_Name, ...
                                DataList.Sublist{i}, ...
                                DataList.filename{i});
end

% Extract original reference headers
ref_headers = cell(length(scans_list), 1);
for i = 1:length(scans_list)
    source_file = strrep(scans_list{i}, [f 'T'], f);
    if exist(source_file, 'file')
        try
            ref_headers{i} = spm_vol(source_file);
        catch
            ref_headers{i} = [];
        end
    else
        ref_headers{i} = [];
    end
end

% Remove time points and track successful files
parfor i = 1:length(scans_list)
    try
        rm_vols_for_nii(scans_list{i}, DelIndex, ref_headers{i});
    catch ME
        fprintf('Error processing %s: %s\n', DataList.Sublist{i}, ME.message);
    end
end


PP.DataList = DataList;
PP.FunPath = Fun_out_Path;


end

function success = rm_vols_for_nii(scans, DelIndex, ref_header)

success = false;
Nii4dFilePath = scans;
[Volume4D, ~, ~, Header, ~] = read_To4d(Nii4dFilePath);

% Get the number of time points
num_time_points = size(Volume4D, 4);

% Check if DelIndex exceeds the number of time points
if DelIndex >= num_time_points
    fprintf('\n[ERROR] Del_Tps (%d) exceeds time points (%d) for: %s\n', ...
            DelIndex, num_time_points, scans);
    return;
end

delete(Nii4dFilePath);

% Write new file
write_To4dNifti(Volume4D(:,:,:,DelIndex+1:end), Header, Nii4dFilePath);

% Restore TR information using the existing add_TR_tag function
% if ~isempty(ref_header)
%     add_TR_tag(Nii4dFilePath, ref_header);
% end

success = true;

end

function PP = OutputCommPara(PP)
%% Update DataList after successful time points removal

DataList = PP.DataList;

% Verify files actually exist and are readable
valid_indices = [];
for i = 1:length(DataList.Sublist)
    file_path = fullfile(DataList.dataroot_path, ...
                        DataList.FunFolder_Name, ...
                        DataList.Sublist{i}, ...
                        DataList.filename{i});
    
    if exist(file_path, 'file')
        try
            V = spm_vol(file_path);
            if length(V) > 0
                valid_indices(end+1) = i;
            end
        catch
            % Skip invalid files
        end
    end
end

% Update DataList with only valid files
if ~isempty(valid_indices)
    DataList.Sublist = DataList.Sublist(valid_indices);
    DataList.filename = DataList.filename(valid_indices);
    DataList.json_name = DataList.json_name(valid_indices);
    DataList.TR = DataList.TR(valid_indices);
    DataList.TE = DataList.TE(valid_indices);
else
    % If no valid files, clear DataList
    DataList.Sublist = {};
    DataList.filename = {};
    DataList.json_name = {};
    DataList.TR = [];
    DataList.TE = [];
end

PP.DataList = DataList;

if isempty(DataList.Sublist)
    fprintf('\n[ERROR] No valid files remaining for next step, please check log!\n');
end
end