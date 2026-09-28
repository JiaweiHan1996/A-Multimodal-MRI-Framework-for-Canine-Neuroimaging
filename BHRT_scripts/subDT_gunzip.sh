#!/bin/bash

subDT_gunzip() {
  # USAGE
  usage() {
    echo "subDT_gunzip is a sub-function to do gunzip .nii.gz data."
    echo "Usage:"
    echo "subDT_BFC2 -i <input_folder> -o <output_folder>"
    echo "Parameters:"
    echo "  -i <input_folder>  Nifti folder path"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Nifti/DHC_Ori"
    echo "  -o <output_folder> Output folder path"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Nifti/DHC_Orim"
    echo "  -h Show HELP"
  }

  # Initialization
  local in_dir=""
  local out_dir=""
  
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
    echo "***** subDT_gunzip --- Subject: ${sid} *****"
    
    # ===== Make Sub Out Folder =====
    sub_out_dir="${out_dir}/${sid}"
    mkdir -p "${sub_out_dir}"
    
    # ===== Do gunzip for T1w & T2w =====
    for sub_in_nii in "$sub_in_dir"*; do
      nii_name=$(basename "$sub_in_nii" .nii.gz)
      sub_out_nii="${sub_out_dir}/${nii_name}.nii"
      gunzip -c "$sub_in_nii" > "$sub_out_nii"
      # --------------------
      unset nii_name sub_out_nii
    done
    
    # ----------------------------------------
    unset sid sub_out_dir sub_in_nii
  done
  
  # ========== Finished ==========
  echo "***** subDT_gunzip --- FINISHED *****"
  }
