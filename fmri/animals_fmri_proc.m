function animals_fmri_proc
%% update: 20251028
clear; clc

% config_path
mfullPath = which('animals_fmri_proc');
[d, ~, ~] = fileparts(mfullPath);
config_path = [d filesep 'config']; clear d

% FilePath
FilePath = spm_select(1, 'dir', 'Please Select Data Folder');
if isempty(FilePath)
    fprintf('Animals_fMRI_Proc    ||    DO NOT Select Data Folder !!!\n');
    return
end

%% Log Record
try
    % Json
    [Pipe_Json_Path, ~] = spm_select(1, '^.*\.json$', 'Select the PrepPipe JSON file', ...
        {}, config_path);
    if ~ischar(Pipe_Json_Path)
        fprintf('Animals_fMRI_Proc    ||    DO NOT Select PrepPipe JSON !!!\n');
        return
    end
    if ~exist(Pipe_Json_Path, 'file')
        fprintf('Animals_fMRI_Proc    ||    PrepPipe JSON is NOT Existed !!!\n');
        return
    end
    
    %% ========== Checking ==========
    % Load & Check config
    config_list = check_and_load_config(config_path);
    if isempty(config_list); return; end
    % Check Json
    [json_flag, JSON] = check_json_standard(Pipe_Json_Path);
    if ~json_flag; return; end
    
    %% ========== Processing ==========
    cd(FilePath);
    if strcmp(JSON.Process_Type, 'Prep')
        
        logFile = fullfile(FilePath, 'PrepLog.txt');
        diary(logFile);
        diary on;
        fprintf('Animals_fMRI_Proc    ||    ======== Start Running fMRI Preprocessing ======== \n');
        % Run pre
        fMRI_Preprocessing(FilePath, config_list, Pipe_Json_Path);
		fprintf('Log saved to：%s\n', logFile);
        diary off;

    elseif strcmp(JSON.Process_Type, 'Rest')
        logFile = fullfile(FilePath, 'RestLog.txt');
        diary(logFile);
        diary on;
        fprintf('Animals_fMRI_Proc    ||    ======== Start Running fMRI Postprocessing: Rest ======== \n');
        % Run rest
        rest_flag = fMRI_Postprocessing_rest(FilePath, config_list, JSON);
        fprintf('Log saved to：%s\n', logFile);
        diary off;
        if ~rest_flag; return; end
    elseif strcmp(JSON.Process_Type, 'Task')
        logFile = fullfile(FilePath, 'TaskLog.txt');
        diary(logFile);
        diary on;
        fprintf('Animals_fMRI_Proc    ||    ======== Start Running fMRI Postprocessing: Task ======== \n');
        % Run task
        task_flag = GLM_Task_Process(FilePath, config_list, JSON);
        fprintf('Log saved to：%s\n', logFile);
        diary off;
        if ~task_flag; return; end
    elseif strcmp(JSON.Process_Type, 'Group')
        logFile = fullfile(FilePath, 'GroupLog.txt');
        diary(logFile);
        diary on;
        fprintf('Animals_fMRI_Proc    ||    ======== Start Running fMRI Postprocessing: Group ======== \n');
        % Run group
        group_flag = GLM_Group_Process(FilePath, config_list, JSON);
        fprintf('Log saved to：%s\n', logFile);
        diary off;
        if ~group_flag; return; end
    end
catch ME
        fprintf('Error：%s\n', ME.message);
        diary off;
end

end


%%
function [json_flag, JSON] = check_json_standard(json_path)
json_flag = false;
% ============================
try 
    jstr = fileread(json_path);
    jstr = strrep(jstr, '\', '\\');
	JSON = jsondecode(jstr); clear jstr
   % NO 'Process_Type'
   if ~isfield(JSON, 'Process_Type')
        fprintf('\nJson Check    |    NO "Process_Type" in Json File !!!\n');
        return
    end
   
catch ME
    fprintf('JSON format error:\n');
    fprintf('   Error message: %s\n', ME.message);
    
    if contains(ME.message, 'position')
        errorDetail = regexp(ME.message, 'position\s*(\d+)', 'tokens', 'once');
        if ~isempty(errorDetail)
            errorPos = str2double(errorDetail{1});
            fprintf('   Possible error character position: %d\n', errorPos);
            
            lines = strsplit(jsonText, '\n');
            charCount = 0;
            for i = 1:length(lines)
                lineLength = length(lines{i}) + 1; % +1 for newline
                if charCount + lineLength >= errorPos
                    fprintf('   Possible location at line: %d, column: %d\n', i, errorPos - charCount);
                    break;
                end
                charCount = charCount + lineLength;
            end
        end
    end
    return;
end

% ============================
json_flag = true;
end