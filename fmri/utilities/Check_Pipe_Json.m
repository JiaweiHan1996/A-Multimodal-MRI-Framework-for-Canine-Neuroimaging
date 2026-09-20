function PP = Check_Pipe_Json(Pipe_Json_Path)
%% update: 2025-09-30

PP = struct();
All_Step_Names = {
    'DICOM_2_Nii',...
    'Remove_First_n_Timepoints',...
    'Realign',...
    'Slice_Timing',...
    'ME_Combine',...
    'Reorient',...
    'Normalize',...
    'Smooth',...
    'Detrend',...
    'Covs_Regressing',...
    'Filter',...
    'QC'
    };

% ========== Load Json ==========
try 
    jstr = fileread(Pipe_Json_Path);
    jstr = strrep(jstr, '\', '\\');
    PP_r = jsondecode(jstr); clear jstr
    PP_r.Pipe_Json_Path = Pipe_Json_Path;
catch ME
    fprintf('JSON 格式错误：\n');
    fprintf('   错误信息: %s\n', ME.message);
    
    if contains(ME.message, 'position')
        errorDetail = regexp(ME.message, 'position\s*(\d+)', 'tokens', 'once');
        if ~isempty(errorDetail)
            errorPos = str2double(errorDetail{1});
            fprintf('   可能错误的字符位置: %d\n', errorPos);
            
            lines = strsplit(jsonText, '\n');
            charCount = 0;
            for i = 1:length(lines)
                lineLength = length(lines{i}) + 1; % +1 for newline
                if charCount + lineLength >= errorPos
                    fprintf('   可能位于行: %d, 列: %d\n', i, errorPos - charCount);
                    break;
                end
                charCount = charCount + lineLength;
            end
        end
    end
    return;
end
%% ========== Check PP Head ==========
[pp_flag, PP_r] = check_pp_head(PP_r);
if ~pp_flag; return; end
clear pp_flag

%% ========== Check PP Steps ==========
Step_Seq = {};          % This Varb is to Check Sequence
num_steps = check_pp_step_num(PP_r.Process_INFO);
if num_steps == -1; return; end
for i = 1:num_steps
    % ---------- General Checking ----------
    [pp_flag, curr_step, FieldNames] = check_pp_step_general(PP_r.Process_INFO, i, All_Step_Names);
    if ~pp_flag; return; end; clear pp_flag

    Step_Seq{i} = curr_step.Name;       % Add Name into Step_Seq 
    
    % ---------- Check Remove_First_n_Timepoints ----------
    if strcmp(curr_step.Name, 'DICOM_2_Nii')
        step_flag = check_dcm2nii_BrainSize(curr_step, FieldNames);
        if ~step_flag; return; end; clear step_flag
        
    % ---------- Check Remove_First_n_Timepoints ----------
    elseif strcmp(curr_step.Name, 'Remove_First_n_Timepoints')
        step_flag = check_rmv_1st_n_tps(curr_step, FieldNames);
        if ~step_flag; return; end; clear step_flag
        
    % ---------- Check Slice_Timing ----------
    elseif strcmp(curr_step.Name, 'Slice_Timing')
        step_flag = check_slice_timing(curr_step, FieldNames);
        if ~step_flag; return; end; clear step_flag
    
    % ---------- Check ME_Combine ----------
    elseif strcmp(curr_step.Name, 'ME_Combine')
        step_flag = check_MECombined(curr_step, FieldNames);
        if ~step_flag; return; end; clear step_flag

    % ---------- Check Normalize ----------
    elseif strcmp(curr_step.Name, 'Normalize')
        step_flag = check_normalize(curr_step, FieldNames);
        if ~step_flag; return; end; clear step_flag
    
    % ---------- Check Smooth ----------
    elseif strcmp(curr_step.Name, 'Smooth')
        step_flag = check_smooth(curr_step, FieldNames);
        if ~step_flag; return; end; clear step_flag
        
    % ---------- Check Covs_Regressing ----------
    elseif strcmp(curr_step.Name, 'Covs_Regressing') && length(FieldNames) > 1
        step_flag = check_cov_regress(curr_step, FieldNames);
        if ~step_flag; return; end; clear step_flag
    
    % ---------- Check Filter ----------
    elseif strcmp(curr_step.Name, 'Filter')
        step_flag = check_filter(curr_step, FieldNames);
        if ~step_flag; return; end; clear step_flag
    
    end
    
    if strcmp(curr_step.Name, 'ME_Combine')
        if PP_r.Data_INFO.Enum == 1
            fprintf('\nWhen ''Enum'' is 1, the ''ME_Combine'' step should be deleted.\n');
            return;
        end
    end
    
    clear curr_step FieldNames
end; clear i

%% ========== Check Step Sequence ==========
seq_flag = check_step_sequence(Step_Seq);
if ~seq_flag; return; end; clear seq_flag

%% ========== Fill PP ==========
[~, Pipe_Json_Name, ~] = fileparts(Pipe_Json_Path);
fprintf('\n%s is Standard, Continue to Parse ...    ||    %s\n', Pipe_Json_Name, spm('time'));
PP = PP_r;
PP.Total_Step_Num = num_steps;

end

%% ========== Sub Functions ==========
function [pp_flag, PP_r] = check_pp_head(PP_r)
% Check Headers in PP_r
pp_flag = false;

% ---------- Check Import_INFO Data_INFO Process_INFO ----------
ck_var = {'Config_INFO','Process_Type', 'Import_INFO', 'Data_INFO', 'Process_INFO', 'Delete_Folder_INFO'};
% NOT Exist
for i = 1:length(ck_var)
    if ~isfield(PP_r, ck_var{i})
        fprintf(['\nNo "' ck_var{i} '" in the Json file !!!\n']);
        return
    end
end; clear i ck_var

% ---------- Check Config_INFO ----------
if ~isfield(PP_r.Config_INFO, 'Template')
    fprintf('\nThe "Template" does not exist in the Config_INFO section of the Json file !!!\n');
    return
else
    if (PP_r.Config_INFO.Template ~= "") && (~isfile(PP_r.Config_INFO.Template))
        fprintf('\n"%s" is NOT Existed !!!\n', PP_r.Config_INFO.Template);
        return
    elseif (PP_r.Config_INFO.Template ~= "") && isfile(PP_r.Config_INFO.Template)  
        file_path = PP_r.Config_INFO.Template;
        [~, ~, ext] = fileparts(file_path);
        if ~strcmpi(ext, '.nii')
            fprintf('\n"%s" is NOT a NIfTI file. Please convert it to NIfTI format.\n', file_path);
            return
        end
    end
end

PP_r.IsOld_Segment = 0;
[check_status, PP_r] = check_TPM_config(PP_r);
if check_status == 0
    return;
end

if isfield(PP_r.Process_INFO, 'Step_W') || isfield(PP_r.Process_INFO, 'Step_C')
    if ~isfield(PP_r.Config_INFO, 'Mask')
        fprintf('\nThe "Mask" does not exist in the Config_INFO section of the Json file !!!\n');
        return
    else
        if isempty(fieldnames(PP_r.Config_INFO.Mask))
            fprintf('\nThe Mask is empty in the Config_INFO section of the Json file !!!\n');
            return
        else
            ck_var = {'Brain', 'WM', 'CSF'};
            for i = 1:length(ck_var)
                if ~isfield(PP_r.Config_INFO.Mask, ck_var{i})
                    fprintf(['\nThe "' ck_var{i} '" does not exist in the Config_INFO.Mask section of the Json file !!!\n']);
                    return
                else
                    if eval(['PP_r.Config_INFO.Mask.' ck_var{i}]) ~= ""
                        file = strsplit(eval(['PP_r.Config_INFO.Mask.' ck_var{i}]), ',');
                        Mask_file = file{1};
                        if ~isfile(Mask_file)
                            fprintf('\n"%s" is NOT Existed !!!\n', Mask_file);
                            return
                        else
                            [~, ~, ext] = fileparts(Mask_file);
                            if ~strcmpi(ext, '.nii')
                                fprintf('\n"%s" is NOT a NIfTI file. Please convert it to NIfTI format.\n', Mask_file);
                                return
                            end
                        end
                    end
                end
            end; clear i ck_var
        end
    end
end


% ---------- Check Import_INFO: Start_Fun_Name Start_T1_Name ----------
ck_var = {'Start_Fun_Name'};
% NOT Exist
if ~isfield(PP_r.Import_INFO, ck_var)
    fprintf(['\nThe "' ck_var '" does not exist in the Import_INFO section of the Json file !!!\n']);
    return
end
clear ck_var
ck_var = {'Start_T1_Name'};
% NOT Exist
if ~isfield(PP_r.Import_INFO, ck_var)
    fprintf(['\nThe "' ck_var{i} '" does not exist in the Import_INFO section of the Json file !!!\n']);
end
clear ck_var

% ---------- Check Data_INFO: TR ----------
if isfield(PP_r.Data_INFO, 'TR')
    % NOT Num
    if ~isnumeric(PP_r.Data_INFO.TR) && all(PP_r.Data_INFO.TR ~= [])
        fprintf('\nThe "TR" is NOT Numeric in the Data_INFO section of the Json file !!!\n');
        return
    end
    % Unit Error
    if PP_r.Data_INFO.TR > 10
        fprintf('\nThe "TR" Value > 10, Unit of TR Shoule be [sec] !!!\n');
        return
    end
end

% ---------- Check Data_INFO: Snum Enum RefEcho ----------
Nums = {'Snum', 'Enum', 'RefEcho'};
for k = 1:length(Nums)
    if ~isfield(PP_r.Data_INFO, Nums{k})
        fprintf(['\nThe "' Nums{k} '" does not exist in the Data_INFO section of the Json file !!!\n']);
        return
    end
    % NOT Num
    if ~isnumeric(eval(['PP_r.Data_INFO.' Nums{k}]))
        fprintf(['\nThe "' Nums{k} '" is NOT Numeric in the Data_INFO section of the Json file !!!\n']);
        return
    end
    % NOT Integer
    if rem(eval(['PP_r.Data_INFO.' Nums{k}]), 1) ~= 0 || eval(['PP_r.Data_INFO.' Nums{k}]) < 0
        fprintf(['\nThe "' Nums{k} '" is NOT Positive Integer in the Data_INFO section of the Json file !!!\n']);
        return
    end
end; clear k
% RefEcho > Enum
if PP_r.Data_INFO.RefEcho > PP_r.Data_INFO.Enum
    fprintf('\nThe value of RefEcho in the Data_INFO section of the Json file should be less than the value of Enum !!!\n');
    return
end

if ~isempty(strfind(PP_r.Import_INFO.Start_Fun_Name, 'Cb'))
    if PP_r.Data_INFO.Enum ~= 1 || PP_r.Data_INFO.RefEcho ~= 1
        fprintf('\n"Cb" found in Start_Fun_Name - Enum value or RefEcho value in Data_INFO section must be 1!!!\n');
        return
    end
end

% ---------- All Finished ----------
pp_flag = true;

end

function num_steps = check_pp_step_num(mainStruct)
% Based on the input "Section", count the number of instances that meet the conditions of the structure
    fieldNames = fieldnames(mainStruct);
    subStructCount = 0;

    for i = 1:length(fieldNames)
        currentField = mainStruct.(fieldNames{i});
        if isstruct(currentField)
            subStructCount = subStructCount + 1;
        else
            fprintf(['\nThere are steps in the Process_INFO section of the Json file that... '
                'do not conform to the structure of the defined structure !!!\n']);
            num_steps = -1;
            return
        end
    end
    num_steps = subStructCount;
end

function [pp_flag, curr_step, FieldNames] = check_pp_step_general(PP_r, sn, All_Step_Names)
% Check Each Step in PP_r
fieldNames = fieldnames(PP_r);
pp_flag = false;

clear curr_step
curr_step = PP_r.(fieldNames{sn});

% Empty Struct
clear FieldNames
FieldNames = fieldnames(curr_step);
if isempty(FieldNames)       
    fprintf('\nThe %s in the Process_INFO section of the Json file is empty !!!\n', fieldNames{sn});
    return
end
% Lack “Name” in Struct
if ~contains('Name', FieldNames)
    fprintf('\nThe "Name" of %s in the Process_INFO section of the Json file is missing !!!\n', fieldNames{sn});
    return
end
% Wrong "Name" in Struct
if ~contains(curr_step.Name, All_Step_Names)
    fprintf('\nThere is a spelling mistake in "%s" within the Process_INFO section of the Json file !!!\n', curr_step.Name);
    return
end

% ---------- All Finished ----------
pp_flag = true;
end

%%
% ---------- Check dcm2nii Brain Size (mm)----------
function step_flag = check_dcm2nii_BrainSize(curr_step, FieldNames)
step_flag = false;

if contains('Brain_Size_mm', FieldNames)
    % NOT Num
    if ~isnumeric(curr_step.Brain_Size_mm)
        fprintf(['\n"'  curr_step.Name '" Brain_Size_mm is NOT Numeric !!!\n']);
        return
    end
    % NOT Integer
    if rem(curr_step.Brain_Size_mm, 1) ~= 0 || curr_step.Brain_Size_mm < 0
        fprintf(['\n"' curr_step.Name '" Brain_Size_mm is NOT Positive Integer !!!\n']);
        return
    end
else
    curr_step.Brain_Size_mm=140;
    fprintf(['\nWarning: "' curr_step.Name '" Brain_Size_mm is NOT Defined, to be set as 140 ...\n']);
end

% ---------- Check Finished ----------
step_flag = true;
end

% ---------- Check Remove First n Timepoints ----------
function step_flag = check_rmv_1st_n_tps(curr_step, FieldNames)
step_flag = false;

if contains('Del_Tps', FieldNames)
    % NOT Num
    if ~isnumeric(curr_step.Del_Tps)
        fprintf(['\n"'  curr_step.Name '" Del_Tps is NOT Numeric !!!\n']);
        return
    end
    % NOT Integer
    if rem(curr_step.Del_Tps, 1) ~= 0 || curr_step.Del_Tps < 0
        fprintf(['\n"' curr_step.Name '" Del_Tps is NOT Positive Integer !!!\n']);
        return
    end
else
    curr_step.Del_Tps=0;
    fprintf(['\nWarning: "' curr_step.Name '" Del_Tps is NOT Defined, to be set as 0 ...\n']);
end

% ---------- Check Finished ----------
step_flag = true;
end

% ---------- Check Slice_Timing ---------
function step_flag = check_slice_timing(curr_step, FieldNames)
step_flag = false;

if contains('Slice_Order', FieldNames)
    if ~isempty(curr_step.Slice_Order) && ~ismatrix(curr_step.Slice_Order)
        fprintf(['\n"' curr_step.Name '" Slice_Order is NOT Standard !!!\n']);
        return
    end
    if isempty(curr_step.Slice_Order)
        fprintf(['\nWarning: The Slice_Order in "' curr_step.Name '" is not specified, program will read it from the Json file !!!\n']);
    end
    if (~isempty(curr_step.Slice_Order)) && ~(all(curr_step.Slice_Order(:) > 0) && all(round(curr_step.Slice_Order(:)) == curr_step.Slice_Order(:)))
        fprintf(['\n"' curr_step.Name '" Slice_Order is NOT Standard !!!\n']); 
        return
    end    
else
    fprintf(['\nWarning: "' curr_step.Name '" Slice_Order is NOT Defined, to be set as [] ...\n']);
end

if contains('Ref_Slice', FieldNames)
    if ~isempty(curr_step.Ref_Slice) && ~isnumeric(curr_step.Ref_Slice)
        fprintf(['\n"' curr_step.Name '" Ref_Slice is NOT Standard !!!\n']);
        return
    end
    if isempty(curr_step.Ref_Slice == [])
        fprintf(['\nWarning: The Ref_Slice in "' curr_step.Name '" is not specified, program will read it from the Json file !!!\n']);
    end
else
    fprintf(['\nWarning: "' curr_step.Name '" Ref_Slice is NOT Defined, to be set as [] ...\n']);
end

% ---------- Check Finished ----------
step_flag = true;
end


% ---------- Check check ME Combined ----------
function step_flag = check_MECombined(curr_step, FieldNames)
step_flag = false;
% ----- Is Parameters -----
IS_Paras = {'OnlyOptcom'};
for isp = 1:length(IS_Paras)
    if contains(IS_Paras{isp}, FieldNames)
        is_val = eval(['curr_step.' IS_Paras{isp}]);
        % NOT Num
        if ~isnumeric(is_val)
            fprintf(['\n"' curr_step.Name '" ' IS_Paras{isp} ' is NOT Numeric !!!\n']);
            return
        end
        % NOT 0/1
        if is_val ~= 0 && is_val ~= 1   % 不是0/1
            fprintf(['\n"' curr_step.Name '" ' IS_Paras{isp} ' Value is NOT 0 or 1 !!!\n']);
            return
        end
        clear is_val
    end
end; clear isp
% ---------- Check Finished ----------
step_flag = true;
end


% ---------- Check Normalize ----------
function step_flag = check_normalize(curr_step, FieldNames)
step_flag = false;

% ----- Check ResVoxelSize -----
if contains('ResVoxelSize', FieldNames)

    if ~isempty(curr_step.ResVoxelSize)
        if ~isnumeric(curr_step.ResVoxelSize)
            fprintf(['\n"' curr_step.Name '" ResVoxelSize is NOT a numeric matrix !!!\n']);
            return
        end
        % NOT 3 x 1 Matrix
        if ~isequal(size(curr_step.ResVoxelSize), [3, 1])
            fprintf(['\n"' curr_step.Name '" ResVoxelSize is NOT a 3 x 1 Matrix !!!\n']);
            return
        end
        % NOT Positive Matrix
        if ~all(curr_step.ResVoxelSize(:) > 0)
            fprintf(['\n"' curr_step.Name '" ResVoxelSize Exists Negative Value !!!\n']);
            return
        end
    end
end

% ----- isDARTEL -----
if contains('IsDARTEL', FieldNames)
    % NOT Num
    if ~isnumeric(curr_step.IsDARTEL)
        fprintf(['\n"' curr_step.Name '" IsDARTEL is NOT Numeric !!!\n']);
        return
    end
    % NOT Integer
    if rem(curr_step.IsDARTEL, 1) ~= 0 || curr_step.IsDARTEL < 0
        fprintf(['\n"' curr_step.Name '" IsDARTEL is NOT Positive Integer !!!\n']);
        return
    end
    
end
% ----- T1_BET -----
if contains('IsT1_BET', FieldNames)
    % NOT Num
    if ~isnumeric(curr_step.IsT1_BET)
        fprintf(['\n"' curr_step.Name '" IsT1_BET is NOT Numeric !!!\n']);
        return
    end
    % NOT Integer
    if rem(curr_step.IsT1_BET, 1) ~= 0 || curr_step.IsT1_BET < 0
        fprintf(['\n"' curr_step.Name '" IsT1_BET is NOT Positive Integer !!!\n']);
        return
    end
end

% ---------- Check Finished ----------
step_flag = true; 
end

function num = tpm_path_check(tpm_struct, isold_seg)
    fields = fieldnames(tpm_struct);
    num_fields = length(fields);
    if ((isold_seg == 1) && (num_fields < 3)) || ((isold_seg == 0) && (num_fields < 6))
        fprintf(['In the Json file, the User_tpm_path field in the Normalize section of '...
                'Process_INFO is missing some necessary fields, please review the sample Json file !!!\n']);
        num = -1;
        return
    end
    num_vector = [];
    is_4d = 0;
    for i=1:num_fields
        Value = tpm_struct.(fields{i});
        split_value = split(Value, ",");
        
        num_value = split_value{2};
        if isstrprop(num_value, 'digit')
            if str2num(num_value) > 6
                fprintf(['Within the Process_INFO.Normalize section of the JSON file, '...
                        'the User_tpm_path corresponding TPM values must be positive integers ≤ 6 !!!']);
                num = -1;
                return;
            elseif (isold_seg == 0) && (str2num(num_value) == 0)
                  fprintf(['Within the Process_INFO.Normalize section of the JSON file, '...
                           'When IsOld_Segment is 0 and User_tpm_path is not empty, '...
                            'the corresponding TPM values of User_tpm_path must be positive integers ranging from 1 to 6 !!!']);
                  num = -1;
                  return;  
            else
                num_vector = [num_vector str2num(num_value)];
            end
        else
            fprintf(['Within the Process_INFO.Normalize section of the JSON file, '...
                    'the User_tpm_path corresponding TPM values are not digits or positive integers !!!']);
            num = -1;
            return;
        end
        
        path_value = split_value{1};
        if (str2num(num_value) ~= 0) && ~isfile(path_value)
            fprintf(['Within the Process_INFO.Normalize section of the JSON file, '...
                    'the User_tpm_path file:%s is NOT Existed !!!', path_value]);
            num = -1;
            return;
        else
            if str2num(num_value) ~= 0
                nii_header = spm_vol(path_value);
                if length(nii_header) == 1
                    if (str2num(num_value) ~= 0) && (str2num(num_value) ~= 1)
                        fprintf(['Within the Process_INFO.Normalize section of the JSON file, '...
                                'the User_tpm_path corresponding TPM value should be 1, when TPM data is in 3D format !!!']);
                        num = -1;
                        return;
                    end
                else
                    is_4d = 1;
                end
            end
        end    
    end
    if is_4d
        if isold_seg == 1
            result = (num_vector(1) ~= num_vector(2)) && (num_vector(1) ~= num_vector(3)) && (num_vector(2) ~= num_vector(3));
            if ~result
                fprintf(['Within the Process_INFO.Normalize section of the JSON file, '...
                        'the first three digits of the User_tpm_path corresponding TPM values must be different, '...
                         'when TPM data is in 4D format and IsOld_Segment is 1 !!!']);
                num = -1;
                return;
            end
        end
        if isold_seg == 0
            result = length(unique(num_vector)) == numel(num_vector);
            if ~result
                fprintf(['Within the Process_INFO.Normalize section of the JSON file, '...
                        'the digits of the User_tpm_path corresponding TPM values must be different, '...
                        'when TPM data is in 4D format and IsOld_Segment is 0 !!!']);
                num = -1;
                return;
            end
        end
    end
    num = num_fields;
end

% ---------- Check Smooth ----------
function step_flag = check_smooth(curr_step, FieldNames)
step_flag = false;

% ----- Check FWHM -----
if contains('FWHM', FieldNames)
    % NOT (Empty) Matrix
    if ~ismatrix(curr_step.FWHM) && all(curr_step.FWHM ~= [])
        fprintf(['\n"' curr_step.Name '" FWHM is NOT Standard !!!\n']);
        return
    end
    % NOT 3 x 1 Matrix
    if all(size(curr_step.FWHM) ~= [3, 1])
        fprintf(['\n"' curr_step.Name '" FWHM is NOT Standard !!!\n']);
        return
    end
    % NOT Positive Matrix
    if ~all(curr_step.FWHM(:) > 0)
        fprintf(['\n"' curr_step.Name '" FWHM Exists Negative Value !!!\n']);
        return
    end
end

% ---------- Check Finished ----------
step_flag = true;
end

% ---------- Check Smooth ----------
function step_flag = check_cov_regress(curr_step, FieldNames)
step_flag = false;

% ----- Is Parameters -----
IS_Paras = {'IsWholeBrain', 'IsCSF', 'IsWhiteMatter', 'AddMean'};
for isp = 1:length(IS_Paras)
    if contains(IS_Paras{isp}, FieldNames)
        is_val = eval(['curr_step.' IS_Paras{isp}]);
        % NOT Num
        if ~isnumeric(is_val)
            fprintf(['\n"' curr_step.Name '" ' IS_Paras{isp} ' is NOT Numeric !!!\n']);
            return
        end
        % NOT 0/1
        if is_val ~= 0 && is_val ~= 1   % 不是0/1
            fprintf(['\n"' curr_step.Name '" ' IS_Paras{isp} ' Value is NOT 0 or 1 !!!\n']);
            return
        end
        clear is_val
    end
end; clear isp

IS_Paras = {'IsHeadMotion'};
for isp = 1:length(IS_Paras)
    if contains(IS_Paras{isp}, FieldNames)
        is_val = eval(['curr_step.' IS_Paras{isp}]);
        % NOT Num
        if ~isnumeric(is_val)
            fprintf(['\n"' curr_step.Name '" ' IS_Paras{isp} ' is NOT Numeric !!!\n']);
            return
        end
        % NOT 0 ~ 4
        if is_val < 0 || is_val > 4   % 不是0到4之间
            fprintf(['\n"' curr_step.Name '" ' IS_Paras{isp} ' Value is NOT 0/1/2/3/4 !!!\n']);
            return
        end
        clear is_val
    end
end; clear isp


% ---------- Check Finished ----------
step_flag = true;
end

% ---------- Check Filter ----------
function step_flag = check_filter(curr_step, FieldNames)
step_flag = false;

% ----- Check Band -----
if  contains('Band', FieldNames)
    % NOT (Empty) Matrix
    if ~ismatrix(curr_step.Band) && all(curr_step.Band ~= [])
        fprintf(['\n"' curr_step.Name '" Band is NOT Standard !!!\n']);
        return
    end
    % NOT 2 x 1 Matrix
    if all(size(curr_step.Band) ~= [2, 1])
        fprintf(['\n"' curr_step.Name '" Band is NOT Standard !!!\n']);
        return
    end
    % NOT Positive Matrix
    if ~all(curr_step.Band(:) > 0)
        fprintf(['\n"' curr_step.Name '" Band Exists Negative Value !!!\n']);
        return
    end
    % Value 1 > Value 2
    if curr_step.Band(1) >= curr_step.Band(2)
        fprintf(['\n"' curr_step.Name '" Band Value 1 >= Value 2 !!!\n']);
        return
    end
end

% ---------- Check Finished ----------
step_flag = true;
end

%%
function seq_flag = check_step_sequence(Step_Seq)
seq_flag = false;

% ----- "DICOM_2_Nii" NOT Step_1 -----
if contains('DICOM_2_Nii', Step_Seq)
    idx = find(strcmp('DICOM_2_Nii', Step_Seq));
    if idx ~= 1
        fprintf('\n"DICOM_2_Nii" Must be Step_1 !!!\n');
        return
    end
    clear idx
end

% ----- "ME_Combine" AFTER Certain Steps -----
if contains('ME_Combine', Step_Seq)
    idx_me = find(strcmp('ME_Combine', Step_Seq));
    steps_aft_me = {'Reorient', 'Normalize', 'Smooth', 'Detrend', 'Covs_Regressing', 'Filter'};
    for k = 1:length(steps_aft_me)
        if contains(steps_aft_me{k}, Step_Seq)
            idx_k = find(strcmp(steps_aft_me{k}, Step_Seq));
            if idx_k < idx_me
                fprintf(['\n"ME_Combine" Must before "' steps_aft_me{k} '" !!!\n']);
                return
            end
            clear idx_k
        end
    end; clear k
    clear steps_aft_me idx_me
end

% ----- "Realign" BEFORE "ME_Combine" -----
if contains('Realign', Step_Seq) && contains('ME_Combine', Step_Seq)
    idx_reo = find(strcmp('Realign', Step_Seq));
    idx_norm = find(strcmp('ME_Combine', Step_Seq));
    if idx_reo > idx_norm
        fprintf('\n"Realign" Must before "ME_Combine" !!!\n');
        return
    end
    clear idx_reo idx_norm
end

% ----- "Reorient" BEFORE "Normalize" -----
if contains('Reorient', Step_Seq) && contains('Normalize', Step_Seq)
    idx_reo = find(strcmp('Reorient', Step_Seq));
    idx_norm = find(strcmp('Normalize', Step_Seq));
    if idx_reo > idx_norm
        fprintf('\n"Reorient" Must before "Normalize" !!!\n');
        return
    end
    clear idx_reo idx_norm
end

% ----- "QC" after "Covs_Regressing" -----
% if contains('QC', Step_Seq) 
%     if contains('Covs_Regressing', Step_Seq)
%         idx_reo = find(strcmp('Covs_Regressing', Step_Seq));
%         idx_norm = find(strcmp('QC', Step_Seq));
%         if idx_reo > idx_norm
%             fprintf('\n"QC" Must after "Covs_Regressing" !!!\n');
%             return
%         end
%     else
%         fprintf('\nWhen "QC" is present, "Covs_Regressing" must also be present !!!\n');
%     end
%     clear idx_reo idx_norm
% end

% ----- "QC" after "ME_Combine" -----
if contains('QC', Step_Seq) && contains('ME_Combine', Step_Seq) 
    if contains('ME_Combine', Step_Seq)
        idx_reo = find(strcmp('ME_Combine', Step_Seq));
        idx_norm = find(strcmp('QC', Step_Seq));
        if idx_reo > idx_norm
            fprintf('\n"QC" Must after "ME_Combine" !!!\n');
            return
        end
    end
    clear idx_reo idx_norm
end

% ----- "Realign" BEFORE "ME_Combine" -----
if contains('QC', Step_Seq) && contains('Normalize', Step_Seq)
    idx_reo = find(strcmp('QC', Step_Seq));
    idx_norm = find(strcmp('Normalize', Step_Seq));
    if idx_reo > idx_norm
        fprintf('\n"QC" Must before "Normalize" !!!\n');
        return
    end
    clear idx_reo idx_norm
end

% ---------- Check Finished ----------
seq_flag = true;
end


function [status, PP_r] = check_TPM_config(PP_r)
% CHECK_TPM_CONFIG 检查TPM配置的有效性
%   [status, PP_r] = check_TPM_config(PP_r) 检查PP_r结构体中的TPM配置
%   
%   输入参数:
%       PP_r - 包含Config_INFO和Process_INFO的结构体
%   
%   输出参数:
%       status - 检查状态: 1表示通过，0表示失败
%       PP_r   - 更新后的PP_r结构体（如果有修改）
%
%   功能说明:
%       1. 检查GM_Path, WM_Path, CSF_Path是否存在且有效
%       2. 检查Skull_Path, Scalp_Path, Background_Path的配置
%       3. 在DARTEL模式下强制要求三个路径必须存在且有效
%       4. 非DARTEL模式下允许三个路径都不存在（使用旧分割流程）

status = 1;  % 初始状态为通过

% 检查 GM_Path, WM_Path, CSF_Path
ck_var = {'GM_Path', 'WM_Path', 'CSF_Path'};
for i = 1:length(ck_var)
    if ~isfield(PP_r.Config_INFO.TPM, ck_var{i}) && ~isempty(PP_r.Import_INFO.Start_T1_Name)
        fprintf('\nThe Start_T1_Name "%s" in the Import_INFO is specified\n', PP_r.Import_INFO.Start_T1_Name);
        fprintf(['\nThe "' ck_var{i} '" must exist in the Config_INFO.TPM section of the Json file !!!\n']);
        status = 0;
        return
    elseif isfield(PP_r.Config_INFO.TPM, ck_var{i}) && ~isempty(PP_r.Import_INFO.Start_T1_Name)
        if eval(['PP_r.Config_INFO.TPM.' ck_var{i}]) ~= ""
            file = strsplit(eval(['PP_r.Config_INFO.TPM.' ck_var{i}]), ',');
            TPM_file = file{1};
            if ~isfile(TPM_file)
                fprintf('\nThe Start_T1_Name "%s" in the Import_INFO is specified\n', PP_r.Import_INFO.Start_T1_Name);
                fprintf('\nBut "%s" is NOT Existed !!!\n', TPM_file);
                status = 0;
                return
            else
                [~, ~, ext] = fileparts(TPM_file);
                if ~strcmpi(ext, '.nii')
                    fprintf('\nThe Start_T1_Name "%s" in the Import_INFO is specified\n', PP_r.Import_INFO.Start_T1_Name);
                    fprintf('\n"%s" is NOT a NIfTI file. Please convert it to NIfTI format.\n', TPM_file);
                    status = 0;
                    return
                end
            end
        end
    end
end; clear i ck_var

% 检查 Skull_Path, Scalp_Path, Background_Path
ck_var = {'Skull_Path', 'Scalp_Path', 'Background_Path'};

% 检查字段是否存在（允许不存在）
fields_exist = true;
for i = 1:length(ck_var)
    if ~isfield(PP_r.Config_INFO.TPM, ck_var{i})
        fields_exist = false;
        break;
    end
end

% 检查是否需要 DARTEL 模式
need_dartel = isfield(PP_r.Process_INFO, 'Step_W') && ...
              isfield(PP_r.Process_INFO.Step_W, 'IsDARTEL') && ...
              PP_r.Process_INFO.Step_W.IsDARTEL == 1;

if need_dartel
    % DARTEL 模式下，三个字段必须存在且非空
    if ~fields_exist
        fprintf('\nDARTEL mode is enabled (Step_W.IsDARTEL == 1).\n');
        fprintf('Skull_Path, Scalp_Path, and Background_Path are required in Config_INFO.TPM section.\n');
        fprintf('Please add these fields to the JSON file.\n');
        status = 0;
        return;
    end
    
    % 获取三个路径的值
    skull_val = eval(['PP_r.Config_INFO.TPM.Skull_Path']);
    scalp_val = eval(['PP_r.Config_INFO.TPM.Scalp_Path']);
    bg_val = eval(['PP_r.Config_INFO.TPM.Background_Path']);
    
    % 统计非空的个数
    non_empty_count = sum([~strcmp(skull_val, ""), ~strcmp(scalp_val, ""), ~strcmp(bg_val, "")]);
    
    if non_empty_count < 3
        % 找出哪些缺失
        missing_list = {};
        if ~fields_exist || strcmp(skull_val, "")
            missing_list{end+1} = 'Skull_Path';
        end
        if ~fields_exist || strcmp(scalp_val, "")
            missing_list{end+1} = 'Scalp_Path';
        end
        if ~fields_exist || strcmp(bg_val, "")
            missing_list{end+1} = 'Background_Path';
        end
        
        fprintf('\nDARTEL mode is enabled (Step_W.IsDARTEL == 1).\n');
        fprintf('Skull_Path, Scalp_Path, and Background_Path must all be present and non-empty.\n');
        fprintf('Currently missing or empty:\n');
        for i = 1:length(missing_list)
            fprintf('  - %s\n', missing_list{i});
        end
        status = 0;
        return;
    end
    
    % 三个都存在且非空，逐一检查文件
    for i = 1:length(ck_var)
        if eval(['PP_r.Config_INFO.TPM.' ck_var{i}]) ~= ""
            file = strsplit(eval(['PP_r.Config_INFO.TPM.' ck_var{i}]), ',');
            TPM_file = file{1};
            if ~isfile(TPM_file)
                fprintf('\n"%s" is NOT Existed !!!\n', TPM_file);
                status = 0;
                return
            else
                [~, ~, ext] = fileparts(TPM_file);
                if ~strcmpi(ext, '.nii')
                    fprintf('\n"%s" is NOT a NIfTI file. Please convert it to NIfTI format.\n', TPM_file);
                    status = 0;
                    return
                end
            end
        end
    end
    
else
    % 非 DARTEL 模式，三个字段可以都不存在
    if fields_exist
        % 字段存在，检查是否部分存在或全部存在
        skull_val = eval(['PP_r.Config_INFO.TPM.Skull_Path']);
        scalp_val = eval(['PP_r.Config_INFO.TPM.Scalp_Path']);
        bg_val = eval(['PP_r.Config_INFO.TPM.Background_Path']);
        
        non_empty_count = sum([~strcmp(skull_val, ""), ~strcmp(scalp_val, ""), ~strcmp(bg_val, "")]);
        
        if non_empty_count > 0 && non_empty_count < 3
            % 部分存在，报错
            missing_list = {};
            if strcmp(skull_val, "")
                missing_list{end+1} = 'Skull_Path';
            end
            if strcmp(scalp_val, "")
                missing_list{end+1} = 'Scalp_Path';
            end
            if strcmp(bg_val, "")
                missing_list{end+1} = 'Background_Path';
            end
            
            fprintf('\nIncomplete TPM configuration detected!\n');
            fprintf('Skull_Path, Scalp_Path, and Background_Path must be either all present or all absent.\n');
            fprintf('Currently, the following required path(s) are missing:\n');
            for i = 1:length(missing_list)
                fprintf('  - %s\n', missing_list{i});
            end
            status = 0;
            return;
        elseif non_empty_count == 3
            % 三个都存在，检查文件
            for i = 1:length(ck_var)
                if eval(['PP_r.Config_INFO.TPM.' ck_var{i}]) ~= ""
                    file = strsplit(eval(['PP_r.Config_INFO.TPM.' ck_var{i}]), ',');
                    TPM_file = file{1};
                    if ~isfile(TPM_file)
                        fprintf('\n"%s" is NOT Existed !!!\n', TPM_file);
                        status = 0;
                        return
                    else
                        [~, ~, ext] = fileparts(TPM_file);
                        if ~strcmpi(ext, '.nii')
                            fprintf('\n"%s" is NOT a NIfTI file. Please convert it to NIfTI format.\n', TPM_file);
                            status = 0;
                            return
                        end
                    end
                end
            end
        elseif non_empty_count == 0
            % 三个都为空，提示使用旧的分割流程
            fprintf('\nOnly ''GM_Path'', ''WM_Path'', and ''CSF_Path'' are provided in Config_INFO.TPM.\n');
            fprintf('Proceeding with old segmentation method.\n');
            PP_r.IsOld_Segment = 1;
        end
    else
        % 字段不存在，提示使用旧的分割流程
        fprintf('\nOnly ''GM_Path'', ''WM_Path'', and ''CSF_Path'' are provided in Config_INFO.TPM.\n');
        fprintf('Proceeding with old segmentation method.\n');
        PP_r.IsOld_Segment = 1;
    end
end

end