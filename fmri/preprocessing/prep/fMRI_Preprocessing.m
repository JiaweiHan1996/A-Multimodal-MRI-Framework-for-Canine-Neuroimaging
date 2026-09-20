function fMRI_Preprocessing(FilePath, config_list, Pipe_Json_Path)

%% ===== Checking =====

% json
PP = Check_Pipe_Json(Pipe_Json_Path);
if isempty(fieldnames(PP)); return; end

% Delete Folder info
Delete_info = PP.Delete_Folder_INFO;

%% ===== Generate New Pipe Var =====
PP = generate_new_pipe(FilePath, PP, config_list);
if isempty(fieldnames(PP)); return; end
% START Record
record_path = [FilePath filesep 'Animals_fMRI_Prep_Record_' datestr(now, 30) '_Start.mat'];
save(record_path, 'PP'); clear record_path

%% Do Pipe Steps
% ---- Filter out the specific steps of the processing ----
allFields  = fieldnames(PP);
keyword = 'Step_';
mask = contains(allFields , keyword);
filteredFields = allFields (mask);
PP.DataList = {};
PP.T1DataList = {};

% ---- mkdir QC path ----
FunPath = PP.FunPath;
parts = strsplit(FunPath, '\\');
Start_Fun_Name = parts{end};
[d, ~, ~] = fileparts(FunPath);
FilePath = d;
QC_Path = [FilePath filesep 'QC'];
if strcmp(Start_Fun_Name, 'FunRaw')
    if exist(QC_Path, 'dir')
        rmdir(QC_Path, 's');
    end
    mkdir(QC_Path);
else
     if ~exist(QC_Path, 'dir')
         mkdir(QC_Path);
     end
end
PP.QC_Path = QC_Path;
SubfodrList = dir_NameList(FunPath);
Snum = PP.Snum;
for i = 1:length(SubfodrList)
    Fun_sub_Path = [FunPath filesep SubfodrList{i}];
    QC_sub_Path = [QC_Path filesep SubfodrList{i}]; mkdir(QC_sub_Path);
    if Snum > 1                                                         % ===== Multi-Session =====
        for sess = 1:Snum
            Fun_sess_Path = [Fun_sub_Path filesep 'S' num2str(sess)];
            if ~exist(Fun_sess_Path, 'dir')
                clear Fun_sess_Path QC_sess_Path
                continue
            end
            QC_sess_Path = [QC_sub_Path filesep 'S' num2str(sess)]; mkdir(QC_sess_Path);
        end
    end
end
clear i d sess
% ---------------------------------------------------------
for k = 1:PP.Total_Step_Num
    curr_step = PP.(filteredFields{k + 1});
    PP.Current_Step = k;
    
    if strcmp(curr_step.Name, 'DICOM_2_Nii')
        PP = dcm_2_nii(PP);
    end
    
    % Genetate DataList structure
    if isempty(PP.DataList) 
        [~, FunFolder_Name, ~] = fileparts(PP.FunPath);
        if ~strcmp(FunFolder_Name, 'FunRaw')
            DataList = Datalist_sort(PP);
            PP.DataList = DataList;
        else
            PP.DataList = {};
            fprintf('[Warning]Please Run [DICOM_2_Nii] or modify the [Start_Fun_Name] in the json.\n');
            return
        end
    end
    
    
    if strcmp(curr_step.Name, 'Remove_First_n_Timepoints')
        if ~isempty(PP.DataList.filename)
            PP = rm_n_time_points(PP);
        else
            fprintf('Please check the log and all input!\n');
            return
        end
    end
    
    if strcmp(curr_step.Name, 'Slice_Timing')
        if ~isempty(PP.DataList.filename)
            PP = Slice_timing_correction(PP);
        else
            fprintf('Please check the log and all input!\n');
            return
        end
    end
    
    if strcmp(curr_step.Name, 'Realign')
        if ~isempty(PP.DataList.filename)
            PP = Realign(PP, config_list);      
            PP = Realign_parameter(PP);
        else
            fprintf('Please check the log and all input!\n');
            return
        end
    end
    
    if strcmp(curr_step.Name, 'ME_Combine')
        if ~isempty(PP.DataList.filename)
            PP = ME_Combination(PP);
        else
            fprintf('Please check the log and all input!\n');
            return
        end
    end
    
    if ~isempty(PP.DataList.filename)
        PP = RunSegmentation(PP, curr_step.Name);
    else
        fprintf('Please check the log and all input!\n');
        return
    end 
    
    if strcmp(curr_step.Name, 'QC')
        if ~isempty(PP.DataList.filename)
            if ~isempty(PP.T1DataList.Sublist)
                [PP.T1DataList, PP.DataList, PP.UnprocSublist] = updateToCommon(PP.T1DataList, PP.DataList);
            end
            PP = QC(PP);
        else
            fprintf('Please check the log and all input!\n');
            return
        end
    end

    if strcmp(curr_step.Name, 'Normalize')     
        if ~isempty(PP.DataList.filename)
            if ~isempty(PP.T1DataList.Sublist)
                [PP.T1DataList, PP.DataList, PP.UnprocSublist] = updateToCommon(PP.T1DataList, PP.DataList);
            end
            if curr_step.IsDARTEL == 0
                PP = Normalize(PP);
            elseif curr_step.IsDARTEL == 1
                PP = Normalize_DARTEL(PP);
            end
        else
            fprintf('Please check the log and all input!\n');
            return
        end
    end
    
    if strcmp(curr_step.Name, 'Smooth')
        if ~isempty(PP.DataList.filename)
            PP = smoothing(PP);
        else
            fprintf('Please check the log and all input!\n');
            return
        end
    end
    
    if strcmp(curr_step.Name, 'Detrend')
        if ~isempty(PP.DataList.filename)
            PP = Detrend(PP);
        else
            fprintf('Please check the log and all input!\n');
            return
        end
    end
    
    if strcmp(curr_step.Name, 'Covs_Regressing')
        if ~isempty(PP.DataList.filename)
            if ~isempty(PP.T1DataList.Sublist)
                [PP.T1DataList, PP.DataList, PP.UnprocSublist] = updateToCommon(PP.T1DataList, PP.DataList);
            end
            PP = Nu_cov_reg(PP);
        else
            fprintf('Please check the log and all input!\n');
            return
        end
    end
    
    if strcmp(curr_step.Name, 'Filter')
        if ~isempty(PP.DataList.filename)
            PP = Filter(PP);
        else
            fprintf('Please check the log and all input!\n');
            return
        end
    end
    
end; clear k

% Finished Record
record_path = [FilePath filesep 'Animals_fMRI_Prep_Record_' datestr(now, 30) '_Finish.mat'];
save(record_path, 'PP'); clear record_path

[~, Pipe_Json_Name, ~] = fileparts(Pipe_Json_Path);
fprintf(['\n' Pipe_Json_Name ' is Finished ...    ||    ' spm('time') '\n']);

% Delete folder
if ~isempty(Delete_info)
    if ~exist(FilePath, 'dir')
        error('The path does not exist: %s', path);
    end
    make_clean_results(FilePath, Delete_info);
end
end

function PP = RunSegmentation(PP, stepName)

stepName = char(stepName);

% --- 1. Obtain and validate basic path info ---
if ~isfield(PP, 'T1Path') || isempty(PP.T1Path) || strcmp(strtrim(PP.T1Path), '')
    fprintf('No T1 data available.\n');
    if ~isfield(PP, 'T1DataList') || isempty(PP.T1DataList)
        PP.T1DataList = struct(); 
    end
    return;
end
[~, T1Folder_Name, ~] = fileparts(PP.T1Path);

% --- 2. Check whether segmentation is needed (Requirement 1) ---
hasRelevantStep = isfield(PP, 'Step_QC') || isfield(PP, 'Step_W') || isfield(PP, 'Step_C'); 
startT1Name = T1Folder_Name;
isCorrectT1Source = ~isempty(startT1Name) && ~strcmp(startT1Name, 'T1RawHSeg');

shouldSegment = hasRelevantStep && isCorrectT1Source;

% --- 3. Check whether it is startup timing (Requirement 2) ---
triggerSteps = {'QC', 'Normalize', 'Covs_Regressing'};
isTriggerStep = ismember(stepName, triggerSteps);

% --- 4. Run ---
hasFunFolderH = false;
if isfield(PP, 'DataList') && isfield(PP.DataList, 'FunFolder_Name') && ~isempty(PP.DataList.FunFolder_Name)
    hasFunFolderH = contains(char(PP.DataList.FunFolder_Name), 'H');
end

if hasFunFolderH && isTriggerStep && shouldSegment
    % Check if already segmented to avoid duplication
    if ~isfield(PP, 'T1DataList') || isempty(PP.T1DataList)
        fprintf('\n--- Segment is started because of "%s" ---\n', stepName); 
        fprintf(['\nSegment Starting   ||    ' spm('time') '\n']);
        T1DataList = T1DataList_sort(PP);
        PP.T1DataList = T1DataList;
        PP.T1Path = T1DataList.T1Folder_Name;

        if ~isempty(PP.T1DataList.Sublist)
            [PP.T1DataList, PP.DataList, PP.UnprocSublist] = updateToCommon(PP.T1DataList, PP.DataList);
        end
        % --- 5. Check segmentation type (Requirement 3) ---
        if isfield(PP, 'IsOld_Segment') && PP.IsOld_Segment == 1
            fprintf(['\nOld Segment (Default MODE) Starting   ||    ' spm('time') '\n']);
            PP = Segment_default(PP);
            
        elseif isfield(PP, 'Step_W') 
            if isfield(PP.Step_W, 'IsDARTEL') && PP.Step_W.IsDARTEL == 1
                fprintf(['\nNew Segment (Dartel MODE) Starting   ||    ' spm('time') '\n']);
                PP = Segment(PP);
            else
                fprintf(['\nNew Segment (Standard MODE) Starting   ||    ' spm('time') '\n']);
                PP = Segment(PP);
            end
            
        elseif isfield(PP, 'Step_C') || isfield(PP, 'Step_QC')
            fprintf(['\nOld Segment (Default MODE) Starting   ||    ' spm('time') '\n']);
            PP = Segment_default(PP);
        end
        fprintf(['\nSegment Completed   ||    ' spm('time') '\n']);
    end
else
    if strcmp(T1Folder_Name, 'T1RawHSeg') && (~isfield(PP, 'T1DataList') || isempty(PP.T1DataList))
         PP.T1DataList = T1DataList_sort(PP);
         if ~isempty(PP.T1DataList.Sublist)
            [PP.T1DataList, PP.DataList, PP.UnprocSublist] = updateToCommon(PP.T1DataList, PP.DataList);
        end
    end
end

end


