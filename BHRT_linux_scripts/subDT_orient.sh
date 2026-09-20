#!/bin/bash

subDT_orient() {
  # USAGE
  usage() {
    echo "subDT_orient is a sub-function to orient header and image matrix of Nifti."
    echo "Usage:"
    echo "subDT_orient -i <input_folder> [-ro <raw_orientation>] -no <new_orientation> -fo <final_orientation> -o <output_folder>"
    echo "Parameters:"
    echo "  -i <input_folder>  Nifti folder path"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Nifti/DHC"
    echo "  -ro <raw_orientation>	Orientation of Nifti, only to check"
    echo "			L/R-Left/Right, A/P-Anterior/Posterior, S/I-Superior.Inferior"
    echo "			e.g. LPI"
    echo "  -no <new_orientation>	New orientation to write into header by [3drefit]"
    echo "			e.g. RIP"
    echo "  -fo <final_orientation>	Final orientation to write into header and image by [3dresample]"
    echo "			e.g. LIP"
    echo "  -o <output_folder> Output folder path"
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Nifti/DHC_Ori"
    echo "  -h Show HELP"
  }

  # Initialization
  local in_dir=""
  local out_dir=""
  local raw_ori=""
  local new_ori=""
  local fin_ori=""

  # Get Command Varbs
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -i|--input)
        in_dir="$2"
        shift 2
        ;;
      -ro|--raw_orientation)
        raw_ori="$2"
        shift 2
        ;;
      -no|--new_orientation)
        new_ori="$2"
        shift 2
        ;;
      -fo|--final_orientation)
        fin_ori="$2"
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
  
  # ========== Do Orient ==========
  for sub_in_dir in "$in_dir"/*/; do
    # ===== Get SubID =====
    sid=$(basename "$sub_in_dir")
    echo "***** subDT_orient --- Subject: ${sid} *****"
    
    # ===== Make Sub Out Folder =====
    sub_out_dir="${out_dir}/${sid}"
    mkdir -p "${sub_out_dir}"
    
    # ===== Do Orient for T1w & T2w =====
    for sub_in_nii in "$sub_in_dir"*; do
      # e.g. sub_in_nii=".../Nifti/DHC/db166/db166_t1.nii.gz"
    
      # ---------- Get Nii Info & Check ----------
      nii_name=$(basename "$sub_in_nii" .nii.gz)	# e.g. "db166_t1"
      nii_ori=$(3dinfo -orient "$sub_in_nii")		# e.g. "LPI"
      # ----- Check Read Ori vs. Input Ori -----
      if [ -z "$raw_ori" ]; then
        # Not Input [-ro] Varb
      	echo "Raw Orientation of ${nii_name} : ${nii_ori}"
      else
        # Compare 2 Varbs
        if [ "$raw_ori" != "$nii_ori" ]; then
          "Warning: NOT Matched between Read Orientation of ${nii_name}(${nii_ori}) and Input Orientation(${raw_ori})"
        else
          echo "Raw Orientation of ${nii_name} : ${nii_ori}"
        fi
      fi
      
      # ---------- Tranverse to AFNI Format ----------
      3dcopy "$sub_in_nii" "${sub_out_dir}/${nii_name}_afni"
      
      # ---------- Fix Header ----------
      3drefit -orient "$new_ori" "${sub_out_dir}/${nii_name}_afni+orig"
      
      # ---------- Fix Img Matrix ----------
      3dresample -overwrite \
          -input "${sub_out_dir}/${nii_name}_afni+orig" \
          -orient "$fin_ori" \
          -prefix "${sub_out_dir}/${nii_name}.nii.gz"
      # ----- Delete AFNI Format File -----
      rm -f "${sub_out_dir}/${nii_name}_afni+orig.BRIK"
      rm -f "${sub_out_dir}/${nii_name}_afni+orig.HEAD"
      # ----- Finished -----
      nii_ori_new=$(3dinfo -orient "${sub_out_dir}/${nii_name}.nii.gz")
      echo "New Orientation of ${nii_name} : ${nii_ori_new}"
      
      # --------------------
      unset nii_name nii_ori nii_ori_new
    done
  
    # --------------------
    unset sid sub_out_dir
  done
  
  # ===== Finished =====
  echo "***** subDT_orient --- FINISHED *****"

}

