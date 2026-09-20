function config_list = check_and_load_config(config_path)
% update: 2025-09-26

config_list = struct();
if ~exist(config_path, 'dir')
    fprintf('UIH_fMRI_Prep Error    |    config Folder is NOT Existed !!!\n');
    return
end


% %% mask
% 
folder_name = 'mask';
config_list.(folder_name).BrainMask = [config_path filesep folder_name filesep 'BrainMask.nii'];
% config_list.(folder_name).CsfMask = [config_path filesep folder_name filesep 'DOG_CSF_0.5mm.nii'];
% config_list.(folder_name).WhiteMask = [config_path filesep folder_name filesep 'DOG_WM_0.5mm.nii'];
% 
% check_config_file_existance(config_list.(folder_name)); clear folder_name
% 
% 
% %% template
% 
% folder_name = 'template';
% config_list.(folder_name).DOG_Template_atlas = [config_path filesep folder_name filesep 'DOG_Template_atlas_cort+subcort_0.5mm.nii'];
% 
% config_list.(folder_name).chnpd_asym_t1w = [config_path filesep folder_name filesep 'DOG_Template_T1w_0.5mm.nii'];
% 
% %config_list.(folder_name).TPM = [config_path filesep folder_name filesep 'TPM.nii'];
% config_list.(folder_name).TPM.GM_Path = [config_path filesep folder_name filesep 'DOG_Template_TPM_0.5mm.nii,2'];
% config_list.(folder_name).TPM.WM_Path = [config_path filesep folder_name filesep 'DOG_Template_TPM_0.5mm.nii,3'];
% config_list.(folder_name).TPM.CSF_Path = [config_path filesep folder_name filesep 'DOG_Template_TPM_0.5mm.nii,1'];
% 
% check_config_file_existance(config_list.(folder_name)); clear folder_name


%% tools_and_mats

folder_name = 'tools_and_mats';
config_list.(folder_name).bet = [config_path filesep folder_name filesep 'bet.exe'];
% config_list.(folder_name).dcm2niix = [config_path filesep folder_name filesep 'dcm2niix.exe'];
config_list.(folder_name).dcm2nii_bak = [config_path filesep folder_name filesep 'dcm2nii_bak.exe'];
config_list.(folder_name).dcm2nii_bak_ini = [config_path filesep folder_name filesep 'dcm2nii_bak.ini'];
config_list.(folder_name).deepbet_tool = [config_path filesep folder_name filesep 'deepbet_tool.exe'];
config_list.(folder_name).MECombed_command = [config_path filesep folder_name filesep 'MECombed_command.exe'];

config_list.(folder_name).FieldMapCalculateVDM = [config_path filesep folder_name filesep 'FieldMapCalculateVDM.mat'];
config_list.(folder_name).Realign = [config_path filesep folder_name filesep 'Realign.mat'];
config_list.(folder_name).Realign_res = [config_path filesep folder_name filesep 'Realign_res.mat'];
config_list.(folder_name).RealignUnwarp = [config_path filesep folder_name filesep 'RealignUnwarp.mat'];


end

%%
function check_config_file_existance(config_struct)

fnames = fieldnames(config_struct);
for n = 1:length(fnames)
    if (~strcmp(fnames{n},'TPM')) && (~exist(config_struct.(fnames{n}), 'file'))
        disp(['config File NOT Existed:    ' config_struct.(fnames{n})]);
    end
    if strcmp(fnames{n},'TPM') && (~exist(config_struct.(fnames{n}).GM_Path(1:end-2), 'file'))
        disp(['config File NOT Existed:    ' config_struct.(fnames{n}).GM_Path(1:end-2)]);
    end
end

end