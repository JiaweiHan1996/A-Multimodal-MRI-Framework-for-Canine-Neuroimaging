function PP = Realign(PP, config_list)

fprintf(['\nRealign Starting   ||    ' spm('time') '\n']);

PP = InputCommPara(PP);
if ~isempty(strtrim(PP.FieldmapPath)) && isempty(find(PP.RefEcho_Para.Total_RO_time == 0, 1)) && isempty(find(PP.RefEcho_Para.PED == 0, 1))
    % ========== Calc. VDM ==========
    [Parameters_VDM, PP] = Calc_VDM_basisPara(PP);
    matlabbatch = SpmBatch2VDM(Parameters_VDM, config_list);
    for i = 1:length(matlabbatch)
        try
            current_batch = matlabbatch(i);
            spm_jobman('run', current_batch);
        catch ME
            fprintf('Error in VDM processing for batch %d: %s\n', i, ME.message);
        end
        try
            % ---------- Clean the intermediate files and move VDM files ----------
            [RefFun_dir, file_name, ext] = fileparts(Parameters_VDM.RefFun_list{i});
            wfmag = fullfile(RefFun_dir, ['wfmag_' file_name ext]);
            if exist(wfmag, 'file')
                delete(wfmag);
            end
            u = fullfile(RefFun_dir, ['u' file_name ext]);
            if exist(u, 'file')
                delete(u);
            end
            [PD_dir, file_name, ext] = fileparts(Parameters_VDM.PD_Path{i});
            VDM_output_dir = Parameters_VDM.VDM_Path{i};
            fpm =  fullfile(PD_dir, ['fpm_sc' file_name ext]);
            if exist(fpm, 'file') == 2
                delete(fpm);
            end
            sc =  fullfile(PD_dir, ['sc' file_name ext]);
            if exist(sc, 'file') == 2
                delete(sc);
            end
            
            vdm_files = fullfile(PD_dir, ['vdm5_sc' file_name ext]);
            if exist(vdm_files, 'file') == 2
                
                if PP.Snum > 1
                    
                    if PP.Enum > 1
                        [~, session_name, ~] = fileparts(fileparts(RefFun_dir));
                    else
                        [~, session_name, ~] = fileparts(RefFun_dir);
                    end
                    
                    new_vdm_name = sprintf('vdm5_sc_%s%s', session_name, ext);
                    new_vdm_path = fullfile(VDM_output_dir, new_vdm_name);
                    movefile(vdm_files, new_vdm_path);
                else
                    
                    new_vdm_name = sprintf('vdm5_sc_%s%s', 'S1', ext);
                    new_vdm_path = fullfile(VDM_output_dir, new_vdm_name);
                    movefile(vdm_files, new_vdm_path);
                end
            end
            
        catch ME
            fprintf('\n[warning] VDM processing for clean files %d: %s\n', i, ME.message);
        end
    end

    clear matlabbatch fpm sc u wfmag
    Parameters_Realign = Realign_basisPara(PP, Parameters_VDM);
    matlabbatch = SpmBatch2VDM_apply(Parameters_Realign.refscans_list, Parameters_Realign.VDM_list);
    parfor i = 1:length(matlabbatch)
        try
            current_batch = matlabbatch(i);
            spm_jobman('run', current_batch);
        catch ME
            fprintf('Error in VDM processing for batch %d: %s\n', i, ME.message);
        end
    end
    for i = 1:length(Parameters_Realign.refscans_list)
        try
            % ---------- Clean the intermediate files and move VDM files ----------
            [RefFun_dir, file_name, ext] = fileparts(Parameters_Realign.refscans_list{i});
            u = fullfile(RefFun_dir, ['u' file_name ext]);
            if exist(u, 'file') == 2
                movefile(u, Parameters_Realign.refscans_list{i});
            end
        catch ME
            fprintf('\n[warning] VDM applying for clean files %d: %s\n', i, ME.message);
        end
    end
    clear matlabbatch u
    if ~isempty(Parameters_Realign.nonrefscans_list)
        matlabbatch = SpmBatch2VDM_apply(Parameters_Realign.nonrefscans_list, Parameters_Realign.NonRef_VDM_list);
        parfor i = 1:length(matlabbatch)
            try
                current_batch = matlabbatch(i);
                spm_jobman('run', current_batch);
            catch ME
                fprintf('Error in VDM processing for batch %d: %s\n', i, ME.message);
            end
        end
        for i = 1:length(Parameters_Realign.nonrefscans_list)
            try
                % ---------- Clean the intermediate files and move VDM files ----------
                [RefFun_dir, file_name, ext] = fileparts(Parameters_Realign.nonrefscans_list{i});
                u = fullfile(RefFun_dir, ['u' file_name ext]);
                if exist(u, 'file') == 2
                    movefile(u, Parameters_Realign.nonrefscans_list{i});
                end
            catch ME
                fprintf('\n[warning] VDM applying for clean files %d: %s\n', i, ME.message);
            end
        end
        clear matlabbatch u
    end
    matlabbatch = SpmBatch2Realign(Parameters_Realign, config_list);
    
else
    fprintf('[Warning] Fieldmap correction was not applied. Please check according to the prompts:\n');
    fprintf('1. Fieldmap folder does not exist\n');
    fprintf('2. TotalReadoutTime or PhaseEncodingDirection does not exist in the JSON of BOLD data\n');
    fprintf('If you are sure that fieldmap correction is not needed, please ignore this [Warning].\n');
    Parameters_Realign = Realign_basisPara(PP);
    matlabbatch = SpmBatch2Realign(Parameters_Realign, config_list);
end

% Realign for Reference Echo Fun Image
parfor i = 1:length(matlabbatch)
    try
        fprintf('\nProcessing Reference Echo: %s\n', Parameters_Realign.refscans_list{i});
        current_batch = matlabbatch(i);
        spm_jobman('run', current_batch);
    catch ME
        fprintf('\n[ERROR] Failed to process reference echo %s: %s\n', Parameters_Realign.refscans_list{i}, ME.message);
    end
    if isempty(Parameters_Realign.nonrefscans_list)
        if exist(Parameters_Realign.refscans_list{i}, 'file')
            delete(Parameters_Realign.refscans_list{i});
        end
    end
end
clear matlabbatch

if ~isempty(Parameters_Realign.nonrefscans_list)
    
    PP = getSpaceForNonRef(PP);
    matlabbatch = SpmBatch2RealignApplyWrite(Parameters_Realign);
    for i = 1:length(Parameters_Realign.nonrefscans_list)
        try
            current_batch = matlabbatch(i);
            spm_jobman('run', current_batch);
            [dir, file_name, ~] = fileparts(Parameters_Realign.nonrefscans_list{i});
            if exist(Parameters_Realign.nonrefscans_list{i}, 'file')
                delete(Parameters_Realign.nonrefscans_list{i});
            end
            matpath = fullfile(dir, [file_name '.mat']);
            if exist(matpath, 'file')
                delete(matpath);
            end
        catch ME
            fprintf('\n[ERROR] Failed to process non-reference echo %s: %s\n', Parameters_Realign.nonrefscans_list{i}, ME.message);
        end
    end
end



PP = OutputCommPara(PP);
fprintf(['\nRealign Completed   ||    ' spm('time') '\n']);
end


function PP = InputCommPara(PP)

DataList = PP.DataList;
[d, f, ~] = fileparts(PP.FunPath);
FilePath = d;
out_dir_name_Fun = [f 'R'];
Fun_out_Path = [FilePath filesep out_dir_name_Fun];
if exist(Fun_out_Path, 'dir')
    rmdir(Fun_out_Path, 's');
end
mkdir(Fun_out_Path);
% Copy process data and get scans list
[status, message] = copyfile(PP.FunPath, Fun_out_Path);
if status
    fprintf('\nSuccessfully copied all files from %s to %s\n', PP.FunPath, Fun_out_Path);
else
    fprintf('\n[ERROR] Copy failed: %s\n', message);
end
DataList.FunFolder_Name = out_dir_name_Fun;

% Update PP
PP.DataList = DataList;
PP.FunPath = Fun_out_Path;
% Get Reference Fun Image Information
RefEcho_Para = RefEcho_Para_sort(PP);
PP.RefEcho_Para = RefEcho_Para;
end

function PP = OutputCommPara(PP)
%% Post-processing common parameters after realignment
% Update filenames and other parameters after realign

DataList = PP.DataList;

% ===== Update filename in DataList by adding 'r' prefix =====
for i = 1:length(DataList.filename)
    if ischar(DataList.filename{i}) && ~isempty(DataList.filename{i})
        DataList.filename{i} = ['r' DataList.filename{i}];
    end
end

% ===== Update RefEcho_Para paths if needed =====
if isfield(PP, 'RefEcho_Para') && isfield(PP.RefEcho_Para, 'RefFun_list')
    for i = 1:length(PP.RefEcho_Para.RefFun_list)
        [path, name, ext] = fileparts(PP.RefEcho_Para.RefFun_list{i});
        PP.RefEcho_Para.RefFun_list{i} = fullfile(path, ['r' name ext]);
    end
end

if isfield(PP, 'RefEcho_Para') && isfield(PP.RefEcho_Para, 'NonRefFun_list')
    for i = 1:length(PP.RefEcho_Para.NonRefFun_list)
        if ~isempty(PP.RefEcho_Para.NonRefFun_list{i})
            [path, name, ext] = fileparts(PP.RefEcho_Para.NonRefFun_list{i});
            PP.RefEcho_Para.NonRefFun_list{i} = fullfile(path, ['r' name ext]);
        end
    end
end

DataList.FunFolder_Name = PP.DataList.FunFolder_Name; 

% Update PP structure
PP.DataList = DataList;

end


function Parameters = Realign_basisPara(PP, varargin)
%% Create Parameters for SpmBatch2RealignUnwarp
% Input:
%   PP - structure containing preprocessing parameters
%       PP.Enum - number of echoes (e.g., 3 for multi-echo)
%       PP.RefEcho_Para.RefFun_list - reference echo files
%       PP.RefEcho_Para.NonRefFun_list - non-reference echo files
%   Parameters_VDM - structure from Calc_VDM_basisPara
% Output:
%   Parameters - structure containing scans_list and VDM_list

if nargin > 1 && ~isempty(varargin{1})
    Parameters_VDM = varargin{1};
else
    Parameters_VDM = struct();   
end

%% ===== Generate scans_list from RefEcho_Para =====
if isfield(PP, 'RefEcho_Para') && isfield(PP.RefEcho_Para, 'RefFun_list')
    Parameters.refscans_list = PP.RefEcho_Para.RefFun_list;
    Parameters.nonrefscans_list = PP.RefEcho_Para.NonRefFun_list;
else
    error('RefEcho_Para.RefFun_list not found in PP structure');
end

if ~isempty(strtrim(PP.FieldmapPath)) && ~isempty(Parameters_VDM)
    %% ===== Generate VDM_list for reference scans =====
    VDM_list = cell(length(Parameters_VDM.VDM_Path), 1);
    for i = 1:length(Parameters_VDM.VDM_Path)
        [RefFun_dir, ~, ext] = fileparts(Parameters.refscans_list{i});
      
     
        if PP.Snum > 1
            
            if PP.Enum > 1
                [~, session_name, ~] = fileparts(fileparts(RefFun_dir));
            else
                [~, session_name, ~] = fileparts(RefFun_dir);
            end
    
            new_vdm_name = sprintf('vdm5_sc_%s%s', session_name, ext);
            new_vdm_path = fullfile(Parameters_VDM.VDM_Path{i}, new_vdm_name);
            VDM_list{i} = new_vdm_path;
        else
            
            new_vdm_name = sprintf('vdm5_sc_%s%s', 'S1', ext);
            new_vdm_path = fullfile(Parameters_VDM.VDM_Path{i}, new_vdm_name);
            VDM_list{i} = new_vdm_path;
        end
    end
    Parameters.VDM_list = VDM_list;
    
    %% ===== Generate NonRef_VDM_list based on PP.Enum =====

    n_echoes = PP.Enum;
    
    if n_echoes > 1
       
        
        n_subjects = length(VDM_list);
        n_nonref_per_sub = n_echoes - 1;
        total_nonref = n_subjects * n_nonref_per_sub;
        
        NonRef_VDM_list = cell(total_nonref, 1);
        
        for sub_idx = 1:n_subjects
            current_vdm = VDM_list{sub_idx};
            
            start_idx = (sub_idx - 1) * n_nonref_per_sub + 1;
            end_idx = sub_idx * n_nonref_per_sub;
            
            for j = start_idx:end_idx
                NonRef_VDM_list{j} = current_vdm;
            end
        end
        
        Parameters.NonRef_VDM_list = NonRef_VDM_list;
        
    else
        Parameters.NonRef_VDM_list = {};
    end
end
end

%%
% scans_list just need the Refefence Echo Image
function matlabbatch = SpmBatch2Realign(Parameters, config_list)
for i = 1:length(Parameters.refscans_list)
    template = load(config_list.tools_and_mats.Realign);
    matlabbatch{i} = template.matlabbatch{1};
    matlabbatch{i}.spm.spatial.realign.estwrite.data = {Parameters.refscans_list(i)};
    matlabbatch{i}.spm.spatial.realign.estwrite.eoptions.rtm = 0;  % 0=Register to first | 1=Register to mean.
end

end

% function matlabbatch = SpmBatch2RealignUnwarpForRef(Parameters, config_list)
% for i = 1:length(Parameters.refscans_list)
%     template = load(config_list.tools_and_mats.RealignUnwarp);
%     matlabbatch{i} = template.matlabbatch{1};
%     matlabbatch{i}.spm.spatial.realignunwarp.data.scans = cellstr(Parameters.refscans_list{i});
%     matlabbatch{i}.spm.spatial.realignunwarp.data.pmscan = cellstr(Parameters.VDM_list{i});
%     matlabbatch{i}.spm.spatial.realignunwarp.eoptions.rtm = 0;    % 0=Register to first | 1=Register to mean.
% end
% 
% end


% Apply all Echo Images
function PP = getSpaceForNonRef(PP)

RefFun_list = PP.RefEcho_Para.RefFun_list;
NonRefFun_list = PP.RefEcho_Para.NonRefFun_list;

RefFunList = repelem(RefFun_list, PP.Enum-1, 1);

% get space matrix and transform
parfor i = 1:numel(NonRefFun_list)
    M = spm_vol(RefFunList{i});
    V = spm_vol(NonRefFun_list{i});
    fprintf('Get space: %s\n', RefFunList{i});
    
    for t = 2:length(V)
        fname_with_vol = sprintf('%s,%d', V(t).fname, t);
        spm_get_space(fname_with_vol, M(t).mat);
    end
    fprintf('Transform space: %s\n', NonRefFun_list{i});
end

for i = 1:numel(NonRefFun_list)
    if mod(i, PP.Enum-1)==0 && exist(RefFunList{i}, 'file') == 2
        delete(RefFunList{i});
        fprintf('delete: %s\n', RefFunList{i})
    end
end
end


function matlabbatch = SpmBatch2RealignApplyWrite(Parameters)

for i = 1:length(Parameters.nonrefscans_list)

    matlabbatch{i}.spm.spatial.realign.write.data = cellstr(Parameters.nonrefscans_list{i});
    matlabbatch{i}.spm.spatial.realign.write.roptions.which = [2 0];
    matlabbatch{i}.spm.spatial.realign.write.roptions.interp = 4;
    matlabbatch{i}.spm.spatial.realign.write.roptions.wrap = [0 0 0];
    matlabbatch{i}.spm.spatial.realign.write.roptions.mask = 1;
    matlabbatch{i}.spm.spatial.realign.write.roptions.prefix = 'r';
end

end


function [Parameters, PP]= Calc_VDM_basisPara(PP)
%% create Parameters for SpmBatch2VDM
% Input:
%   PP - structure containing preprocessing parameters
% Output:
%   Parameters - structure containing:
%     .RefFun_list - reference functional images absolute paths
%     .PD_Path - phase difference images absolute paths
%     .Mag1_Path - magnitude1 images absolute paths
%     .TE1 - echo time 1 values
%     .TE2 - echo time 2 values
%     .PED - phase encoding direction values
%     .Total_RO_time - total readout time values
%     .VDM_Path - VDM output directory paths
%% ===== Initialize Parameters Structure =====
Parameters = struct();
Parameters.RefFun_list = {};
Parameters.PD_Path = {};
Parameters.Mag1_Path = {};
Parameters.VDM_Path = {};
Parameters.TE1 = [];
Parameters.TE2 = [];
Parameters.PED = [];
Parameters.Total_RO_time = [];

%% dcm2nii for Fieldmap
FieldmapPath = PP.FieldmapPath;
fieldmap_dcm2nii(FieldmapPath,PP);
FieldMapDataList = FieldMapDataList_sort(PP);
RefEcho_Para = PP.RefEcho_Para;
VDMImg_Path = [FieldmapPath filesep 'VDMImg'];
if exist(VDMImg_Path, 'dir')
    rmdir(VDMImg_Path, 's');
end
mkdir(VDMImg_Path);
Parameters.VDMImg_Path = VDMImg_Path;

%% ===== Match FieldMap subjects with Functional paths =====
com_list = [];
matched_count = 0;

for i = 1:length(FieldMapDataList.FMSublist)
    fm_subject = FieldMapDataList.FMSublist{i};
   
    found_indices = [];
    for j = 1:length(RefEcho_Para.RefFun_list)
        if contains(RefEcho_Para.RefFun_list{j}, fm_subject)
            found_indices(end+1) = j;
        end
    end
    
    if ~isempty(found_indices)
        for k = 1:length(found_indices)
            com_list(end+1).fm_index = i;
            com_list(end).ref_index = found_indices(k);
            com_list(end).subject = fm_subject;
            matched_count = matched_count + 1;
            fprintf('Matched: %s -> %s\n', fm_subject, RefEcho_Para.RefFun_list{found_indices(k)});
        end
    else
        fprintf('No match found for FieldMap subject: %s\n', fm_subject);
    end
end

%% ===== Merge Data Based on com_list =====

for k = 1:length(com_list)
    fm_idx = com_list(k).fm_index;
    ref_idx = com_list(k).ref_index;
    subject = com_list(k).subject;
    
    % ===== Construct Absolute Paths for FieldMap Data =====
    % PD image path
    pd_abs_path = fullfile(FieldMapDataList.PD_Folder, subject, FieldMapDataList.pdname{fm_idx});
    
    % Mag1 image path
    mag1_abs_path = fullfile(FieldMapDataList.Mag1_Folder, subject, FieldMapDataList.mag1name{fm_idx});
    
    % ===== Create VDM output directory with same structure as PD =====
    vdm_output_dir = fullfile(VDMImg_Path, subject);
    if exist(vdm_output_dir, 'dir')
        rmdir(vdm_output_dir, 's');
    end
    mkdir(vdm_output_dir);
    
    % ===== Add to Parameters Structure =====
    Parameters.RefFun_list{end+1, 1} = RefEcho_Para.RefFun_list{ref_idx};
    Parameters.PD_Path{end+1, 1} = pd_abs_path;
    Parameters.Mag1_Path{end+1, 1} = mag1_abs_path;
    Parameters.VDM_Path{end+1, 1} = vdm_output_dir;  
    Parameters.TE1(end+1, 1) = FieldMapDataList.TE1(fm_idx);
    Parameters.TE2(end+1, 1) = FieldMapDataList.TE2(fm_idx);
    Parameters.PED(end+1, 1) = RefEcho_Para.PED(ref_idx);
    Parameters.Total_RO_time(end+1, 1) = RefEcho_Para.Total_RO_time(ref_idx);
    
    fprintf('Created VDM directory: %s\n', vdm_output_dir);
end

%% ===== Ensure Column Vectors =====
Parameters.RefFun_list = Parameters.RefFun_list(:);
Parameters.PD_Path = Parameters.PD_Path(:);
Parameters.Mag1_Path = Parameters.Mag1_Path(:);
Parameters.VDM_Path = Parameters.VDM_Path(:);
Parameters.TE1 = Parameters.TE1(:);
Parameters.TE2 = Parameters.TE2(:);
Parameters.PED = Parameters.PED(:);
Parameters.Total_RO_time = Parameters.Total_RO_time(:);

if isempty(Parameters.RefFun_list)
    warning('No data was merged! Please check if FieldMap and Functional data have corresponding entries.');
end

fprintf('\nVDM folder structure created successfully!\n');

end

function matlabbatch = SpmBatch2VDM(Parameters, config_list)

for i = 1:length(Parameters.RefFun_list)
    template = load(config_list.tools_and_mats.FieldMapCalculateVDM);
    matlabbatch{i} = template.matlabbatch{1};
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.data = [];
    %load Phase Map
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = cellstr(Parameters.PD_Path{i}); 
    % Load Mag1
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = cellstr(Parameters.Mag1_Path{i}); 
    % Load TE1, TE2  
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.et = [Parameters.TE1(i), Parameters.TE2(i)];
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.maskbrain = 0;
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.blipdir=Parameters.PED(i);
    % ---------- Write SPMJOB ----------
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.tert = Parameters.Total_RO_time(i);
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.epifm = 0;
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.ajm = 0;
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.template = {fullfile(spm('Dir'),'toolbox','FieldMap','T1.nii')};
    % ---------- Load FunImg ----------
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.session.epi = {[Parameters.RefFun_list{i}, ',1']}; 
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 1;
    matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'session';
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 0;
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.anat = '';
    matlabbatch{i}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 0;
                
end

end

function matlabbatch = SpmBatch2VDM_apply(scans_list, vdmlist)
for i = 1:length(scans_list)
    matlabbatch{i}.spm.tools.fieldmap.applyvdm.data.scans = cellstr(scans_list{i});
    matlabbatch{i}.spm.tools.fieldmap.applyvdm.data.vdmfile = cellstr(vdmlist{i});
    matlabbatch{i}.spm.tools.fieldmap.applyvdm.roptions.pedir = 2;
    matlabbatch{i}.spm.tools.fieldmap.applyvdm.roptions.which = [2 0];
    matlabbatch{i}.spm.tools.fieldmap.applyvdm.roptions.rinterp = 4;
    matlabbatch{i}.spm.tools.fieldmap.applyvdm.roptions.wrap = [0 0 0];
    matlabbatch{i}.spm.tools.fieldmap.applyvdm.roptions.mask = 1;
    matlabbatch{i}.spm.tools.fieldmap.applyvdm.roptions.prefix = 'u';
end
end
