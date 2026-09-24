# VBM\_DB\_Matlab\_Pipeline

**Version:** 1.0  
**Update:** 2026-09-24

\---

## Introduction

This is a MATLAB code pipeline to do VBM analysis for dog brain (especially for Beagle), which is based on SPM12.



## Installation

Before using it, please set SPM12 path and this pipeline path in matlab, and reset the BHRT template folder path in the function `VBM\_DB\_pipeline`.



## Usage

The DataFolder directory contains the folders of multi-subjects. The directory structure is organized as follows:

```text
DataFolder/
├── sub001/
│   └── \\\*.dcm

├── sub002/
│   └── \\\*.dcm
└── ...
```

Then, running the  `VBM\\\_DB\\\_pipeline` function in MATLAB command window, and selecting the DataFolder and to do reorient by the hints.

## Outputs

A `VBM\_\[yyyymmdd]T\[hhmmss]` folder will be generated in the same directory as the `DataFolder`, which contains, such as:

&#x20;```text
VBM\_20261001T093030/
├── data/
│   └── \*.nii		% intermediate process nifti

│   └── \*.mat		% intermediate process matlab file
├── Results/
│   ├── Volumes/

│   │   └── StandardSpace\_\*\_CSFD.nii	% CSF density file in standard space

│   │   └── StandardSpace\_\*\_GMD.nii	% GM density file in standard space

│   │   └── StandardSpace\_\*\_WMD.nii	% WM density file in standard space

│   ├── SmoothedVolumes/

│   │   └── sStandardSpace\_\*\_CSFD.nii	% smoothed CSF density file in standard space

│   │   └── sStandardSpace\_\*\_GMD.nii	% smoothed GM density file in standard space

│   │   └── sStandardSpace\_\*\_WMD.nii	% smoothed WM density file in standard space

│   └── Volumes\_results\_\*\_atlas.mat		% statistical ROI volume values with different atlas with MATLAB format

│   └── Volumes\_results\_\*\_atlas.xlsx		% statistical ROI volume values with different atlas with EXCEL format
```



