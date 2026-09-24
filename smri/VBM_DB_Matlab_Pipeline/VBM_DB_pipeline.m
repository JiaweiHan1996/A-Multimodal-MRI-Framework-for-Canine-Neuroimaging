function VBM_DB_pipeline()

%-----------------------------------------------------------------------
% VBM_DB_pipeline.m is to run VBM analysis for Beagle 
% structure MRI with DARTEL.
% Author: jiawei.han
%-----------------------------------------------------------------------
close all;
clear,clc

% ==================== Settings  ==================== %
Template_Path = 'C:\Users\BHRT_v1.0';	% Please Reset This Path
run_dc2nii = 1;
flip_flag = 0;
brain_size = 60;

% ==================== Initialization ==================== %
% --> Varbs
% TMP: template files' paths
% Ip_Dir: input data folder
% Sub_ID: subject id (subject folder name)
% vbmDir: output VBM_ folder path
% dataDir: VBM_xxxx/data path

[TMP, Sub_ID, vbmDir, dataDir] = Initialization(Template_Path, run_dc2nii, brain_size, flip_flag);

% ========== VBM ========== %
% ---------- Old Segment ---------- %
for i = 1:length(Sub_ID), T1w(i,1) = {[dataDir filesep Sub_ID{i} '.nii']}; end
clear i
VBM_db_OldSeg(T1w, TMP);
% ---------- DARTEL ---------- %
VBM_db_DARTEL(Sub_ID, dataDir, TMP);
% ---------- Smooth ---------- %
% Note: Smooth is for voxel-by-voxel statistical analysis
%		Actually, the paper did not use the smoothed data
k = 3;	% Smooth FWHM
% Smooth GM
for i = 1:length(Sub_ID)
    data(i,1) = {[dataDir filesep 'mwmwc1' Sub_ID{i} '.nii']};
end
clear i
VBM_db_Smooth(data,k);  % smooth GMD images
clear data
% Smooth WM
for i = 1:length(Sub_ID)
    data(i,1) = {[dataDir filesep 'mwmwc2', Sub_ID{i}, '.nii']};
end
clear i
VBM_db_Smooth(data,k);  % smooth WMD images
clear data
% Smooth CSF
for i = 1:length(Sub_ID)
    data(i,1) = {[dataDir filesep 'mwmwc3', Sub_ID{i}, '.nii']};
end
clear i
VBM_db_Smooth(data,k);  % smooth CSFD images
clear data

% ========== Output Results ========== %
ResultsDir = ResultsSort(vbmDir,Sub_ID);
% ---------- Volume Calculation ---------- %
Vol_Calc_gm_atlas(ResultsDir, [ResultsDir filesep 'Volumes'], Sub_ID, TMP);
Vol_Calc_wm_atlas(ResultsDir, [ResultsDir filesep 'Volumes'], Sub_ID, TMP);
Vol_Calc_lobe_atlas(ResultsDir, [ResultsDir filesep 'Volumes'], Sub_ID, TMP);

fprintf('Congradulations! All steps are finished !!!\n');

end