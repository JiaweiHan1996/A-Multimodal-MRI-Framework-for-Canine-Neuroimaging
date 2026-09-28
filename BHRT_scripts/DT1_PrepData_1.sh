#!/bin/bash

# --------------- INPUT ---------------
work_dir="/home/neuro/Desktop/Beagle_High_Resolution_Template"
scr_dir="/home/neuro/Desktop/BHRT_linux_scripts"
DICOM_dir="${work_dir}/DICOM"
NII_dir="${work_dir}/Nifti"

############### MAIN ###############
# ========== Run Dicom2Nii ==========
source "${scr_dir}/subDT_dcm2nii.sh"
subDT_dcm2nii -i "${DICOM_dir}/DHC" -o "${NII_dir}/DHC"

# ========== Orientation ==========
# ---------- Fix Header & Matrix ----------
source "${scr_dir}/subDT_orient.sh"
subDT_orient -i "${NII_dir}/DHC" -ro LPI -no RIP -fo LPI -o "${NII_dir}/DHC_Ori"
# ---------- Unzip to Reorien in SPM ----------
source "${scr_dir}/subDT_gunzip.sh"
subDT_gunzip -i "${NII_dir}/DHC_Ori" -o "${NII_dir}/DHC_Orim"


###################################################
########## In SPM to Reset Origin Manually ##########
###################################################
echo "Now, Go to SPM and reset the origin manually for T1w & T2w of EACH case ..."
echo "${NII_dir}/DHC_Orim  is waiting for manually reset origin"
