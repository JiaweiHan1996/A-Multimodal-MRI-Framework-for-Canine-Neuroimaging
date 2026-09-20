#!/bin/bash
# =============================================================================
# dMRI preprocessing pipeline with TOPUP and EDDY (FSL)
#
# This script performs:
#   - Susceptibility distortion correction using blip-up/down b0 (TOPUP)
#   - Eddy current and motion correction (EDDY)
#   - Optional DTI fitting (dtifit)
#
# Usage:
#   dmri_preprocessing.sh -i <forward> -r <reverse> -t <esp_ms> -p <PE_dir> \
#                          -b <bval> -v <bvec> -L <outdir> [-o <output>] [-y <yes/no>]
#
# Required arguments:
#   -i   Forward phase-encoded 4D DWI (e.g., AP)
#   -r   Reverse phase-encoded 4D DWI (e.g., PA)
#   -t   Effective echo spacing (in milliseconds, e.g., 0.34)
#   -p   Phase-encoding direction: AP, PA, RL, or LR (for the forward image)
#   -b   b-value file (FSL format)
#   -v   b-vector file (FSL format)
#   -L   Output directory (will be created)
#
# Optional:
#   -o   Output filename (default: preprocessed_dwi.nii.gz)
#   -y   Compute DTI parameters? (yes/no, default: yes)
#   -h   Show this help
#
# Dependencies: FSL, MRtrix3, CUDA-enabled eddy (eddy_cuda), bc, etc.
# =============================================================================

set -euo pipefail

Usage() {
    cat <<EOF
Unwarping of B0 inhomogeneity distortion, correction of eddy current and motion

Usage:
  dmri_preprocessing.sh -i <forward> -r <reverse> -t <esp_ms> -p <PE_dir> \\
                         -b <bval> -v <bvec> -L <outdir> [options]

Required:
  -i <forward>    : 4D DWI with forward phase encoding
  -r <reverse>    : 4D DWI with reverse phase encoding
  -t <esp_ms>     : Effective echo spacing (ms)
  -p <AP/PA/RL/LR>: Phase-encoding direction of forward image
  -b <bval>       : b-value file
  -v <bvec>       : b-vector file
  -L <outdir>     : Output directory (will be created)

Options:
  -o <name>       : Output filename (within outdir/results/, default: preprocessed_dwi.nii.gz)
  -y <yes/no>     : Run DTI fitting? (default: yes)
  -h              : Print this help
EOF
    exit 1
}

# -----------------------------------------------------------------------------
# Parse arguments
# -----------------------------------------------------------------------------
forward=""
reverse=""
esp_ms=""
pedir=""
bval=""
bvec=""
outdir=""
outname="preprocessed_dwi.nii.gz"
do_dti="yes"

while getopts ":i:r:t:p:b:v:L:o:y:h" opt; do
    case "$opt" in
        i) forward="$OPTARG" ;;
        r) reverse="$OPTARG" ;;
        t) esp_ms="$OPTARG" ;;
        p) pedir="$OPTARG" ;;
        b) bval="$OPTARG" ;;
        v) bvec="$OPTARG" ;;
        L) outdir="$OPTARG" ;;
        o) outname="$OPTARG" ;;
        y) do_dti="$OPTARG" ;;
        h) Usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; Usage ;;
        :) echo "Option -$OPTARG requires an argument" >&2; Usage ;;
    esac
done

# Validate required arguments
if [[ -z "$forward" || -z "$reverse" || -z "$esp_ms" || -z "$pedir" || -z "$bval" || -z "$bvec" || -z "$outdir" ]]; then
    echo "ERROR: Missing required arguments." >&2
    Usage
fi
for f in "$forward" "$reverse" "$bval" "$bvec"; do
    [[ -f "$f" ]] || { echo "ERROR: File not found: $f" >&2; exit 1; }
done

# Check phase encoding direction
case "$pedir" in
    AP|PA|RL|LR) ;;
    *) echo "ERROR: Phase-encoding direction must be AP, PA, RL, or LR" >&2; exit 1 ;;
esac

# -----------------------------------------------------------------------------
# Setup directories and logging
# -----------------------------------------------------------------------------
mkdir -p "$outdir"
logfile="$outdir/preprocessing.log"
exec > >(tee -a "$logfile") 2>&1
echo "Started at $(date)"
echo "Command: $0 $*"

tmpdir="$outdir/dwi_preproc_tmp"
if [[ -d "$tmpdir" ]]; then
    echo "Removing old temporary directory: $tmpdir"
    rm -rf "$tmpdir"
fi
mkdir -p "$tmpdir"
echo "Temporary directory (kept for inspection): $tmpdir"

# -----------------------------------------------------------------------------
# Step 1: Check dependencies
# -----------------------------------------------------------------------------
echo "Step 1: Check dependencies"
for cmd in fslroi fslmerge fslmaths fslval bet dtifit topup eddy_cuda10.2 eddy_cpu select_dwi_vols; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "ERROR: Required command not found: $cmd" >&2
        exit 1
    fi
done

if ! command -v eddy_cuda10.2 &>/dev/null && ! command -v eddy_cpu &>/dev/null; then
    echo "ERROR: Neither eddy_cuda10.2 nor eddy_cpu found" >&2
    exit 1
fi

echo "All required commands are available."

# -----------------------------------------------------------------------------
# Step 2: Crop odd slices in Z dimension - required by topup
# -----------------------------------------------------------------------------
echo "Step 2: Cropping odd Z slices (if present) to ensure even number"
trim_odd() {
    local input=$1
    local output=$2
    local dim3=$(fslval "$input" dim3)
    if (( dim3 % 2 == 1 )); then
        echo "  Z dimension is odd ($dim3), cropping last slice"
        fslroi "$input" "$output" 0 -1 0 -1 0 $((dim3 - 1))
    else
        cp "$input" "$output"
    fi
}
forward_crop="$tmpdir/forward_crop.nii.gz"
reverse_crop="$tmpdir/reverse_crop.nii.gz"
trim_odd "$forward" "$forward_crop"
trim_odd "$reverse" "$reverse_crop"

# -----------------------------------------------------------------------------
# Step 3: Extract b0 volumes using select_dwi_vols
# -----------------------------------------------------------------------------
echo "Step 3: Extracting b0 volumes (bval < 50)"
# For forward data, use the given bval file
b0_fwd="$tmpdir/b0_forward.nii.gz"
select_dwi_vols "$forward_crop" "$bval" "$b0_fwd" 0 -db 50

# For reverse data, create a dummy bval file with all zeros
n_rev=$(fslval "$reverse_crop" dim4)
dummy_bval="$tmpdir/dummy_bval.txt"
printf "0 %.0s" $(seq 1 $n_rev) > "$dummy_bval"
b0_rev="$tmpdir/b0_reverse.nii.gz"
select_dwi_vols "$reverse_crop" "$dummy_bval" "$b0_rev" 0 -db 50

# Merge b0s for TOPUP
topup_input="$tmpdir/topup_b0.nii.gz"
fslmerge -t "$topup_input" "$b0_fwd" "$b0_rev"

# -----------------------------------------------------------------------------
# Step 4: Prepare TOPUP parameters
# -----------------------------------------------------------------------------
# Determine readout time
if [[ "$pedir" == "AP" || "$pedir" == "PA" ]]; then
    pe_dim=2   # y
else
    pe_dim=1   # x
fi
n_pe=$(fslval "$forward_crop" "dim$pe_dim")
total_readout=$(echo "$esp_ms / 1000 * ($n_pe - 1)" | bc -l)

# Build acq.txt for TOPUP
acq_file="$tmpdir/acq_topup.txt"
case "$pedir" in
    AP) fwd_sign="0 -1 0"; rev_sign="0 1 0" ;;
    PA) fwd_sign="0 1 0";  rev_sign="0 -1 0" ;;
    RL) fwd_sign="1 0 0";  rev_sign="-1 0 0" ;;
    LR) fwd_sign="-1 0 0"; rev_sign="1 0 0" ;;
esac
n_fwd_b0=$(fslval "$b0_fwd" dim4)
n_rev_b0=$(fslval "$b0_rev" dim4)
for ((i=0; i<n_fwd_b0; i++)); do echo "$fwd_sign $total_readout" >> "$acq_file"; done
for ((i=0; i<n_rev_b0; i++)); do echo "$rev_sign $total_readout" >> "$acq_file"; done

# Run TOPUP
echo "Step 4: Running TOPUP"
topup_out="$tmpdir/topup_result"
topup --imain="$topup_input" --datain="$acq_file" --config=b02b0.cnf \
      --out="$topup_out" --iout="$tmpdir/topup_corrected_b0" \
      --fout="$tmpdir/fieldmap"

# Generate brain mask from corrected mean b0
mean_b0="$tmpdir/mean_b0.nii.gz"
fslmaths "$tmpdir/topup_corrected_b0" -Tmean "$mean_b0"
bet "$mean_b0" "$tmpdir/brain" -m -f 0.3
mask="$tmpdir/brain_mask.nii.gz"

# -----------------------------------------------------------------------------
# Step 5: Prepare EDDY input (uses forward data only)
# -----------------------------------------------------------------------------
echo "Step 5: Preparing EDDY"
n_vols=$(fslval "$forward_crop" dim4)
index_file="$tmpdir/index.txt"
printf "1\n%.0s" $(seq 1 $n_vols) > "$index_file"   # all volumes correspond to forward line

eddy_acq="$tmpdir/acq_eddy.txt"
echo "$fwd_sign $total_readout" > "$eddy_acq"

# -----------------------------------------------------------------------------
# Step 6: Run EDDY
# -----------------------------------------------------------------------------
echo "Step 6: Running EDDY"
eddy_cmd="eddy_cuda10.2"
if ! command -v eddy_cuda10.2 &>/dev/null; then
    echo "WARNING: eddy_cuda10.2 not found, using eddy (CPU) - may be slow"
    eddy_cmd="eddy_cpu"
fi
$eddy_cmd --imain="$forward_crop" --mask="$mask" \
          --acqp="$eddy_acq" --index="$index_file" \
          --bvecs="$bvec" --bvals="$bval" \
          --topup="$topup_out" \
          --out="$tmpdir/eddy_corrected" \
          --data_is_shelled --cnr_maps --repol

# -----------------------------------------------------------------------------
# Step 7: Optional DTI fitting
# -----------------------------------------------------------------------------
if [[ "$do_dti" == "yes" ]]; then
    echo "Step 7: DTI fitting (dtifit)"

    dti_input="$tmpdir/eddy_corrected"
    dti_output_prefix="$tmpdir/dtifit"
    dti_bvecs="$tmpdir/eddy_corrected.eddy_rotated_bvecs"

    dtifit -k "$dti_input" -o "$dti_output_prefix" \
           -b "$bval" -r "$dti_bvecs" \
           -m "$mask" --sse

    dti_dir="$outdir/dti_results"
    mkdir -p "$dti_dir"

    cp "${dti_output_prefix}_FA.nii.gz" "$dti_dir/dtifit_FA.nii.gz"
    cp "${dti_output_prefix}_MD.nii.gz" "$dti_dir/dtifit_MD.nii.gz"
    cp "${dti_output_prefix}_L1.nii.gz" "$dti_dir/dtifit_AD.nii.gz"

    fslmaths "${dti_output_prefix}_L2.nii.gz" -add "${dti_output_prefix}_L3.nii.gz" \
             -div 2 "${dti_output_prefix}_RD"

    cp "${dti_output_prefix}_RD.nii.gz" "$dti_dir/dtifit_RD.nii.gz"

    echo "DTI results saved to: $dti_dir"
fi

# -----------------------------------------------------------------------------
# Step 8: Copy final outputs to a dedicated "results" folder
# -----------------------------------------------------------------------------
echo "Step 8: Copying results to $outdir/results/"
results_dir="$outdir/results"
mkdir -p "$results_dir"

# Core outputs
cp "$tmpdir/eddy_corrected.nii.gz" "$results_dir/$outname"
cp "$tmpdir/eddy_corrected.eddy_rotated_bvecs" "$results_dir/${outname%.nii.gz}.bvec"
cp "$bval" "$results_dir/${outname%.nii.gz}.bval"
cp "$mask" "$results_dir/${outname%.nii.gz}_mask.nii.gz"

# -----------------------------------------------------------------------------
# Step 9: Run eddy_quad to QC
# -----------------------------------------------------------------------------
if command -v eddy_quad &>/dev/null; then
    echo "Running eddy_quad for QC (output in $outdir/eddy_quad)"
    rm -rf "$outdir/eddy_quad"
    eddy_quad "$tmpdir/eddy_corrected" \
              -idx "$index_file" -par "$eddy_acq" \
              -m "$mask" -b "$bval" -g "$bvec" \
              -f "$tmpdir/fieldmap" \
              -o "$outdir/eddy_quad"
    # After running, copy the QC PDF as above
    qc_pdf=$(find "$outdir/eddy_quad" -name "qc.pdf" -type f | head -1)
    if [[ -f "$qc_pdf" ]]; then
        cp "$qc_pdf" "$results_dir/${outname%.nii.gz}_qc.pdf"
        echo "  QC PDF copied to $results_dir/"
    fi
fi

echo "Completed at $(date)"
echo "All final outputs are in: $results_dir"