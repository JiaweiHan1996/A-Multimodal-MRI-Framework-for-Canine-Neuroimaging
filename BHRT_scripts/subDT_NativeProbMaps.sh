#!/bin/bash

subDT_NativeProbMaps() {
  # USAGE
  usage() {
    echo "subDT_NativeProbMaps is a sub-function to do native segment to get native probality maps."
    echo "This function is used to ONE subject."
    echo "Usage:"
    echo "subDT_NativeProbMaps -i <input_folder> -o <output_folder> -t1_suff <suffix_of_t1> -t2_suff <suffix_of_t2> -seg_suff <suffix_of_native_segment> -bm_suff <suffix_of_native_brainmask>"
    echo "Parameters:"
    echo "  -i <input_folder>  Input folder path of ONE subject."
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Template/DHC_Orim_Reg_Den/Native_Trans/db81"
    echo "  -o <output_folder> Output folder path of ONE subject."
    echo "			e.g. /home/neuro/Desktop/Beagle_High_Resolution_Template/Template/DHC_Orim_Reg_Den/Native_Trans/db81"
    echo "  -t1_suff <suffix_of_t1>  T1w nii file suffix"
    echo "			e.g. _t1.nii"
    echo "  -t2_suff <suffix_of_t2>  T2w nii file suffix"
    echo "			e.g. _t2.nii"
    echo "  -seg_suff <suffix_of_native_segment> Native segment nii file suffix"
    echo "			e.g. _Segment_NativeSpace.nii.gz"
    echo "  -bm_suff <suffix_of_native_brainmask> Native brainmask nii file suffix"
    echo "			e.g. _BrainMask_NativeSpace.nii.gz"
    echo "  -h Show HELP"
  }
  
  # Initialization
  local in_dir=""
  local out_dir=""
  local t1_suff="_t1.nii.gz"
  local t2_suff="_t2.nii.gz"
  local seg_suff="_Segment_NativeSpace.nii.gz"
  local bm_suff="_BrainMask_NativeSpace.nii.gz"
  
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
      -t1_suff|--suffix_of_t1)
        t1_suff="$2"
        shift 2
        ;;
      -t2_suff|--suffix_of_t2)
        t2_suff="$2"
        shift 2
        ;;
      -seg_suff|--suffix_of_segment)
        seg_suff="$2"
        shift 2
        ;;
      -bm_suff|--suffix_of_brainmask)
        bm_suff="$2"
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
  echo "--- subDT_NativeProbMaps for ${in_dir} ---"
  
  # ========== Calc. Native MyelinMap ==========
  sub_t1file=""
  sub_t2file=""
  # ===== T1w =====
  while IFS= read -r -d '' t1_file; do
    sub_t1file="$t1_file"
    # Only to Find First T1w File
    break
  done < <(find "$in_dir" -type f -name "*${t1_suff}" -print0)
  unset t1_file
  # ===== T2w =====
  while IFS= read -r -d '' t2_file; do
    sub_t2file="$t2_file"
    # Only to Find First T2w File
    break
  done < <(find "$in_dir" -type f -name "*${t2_suff}" -print0)
  unset t2_file
  # ===== MyelinMap ======
  sub_mmfile="${out_dir}/MyelinMap_NativeSpace.nii.gz"
  fslmaths "$sub_t1file" -div "$sub_t2file" "$sub_mmfile"
  # thre > 10 ---> 10
  fslmaths $sub_mmfile -uthr 10 -min 10 $sub_mmfile
  echo "T1w File : ${sub_t1file}"
  echo "T2w File : ${sub_t2file}"
  echo "MyelinMap File : ${sub_mmfile}"
  
  # ========== Atropos: Segment in NativeSpace ==========
  # ===== Load Seg & BrainMask =====
  sub_segfile=""
  while IFS= read -r -d '' seg_file; do
    sub_segfile="$seg_file"
    # Only to Find First Seg File
    break
  done < <(find "$in_dir" -type f -name "*${seg_suff}" -print0)
  unset seg_file
  sub_bmfile=""
  while IFS= read -r -d '' bm_file; do
    sub_bmfile="$bm_file"
    # Only to Find First BrainMask File
    break
  done < <(find "$in_dir" -type f -name "*${bm_suff}" -print0)
  unset bm_file
  
  echo "Segment File : ${sub_segfile}"
  echo "BrainMask File : ${sub_bmfile}"
  
  # ===== Segment by Prior =====
  Atropos -d 3 \
    -a "$sub_t1file" -a "$sub_t2file" -a "$sub_mmfile" \
    -x "$sub_bmfile" \
    -o ["${out_dir}/Segment.nii.gz","${out_dir}/Prob_%02d.nii.gz"] \
    -i priorlabelimage[3,"$sub_segfile",0.25] \
    -c [5,0.0001] \
    -m [0.1,1x1x1] \
    -v 1

  echo "Atropos Native Segment --- ${out_dir}/Segment.nii.gz"


}
