function FieldMapDataList = FieldMapDataList_sort(PP)
% Create FieldMap data list structure
% Input: PP - structure containing FieldmapPath and other information
% Output: FieldMapDataList - structure containing PD folder, Mag folders, subject list, filenames and TE values

    % Initialize output structure
    FieldMapDataList = struct();
    
    % 1. Set PD folder path
    FieldMapDataList.PD_Folder = [PP.FieldmapPath filesep 'PhaseDiffRawH'];
    
    % 2. Set Mag1 folder path
    FieldMapDataList.Mag1_Folder = [PP.FieldmapPath filesep 'Magnitude1RawH'];
    
    % 3. Set Mag2 folder path
    FieldMapDataList.Mag2_Folder = [PP.FieldmapPath filesep 'Magnitude2RawH'];
    
    % Check if folders exist
    if ~exist(FieldMapDataList.PD_Folder, 'dir')
        error('PD folder does not exist: %s', FieldMapDataList.PD_Folder);
    end
    if ~exist(FieldMapDataList.Mag1_Folder, 'dir')
        error('Mag1 folder does not exist: %s', FieldMapDataList.Mag1_Folder);
    end
    if ~exist(FieldMapDataList.Mag2_Folder, 'dir')
        error('Mag2 folder does not exist: %s', FieldMapDataList.Mag2_Folder);
    end
    
    % Get all subjects from PD folder
    PD_subjects = dir(FieldMapDataList.PD_Folder);
    PD_subjects = PD_subjects([PD_subjects.isdir] & ~ismember({PD_subjects.name}, {'.', '..'}));
    
    % Initialize other variables
    FieldMapDataList.FMSublist = {};
    FieldMapDataList.pdname = {};
    FieldMapDataList.mag1name = {};
    FieldMapDataList.TE1 = [];
    FieldMapDataList.TE2 = [];
    
    % Loop through each subject
    for i = 1:length(PD_subjects)
        subject_name = PD_subjects(i).name;
        
        % 4. Add subject to FMSublist
        FieldMapDataList.FMSublist{end+1} = subject_name;
        
        % Build paths for each subject
        PD_sub_Path = [FieldMapDataList.PD_Folder filesep subject_name];
        Mag1_sub_Path = [FieldMapDataList.Mag1_Folder filesep subject_name];
        Mag2_sub_Path = [FieldMapDataList.Mag2_Folder filesep subject_name];
        
        % 5. Get nii filename from PD folder
        PD_files = dir([PD_sub_Path filesep '*.nii']);
        if ~isempty(PD_files)
            FieldMapDataList.pdname{end+1} = PD_files(1).name;
        else
            FieldMapDataList.pdname{end+1} = '';
            warning('No nii file found in PD folder: %s', PD_sub_Path);
        end
        
        % 6. Get nii filename from Mag1 folder
        Mag1_files = dir([Mag1_sub_Path filesep '*.nii']);
        if ~isempty(Mag1_files)
            FieldMapDataList.mag1name{end+1} = Mag1_files(1).name;
        else
            FieldMapDataList.mag1name{end+1} = '';
            warning('No nii file found in Mag1 folder: %s', Mag1_sub_Path);
        end
        
        % 7. Get TE1 value (from Mag1 JSON file)
        Mag1_json_files = dir([Mag1_sub_Path filesep '*.json']);
        if ~isempty(Mag1_json_files)
            JSON_path = [Mag1_sub_Path filesep Mag1_json_files(1).name];
            try
                JSON = spm_jsonread(JSON_path);
                TE1_value = JSON.EchoTime * 1000; % Convert to milliseconds
                FieldMapDataList.TE1(end+1) = TE1_value;
            catch
                FieldMapDataList.TE1(end+1) = NaN;
                warning('Failed to read Mag1 JSON file or get TE1 value: %s', JSON_path);
            end
        else
            FieldMapDataList.TE1(end+1) = NaN;
            warning('No JSON file found in Mag1 folder: %s', Mag1_sub_Path);
        end
        
        % 8. Get TE2 value (from Mag2 JSON file)
        Mag2_json_files = dir([Mag2_sub_Path filesep '*.json']);
        if ~isempty(Mag2_json_files)
            JSON_path = [Mag2_sub_Path filesep Mag2_json_files(1).name];
            try
                JSON = spm_jsonread(JSON_path);
                TE2_value = JSON.EchoTime * 1000; % Convert to milliseconds
                FieldMapDataList.TE2(end+1) = TE2_value;
            catch
                FieldMapDataList.TE2(end+1) = NaN;
                warning('Failed to read Mag2 JSON file or get TE2 value: %s', JSON_path);
            end
        else
            FieldMapDataList.TE2(end+1) = NaN;
            warning('No JSON file found in Mag2 folder: %s', Mag2_sub_Path);
        end
        
        % Clear variables
        clear PD_files Mag1_files Mag1_json_files Mag2_json_files JSON TE1_value TE2_value;
    end
    
    % Convert cell arrays to more friendly format
    if isempty(FieldMapDataList.FMSublist)
        FieldMapDataList.FMSublist = {};
    end
    if isempty(FieldMapDataList.pdname)
        FieldMapDataList.pdname = {};
    end
    if isempty(FieldMapDataList.mag1name)
        FieldMapDataList.mag1name = {};
    end
    
    fprintf('\nSuccessfully created FieldMap data list, found %d subjects\n', length(FieldMapDataList.FMSublist));
end