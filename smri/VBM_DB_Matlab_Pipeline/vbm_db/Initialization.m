% ========== Initialization ========== %
function [TMP,Sub_ID,vbmDir,dataDir] = Initialization(TMP_Dir, run_dcm2nii, brain_size, flip_flag)
% ---------- Readme ---------- %
ss = get(0, 'ScreenSize');
text_info = {'This script is to do VBM analysis for Beagle T1w MRI.', ...
			 'Before running, please sort the DICOM data as:', ...
			 'If data is DICOM --- D:\T1Raw\dog_001\xxxxxxxx.dcm   D:\T1Raw\dog_002\xxxxxxxx.dcm   ...', ...
			 'If data is Nifti --- D:\T1RawH\dog_001\t1w.nii   D:\T1RawH\dog_002\t1w.nii   ...', ...
             'Note: make sure that SPM12 has been added into matlab path.'};
hw = 500; hh = 200;
hl = (ss(3)-hw)/2; hb = (ss(4)-hh)/2;
h = dialog('name', 'Readme', 'position', [hl, hb, hw, hh]);
uicontrol('parent', h, 'style', 'text', 'string', text_info,...
               'position', [20, 20, hw-20*2, hh-20*2], 'Horizontal', 'left', 'fontsize', 12);
uicontrol('parent', h, 'style', 'pushbutton', 'position',...
                [(hw-50)/2 20 50 20], 'string', 'Yes', 'callback', 'delete(gcbf)');
waitfor(h); clear h
clear text_info hw hh hl hb

% ---------- Template Path ---------- %
TMP.T1 = [TMP_Dir filesep 'BHRT_T1w_0.5mm.nii'];
TMP.T1_brain = [TMP_Dir filesep 'BHRT_T1w_brain_0.5mm.nii'];
TMP.GMtpm = [TMP_Dir filesep 'BHRT_TPM_GM_0.5mm.nii'];
TMP.WMtpm = [TMP_Dir filesep 'BHRT_TPM_WM_0.5mm.nii'];
TMP.CSFtpm = [TMP_Dir filesep 'BHRT_TPM_CSF_0.5mm.nii'];
TMP.brainmask = [TMP_Dir,'BHRT_BrainMask_0.5mm.nii'];
TMP.atlas_gm = [TMP_Dir filesep 'BHRT_atlas_cort+subcort_0.5mm.nii'];
TMP.atlas_gm_info = [TMP_Dir filesep 'Label_BHRT_atlas_cort+subcort.txt'];
TMP.atlas_wm = [TMP_Dir filesep 'BHRT_atlas_wm_0.5mm.nii'];
TMP.atlas_wm_info = [TMP_Dir filesep 'Label_BHRT_atlas_wm.txt'];
TMP.atlas_lobe = [TMP_Dir filesep 'BHRT_atlas_lobe_0.5mm.nii'];
TMP.atlas_lobe_info = [TMP_Dir filesep 'Label_BHRT_atlas_lobe.txt'];
% bounding box
[BB,vx] = spm_get_bbox(TMP.T1);  TMP.BB = BB;  TMP.vx = vx;
clear BB vx

% ---------- Select Data Folder ---------- %
h=msgbox('Please select MRI data folder', 'Hint', 'help'); waitfor(h); clear h
ppp = uigetdir('.\', 'Please select T1Raw or T1RawH folder');
if ppp == 0
    error('NOT select T1w data folder, script will be end...');
end
Ip_Dir = ppp; clear ppp;
DirSUB = dir(Ip_Dir); DirSUB(1:2) = [];
if isempty(DirSUB)
    error('T1w data folder is empty, script will be end...');
end
Sub_ID = dir_NameList(Ip_Dir);

% ---------- T1 DICOM to Nifti ---------- %
if run_dcm2nii
    T1_out_Path = T1_2_Nii(Ip_Dir, TMP.T1, brain_size, flip_flag);
    Ip_Dir = T1_out_Path;
end

% ---------- Generate output Folder ---------- %
[d, ~, ~] = fileparts(Ip_Dir);
vbmDir = [d filesep 'VBM_' datestr(now,30)]; mkdir(vbmDir);
clear d
% copy raw t1w nii
dataDir = [vbmDir filesep 'data'];  mkdir(dataDir);
for i = 1:length(Sub_ID)
    Sub_in_Path = [Ip_Dir filesep Sub_ID{i}];
    DirNII = dir([Sub_in_Path filesep '*.nii']);
    Sub_in_nii = [Ip_Dir filesep Sub_ID{i} filesep DirNII(1).name];
    Sub_out_nii = [dataDir filesep Sub_ID{i} '.nii'];
    
    copyfile(Sub_in_nii, Sub_out_nii);
    % -----------------------------------------------
    clear Sub_in_Path DirNII Sub_in_nii Sub_out_ni
end
clear i

end
