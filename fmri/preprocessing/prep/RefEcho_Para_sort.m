function RefEcho_Para = RefEcho_Para_sort(PP)
%% Extract reference echo parameters for fieldmap calculation
% Input:
%   PP - structure containing preprocessing parameters
%   DataList - structure with file information organized by subject/session/echo
% Output:
%   RefEcho_Para - structure containing:
%     .RefFun_list - cell array of absolute paths to reference echo NIfTI files
%     .NonRefFun_list - cell array of absolute paths to non-reference echo NIfTI files
%     .PED - phase encoding direction (1 or -1) for each reference entry
%     .Total_RO_time - total readout time for each reference entry

fprintf('LOG: Extracting reference and non-reference echo parameters...\n');

%% ===== Load PP Parameters =====
DataList = PP.DataList;
Snum = PP.Snum;
Enum = PP.Enum;
RefEcho = PP.RefEcho;
FunPath = PP.FunPath;

%% ===== Initialize Output Structure =====
RefEcho_Para = struct();
RefEcho_Para.RefFun_list = {};
RefEcho_Para.NonRefFun_list = {};
RefEcho_Para.PED = [];
RefEcho_Para.Total_RO_time = [];

%% ===== Process Each Entry in DataList =====
for i = 1:length(DataList.Sublist)
    
    % Get current sublist entry
    current_sublist = DataList.Sublist{i};
    filename = DataList.filename{i};
    
    % Skip if no filename (empty entry)
    if isempty(filename)
        continue;
    end
    
    % ===== Construct absolute path to NIfTI file =====
    if Snum > 1
        % Multi-session: path is FunPath/Subject/Session/[Echo]/file.nii
        path_parts = strsplit(current_sublist, filesep);
        if Enum > 1
            % Multi-echo, multi-session: FunPath/sub/Sess/Echo/file.nii
            abs_path = fullfile(FunPath, path_parts{1}, path_parts{2}, path_parts{3}, filename);
        else
            % Single-echo, multi-session: FunPath/sub/Sess/file.nii
            abs_path = fullfile(FunPath, path_parts{1}, path_parts{2}, filename);
        end
    else
        % Single-session: path is FunPath/Subject/[Echo]/file.nii
        path_parts = strsplit(current_sublist, filesep);
        if Enum > 1
            % Multi-echo, single-session: FunPath/sub/Echo/file.nii
            abs_path = fullfile(FunPath, path_parts{1}, path_parts{2}, filename);
        else
            % Single-echo, single-session: FunPath/sub/file.nii
            abs_path = fullfile(FunPath, path_parts{1}, filename);
        end
    end
    
    % Check if file exists
    if ~exist(abs_path, 'file')
        fprintf('LOG: [WARNING] File not found: %s\n', abs_path);
        continue;
    end
    
    % ===== Determine if this entry matches the reference echo =====
    is_ref_echo = false;
    
    if Enum > 1
        % Multi-echo case: check if this entry contains the reference echo
        echo_pattern = ['Echo' num2str(RefEcho)];
        if contains(current_sublist, echo_pattern)
            is_ref_echo = true;
        end
    else
        % Single-echo case: use all entries as reference echo
        is_ref_echo = true;
    end
    
    % ===== Extract PED and Total_RO_time from JSON (only for reference echoes) =====
    if is_ref_echo
        json_path = '';
        if ~isempty(DataList.json_name{i})
            % Construct JSON path similar to NIfTI path
            if Snum > 1
                path_parts = strsplit(current_sublist, filesep);
                if Enum > 1
                    json_path = fullfile(FunPath, path_parts{1}, path_parts{2}, path_parts{3}, DataList.json_name{i});
                else
                    json_path = fullfile(FunPath, path_parts{1}, path_parts{2}, DataList.json_name{i});
                end
            else
                path_parts = strsplit(current_sublist, filesep);
                if Enum > 1
                    json_path = fullfile(FunPath, path_parts{1}, path_parts{2}, DataList.json_name{i});
                else
                    json_path = fullfile(FunPath, path_parts{1}, DataList.json_name{i});
                end
            end
        end
        
        % If JSON path not found via DataList, try to find it in the same directory as NIfTI
        if isempty(json_path) || ~exist(json_path, 'file')
            [nii_dir, ~, ~] = fileparts(abs_path);
            json_files = dir([nii_dir filesep '*.json']);
            if ~isempty(json_files)
                json_path = fullfile(nii_dir, json_files(1).name);
            else
                fprintf('LOG: [WARNING] No JSON file found for: %s\n', abs_path);
                continue;
            end
        end
        
        % Read JSON and extract parameters
        try
            JSON = spm_jsonread(json_path);
            
            % Extract Phase Encoding Direction (PED)
            if isfield(JSON, 'PhaseEncodingDirection')
                if isempty(strfind(JSON.PhaseEncodingDirection, '-'))
                    PED = 1;
                else
                    PED = -1;
                end
            else
                fprintf('LOG: [WARNING] PhaseEncodingDirection not found in: %s\n', json_path);
                return
            end
            
            % Extract Total Readout Time
            if isfield(JSON, 'TotalReadoutTime')
                Total_RO_time = JSON.TotalReadoutTime * 1000;
            else
                fprintf('LOG: [WARNING] TotalReadoutTime not found in: %s\n', json_path);
                return
            end
            
            % Only add to reference list if both PED and Total_RO_time were successfully extracted
            if ~isempty(PED) && ~isempty(Total_RO_time)
                RefEcho_Para.RefFun_list{end+1, 1} = abs_path;
                RefEcho_Para.PED(end+1, 1) = PED;
                RefEcho_Para.Total_RO_time(end+1, 1) = Total_RO_time;
                
                fprintf('LOG: Added reference echo - %s (PED=%d, Total_RO_time=%.3f)\n', ...
                    current_sublist, PED, Total_RO_time);
            else
                fprintf('LOG: [WARNING] TotalReadoutTime or PhaseEncodingDirection is empty in: %s\n', json_path);
                return
            end
            
        catch ME
            fprintf('LOG: [ERROR] Failed to read JSON file: %s\n', json_path);
            fprintf('LOG: Error message: %s\n', ME.message);
        end
    else
        % Add to non-reference list
        RefEcho_Para.NonRefFun_list{end+1, 1} = abs_path;
        fprintf('LOG: Added non-reference echo - %s\n', current_sublist);
    end
end

% ===== Ensure Column Vectors =====
RefEcho_Para.RefFun_list = RefEcho_Para.RefFun_list(:);
RefEcho_Para.NonRefFun_list = RefEcho_Para.NonRefFun_list(:);
RefEcho_Para.PED = RefEcho_Para.PED(:);
RefEcho_Para.Total_RO_time = RefEcho_Para.Total_RO_time(:);

fprintf('LOG: Parameter extraction completed - Found %d reference echoes and %d non-reference echoes\n', ...
    length(RefEcho_Para.RefFun_list), length(RefEcho_Para.NonRefFun_list));

end