#!/bin/bash

# --------------- Notes ---------------
# Before Run This Bash, Please Make Template Brain Mask Manually !!!
# Image(Raw) Resolution=0.5mm iso, Matrix=240x240x130
# Image(Raw) data_type NT16, datatype 4

work_dir="/home/neuro/Desktop/Beagle_High_Resolution_Template"
scr_dir="/home/neuro/Desktop/BHRT_linux_scripts"
template_dir="${work_dir}/Template"
fodr_name="DHC_Orim_Reg_Den"

# ---------- INPUT ---------
T_name="BHRT"
T_Pref="${T_name}_"
T_Suff="_0.5mm.nii.gz"

# --------------- Files ---------------
template_maskfile="${template_dir}/${fodr_name}/${T_name}/${T_Pref}BrainMask${T_Suff}"
template_t1file="${template_dir}/${fodr_name}/${T_name}/${T_Pref}T1w${T_Suff}"
template_t2file="${template_dir}/${fodr_name}/${T_name}/${T_Pref}T2w${T_Suff}"

# --------------- Main ---------------
# ---------- Make MyelinMap ----------
template_mmfile="${template_dir}/${fodr_name}/${T_name}/${T_Pref}MyelinMap${T_Suff}"
fslmaths $template_t1file -div $template_t2file $template_mmfile
# ********** Optional **********
# thre > 10 ---> 10
# Need to Check wether to extract it
fslmaths $template_mmfile -uthr 10 -min 10 $template_mmfile

# ---------- Segment by ANTs-Atropos ----------
Atropos -d 3 \
  -a "${template_t1file}" -a "${template_t2file}" -a "${template_mmfile}" \
  -x "${template_maskfile}" \
  -o ["${template_dir}/${fodr_name}/${T_name}/Segment.nii.gz","${template_dir}/${fodr_name}/${T_name}/Prob_%02d.nii.gz"] \
  -i kmeans[3] -c [5,0.0001] -m [0.1,1x1x1] \
  -v 1


#########################################################
########## In ITK-SNAP to Fix Segment Manually ##########
#########################################################
echo "Now, Go to ITK-SNAP(or other software) and fix the segment manually ..."

echo "***** DT3_Atropos --- Finished *****"

