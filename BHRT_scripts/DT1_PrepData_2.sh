#!/bin/bash

# --------------- INPUT ---------------
work_dir="/home/neuro/Desktop/Beagle_High_Resolution_Template"
scr_dir="/home/neuro/Desktop/BHRT_linux_scripts"
DICOM_dir="${work_dir}/DICOM"
NII_dir="${work_dir}/Nifti"

############### MAIN ###############

# ========== Native Registration ==========
echo "Note: Please make sure the data have been reset the origin ..."
source "${scr_dir}/subDT_NativeRegistration.sh"
subDT_NativeRegistration -i "${NII_dir}/DHC_Orim" -t1_suff _t1.nii -t2_suff _t2.nii -o "${NII_dir}/DHC_Orim_Reg"

# ========== DenoiseImage ==========
source "${scr_dir}/subDT_denoiseImage.sh"
subDT_denoiseImage -i "${NII_dir}/DHC_Orim_Reg" -o "${NII_dir}/DHC_Orim_Reg_Den"
