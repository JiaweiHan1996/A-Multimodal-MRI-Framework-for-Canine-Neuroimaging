#!/bin/bash

# --------------- INPUT ---------------
work_dir="/home/neuro/Desktop/Beagle_High_Resolution_Template"
scr_dir="/home/neuro/Desktop/BHRT_linux_scripts"
template_dir="${work_dir}/BHRT_v202605"
# --------------------
T_name="BHRT"
T_Pref="${T_name}_"
T_Suff="_0.5mm.nii.gz"

# --------------- Matrix INFO ---------------
# Keep y&z axis, cut x axis for 20 slices
# Final template matrix = 220*214*120
dim1_start=20
dim1_size=220
dim2_start=0
dim2_size=214
dim3_start=0
dim3_size=120

# =============== Main ===============
if [ -d "${template_dir}/Cut" ]; then
  rm -rf "${template_dir}/Cut"
fi
mkdir -p "${template_dir}/Cut"

# ===== Cut T1w =====
fslroi "${template_dir}/${T_Pref}T1w${T_Suff}" \
	"${template_dir}/Cut/${T_Pref}T1w${T_Suff}" \
	$dim1_start $dim1_size $dim2_start $dim2_size $dim3_start $dim3_size

# ===== Cut T2w =====
fslroi "${template_dir}/${T_Pref}T2w${T_Suff}" \
	"${template_dir}/Cut/${T_Pref}T2w${T_Suff}" \
	$dim1_start $dim1_size $dim2_start $dim2_size $dim3_start $dim3_size

# ===== Cut MyelinMap =====
fslroi "${template_dir}/${T_Pref}MyelinMap${T_Suff}" \
	"${template_dir}/Cut/${T_Pref}MyelinMap${T_Suff}" \
	$dim1_start $dim1_size $dim2_start $dim2_size $dim3_start $dim3_size

# ===== Cut BrainMask & TissueSegment =====
fslroi "${template_dir}/${T_Pref}BrainMask${T_Suff}" \
	"${template_dir}/Cut/${T_Pref}BrainMask${T_Suff}" \
	$dim1_start $dim1_size $dim2_start $dim2_size $dim3_start $dim3_size

fslroi "${template_dir}/${T_Pref}TissueSegment${T_Suff}" \
	"${template_dir}/Cut/${T_Pref}TissueSegment${T_Suff}" \
	$dim1_start $dim1_size $dim2_start $dim2_size $dim3_start $dim3_size

# ===== Cut Prob =====
fslroi "${template_dir}/${T_Pref}Prob_01${T_Suff}" \
	"${template_dir}/Cut/${T_Pref}Prob_01${T_Suff}" \
	$dim1_start $dim1_size $dim2_start $dim2_size $dim3_start $dim3_size

fslroi "${template_dir}/${T_Pref}Prob_02${T_Suff}" \
	"${template_dir}/Cut/${T_Pref}Prob_02${T_Suff}" \
	$dim1_start $dim1_size $dim2_start $dim2_size $dim3_start $dim3_size

fslroi "${template_dir}/${T_Pref}Prob_03${T_Suff}" \
	"${template_dir}/Cut/${T_Pref}Prob_03${T_Suff}" \
	$dim1_start $dim1_size $dim2_start $dim2_size $dim3_start $dim3_size

# ===== Cut Atlas =====
fslroi "${template_dir}/${T_Pref}atlas_cort+subcort${T_Suff}" \
	"${template_dir}/Cut/${T_Pref}atlas_cort+subcort${T_Suff}" \
	$dim1_start $dim1_size $dim2_start $dim2_size $dim3_start $dim3_size

fslroi "${template_dir}/${T_Pref}wm_atlas_manual${T_Suff}" \
	"${template_dir}/Cut/${T_Pref}wm_atlas_manual${T_Suff}" \
	$dim1_start $dim1_size $dim2_start $dim2_size $dim3_start $dim3_size

# ===== Calc. _brain =====
# T1w_brain
fslmaths "${template_dir}/Cut/${T_Pref}T1w${T_Suff}" -mul "${template_dir}/Cut/${T_Pref}BrainMask${T_Suff}" \
    "${template_dir}/Cut/${T_Pref}T1w_brain${T_Suff}"

# T2w_brain
fslmaths "${template_dir}/Cut/${T_Pref}T2w${T_Suff}" -mul "${template_dir}/Cut/${T_Pref}BrainMask${T_Suff}" \
    "${template_dir}/Cut/${T_Pref}T2w_brain${T_Suff}"
    
# MyelinMap_brain
fslmaths "${template_dir}/Cut/${T_Pref}MyelinMap${T_Suff}" -mul "${template_dir}/Cut/${T_Pref}BrainMask${T_Suff}" \
    "${template_dir}/Cut/${T_Pref}MyelinMap_brain${T_Suff}"
    
# ===== Merge Prob =====
fslmerge -t "${template_dir}/Cut/${T_Pref}TPM${T_Suff}" \
    "${template_dir}/Cut/${T_Pref}Prob_01${T_Suff}" \
    "${template_dir}/Cut/${T_Pref}Prob_02${T_Suff}" \
    "${template_dir}/Cut/${T_Pref}Prob_03${T_Suff}"

##########################################################################
########## NOTE: The Final Template FileName Might be Different ##########
########## Because we updated the template naming and resorted  ##########
########## the files in the mid-to-late stages of the project.  ##########
##########################################################################

echo "********** DT6_CutTemplateMatrix --- ALL FINISHED **********"
