function DataList = Datalist_sort(PP)
%% File traversal function to create DataList structure
% Input: PP - structure containing preprocessing parameters
% Output: DataList - structure with file information organized by subject/session/echo

fprintf('LOG: File traversal starting ...\n');

DataList = struct();

%% ===== Load PP Parameters =====
FunPath = PP.FunPath;
Snum = PP.Snum;
Enum = PP.Enum;

%% ===== Set DataList Root Path and Folder Name =====
[dataroot_path, FunFolder_Name, ~] = fileparts(FunPath);
DataList.dataroot_path = dataroot_path;
DataList.FunFolder_Name = FunFolder_Name;

%% ===== Initialize Lists =====
DataList.Sublist = {};
DataList.filename = {};
DataList.json_name = {};
DataList.TR = [];
DataList.TE = [];  % Add: store TE values

%% ===== Get Subject List =====
SubfodrList = dir_NameList(FunPath);

%% ===== Traverse Through All Subjects/Sessions/Echoes =====
for i = 1:length(SubfodrList)
    
    Fun_sub_Path = [FunPath filesep SubfodrList{i}];
    
    % ===== Multi-Session Processing =====
    if Snum > 1
        for sess = 1:Snum
            Fun_sess_Path = [Fun_sub_Path filesep 'S' num2str(sess)];
            
            % Check if session directory exists
            if ~exist(Fun_sess_Path, 'dir')
                continue;
            end
            
            % ===== Multi-Echo Processing =====
            if Enum > 1
                for echo = 1:Enum
                    Fun_echo_Path = [Fun_sess_Path filesep 'Echo' num2str(echo)];
                    Process_DataPath(Fun_echo_Path, SubfodrList{i}, sess, echo);
                end
            % ===== Single-Echo Processing =====
            else
                Process_DataPath(Fun_sess_Path, SubfodrList{i}, sess, []);
            end
        end
        
    % ===== Single-Session Processing =====
    else
        % ===== Multi-Echo Processing =====
        if Enum > 1
            for echo = 1:Enum
                Fun_echo_Path = [Fun_sub_Path filesep 'Echo' num2str(echo)];
                Process_DataPath(Fun_echo_Path, SubfodrList{i}, [], echo);
            end
        % ===== Single-Echo Processing =====
        else
            Process_DataPath(Fun_sub_Path, SubfodrList{i}, [], []);
        end
    end
end

% ===== Ensure Column Vectors =====
DataList.Sublist = DataList.Sublist(:);
DataList.filename = DataList.filename(:);
DataList.json_name = DataList.json_name(:);
DataList.TR = DataList.TR(:);
DataList.TE = DataList.TE(:);  % Ensure TE is column vector

fprintf('LOG: File traversal completed - Found %d data entries\n', length(DataList.Sublist));

%% Nested function to process individual data paths
    function Process_DataPath(DataPath, subject, session, echo)
        % Check if data path exists
        if ~exist(DataPath, 'dir')
            fprintf('LOG: [WARNING] Directory not found: %s\n', DataPath);
            return;
        end
        
        % Get NIfTI files
        nii_files = dir([DataPath filesep '*.nii']);
        nii_filename = '';
        if isempty(nii_files)
            fprintf('LOG: [WARNING] No NIfTI files found in: %s\n', DataPath);
        else
            % Use first NIfTI file (assuming single file per directory)
            nii_filename = nii_files(1).name;
        end
        
        % Get JSON files
        json_files = dir([DataPath filesep '*.json']);
        json_filename = '';
        if isempty(json_files)
            fprintf('LOG: [WARNING] No JSON files found in: %s\n', DataPath);
        else
            % Use first JSON file
            json_filename = json_files(1).name;
        end
        
        % Construct sublist entry
        if ~isempty(session) && ~isempty(echo)
            % Multi-session, multi-echo: sub1\S1\Echo1
            sublist_entry = [subject filesep 'S' num2str(session) filesep 'Echo' num2str(echo)];
        elseif ~isempty(session) && isempty(echo)
            % Multi-session, single-echo: sub1\S1
            sublist_entry = [subject filesep 'S' num2str(session)];
        elseif isempty(session) && ~isempty(echo)
            % Single-session, multi-echo: sub1\Echo1
            sublist_entry = [subject filesep 'Echo' num2str(echo)];
        else
            % Single-session, single-echo: sub1
            sublist_entry = subject;
        end
        
        % Get TR and TE values from JSON file
        [tr_value, te_value] = Get_TR_TE_From_JSON(DataPath);
        if isempty(tr_value)
            fprintf('LOG: [WARNING] Could not read TR from JSON in: %s\n', DataPath);
            return;
        end
        if isempty(te_value)
            fprintf('LOG: [WARNING] Could not read TE from JSON in: %s\n', DataPath);
            return;
        end
        
        % Add to DataList (as column elements)
        DataList.Sublist{end+1, 1} = sublist_entry;
        DataList.filename{end+1, 1} = nii_filename;
        DataList.json_name{end+1, 1} = json_filename;
        DataList.TR(end+1, 1) = tr_value;
        DataList.TE(end+1, 1) = te_value;
        
        fprintf('LOG: Added entry - %s : %s (TR=%.3f, TE=%.3f)\n', sublist_entry, nii_filename, tr_value, te_value);
    end

%% Helper function to extract TR and TE from JSON file
    function [tr_value, te_value] = Get_TR_TE_From_JSON(DataPath)
        tr_value = [];
        te_value = [];
        
        % Look for JSON files
        json_files = dir([DataPath filesep '*.json']);
        if isempty(json_files)
            fprintf('LOG: [WARNING] No JSON files found in: %s\n', DataPath);
            return;
        end
        
        % Use first JSON file
        json_path = [DataPath filesep json_files(1).name];
        
        try
            JSON = spm_jsonread(json_path);
            
            % Get TR value
            if isfield(JSON, 'RepetitionTime')
                tr_value = JSON.RepetitionTime;
            else
                fprintf('LOG: [WARNING] RepetitionTime field not found in: %s\n', json_path);
            end
            
            % Get TE value
            if isfield(JSON, 'EchoTime')
                te_value = JSON.EchoTime;
            else
                fprintf('LOG: [WARNING] EchoTime field not found in: %s\n', json_path);
            end
            
        catch ME
            fprintf('LOG: [ERROR] Failed to read JSON file: %s\n', json_path);
            fprintf('LOG: Error message: %s\n', ME.message);
        end
    end

end