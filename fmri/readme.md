# Animals_fMRI_Proc_V20260920

## 1. Introduction

**Animals_fMRI_Proc_V20260920** is a preprocessing toolbox developed for animal fMRI analysis, supporting both single-echo and multi-echo data. It is designed to handle alignment between animal scan body positions and templates, as well as custom template analysis. In particular, we would like to express our sincere gratitude to the developers of the DPABI and RESTplus toolboxes, from which the code in `fmri/preprocessing/basic` was primarily adapted, for providing robust and convenient functions that have greatly facilitated fMRI data preprocessing and analysis.

## 2. Installation

1. Download **SPM12** (https://www.fil.ion.ucl.ac.uk/spm/software/spm12/) and **NIfTI_20140122**, and add them to the MATLAB environment path.
2. Extract the **Animals_fMRI_Proc_V20260920** package and add it to the MATLAB environment path (subfolders must be included).
3. MATLAB version must be **R2022a or above**.

## 3. Data Input Format

The project root directory contains the folders `Fun`, `FunME`, `T1`, and `FieldMap`. The directory structure is organized as follows:

```text
ProjectRoot/
├── Fun/                          % Single-echo functional data
│   ├── Subject001/
│   │   ├── S1/                % Session level (if applicable)
│   │   │   └── *.dcm                % DICOM data for this session
│   │   ├── S2/
│   │   │   └── *.dcm
│   │   └── ...
│   ├── Subject002/
│   │   ├── S1/
│   │   │   └── *.dcm
│   │   └── ...
│   └── ...
│
├── FunME/                        % Multi-echo functional data
│   ├── Subject001/
│   │   ├── S1/                % Session level (if applicable)
│   │   │   ├── Echo1/
│   │   │   │   └── *.dcm            % DICOM data for Echo1
│   │   │   ├── Echo2/
│   │   │   │   └── *.dcm            % DICOM data for Echo2
│   │   │   └── ...
│   │   ├── Echo1/                   % If no session level exists, Echo folders
│   │   │   └── *.dcm                % are placed directly under the subject folder
│   │   ├── Echo2/
│   │   │   └── *.dcm
│   │   └── ...
│   ├── Subject002/
│   │   ├── Echo1/
│   │   │   └── *.dcm
│   │   ├── Echo2/
│   │   │   └── *.dcm
│   │   └── ...
│   └── ...
│
├── T1/
│   ├── Subject001/
│   │   └── *.dcm                    % DICOM data directly under the subject folder
│   ├── Subject002/
│   │   └── *.dcm
│   └── ...
│
├── FieldMap/
│   ├── Magnitude1/
│   │   ├── Subject001/
│   │   │   └── *.dcm                % DICOM data for Magnitude1
│   │   ├── Subject002/
│   │   │   └── *.dcm
│   │   └── ...
│   ├── Magnitude2/
│   │   ├── Subject001/
│   │   │   └── *.dcm                % DICOM data for Magnitude2
│   │   ├── Subject002/
│   │   │   └── *.dcm
│   │   └── ...
│   └── PhaseDiff/
│       ├── Subject001/
│       │   └── *.dcm                % DICOM data for PhaseDiff
│       ├── Subject002/
│       │   └── *.dcm
│       └── ...
│
└── Template/
    └── template_TPM.nii             % Custom template in SPM12-compatible TPM format
```

**Notes:**

| Folder / File | Required | Description |
| --- | --- | --- |
| `Fun/` | Yes | Single-echo functional data; each subject folder contains session-level folders (if applicable) with DICOM data, or DICOM data directly under the subject folder if no sessions exist |
| `FunME/` | Yes | Multi-echo functional data; each subject folder contains session-level folders (if applicable), and each session (or the subject folder itself if no sessions exist) contains `Echo1/`, `Echo2/`, ... folders holding the corresponding DICOM data |
| `T1/` | Yes | Structural data; each subject folder contains DICOM data directly |
| `FieldMap/Magnitude1/` | No | Magnitude1 field map data; each subject folder contains DICOM data directly |
| `FieldMap/Magnitude2/` | No | Magnitude2 field map data; each subject folder contains DICOM data directly |
| `FieldMap/PhaseDiff/` | No | Phase difference field map data; each subject folder contains DICOM data directly |
| `Template/template_TPM.nii` | No | Custom template in SPM12-compatible TPM format |

> File names are not fixed; they only need to correspond one-to-one in the parameter configuration file.

> Multi-echo and single-echo data do not need to coexist. Only one of them is required, depending on the needs of the study.

> If the input is dcm, no additional processing is required.

## 4. Parameter Configuration File

The parameter configuration file specifies the parameters for each step of the preprocessing pipeline (e.g., body position rotation, origin alignment, left-right flip, template selection). This file must be selected along with the data path during runtime.
### 4.1 Example Configuration File

```json
{
    "Config_INFO": {
        "Template": "...\BHRT\BHRT_T1w_0.5mm.nii",
        "TPM": {
            "GM_Path": "...\BHRT\BHRT_TPM_0.5mm.nii,2",
            "WM_Path": "...\BHRT\BHRT_TPM_0.5mm.nii,3",
            "CSF_Path": "...\BHRT\BHRT_TPM_0.5mm.nii,1"
        },
        "Mask": {
            "Brain": "...\Animals_fMRI_Proc_V20260920\config\mask\BrainMask.nii",
            "WM": "...\Animals_fMRI_Proc_V20260920\config\mask\WmMask.nii",
            "CSF": "...\Animals_fMRI_Proc_V20260920\config\mask\CsfMask.nii"
        }
    },
    "Process_Type": "Prep",
    "Import_INFO": {
        "Start_Fun_Name": "FunME",
        "Start_T1_Name": "T1"
    },
    "Data_INFO": {
        "TR": [],
        "Snum": 1,
        "Enum": 3,
        "RefEcho": 1
    },
    "Process_INFO": {
        "Step_H":  { "Name": "DICOM_2_Nii", "Brain_Size_mm": 60 },
        "Step_T":  { "Name": "Remove_First_n_Timepoints", "Del_Tps": 5 },
        "Step_A":  { "Name": "Slice_Timing", "Slice_Order": [], "Ref_Slice": [] },
        "Step_R":  { "Name": "Realign" },
        "Step_Cb": { "Name": "ME_Combine" },
        "Step_C":  { "Name": "Covs_Regressing",
                     "IsWholeBrain": 0,
                     "IsCSF": 1,
                     "IsWhiteMatter": 1,
                     "IsHeadMotion": 4,
                     "AddMean": 1 },
        "Step_W":  { "Name": "Normalize",
                     "IsDARTEL": 0,
                     "ResVoxelSize": [1.5, 1.5, 1.5] },
        "Step_S":  { "Name": "Smooth", "FWHM": [3, 3, 3] },
        "Step_D":  { "Name": "Detrend" },
        "Step_F":  { "Name": "Filter", "Band": [0.01, 100] }
    },
    "Delete_Folder_INFO": []
}
```

### 4.2 Parameter Description

#### `Config_INFO`

Configuration information related to templates and masks.

| Field | Type | Description |
| --- | --- | --- |
| `Template` | String | Path to the template image used for normalization and alignment. Should be a NIfTI file. |
| `TPM.GM_Path` | String | Path to the gray matter (GM) tissue probability map. The suffix `,2` indicates the second volume in the TPM file (SPM convention). |
| `TPM.WM_Path` | String | Path to the white matter (WM) tissue probability map. The suffix `,3` indicates the third volume in the TPM file. |
| `TPM.CSF_Path` | String | Path to the cerebrospinal fluid (CSF) tissue probability map. The suffix `,1` indicates the first volume in the TPM file. |
| `Mask.Brain` | String | Path to the whole-brain mask. |
| `Mask.WM` | String | Path to the white matter mask. |
| `Mask.CSF` | String | Path to the CSF mask. |

#### `Process_Type`

| Field | Type | Description |
| --- | --- | --- |
| `Process_Type` | String | Type of processing pipeline to run. Example values: `"Prep"` (preprocessing). |

#### `Import_INFO`

| Field | Type | Description |
| --- | --- | --- |
| `Start_Fun_Name` | String | Name of the root folder containing functional data (e.g., `"FunME"`). |
| `Start_T1_Name` | String | Name of the root folder containing structural data (e.g., `"T1"`). |

#### `Data_INFO`

| Field | Type | Description |
| --- | --- | --- |
| `TR` | Array | Repetition time (in seconds). Empty array `[]` means it will be read from the data or left unspecified. |
| `Snum` | Integer | Index of the first echo to use. |
| `Enum` | Integer | Index of the last echo to use. |
| `RefEcho` | Integer | Reference echo used for multi-echo combination. |

#### `Process_INFO`

Each step is defined as a key-value pair. The key is the step ID (e.g., `Step_H`), and the value is an object containing the step `Name` and its parameters.

| Step | `Name` | Parameters | Description |
| --- | --- | --- | --- |
| `Step_H` | `DICOM_2_Nii` | `Brain_Size_mm` | Convert DICOM to NIfTI. `Brain_Size_mm` specifies the preset brain size (in mm) for FOV cropping. |
| `Step_T` | `Remove_First_n_Timepoints` | `Del_Tps` | Remove the first *n* time points. `Del_Tps` specifies the number of time points to delete. |
| `Step_A` | `Slice_Timing` | `Slice_Order`, `Ref_Slice` | Slice-timing correction. `Slice_Order` is the slice acquisition order; `Ref_Slice` is the reference slice. |
| `Step_R` | `Realign` | — | Realign functional images to correct for head motion. |
| `Step_Cb` | `ME_Combine` | — | Combine multi-echo data into a single echo time series. |
| `Step_C` | `Covs_Regressing` | `IsWholeBrain`, `IsCSF`, `IsWhiteMatter`, `IsHeadMotion`, `AddMean` | Regress out nuisance covariates. `IsWholeBrain`/`IsCSF`/`IsWhiteMatter` are flags (0/1) for regressing whole-brain, CSF, and WM signals, respectively. `IsHeadMotion` specifies the head-motion model order (e.g., `4` for 24-parameter model). `AddMean` adds the mean signal back after regression. |
| `Step_W` | `Normalize` | `IsDARTEL`, `ResVoxelSize` | Normalize to template space. `IsDARTEL` toggles DARTEL-based normalization (0/1). `ResVoxelSize` is the target voxel size (e.g., `[1.5, 1.5, 1.5]`). |
| `Step_S` | `Smooth` | `FWHM` | Spatial smoothing. `FWHM` is the Gaussian kernel size in mm (e.g., `[3, 3, 3]`). |
| `Step_D` | `Detrend` | — | Remove linear (and optionally higher-order) trends from the time series. |
| `Step_F` | `Filter` | `Band` | Temporal filtering. `Band` is the frequency band in Hz (e.g., `[0.01, 100]`). |

#### `Delete_Folder_INFO`

| Field | Type | Description |
| --- | --- | --- |
| `Delete_Folder_INFO` | Array | List of intermediate folders to delete after processing. Empty array `[]` means no folders are deleted. |

> The order of steps in `Process_INFO` determines the order in which they are executed. To disable a step, simply remove its entry from `Process_INFO`.


## 5. Usage

1. Run `animals_fmri_proc` in the MATLAB command line.
2. Select the data path.
3. After confirmation, select the parameter configuration JSON file.
4. The processing will then begin.

---

> **Note:** Before running the code, add the NIfTI_20140122 and SPM12 toolboxes to the MATLAB working path. This tool can rotate animal images from special body positions to the template standard position (including structural, functional, and diffusion images), and can perform origin alignment as needed. It supports dcm and nii(.gz) data formats.

## Reference
> Yan, Chao-Gan et al. “DPABI: Data Processing & Analysis for (Resting-State) Brain Imaging.” Neuroinformatics vol. 14,3 (2016): 339-51. doi:10.1007/s12021-016-9299-4

> https://github.com/Chaogan-Yan/DPABI

>Jia, Xi-Ze et al. “RESTplus: an improved toolkit for resting-state functional magnetic resonance imaging data processing.” Science bulletin vol. 64,14 (2019): 953-954. doi:10.1016/j.scib.2019.05.008

> http://restfmri.net/forum/restplus
