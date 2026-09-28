#!/bin/bash

subDT_dcm2nii() {
  # USAGE
  usage() {
    echo "subDT_dcm2nii is a sub-function to translate DOG DICOM to Nifti."
    echo "Parameters:"
    echo "  -i <input_folder>  DICOM folder path"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/DICOM/DHC"
    echo "  -o <output_folder> Output folder path"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Nifti/DHC"
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
  mkdir -p "${out_dir}"
  
  # ========== Walk Subjects ==========
  for sub_in_dir in "$in_dir"/*/; do
    # ===== Get SubID =====
    sid=$(basename "$sub_in_dir")
    echo "***** subDT_dcm2nii --- Subject: ${sid} *****"
    
    # ===== Make Sub Out Folder ----------
    sub_out_dir="${out_dir}/${sid}"
    mkdir -p "${sub_out_dir}"
    
    # ===== Do dcm2nii =====
    for seq_dir in "$sub_in_dir"*/; do
      dcm2niix -f %f -b n -o "${sub_out_dir}" -z y "${seq_dir}"
    done
  done
  
  # ========== Finished ==========
  echo "***** subDT_dcm2nii --- FINISHED *****"

}

