#!/bin/bash

# --------------- Notes ---------------
# Before Run This Bash, Fix Template Tissue Segment Results Manually !!!

# --------------- INPUT ---------------
work_dir="/home/neuro/Desktop/Beagle_High_Resolution_Template"
scr_dir="/home/neuro/Desktop/BHRT_linux_scripts"
preped_dir="${work_dir}/Preped"
template_dir="${work_dir}/Template"
# --------------------
fodr_name="DHC_Orim_Reg_Den"

# ---------- INPUT in Template Dir ----------
T_name="BHRT"
T_Pref="${T_name}_"
T_Suff="_0.5mm.nii.gz"
template_t1file="${template_dir}/${fodr_name}/${T_name}/${T_Pref}T1w${T_Suff}"
template_t2file="${template_dir}/${fodr_name}/${T_name}/${T_Pref}T2w${T_Suff}"
template_mmfile="${template_dir}/${fodr_name}/${T_name}/${T_Pref}MyelinMap${T_Suff}"
template_segfile="${template_dir}/${fodr_name}/${T_name}/${T_Pref}TissueSegment${T_Suff}"

# ---------- INPUT in Preped Dir ----------
P_t1_Suff="_t1.nii"
P_t2_Suff="_t2.nii"

# --------------- OUTPUT ---------------
out_dir="${template_dir}/${fodr_name}/Native_Trans"
if [ -d "${out_dir}" ]; then
  rm -rf "${out_dir}"
fi
mkdir -p "$out_dir"

# --------------- OUTPUT : TPM ---------------
tpm_dir="${template_dir}/${fodr_name}/${T_name}/TPM"


# =============== Main ===============
# Source bashes
source "${scr_dir}/subDT_inverseTransform.sh"
source "${scr_dir}/subDT_NativeProbMaps.sh"

# ========= Calc. Native2Standard ProbMap for Each Subject ==========
# ===== Default Output Suffix =====
N_seg_Suff="_Segment_NativeSpace.nii.gz"
N_bm_Suff="_BrainMask_NativeSpace.nii.gz"
N_stdspc_Suff="_StandardSpace.nii.gz"
# ===== RUN =====
for sub_in_dir in "${preped_dir}/${fodr_name}"/*/; do
  # ---------- Get SubID ----------
  sid=$(basename "$sub_in_dir")
  echo "***** DT4_ApplyTrans --- Subject: ${sid} *****"
  
  # ---------- Inverse Transform to Segment ----------
  subDT_inverseTransform -i "${template_dir}/${fodr_name}" \
  			  -o "$out_dir" \
  			  -seg "$template_segfile" \
  			  -p "${preped_dir}/${fodr_name}" \
  			  -s "$sid" \
  			  -t1_suff "$P_t1_Suff" -t2_suff "$P_t2_Suff"
  # OUTPUT
  # e.g. ~/Native_Trans/db81/db81_Sgement_NativeSpace.nii.gz
  # e.g. ~/Native_Trans/db81/db81_BrainMask_NativeSpace.nii.gz
  			  
  # ---------- Make Native ProbMaps ----------
  subDT_NativeProbMaps -i "${out_dir}/${sid}" \
  			-o "${out_dir}/${sid}" \
  			-t1_suff "$P_t1_Suff" -t2_suff "$P_t2_Suff" \
  			-seg_suff "$N_seg_Suff" \
  			-bm_suff "$N_bm_Suff"
  # OUTPUT
  # e.g. ~/Native_Trans/db81/MyelinMap_NativeSpace.nii.gz
  # e.g. ~/Native_Trans/db81/Segment.nii.gz
  # e.g. ~/Native_Trans/db81/Prob_01.nii.gz
  # e.g. ~/Native_Trans/db81/Prob_02.nii.gz
  # e.g. ~/Native_Trans/db81/Prob_03.nii.gz
  
  # ---------- Make Native2Standard ProbMaps ----------
  # ----- Warp File ------
  sub_warpfile=`ls ${out_dir}/${sid}/*-1Warp.nii.gz`
  echo "Warp File : ${sub_warpfile}"
  # ----- Affine MAT -----
  sub_affinemat=`ls ${out_dir}/${sid}/*-0GenericAffine.mat`
  echo "Affine Mat : ${sub_affinemat}"
  # ----- Run -----
  plist="01 02 03"
  for pn in $plist ; do
    out_prob="${out_dir}/${sid}/${sid}_Prob_${pn}${N_stdspc_Suff}"
    antsApplyTransforms -d 3 \
    -e 0 \
    -i "${out_dir}/${sid}/Prob_${pn}.nii.gz" \
    -r "$template_t1file" \
    -o "$out_prob" \
    -n Linear \
    -u float \
    -t "$sub_warpfile" \
    -t ["$sub_affinemat",0] \
    -v 1
    echo "******************************"
    echo $out_prob
    echo "******************************"
    unset out_prob
  done
  unset pn plist
  # ----- OUTPUT -----
  # e.g. ~/Native_Trans/db81/db81_Prob_01_StandardSpace.nii.gz
  # e.g. ~/Native_Trans/db81/db81_Prob_02_StandardSpace.nii.gz
  # e.g. ~/Native_Trans/db81/db81_Prob_03_StandardSpace.nii.gz
  # --------------------------------------------
  unset sid sub_warpfile sub_affinemat
done


# ========== Average ProbMaps ==========
echo "***** START : Average ProbMaps *****"
plist="01 02 03"
# ===== Make TPM Folder =====
if [ -d "${tpm_dir}" ]; then
  rm -rf "${tpm_dir}"
fi
mkdir -p "${tpm_dir}"
for pn in $plist; do
  echo "${tpm_dir}/prob_${pn}"
  mkdir -p "${tpm_dir}/prob_${pn}"
done
unset pn

# ===== Copy Prob images =====
for sub_dir in "$out_dir"/*/; do
  # ===== Get SubID =====
  sid=$(basename "$sub_dir")
  # ===== Copy Prob =====
  for pn in $plist ; do
    # ---------- Load Prob ----------
    sub_probfile=`ls ${sub_dir}/*Prob_${pn}${N_stdspc_Suff}`
    # ---------- Copy -----------
    cp "$sub_probfile" "${tpm_dir}/prob_${pn}/"
    # --------------------
    unset sub_probfile
  done
  # --------------------
  unset pn sid
done
unset sub_dir

# ===== Average probs =====
for pn in $plist ; do
  cd "${tpm_dir}/prob_${pn}"
  AverageImages 3 \
    "${tpm_dir}/${T_Pref}Prob_${pn}${T_Suff}" \
    0 \
    *Prob_${pn}${N_stdspc_Suff}
done


echo "********** DT4_ApplyTrans --- ALL FINISHED **********"

