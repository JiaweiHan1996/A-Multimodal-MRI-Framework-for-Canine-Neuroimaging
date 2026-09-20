function [PP_new, config_list] = generate_new_pipe(FilePath, PP, config_list)
%% update: 2025-09-30

PP_new = struct();
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

%% ========== Path ==========
FunPath = [FilePath filesep PP.Import_INFO.Start_Fun_Name];
if ~exist(FunPath, 'file')
    fprintf('\n Start_Fun_Name Folder[%s] does not exist in Input path[%s]\n', ...
        PP.Import_INFO.Start_Fun_Name, FilePath);
    return;
end

if exist(FunPath, 'dir')
    folderContent = dir(FunPath);
    numItems = numel(folderContent);
    
    if numItems <= 2
        fprintf('The folder exists, but it is empty\n');
        return;
    end
end
if ~isempty(PP.Import_INFO.Start_T1_Name) 
    T1Path = [FilePath filesep PP.Import_INFO.Start_T1_Name];
    if ~exist(T1Path, 'dir') 
        T1Path = ''; 
        fprintf('\n Start_T1_Name[%s] does not exist in Input path[%s]\n', PP.Import_INFO.Start_T1_Name, FilePath);
    else
        if exist(T1Path, 'dir')
            folderContent = dir(T1Path);
            numItems = numel(folderContent);
            if numItems <= 2
                fprintf('The folder [%s] exists, but it is empty\n', T1Path);
                return;
            end
        end
    end
else
    fprintf('\n Start_T1_Name is empty.\n');
    T1Path = '';
end
FieldmapPath = [FilePath filesep 'FieldMap'];
if ~exist(FieldmapPath, 'dir'); FieldmapPath = ''; end
RefRawPath = [FilePath filesep 'RefRaw'];
if ~exist(RefRawPath, 'dir'); RefRawPath = ''; end

PP_new.Pipe_Json_Path = PP.Pipe_Json_Path;
PP_new.FunPath = FunPath;
PP_new.T1Path = T1Path;
PP_new.FieldmapPath = FieldmapPath;
PP_new.RefRawPath = RefRawPath;

RP_Path = [FilePath filesep 'RealignParameter'];
if exist(RP_Path, 'dir') || isfield(PP.Process_INFO, 'Step_R') || isfield(PP.Process_INFO, 'Step_Cb')
    PP_new.RP_Path = RP_Path;
end

QC_Path = [FilePath filesep 'QC'];
if exist(QC_Path, 'dir') || isfield(PP.Process_INFO, 'Step_QC')
    PP_new.QC_Path = QC_Path;
end

CP_Path = [FilePath filesep 'CovariatesParameter'];
if exist(CP_Path, 'dir')  || isfield(PP.Process_INFO, 'Step_C')
    PP_new.CP_Path = CP_Path;
end

%% ========== Config_INFO ==========
PP_new.Config_INFO.Template = PP.Config_INFO.Template;
config_list.template.Template = PP.Config_INFO.Template;
if isfield(PP.Process_INFO, 'Step_W') || isfield(PP.Process_INFO, 'Step_C') || isfield(PP.Process_INFO, 'Step_QC')
    PP_new.Config_INFO.TPM = PP.Config_INFO.TPM;
    PP_new.Config_INFO.Mask = PP.Config_INFO.Mask;
end



%% ========== Number ==========
Nums = {'Snum', 'Enum', 'RefEcho'};
for k = 1:length(Nums)
    if isfield(PP.Data_INFO, Nums{k})
        s = ['PP_new.' Nums{k} ' = PP.Data_INFO.' Nums{k} ';'];
        eval(s); clear s
    else
        s = ['PP_new.' Nums{k} ' = 1;'];
        eval(s); clear s
    end
end; clear k

%% ========== TR ==========
if isfield(PP.Data_INFO, 'TR')
    PP_new.TR = PP.Data_INFO.TR;
else
    PP_new.TR = [];
end

%% ========== Flip_LR ==========
if isfield(PP.Data_INFO, 'Flip_LR')
    PP_new.Flip_LR = PP.Data_INFO.Flip_LR;
else
    PP_new.Flip_LR = 0;
end

%% ========== EffectiveEchoSpacing ==========
if isfield(PP.Data_INFO, 'EffectiveEchoSpacing')
    PP_new.EffectiveEchoSpacing = PP.Data_INFO.EffectiveEchoSpacing;
else
    PP_new.EffectiveEchoSpacing = [];
end

%% ========== Steps ==========
PP_new.IsOld_Segment = PP.IsOld_Segment;
PP_new.Total_Step_Num = PP.Total_Step_Num;
fieldNames = fieldnames(PP.Process_INFO);
for i = 1:PP.Total_Step_Num
    % ===== Copy Step Name =====
    s = ['PP_new.' fieldNames{i} '.Name = PP.Process_INFO.' fieldNames{i} '.Name;'];
    eval(s); clear s
    
    % ===== Copy Other Parameters =====
    curr_step = PP.Process_INFO.(fieldNames{i});
    FieldNames = fieldnames(curr_step);
    
    % ---------- DCM2NII ----------
    if strcmp(curr_step.Name, 'DICOM_2_Nii')
        if contains('Brain_Size_mm', FieldNames)
            s = ['PP_new.' fieldNames{i} '.Brain_Size_mm = PP.Process_INFO.' fieldNames{i} '.Brain_Size_mm;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.Brain_Size_mm = 140;'];            % 不定义则默认为140mm
            eval(s); clear s
        end
    end
    
    % ---------- Remove_First_n_Timepoints ----------
    if strcmp(curr_step.Name, 'Remove_First_n_Timepoints')
        if contains('Del_Tps', FieldNames)
            s = ['PP_new.' fieldNames{i} '.Del_Tps = PP.Process_INFO.' fieldNames{i} '.Del_Tps;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.Del_Tps = 0;'];            % 不定义则不删除时间点
            eval(s); clear s
        end
    end
    
    % ---------- Slice_Timing ----------
    if strcmp(curr_step.Name, 'Slice_Timing')
        if contains('Slice_Order', FieldNames)
            s = ['PP_new.' fieldNames{i} '.Slice_Order = PP.Process_INFO.' fieldNames{i} '.Slice_Order;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.Slice_Order = [];'];            % 不定义则为空
            eval(s); clear s
        end
        if contains('Ref_Slice', FieldNames)
            s = ['PP_new.' fieldNames{i} '.Ref_Slice = PP.Process_INFO.' fieldNames{i} '.Ref_Slice;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.Ref_Slice = [];'];            % 不定义则为空
            eval(s); clear s
        end
    end

    % ---------- ME_Combine ----------
    if strcmp(curr_step.Name, 'ME_Combine')
        if contains('OnlyOptcom', FieldNames)
            s = ['PP_new.' fieldNames{i} '.OnlyOptcom = PP.Process_INFO.' fieldNames{i} '.OnlyOptcom;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.OnlyOptcom = 1;'];            % 不定义则为1
            eval(s); clear s
        end
    end

    
    % ---------- Normalize ----------
    if strcmp(curr_step.Name, 'Normalize')

        if contains('ResVoxelSize', FieldNames)
            s = ['PP_new.' fieldNames{i} '.ResVoxelSize = PP.Process_INFO.' fieldNames{i} '.ResVoxelSize;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.ResVoxelSize = [];'];            % 不定义则为[]
            eval(s); clear s
        end

        if contains('IsDARTEL', FieldNames)
            s = ['PP_new.' fieldNames{i} '.IsDARTEL = PP.Process_INFO.' fieldNames{i} '.IsDARTEL;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.IsDARTEL = 0;'];            % 不定义则不做DARTEL
            eval(s); clear s
        end
        % -----
        if contains('IsT1_BET', FieldNames)
            s = ['PP_new.' fieldNames{i} '.IsT1_BET = PP.Process_INFO.' fieldNames{i} '.IsT1_BET;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.IsT1_BET = 0;'];            % 不定义则不剥头皮
            eval(s); clear s
        end
    end
    
    % ---------- Smooth ----------
    if strcmp(curr_step.Name, 'Smooth')
        if contains('FWHM', FieldNames)
            s = ['PP_new.' fieldNames{i} '.FWHM = PP.Process_INFO.' fieldNames{i} '.FWHM;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.FWHM = [3, 3, 3];'];            % 不定义则为[3, 3, 3]
            eval(s); clear s
        end
    end
    
    % ---------- Covs_Regressing ----------
    if strcmp(curr_step.Name, 'Covs_Regressing')
        if contains("IsWholeBrain", FieldNames)
            s = ['PP_new.' fieldNames{i} '.IsWholeBrain = PP.Process_INFO.' fieldNames{i} '.IsWholeBrain;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.IsWholeBrain = 0;'];            % 不定义则不回归全脑信号
            eval(s); clear s
        end
        
        if contains("IsCSF", FieldNames)
            s = ['PP_new.' fieldNames{i} '.IsCSF = PP.Process_INFO.' fieldNames{i} '.IsCSF;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.IsCSF = 1;'];                        % 不定义则回归CSF信号
            eval(s); clear s
        end
        
        if contains("IsWhiteMatter", FieldNames)
            s = ['PP_new.' fieldNames{i} '.IsWhiteMatter = PP.Process_INFO.' fieldNames{i} '.IsWhiteMatter;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.IsWhiteMatter = 1;'];            % 不定义则回归WM信号
            eval(s); clear s
        end
        
        if contains("IsHeadMotion", FieldNames)
            s = ['PP_new.' fieldNames{i} '.IsHeadMotion = PP.Process_INFO.' fieldNames{i} '.IsHeadMotion;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.IsHeadMotion = 1;'];            % 不定义则回归6头动参数
            eval(s); clear s
        end

        if contains("AddMean", FieldNames)
            s = ['PP_new.' fieldNames{i} '.AddMean = PP.Process_INFO.' fieldNames{i} '.AddMean;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.AddMean = 1;'];            % 不定义则默认加均值
            eval(s); clear s
        end
    end
    
    % ---------- Filter ----------
    if strcmp(curr_step.Name, 'Filter')
        if contains('Band', FieldNames)
            s = ['PP_new.' fieldNames{i} '.Band = PP.Process_INFO.' fieldNames{i} '.Band;'];
            eval(s); clear s
        else
            s = ['PP_new.' fieldNames{i} '.Band = [0.01, 0.1];'];            % 不定义则为[0.01, 0.08]
            eval(s); clear s
        end
    end

    clear curr_step FieldNames
end

end