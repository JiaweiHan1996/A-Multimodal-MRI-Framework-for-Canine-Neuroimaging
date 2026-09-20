function fieldmap_dcm2nii(FieldmapPath, PP)
% ========== FieldMap dcm2nii ==========
% Input:
%   FieldmapPath - root directory containing fieldmap DICOM subfolders
%   PP - parameter structure containing reorient_index, z_lower, z_upper, 
%        Origin_transform_matrix for each subject and session

Mag1Raw_Path = [FieldmapPath filesep 'Magnitude1Raw'];
Mag2Raw_Path = [FieldmapPath filesep 'Magnitude2Raw'];
PDRaw_Path = [FieldmapPath filesep 'PhaseDiffRaw'];

% Remove existing output directories if they exist
if exist([Mag1Raw_Path 'H'], 'dir')
    rmdir([Mag1Raw_Path 'H'], 's');
end
if exist([Mag2Raw_Path 'H'], 'dir')
    rmdir([Mag2Raw_Path 'H'], 's');
end
if exist([PDRaw_Path 'H'], 'dir')
    rmdir([PDRaw_Path 'H'], 's');
end

% Process each fieldmap type
[Mag1ImgH_Path] = FM_dcm2nii(Mag1Raw_Path, PP);
[Mag2ImgH_Path] = FM_dcm2nii(Mag2Raw_Path, PP);
[PDImgH_Path] = FM_dcm2nii(PDRaw_Path, PP);

end

function [RawH_Path] = FM_dcm2nii(raw_path, PP)

[FilePath, f, ~] = fileparts(raw_path);
out_dir_name = [f 'H'];

% Check if raw_path is empty or just whitespace
if ~isempty(raw_path) && ~all(isspace(raw_path))
    mkdir([FilePath filesep out_dir_name]);
    
    SubfodrList = dir_NameList(raw_path);
    
    % Check if PP contains required fields
    if ~isfield(PP, 'reorient_index') || ~isfield(PP, 'z_lower') || ...
       ~isfield(PP, 'z_upper') || ~isfield(PP, 'Origin_transform_matrix')
        warning('PP does not contain required parameter fields. Using default processing.');
        use_default_params = true;
    else
        use_default_params = false;
        % Get the list of subjects from FunPath to map indices
        if isfield(PP, 'FunPath')
            FunPath = PP.FunPath;
            FunSubfodrList = dir_NameList(FunPath);
        else
            warning('PP.FunPath not found. Using raw_path subject list for mapping.');
            FunSubfodrList = SubfodrList;
        end
    end
    
    for i = 1:length(SubfodrList)
        subj = SubfodrList{i};
        sub_path = [raw_path filesep subj];
        Raw_out_Path = [FilePath filesep out_dir_name filesep subj];
        mkdir(Raw_out_Path);
        
        % Convert DICOM to NIfTI
        dicm2nii(sub_path, Raw_out_Path, 0);
        
        % Get subject-specific parameters if available
        if ~use_default_params
            % Find the index of this subject in the functional data list
            subj_idx = find(strcmp(FunSubfodrList, subj), 1);
            
            if isempty(subj_idx)
                warning('Subject %s not found in functional data. Using first subject''s parameters.', subj);
                subj_idx = 1;
            end
            
            % Extract parameters for this subject
            % For fieldmap, use the first session (session 1) by default
            % If you want to specify a different session, add a parameter
            session_num = 1;
            [reorient_idx, z_lower, z_upper, origin_matrix] = ...
                get_subject_params(PP, subj_idx, session_num);
        else
            % Use empty/default parameters
            reorient_idx = [];
            z_lower = [];
            z_upper = [];
            origin_matrix = [];
        end
        
        % Apply reorientation
        if ~isempty(reorient_idx)
            [~, outputname, perm, flipDims] = ...
                reorient_img(Raw_out_Path, PP.Config_INFO.Template, PP.Flip_LR, reorient_idx);
        else
            % Use default reorientation (no pre-specified index)
            [~, outputname, perm, flipDims] = ...
                reorient_img(Raw_out_Path, PP.Config_INFO.Template, PP.Flip_LR, []);
        end
        
        % Apply robust FOV cropping
        if ~isempty(z_lower) && ~isempty(z_upper)
            [~, ~] = robustfov_matlab(outputname, [], PP.Step_H.Brain_Size_mm, perm, flipDims, ...
                z_lower, z_upper);
        else
            % Use default robustfov if no parameters available
            [~, ~] = robustfov_matlab(outputname, [], PP.Step_H.Brain_Size_mm, perm, flipDims);
        end
        
        % Apply origin transformation matrix
        [path, name, ~] = fileparts(outputname);
        co_output_nii = fullfile(path, ['co' name '.nii']);
        if ~isempty(origin_matrix)
            applyReorientMatrixCorrected(origin_matrix, co_output_nii);
        end
        
        % Keep only coregistered NIfTI and JSON files
        keepCoNiiAndJson(Raw_out_Path);        
    end
    
    RawH_Path = [FilePath filesep out_dir_name];
else
    RawH_Path = '';
end

end

function [reorient_idx, z_lower, z_upper, origin_matrix] = get_subject_params(PP, subj_idx, session_num)
% Get parameters for a specific subject and session
% Input:
%   PP - structure containing parameter arrays
%   subj_idx - index of the subject
%   session_num - session number (optional, default: 1)
%
% Output:
%   reorient_idx - reorientation index (empty if not found)
%   z_lower - lower z bound (empty if not found)
%   z_upper - upper z bound (empty if not found)
%   origin_matrix - origin transformation matrix (empty if not found)

if nargin < 3
    session_num = 1;
end

% Initialize outputs as empty
reorient_idx = [];
z_lower = [];
z_upper = [];
origin_matrix = [];

% Check if PP contains required fields
if ~isfield(PP, 'reorient_index') || ~isfield(PP, 'z_lower') || ...
   ~isfield(PP, 'z_upper') || ~isfield(PP, 'Origin_transform_matrix')
    warning('PP does not contain required parameter fields.');
    return;
end

% Check if subject index is valid
if subj_idx < 1 || subj_idx > length(PP.reorient_index)
    warning('Subject index %d is out of range (1-%d).', subj_idx, length(PP.reorient_index));
    return;
end

% Get parameters for this subject
try
    % Check if we have multi-session data
    if iscell(PP.reorient_index{subj_idx})
        % Multi-session case
        num_sessions = length(PP.reorient_index{subj_idx});
        
        % Check if requested session exists and has data
        if session_num <= num_sessions && ...
           ~isempty(PP.reorient_index{subj_idx}{session_num})
            % Use specified session
            reorient_idx = PP.reorient_index{subj_idx}{session_num};
            z_lower = PP.z_lower{subj_idx}{session_num};
            z_upper = PP.z_upper{subj_idx}{session_num};
            origin_matrix = PP.Origin_transform_matrix{subj_idx}{session_num};
        else
            % Try to find any non-empty session
            found = false;
            for s = 1:num_sessions
                if ~isempty(PP.reorient_index{subj_idx}{s})
                    reorient_idx = PP.reorient_index{subj_idx}{s};
                    z_lower = PP.z_lower{subj_idx}{s};
                    z_upper = PP.z_upper{subj_idx}{s};
                    origin_matrix = PP.Origin_transform_matrix{subj_idx}{s};
                    found = true;
                    warning('Session %d not found or empty for subject %d. Using session %d instead.', ...
                        session_num, subj_idx, s);
                    break;
                end
            end
            if ~found
                warning('No valid parameters found for subject %d across all sessions.', subj_idx);
            end
        end
    else
        % Single-session case
        if ~isempty(PP.reorient_index{subj_idx})
            reorient_idx = PP.reorient_index{subj_idx};
            z_lower = PP.z_lower{subj_idx};
            z_upper = PP.z_upper{subj_idx};
            origin_matrix = PP.Origin_transform_matrix{subj_idx};
        else
            warning('No valid parameters found for subject %d (single session).', subj_idx);
        end
    end
catch err
    warning('Error extracting parameters for subject %d: %s', subj_idx, err.message);
    % Return empty values
    reorient_idx = [];
    z_lower = [];
    z_upper = [];
    origin_matrix = [];
end

end