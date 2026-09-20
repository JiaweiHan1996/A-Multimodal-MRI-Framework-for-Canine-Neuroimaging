#!/bin/bash

# --------------- INPUT ---------------
work_dir="/home/neuro/Desktop/Beagle_High_Resolution_Template"
scr_dir="/home/neuro/Desktop/BHRT_linux_scripts"
preped_dir="${work_dir}/Preped"
template_dir="${work_dir}/Template"
# --------------------
fodr_name="DHC_Orim_Reg_Den"
t1_suff="_t1.nii"
t2_suff="_t2.nii"
Out_Pref="BHRT_"


############### MAIN ###############
# ========== Load T1w & T2w Pairs ==========
data_dir="${preped_dir}/${fodr_name}"
for sub_dir in "$data_dir"/*/; do
  if [ -d "$sub_dir" ]; then
    sid=$(basename "$sub_dir")
    echo $sid
    # ===== Load Sub T1w & T2w =====
    sub_t1=""
    sub_t2=""
    while IFS= read -r -d '' t1_file; do
      sub_t1="$t1_file"
      # Only to Find First T1w File
      break
    done < <(find "$sub_dir" -type f -name "*${t1_suff}" -print0)
    while IFS= read -r -d '' t2_file; do
      sub_t2="$t2_file"
      # Only to Find First T2w File
      break
    done < <(find "$sub_dir" -type f -name "*${t2_suff}" -print0)
    unset t1_file t2_file
    # ===== Add into FileList =====
    if [[ -f "$sub_t1" && -f "$sub_t2" ]]; then
      echo "T1w File : ${sub_t1}"
      echo "T2w File : ${sub_t2}"
      data_pairs+=("$sub_t1")
      data_pairs+=("$sub_t2")
    fi
    # ------------------------------
    unset sid sub_t1 sub_t2
  fi
done
echo $data_pairs

# ========== Run Template Inter ==========
echo "***** START: antsMultivariateTemplateConstruction2.sh *****"
# ===== Make Output Dir =====
out_dir="${template_dir}/${fodr_name}"
mkdir -p "$out_dir"

antsMultivariateTemplateConstruction2.sh \
  -d 3 \
  -o "${out_dir}/${Out_Pref}" \
  -i 4 \
  -k 2 \
  -m MI \
  -c 2 \
  "${data_pairs[@]}"

echo "***** FINISHED: antsMultivariateTemplateConstruction2.sh *****"

# ========== Move Outputs ==========
sort_dir="${out_dir}/${Out_Pref}Template"
mkdir -p "$sort_dir"
template_t1_raw="${sort_dir}/${Out_Pref}Template_T1w_0.5mm.nii.gz"
template_t2_raw="${sort_dir}/${Out_Pref}Template_T2w_0.5mm.nii.gz"
cp "${out_dir}/${Out_Pref}template0.nii.gz" ${template_t1_raw}
cp "${out_dir}/${Out_Pref}template1.nii.gz" ${template_t2_raw}


echo "********** DT2_InterTemplate --- ALL FINISHED **********"

