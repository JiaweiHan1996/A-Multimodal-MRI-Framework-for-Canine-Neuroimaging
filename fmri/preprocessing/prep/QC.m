function PP = QC(PP)

fprintf(['\nQC Starting   ||    ' spm('time') '\n']);

[~,FunFolderName,~] = fileparts(PP.FunPath);
if contains(FunFolderName, "R") && (PP.Enum == 1 || (PP.Enum > 1 && contains(FunFolderName, "Cb")))
    [Parameters, PP] = QC_basisPara(PP);
    if strcmp(PP.T1Path, ' ')
        fprintf('No T1 data available, can not calculate tSNR in masks.\n');
        for i = 1:length(Parameters.scans_list)
            tSNR_Calc(Parameters.scans_list{i}, Parameters.QCtxt_list{i});
        end
        fprintf(['\nQC Completed   ||    ' spm('time') '\n']);
    else
        for i = 1:length(Parameters.scans_list)
            if ~isempty(PP.T1DataList)  
                [~, T1Folder_Name, ~] = fileparts(PP.T1Path);
                if strcmp(T1Folder_Name, 'T1RawHSeg')
                   maskList = OriSpaceMaskGen(Parameters.c1ToFunList{i}, Parameters.c2ToFunList{i}, ...
                        Parameters.c3ToFunList{i}, [], [], Parameters.brainToFunList{i});
                   tSNR_Calc(Parameters.scans_list{i}, Parameters.QCtxt_list{i}, maskList{1}, ...
                        Parameters.c1ToFunList{i}, Parameters.c2ToFunList{i});
                   delete(maskList{1})
                end
            end
        end
        fprintf(['\nQC Completed   ||    ' spm('time') '\n']);
    end

else
    fprintf('[QC] QC not applied: Conditions not satisfied. ');
    fprintf('PP.Enum = %d, FunFolderName = %s. ', PP.Enum, FunFolderName);
    if PP.Enum == 1
        if ~contains(FunFolderName, "R")
            fprintf('Requirement: Enum == 1 requires folder name containing "R".\n');
        end
    elseif PP.Enum > 1
        if ~contains(FunFolderName, "Cb") || ~contains(FunFolderName, "R")
            fprintf('Requirement: Enum > 1 requires folder name containing both "Cb" and "R".\n');
        end
    end
end

end

function [Parameters, PP] = QC_basisPara(PP)

DataList = PP.DataList;
T1DataList = PP.T1DataList;
QC_Path = PP.QC_Path;
if ~exist(QC_Path, 'dir')
    mkdir(QC_Path);
end

scans_list = cell(length(DataList.Sublist), 1);
c1ToFunList = cell(length(DataList.Sublist), 1);
c2ToFunList = cell(length(DataList.Sublist), 1);
brainToFunList = cell(length(DataList.Sublist), 1);

j=0;
for i = 1:length(DataList.Sublist)
    if DataList.FunFolder_Name(end) == 'C'
        DataList.FunFolder_Name = DataList.FunFolder_Name(1:end-1);
    end
    
    if DataList.filename{i}(1) == 'c'
        DataList.filename{i} = DataList.filename{i}(2:end);
    end
    scans_list{i} = fullfile(DataList.dataroot_path, ...
                                DataList.FunFolder_Name, ...
                                DataList.Sublist{i}, ...
                                DataList.filename{i});
    
    QCtxt_list{i} = fullfile(QC_Path, DataList.Sublist{i}, 'tSNR.txt');
    % match T1 and meanFun
    if PP.Snum > 1
        
        path = fileparts(scans_list{i});
        parts = split(path, '\');
        sub_id = parts{end-1};
        sess_id = parts{end};
        if mod(i,PP.Snum)==1
           j = j + 1;
        end
        c1ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, ['c1r' T1DataList.filename{j}]);
        c2ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, ['c2r' T1DataList.filename{j}]);
        c3ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, ['c3r' T1DataList.filename{j}]);
        brainToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, 'Brain_mask.nii');
    else
        path = fileparts(scans_list{i});
        parts = split(path, '\');
        sub_id = parts{end};
        c1ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, ['c1r' T1DataList.filename{i}]);
        c2ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, ['c2r' T1DataList.filename{i}]);
        c3ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, ['c3r' T1DataList.filename{i}]);
        brainToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, 'Brain_mask.nii');
    end
end
Parameters.scans_list = scans_list;
Parameters.QCtxt_list = QCtxt_list;
Parameters.c1ToFunList = c1ToFunList;
Parameters.c2ToFunList = c2ToFunList;
Parameters.c3ToFunList = c3ToFunList;
Parameters.brainToFunList = brainToFunList;

end


function tSNR_Calc(Functional4D, QCtxt, Brain_Mask, GM_Mask, WM_Mask)
% tSNR_Calc computes the tSNR (signal-to-noise ratio) of 4D fMRI data
%
% Inputs:
%   Functional4D  - 4D fMRI time series file (.nii)  [required]
%   Brain_Mask    - Whole-brain mask file (.nii)     [optional]
%   GM_Mask       - Gray matter mask file (.nii)     [optional]
%   WM_Mask       - White matter mask file (.nii)    [optional]
%   QCtxt         - Quality control text file path   [optional]
%
% Outputs:
%   tSNR          - Struct containing the following fields:
%       .global      - Global mean tSNR (scalar)
%       .brain       - Mean tSNR within the brain mask (if provided)
%       .GM          - Mean tSNR within the gray matter mask (if provided)
%       .WM          - Mean tSNR within the white matter mask (if provided)
%                     Fields corresponding to masks not provided are NaN

if nargin < 3, Brain_Mask = []; end
if nargin < 4, GM_Mask = []; end
if nargin < 5, WM_Mask = []; end

if isempty(Functional4D) || ~exist(Functional4D, 'file')
    error('Input 4D fMRI data file is not exist：%s', Functional4D);
end


[data_4D, ~, Header] = rp_readfile(Functional4D, 'all'); 

[Ni, Nj, Nk, Nt] = size(data_4D);


F_2D = reshape(data_4D, Ni*Nj*Nk, Nt);


F_2D_mean = mean(F_2D, 2);
F_2D_stddev = std(F_2D, 0, 2);
ratio = F_2D_mean ./ F_2D_stddev;


ratio_3D = reshape(ratio, [Ni, Nj, Nk]);


tSNR.global = nanmean(ratio);


if ~isempty(QCtxt)
    [output_dir, ~, ~] = fileparts(QCtxt);
else
    output_dir = pwd; 
end


global_filename = fullfile(output_dir, 'tSNR_global.nii');
rp_writefile(ratio_3D, global_filename, [Ni, Nj, Nk], [1 1 1], Header, 'float32');


if ~isempty(Brain_Mask) && exist(Brain_Mask, 'file')
    [W_mask, ~, ~] = rp_readfile(Brain_Mask);
    I_W_mask = find(W_mask > 0);
    tSNR.brain = nanmean(ratio(I_W_mask));
    

    brain_tSNR_3D = nan(size(ratio_3D));
    brain_tSNR_3D(I_W_mask) = ratio(I_W_mask);
    brain_filename = fullfile(output_dir, 'tSNR_brain.nii');
    rp_writefile(brain_tSNR_3D, brain_filename, [Ni, Nj, Nk], [1 1 1], Header, 'float32');
else
    tSNR.brain = NaN;
end


if ~isempty(GM_Mask) && exist(GM_Mask, 'file')
    [GM_mask, ~, ~] = rp_readfile(GM_Mask);
    I_GM_mask = find(GM_mask > 0);
    tSNR.GM = nanmean(ratio(I_GM_mask));
    
    
    gm_tSNR_3D = nan(size(ratio_3D));
    gm_tSNR_3D(I_GM_mask) = ratio(I_GM_mask);
    gm_filename = fullfile(output_dir, 'tSNR_GM.nii');
    rp_writefile(gm_tSNR_3D, gm_filename, [Ni, Nj, Nk], [1 1 1], Header, 'float32');
else
    tSNR.GM = NaN;
end


if ~isempty(WM_Mask) && exist(WM_Mask, 'file')
    [WM_mask, ~, ~] = rp_readfile(WM_Mask);
    I_WM_mask = find(WM_mask > 0);
    tSNR.WM = nanmean(ratio(I_WM_mask));
    
    
    wm_tSNR_3D = nan(size(ratio_3D));
    wm_tSNR_3D(I_WM_mask) = ratio(I_WM_mask);
    wm_filename = fullfile(output_dir, 'tSNR_WM.nii');
    rp_writefile(wm_tSNR_3D, wm_filename, [Ni, Nj, Nk], [1 1 1], Header, 'float32');
else
    tSNR.WM = NaN;
end


if ~isempty(QCtxt)
   
     if exist(QCtxt, 'file')
        delete(QCtxt);
    end
    
    
    fid = fopen(QCtxt, 'w');
    if fid == -1
        warning('Can not open QCtxt文件：%s', QCtxt);
    else
        
        if ftell(fid) == 0
            fprintf(fid, 'tSNR_global\ttSNR_brain\ttSNR_GM\ttSNR_WM\n');
        end
        
        fprintf(fid, '%.4f\t%.4f\t%.4f\t%.4f\n', ...
            tSNR.global, tSNR.brain, tSNR.GM, tSNR.WM);
        fclose(fid);
    end
end

end