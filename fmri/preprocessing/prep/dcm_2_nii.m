function PP = dcm_2_nii(PP)
%% dcm_2_nii: Convert DICOM to NIfTI for functional and T1 data
%   update: 20260319
%
%   Input PP structure with fields:
%       FunPath    - root directory containing functional DICOM subfolders
%       T1Path     - root directory containing T1 DICOM subfolders (may be empty)
%       Snum       - number of sessions
%       Enum       - number of echoes
%       Template   - path to T1 template for reorientation
%       brain_size - size for robust field of view (robustfov)
%       Flip_LR    - flag for left-right flip (passed to reorient_img)
%       ReferenceEcho - reference echo number for parameter extraction (default: 1)
%
%   Output PP with updated FunPath and T1Path pointing to output directories

% ===== Extract parameters =====
FunPath = PP.FunPath;
T1Path = PP.T1Path;
Snum = PP.Snum;
Enum = PP.Enum;
T1w_Template_path = PP.Config_INFO.Template;
brain_size = PP.Step_H.Brain_Size_mm;
flip_flag = PP.Flip_LR;

% ===== Extract reference echo parameter =====
if isfield(PP, 'ReferenceEcho') && ~isempty(PP.ReferenceEcho)
    ref_echo = PP.ReferenceEcho;
    if ref_echo < 1 || ref_echo > Enum
        warning('Reference echo %d is out of range (1-%d). Using echo 1 instead.', ref_echo, Enum);
        ref_echo = 1;
    end
else
    ref_echo = 1;  % Default to first echo
end
fprintf('Using Echo %d as reference for parameter extraction\n', ref_echo);

% ===== Prepare output directories =====
[d, f, ~] = fileparts(FunPath);
FilePath = d;

out_dir_name_Fun = [f 'H'];
Fun_out_Path = [FilePath filesep out_dir_name_Fun];
if exist(Fun_out_Path, 'dir')
    rmdir(Fun_out_Path, 's');
end
mkdir(Fun_out_Path);

if ~isempty(T1Path)
    [~, f_t1, ~] = fileparts(T1Path);
    out_dir_name_T1 = [f_t1 'H'];
    T1_out_Path = [FilePath filesep out_dir_name_T1];
    if exist(T1_out_Path, 'dir')
        rmdir(T1_out_Path, 's');
    end
    mkdir(T1_out_Path);
else
    T1_out_Path = '';
end

% ===== Functional Data Processing =====
SubfodrList = dir_NameList(FunPath);   % get subject folders
errors_Fun = cell(length(SubfodrList), 1);

% Initialize nested storage for all subjects and sessions
reorient_index_all = cell(length(SubfodrList), 1);
z_lower_all = cell(length(SubfodrList), 1);
z_upper_all = cell(length(SubfodrList), 1);
Origin_transform_matrix_all = cell(length(SubfodrList), 1);

fprintf('\n=== Starting Functional DICOM to NIfTI Conversion ===\n');

for i = 1:length(SubfodrList)
    subj = SubfodrList{i};  % Move outside try block to ensure defined in catch
    try
        Fun_sub_Path = [FunPath filesep subj];
        Funsub_out_Path = [Fun_out_Path filesep subj];

        if ~exist(Fun_sub_Path, 'dir')
            errors_Fun{i} = sprintf('Source directory does not exist: %s', Fun_sub_Path);
            continue;
        end
        mkdir(Funsub_out_Path);

        % Initialize session storage for current subject
        num_sessions_to_store = max(Snum, 1);  % At least 1 session
        reorient_index_subj = cell(num_sessions_to_store, 1);
        z_lower_subj = cell(num_sessions_to_store, 1);
        z_upper_subj = cell(num_sessions_to_store, 1);
        Origin_transform_matrix_subj = cell(num_sessions_to_store, 1);

        % --- Multi-Session ---
        if Snum > 1
            for sess = 1:Snum
                Fun_sess_Path = [Fun_sub_Path filesep 'S' num2str(sess)];
                if ~exist(Fun_sess_Path, 'dir')
                    warning('Session directory does not exist: %s', Fun_sess_Path);
                    % Store empty for this session
                    reorient_index_subj{sess} = [];
                    z_lower_subj{sess} = [];
                    z_upper_subj{sess} = [];
                    Origin_transform_matrix_subj{sess} = [];
                    continue; 
                end
                Funsess_out_Path = [Funsub_out_Path filesep 'S' num2str(sess)];
                mkdir(Funsess_out_Path);

                % Initialize variables for current session
                reorient_index = [];
                z_lower = [];
                z_upper = [];
                Origin_transform_matrix = [];

                if Enum > 1
                    % Multi-Echo: call common processing function
                    [reorient_index, z_lower, z_upper, Origin_transform_matrix] = ...
                        process_multi_echo(Fun_sess_Path, Funsess_out_Path, ref_echo);
                else
                    % Single-Echo
                    dicm2nii(Fun_sess_Path, Funsess_out_Path, 0);
                    [reorient_index, outputname, perm, flipDims] = ...
                        reorient_img(Funsess_out_Path, T1w_Template_path, flip_flag, []);
                    [z_lower, z_upper] = robustfov_matlab(outputname, [], brain_size, perm, flipDims);
                    [path, name, ext] = fileparts(outputname);
                    co_output_nii = fullfile(path, ['co' name ext]);
                    
                    raw_mat = spm_vol(co_output_nii);
                    originAlignmentPrompt(co_output_nii, T1w_Template_path);
                    ref_mat = spm_vol(co_output_nii);
                    MAT = ref_mat(1).mat(1:3,4) - raw_mat(1).mat(1:3,4);
                    Origin_transform_matrix = [eye(3) MAT; 0 0 0 1];
                    
                    keepCoNiiAndJson(Funsess_out_Path);
                end
                
                % Store session data
                if ~isempty(reorient_index) && ~isempty(Origin_transform_matrix)
                    reorient_index_subj{sess} = reorient_index;
                    z_lower_subj{sess} = z_lower;
                    z_upper_subj{sess} = z_upper;
                    Origin_transform_matrix_subj{sess} = Origin_transform_matrix;
                else
                    reorient_index_subj{sess} = [];
                    z_lower_subj{sess} = [];
                    z_upper_subj{sess} = [];
                    Origin_transform_matrix_subj{sess} = [];
                    warning('Subject %s, Session %d: No valid parameters obtained', subj, sess);
                end
            end

        else % Single-Session
            % Initialize variables for single session
            reorient_index = [];
            z_lower = [];
            z_upper = [];
            Origin_transform_matrix = [];
            
            if Enum > 1
                % Multi-Echo: call common processing function
                [reorient_index, z_lower, z_upper, Origin_transform_matrix] = ...
                    process_multi_echo(Fun_sub_Path, Funsub_out_Path, ref_echo);
            else
                % Single-Echo
                dicm2nii(Fun_sub_Path, Funsub_out_Path, 0);
                [reorient_index, outputname, perm, flipDims] = ...
                    reorient_img(Funsub_out_Path, T1w_Template_path, flip_flag, []);
                [z_lower, z_upper] = robustfov_matlab(outputname, [], brain_size, perm, flipDims);
                [path, name, ext] = fileparts(outputname);
                co_output_nii = fullfile(path, ['co' name ext]);
                
                raw_mat = spm_vol(co_output_nii);
                originAlignmentPrompt(co_output_nii, T1w_Template_path);
                ref_mat = spm_vol(co_output_nii);
                MAT = ref_mat(1).mat(1:3,4) - raw_mat(1).mat(1:3,4);
                Origin_transform_matrix = [eye(3) MAT; 0 0 0 1];
                
                keepCoNiiAndJson(Funsub_out_Path);
            end
            
            % Store single session data
            if ~isempty(reorient_index) && ~isempty(Origin_transform_matrix)
                reorient_index_subj{1} = reorient_index;
                z_lower_subj{1} = z_lower;
                z_upper_subj{1} = z_upper;
                Origin_transform_matrix_subj{1} = Origin_transform_matrix;
            else
                reorient_index_subj{1} = [];
                z_lower_subj{1} = [];
                z_upper_subj{1} = [];
                Origin_transform_matrix_subj{1} = [];
                warning('Subject %s: No valid parameters obtained', subj);
            end
        end
        
        % Store subject data
        reorient_index_all{i} = reorient_index_subj;
        z_lower_all{i} = z_lower_subj;
        z_upper_all{i} = z_upper_subj;
        Origin_transform_matrix_all{i} = Origin_transform_matrix_subj;

    catch main_err
        errors_Fun{i} = sprintf('Main processing error for subject %s: %s', subj, main_err.message);
        % Store empty values for error cases
        reorient_index_all{i} = [];
        z_lower_all{i} = [];
        z_upper_all{i} = [];
        Origin_transform_matrix_all{i} = [];
    end
end

% Report functional errors
fprintf('\n=== Functional DICOM to NIfTI Conversion INFO ===\n');
any_Fun_errors = false;
for i = 1:length(errors_Fun)
    if ~isempty(errors_Fun{i})
        fprintf('Subject %s: %s\n', SubfodrList{i}, errors_Fun{i});
        any_Fun_errors = true;
    end
end
if ~any_Fun_errors
    fprintf('No errors encountered during functional data conversion.\n');
end

% ===== T1 Data Processing =====
if ~isempty(T1_out_Path)
    SubfodrList_T1 = dir_NameList(T1Path);
    errors_T1 = cell(length(SubfodrList_T1), 1);

    fprintf('\n=== Starting T1 DICOM to NIfTI Conversion ===\n');
    for i = 1:length(SubfodrList_T1)
        subj = SubfodrList_T1{i};
        try
            T1_sub_Path = [T1Path filesep subj];
            T1sub_out_Path = [T1_out_Path filesep subj];

            if ~exist(T1_sub_Path, 'dir')
                errors_T1{i} = sprintf('T1 source directory does not exist: %s', T1_sub_Path);
                continue;
            end
            mkdir(T1sub_out_Path);

            % Convert DICOM to NIfTI
            dicm2nii(T1_sub_Path, T1sub_out_Path, 0);

            % Reorient, crop, and manually adjust origin
            [~, outputname, perm, flipDims] = ...
                reorient_img(T1sub_out_Path, T1w_Template_path, flip_flag, []);
            [~, ~] = robustfov_matlab(outputname, [], brain_size, perm, flipDims);

            [path, name, ext] = fileparts(outputname);
            co_output_nii = fullfile(path, ['co' name ext]);
            originAlignmentPrompt(co_output_nii, T1w_Template_path);
            keepCoNiiAndJson(T1sub_out_Path);

        catch t1_err
            errors_T1{i} = sprintf('T1 processing error for subject %s: %s', subj, t1_err.message);
        end
    end

    % Report T1 errors
    fprintf('\n=== T1 DICOM to NIfTI Conversion INFO ===\n');
    any_T1_errors = false;
    for i = 1:length(errors_T1)
        if ~isempty(errors_T1{i})
            fprintf('Subject %s: %s\n', SubfodrList_T1{i}, errors_T1{i});
            any_T1_errors = true;
        end
    end
    if ~any_T1_errors
        fprintf('No errors encountered during T1 data conversion.\n');
    end
end

% ===== Update output paths in PP =====
PP.FunPath = Fun_out_Path;
PP.T1Path = T1_out_Path;

% Store nested cell arrays in PP
% Check if at least one subject has valid data
hasValidData = false;
for i = 1:length(reorient_index_all)
    if ~isempty(reorient_index_all{i}) && iscell(reorient_index_all{i})
        for j = 1:length(reorient_index_all{i})
            if ~isempty(reorient_index_all{i}{j})
                hasValidData = true;
                break;
            end
        end
    end
    if hasValidData
        break;
    end
end

if hasValidData
    PP.reorient_index = reorient_index_all;
    PP.z_lower = z_lower_all;
    PP.z_upper = z_upper_all;
    PP.Origin_transform_matrix = Origin_transform_matrix_all;
    fprintf('\nConvert DICOM to NIfTI Completed    ||    %s\n', spm('time'));
else
    fprintf('Error occurred during bold format conversion - no valid data found.\n');
    return;
end

% -------------------------------------------------------------------------
% Nested function: common multi-echo processing
% -------------------------------------------------------------------------
    function [reorient_index, z_lower, z_upper, Origin_transform_matrix] = ...
            process_multi_echo(source_dir, target_dir, ref_echo_num)
        % source_dir : directory containing Echo1, Echo2, ... (e.g. Fun_sess_Path)
        % target_dir : output directory for this session (e.g. Funsess_out_Path)
        % ref_echo_num : reference echo number for parameter extraction

        % Initialize return values
        reorient_index = [];
        z_lower = 0;
        z_upper = 0;
        Origin_transform_matrix = [];
        ref_echo_processed = false;

        % First, check if reference echo exists
        ref_echo_in = [source_dir filesep 'Echo' num2str(ref_echo_num)];
        if ~exist(ref_echo_in, 'dir')
            warning('Reference echo directory does not exist: %s. Using echo 1 instead.', ref_echo_in);
            ref_echo_num = 1;
        end

        % Process all echoes
        for echo = 1:Enum
            echo_in = [source_dir filesep 'Echo' num2str(echo)];
            if ~exist(echo_in, 'dir')
                warning('Echo directory does not exist: %s', echo_in);
                continue; 
            end
            echo_out = [target_dir filesep 'Echo' num2str(echo)];
            mkdir(echo_out);

            if echo == ref_echo_num
                % Reference echo: determine parameters
                dicm2nii(echo_in, echo_out, 0);
                [selectedIdx, outputname, perm, flipDims] = ...
                    reorient_img(echo_out, T1w_Template_path, flip_flag, []);
                reorient_index = selectedIdx;
                [z_lower, z_upper] = robustfov_matlab(outputname, [], brain_size, perm, flipDims);

                [path, name, ~] = fileparts(outputname);
                co_output_nii = fullfile(path, ['co' name '.nii']);
                raw_mat = spm_vol(co_output_nii);
                originAlignmentPrompt(co_output_nii, T1w_Template_path);
                          
                ref_mat = spm_vol(co_output_nii);
                MAT = ref_mat(1).mat(1:3,4) - raw_mat(1).mat(1:3,4);
                Origin_transform_matrix = [eye(3) MAT; 0 0 0 1];

                keepCoNiiAndJson(echo_out);
                ref_echo_processed = true;

            else
                % Other echoes: reuse reference echo parameters
                % Make sure reference echo has been processed
                if ~ref_echo_processed
                    error('Reference echo %d must be processed before other echoes.', ref_echo_num);
                end
                
                dicm2nii(echo_in, echo_out, 0);
                [~, outputname, perm, flipDims] = ...
                    reorient_img(echo_out, T1w_Template_path, flip_flag, reorient_index);
                [~, ~] = robustfov_matlab(outputname, [], brain_size, perm, flipDims, ...
                    z_lower, z_upper);

                [path, name, ~] = fileparts(outputname);
                co_output_nii = fullfile(path, ['co' name '.nii']);
                applyReorientMatrixCorrected(Origin_transform_matrix, co_output_nii);

                keepCoNiiAndJson(echo_out);
            end
        end
        
        % Check if reference echo was processed
        if ~ref_echo_processed
            error('Reference echo %d not found in: %s', ref_echo_num, source_dir);
        end
    end
end