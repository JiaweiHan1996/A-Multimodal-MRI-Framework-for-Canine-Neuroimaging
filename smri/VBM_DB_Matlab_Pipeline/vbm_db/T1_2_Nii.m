function [T1_out_Path] = T1_2_Nii(T1Path, T1w_Template_path, brain_size, flip_flag)
% ===== Prepare output directories =====
if ~isempty(T1Path)
    [FilePath, f_t1, ~] = fileparts(T1Path);
    out_dir_name_T1 = [f_t1 'H'];
    T1_out_Path = [FilePath filesep out_dir_name_T1];
    if exist(T1_out_Path, 'dir')
        rmdir(T1_out_Path, 's');
    end
    mkdir(T1_out_Path);
else
    T1_out_Path = '';
end

% ===== T1 Data Processing =====
if ~isempty(T1_out_Path)
    SubfodrList_T1 = dir_NameList(T1Path);
    errors_T1 = cell(length(SubfodrList_T1), 1);

    fprintf('\n=== Starting T1 DICOM to NIfTI Conversion ===\n');
    for i = 1:length(SubfodrList_T1)
        try
            subj = SubfodrList_T1{i};
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
            return;
        end
    end
    if ~any_T1_errors
        fprintf('No errors encountered during T1 data conversion.\n');
    end
end
% ====================
fprintf('T1_2_Nii is finished !!!\n');
end