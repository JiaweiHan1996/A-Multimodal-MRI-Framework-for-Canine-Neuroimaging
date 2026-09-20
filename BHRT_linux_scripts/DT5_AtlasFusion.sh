#!/bin/bash

# --------------- INPUT ---------------
work_dir="/home/neuro/Desktop/Beagle_High_Resolution_Template"
scr_dir="/home/neuro/Desktop/BHRT_linux_scripts"
template_dir="${work_dir}/Template"
dog_dir="${work_dir}/DogTemplates"
# --------------------
fodr_name="DHC_Orim_Reg_Den"

T_name="BHRT"
T_Pref="${T_name}_"
T_Suff="_0.5mm.nii.gz"

# ---------- DOG_Template ----------
template_t1file="${template_dir}/${fodr_name}/${T_name}/${T_Pref}T1w${T_Suff}"
template_maskfile="${template_dir}/${fodr_name}/${T_name}/${T_Pref}BrainMask${T_Suff}"

# ---------- Reference : CornDog_v3.0 ----------
ref_fodr_name="CornDog_v3.0"
ref_template_t1file="${dog_dir}/${ref_fodr_name}/corndog_v3_template.nii.gz"
ref_atlas_fname_list="${scr_dir}/${ref_fodr_name}_Atlas_FileName.txt"

# --------------- OUTPUT ---------------
trans_dir="${template_dir}/${fodr_name}/${ref_fodr_name}_Trans"
if [ -d "${trans_dir}" ]; then
  rm -rf "${trans_dir}"
fi
mkdir -p "$trans_dir"


# =============== Main ===============

# ========== Mask DOG_Template ==========
template_t1file_brain="${template_dir}/${fodr_name}/${T_name}/${T_Pref}T1w_brain${T_Suff}"
fslmaths $template_t1file -mul $template_maskfile $template_t1file_brain

# ========== Registration: CornDog -> DOG_Template (Masked) ==========
antsRegistrationSyN.sh -d 3 \
  -f $template_t1file_brain \
  -m $ref_template_t1file \
  -o "${trans_dir}/${ref_fodr_name}_TO_${T_Pref}"

# Output
ref_warp="${trans_dir}/${ref_fodr_name}_TO_${T_Pref}1Warp.nii.gz"
ref_affine_mat="${trans_dir}/${ref_fodr_name}_TO_${T_Pref}0GenericAffine.mat"

# ========== Apply Tranform ==========
while IFS= read -r ref_fname; do

  ref_fname=$(echo "$ref_fname" | tr -d '\r')
  ref_fname=$(echo "$ref_fname" | xargs)

  echo $ref_fname

  # ===== Load Atlas Image =====
  ref_atlasfile="${dog_dir}/${ref_fodr_name}/${ref_fname}"

  # ===== Apply Transform =====
  atlas_suff=${ref_fname#*corndog_v3_}
  atlas_suff=${atlas_suff%.nii.gz*}
  template_atlasfile="${template_dir}/${fodr_name}/${T_nmae}/${T_Pref}${atlas_suff}${T_Suff}"
  echo $template_atlasfile
  antsApplyTransforms -d 3 \
    -e 0 \
    -i "$ref_atlasfile" \
    -r "$template_t1file" \
    -o "$template_atlasfile" \
    -n MultiLabel \
    -u int \
    -t "$ref_warp" \
    -t ["$ref_affine_mat",0] \
    -v 1

  unset ref_fname ref_atlasfile atlas_suff template_atlasfile
done < "$ref_atlas_fname_list"

########################################################################
########## After the Atlas Generated, You can Fix it Manually ##########
########################################################################


echo "********** DT5_AtlasFusion --- ALL FINISHED **********"
