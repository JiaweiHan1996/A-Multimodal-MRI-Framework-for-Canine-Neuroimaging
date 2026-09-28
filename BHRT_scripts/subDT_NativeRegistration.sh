#!/bin/bash

subDT_NativeRegistration() {
  # USAGE
  usage() {
    echo "subDT_NativeRegistration is a sub-function to do rigid-registration T2w->T1w."
    echo "Usage:"
    echo "subDT_NativeRegistration -i <input_folder> [-t1_suff <suffix_of_t1>] [-t2_suff <suffix_of_t2>] -o <output_folder>"
    echo "Parameters:"
    echo "  -i <input_folder>  Nifti folder path"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Nifti/DHC_Orim"
    echo "  -t1_suff <suffix_of_t1>	Suffix of T1w file"
    echo "			e.g. _t1.nii.gz (default)"
    echo "  -t2_suff <suffix_of_t2>	Suffix of T2w file"
    echo "			e.g. _t2.nii.gz (default)"
    echo "  -o <output_folder> Output folder path"
    echo "			e.g. //home/neuro/Desktop/Beagle_High_Resolution_Template/Nifti/DHC_Orim_Reg"
    echo "  -h Show HELP"
  }
  
  # Initialization
  local in_dir=""
  local out_dir=""
  local t1_suff="_t1.nii.gz"
  local t2_suff="_t2.nii.gz"

  # Get Command Varbs
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--input)
        in_dir="$2"
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
      -o|--output)
        out_dir="$2"
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
  # ========== Make Output Dir ==========
  mkdir -p "$out_dir"
  
  # ========== Walk Subjects ==========
  for sub_in_dir in "$in_dir"/*/; do
    # ===== Get SubID =====
    sid=$(basename "$sub_in_dir")
    echo "***** subDT_NativeRegistration --- Subject: ${sid} *****"
    
    # ===== Load T1w & T2w Image =====
    sub_in_t1=""
    sub_in_t2=""
    # ---------- Walk Folder to Find File ----------
    while IFS= read -r -d '' t1_file; do
      sub_in_t1="$t1_file"
      # Only to Find First T1w File
      break
    done < <(find "$sub_in_dir" -type f -name "*${t1_suff}" -print0)
    
    while IFS= read -r -d '' t2_file; do
      sub_in_t2="$t2_file"
      # Only to Find First T2w File
      break
    done < <(find "$sub_in_dir" -type f -name "*${t2_suff}" -print0)
    
    # ---------- Do T1w & T2w Registration ----------
    if [[ -f "$sub_in_t1" && -f "$sub_in_t2" ]]; then
      echo "T1w File : ${sub_in_t1}"
      echo "T2w File : ${sub_in_t2}"
    
      # ----- Make Sub Out Folder -----
      sub_out_dir="${out_dir}/${sid}"
      mkdir -p "${sub_out_dir}"
      
      # ----- Copy T1w & T2w -----
      t1_fname=$(basename "$sub_in_t1")
      sub_out_t1="${sub_out_dir}/${t1_fname}"
      cp "$sub_in_t1" "$sub_out_t1"
      
      # ----- antsRegistration -----
      t2_fname=$(basename "$sub_in_t2")
      antsRegistration -d 3 \
        --float 0 \
        -z 1 \
        -o ["${sub_out_dir}/T2_to_T1", "${sub_out_dir}/${t2_fname}"] \
        -n Linear \
        -w [0.005, 0.995] \
        -u 0 \
        -r ["$sub_out_t1", "$sub_in_t2", 1] \
        -t Rigid[0.1] \
        -m MI["$sub_out_t1", "$sub_in_t2", 1, 32, Regular, 0.25] \
        -c [1000x500x250x100, 1e-6, 10] \
        -f 8x4x2x1 \
        -s 3x2x1x0vox \
        -v 1
      
      # ----- Clear Varbs -----
      unset sub_out_dir t1_fname t2_fname sub_out_t1
    
    # ---------- No T1w & T2w, Jump ----------
    else
      if [[ -z "$sub_in_t1" ]]; then
        echo "T1w File Warning : NO ${t1_suff} File ..."
      fi
      if [[ -z "$sub_in_t2" ]]; then
        echo "T2w File Warning : NO ${t2_suff} File ..."
      fi
    fi
    
    # ----------------------------------------
    unset sid sub_in_t1 sub_in_t2
  done

  # ========== Finished ==========
  echo "***** subDT_NativeRegistration --- FINISHED *****"

}
