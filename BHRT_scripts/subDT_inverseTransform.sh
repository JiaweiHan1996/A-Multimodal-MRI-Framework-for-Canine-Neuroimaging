#!/bin/bash

subDT_inverseTransform() {
  # USAGE
  usage() {
    echo "subDT_inverseTransform is a sub-function to apply transformation MAT, to get tissue segment in native space."
    echo "This function is used to ONE subject."
    echo "Usage:"
    echo "subDT_inverseTransform -i <input_folder> -o <output_folder> -seg <template_tissue_segment> -p <preped_folder> -s <subject_ID> -t1_suff <suffix_of_t1> -t2_suff <suffix_of_t2>"
    echo "Parameters:"
    echo "  -i <input_folder>  Iterated template folder path"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Template/DHC_Orim_Reg_Den"
    echo "  -o <output_folder> Output folder path"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Template/DHC_Orim_Reg_Den/Native_Trans"
    echo "  -seg <template_tissue_segment> The Template segment nii file"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Template/DHC_Orim_Reg_Den/BHRT/Segment.nii.gz"
    echo "  -p <preped_folder> The input preped folder when did DT2_IterTemplate, to load subject T1w & T2w nii filename"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Preped/DHC_Orim_Reg_Den"
    echo "  -s <subject_ID>	Subject ID to find the T1w & T2w"
    echo "			e.g. db81"
    echo "  -t1_suff <suffix_of_t1>  T1w nii file suffix"
    echo "			e.g. _t1.nii"
    echo "  -t2_suff <suffix_of_t2>  T2w nii file suffix"
    echo "			e.g. _t2.nii"
    echo "  -h Show HELP"
  }
  
  # Initialization
  local in_dir=""
  local out_dir=""
  local template_segfile=""
  local prep_dir=""
  local sid=""
  local t1_suff="_t1.nii.gz"
  local t2_suff="_t2.nii.gz"
  
  # Get Command Varbs
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--input)
        in_dir="$2"
        shift 2
        ;;
      -o|--output)
        out_dir="$2"
        shift 2
        ;;
      -seg|--segment)
        template_segfile="$2"
        shift 2
        ;;
      -p|--preped)
        prep_dir="$2"
        shift 2
        ;;
      -s|--sid)
        sid="$2"
        shift 2
        ;;
      -t1_suff|--suffix_of_t1)
        t1_suff="$2"
        shift 2
        ;;
      -t2_suff|--suffix_of_t2)
        t2_suff="$2"
        shift 2
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        echo "Infalid Input: $1"
        usage
        return 1
        ;;
    esac
  done
  
  # ==================== Main ====================
  # ========= Make Sub Out Dir ==========
  sub_out_dir="${out_dir}/${sid}"    # e.g. "~/Native_Trans/db286"
  if [ -d "${sub_out_dir}" ]; then
    rm -rf "${sub_out_dir}"
  fi
  mkdir "${sub_out_dir}"
  
  # ========== Load Sub T1w & T2w Files in Preped Dir ==========
  prep_sub_dir="${prep_dir}/${sid}"
  prep_sub_t1fname=""
  prep_sub_t2fname=""
  # ===== Sub T1w FileName =====
  # ---------- Load FileName ----------
  while IFS= read -r -d '' t1_file; do
    sub_t1="$t1_file"
    # Only to Find First T1w File
    break
  done < <(find "$prep_sub_dir" -type f -name "*${t1_suff}" -print0)
  fname="${sub_t1##*/}"		# e.g. "db286_t1.nii.gz" or "db286_t1.nii"
  prep_sub_t1fname="${fname%%.*}"	# e.g. "db286_t1"
  # ---------- Copy Sub T1w ----------
  cp "$sub_t1" "${sub_out_dir}/"
  sub_out_t1file="${sub_out_dir}/${fname}"
  unset t1_file sub_t1 fname
  # ===== Sub T2 FileName =====
  # ---------- Load FileName ----------
  while IFS= read -r -d '' t2_file; do
    sub_t2="$t2_file"
    # Only to Find First T2w File
    break
  done < <(find "$prep_sub_dir" -type f -name "*${t2_suff}" -print0)
  fname="${sub_t2##*/}"		# e.g. "db286_t2.nii.gz" or "db286_t2.nii"
  prep_sub_t2fname="${fname%%.*}"	# e.g. "db286_t1"
  # ---------- Copy Sub T1w ----------
  cp "$sub_t2" "${sub_out_dir}/"
  sub_out_t2file="${sub_out_dir}/${fname}"
  unset t2_file sub_t2 fname
  
  echo "--- subDT_inverseTransform: Sub ${sid} T1w and T2w FileNames are ${prep_sub_t1fname} and ${prep_sub_t2fname} ---"
  
  # ========== Find Sub T1w & T2w Iter Files ==========
  # ===== T1w Files =====
  # Affine MAT
  aim_file=`ls ${in_dir}/*-${prep_sub_t1fname}*-0GenericAffine.mat`
  cp "$aim_file" "${sub_out_dir}/"
  unset aim_file
  sub_out_affinemat=`ls ${sub_out_dir}/*-${prep_sub_t1fname}*-0GenericAffine.mat`
  echo "Affine MAT --- ${sub_out_affinemat}"
  # Inverse Warp
  aim_file=`ls ${in_dir}/*-${prep_sub_t1fname}*-1InverseWarp.nii.gz`
  cp "$aim_file" "${sub_out_dir}/"
  unset aim_file
  sub_out_invwarp=`ls ${sub_out_dir}/*-${prep_sub_t1fname}*-1InverseWarp.nii.gz`
  echo "Inverse Warp --- ${sub_out_invwarp}"
  # Warp
  aim_file=`ls ${in_dir}/*-${prep_sub_t1fname}*-1Warp.nii.gz`
  cp "${aim_file}" "${sub_out_dir}/"
  unset aim_file
  sub_out_warp=`ls ${sub_out_dir}/*-${prep_sub_t1fname}*-1Warp.nii.gz`
  echo "Warp --- ${sub_out_warp}"
  # --------------------
  aim_file=`ls ${in_dir}/*-${prep_sub_t1fname}*Repaired.nii.gz`
  cp "$aim_file" "${sub_out_dir}/"
  unset aim_file
  aim_file=`ls ${in_dir}/*-${prep_sub_t1fname}*WarpedToTemplate.nii.gz`
  cp "$aim_file" "${sub_out_dir}/"
  unset aim_file
  
  # ===== T2w Files =====
  aim_file=`ls ${in_dir}/*-${prep_sub_t2fname}*Repaired.nii.gz`
  cp "$aim_file" "${sub_out_dir}/"
  unset aim_file
  aim_file=`ls ${in_dir}/*-${prep_sub_t2fname}*WarpedToTemplate.nii.gz`
  cp "$aim_file" "${sub_out_dir}/"
  unset aim_file
  
  # ========== Run Inverse Transeform ==========
  sub_out_segfile="${sub_out_dir}/${sid}_Segment_NativeSpace.nii.gz"
  antsApplyTransforms -d 3 \
    -e 0 \
    -i "$template_segfile" \
    -r "$sub_out_t1file" \
    -o "$sub_out_segfile" \
    -n GenericLabel \
    -u int \
    -t ["$sub_out_affinemat",1] \
    -t "$sub_out_invwarp" \
    -v 1
  
  # ========== Make BrainMask by Segment ==========
  sub_out_maskfile="${sub_out_dir}/${sid}_BrainMask_NativeSpace.nii.gz"
  fslmaths "$sub_out_segfile" -bin "$sub_out_maskfile"
  
  
  echo "Native Segment --- ${sub_out_segfile}"

  
  
  
  
}
