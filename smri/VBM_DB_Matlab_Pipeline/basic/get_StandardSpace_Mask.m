function Mask_FilePath = get_StandardSpace_Mask(FunPath, Snum, config_list)

Mask_FilePath = '';

% ===== Load One FuncFile =====
SubfodrList = dir_NameList(FunPath);
if isempty(SubfodrList)
    disp(['NO Sub Folders in :' FunPath]); return
end
% Get Nii FilePath
Fun_sub_Path = [FunPath filesep SubfodrList{1}];

if Snum > 1                                                         % ===== Multi-Session =====
    FuncFile = '';
    for sess = 1:Snum
        Fun_sess_Path = [Fun_sub_Path filesep 'S' num2str(sess)];
        if exist(Fun_sess_Path, 'dir')
            DirNII = dir([Fun_sess_Path filesep '*.nii']);
            if isempty(DirNII)
                disp(['NO Nii File in :' Fun_sess_Path]); return
            end
            FuncFile = [Fun_sess_Path filesep DirNII(1).name]; clear DirNII
            clear Fun_sess_Path
            break
        end
        clear Fun_sess_Path
    end; clear sess
    if isempty(FuncFile)
        disp(['NO Nii File in :' Fun_sub_Path]); return
    end
else                                                                      % ===== Single-Session =====
    DirNII = dir([Fun_sub_Path filesep '*.nii']);
    if isempty(DirNII)
        disp(['NO Nii File in :' Fun_sub_Path]); return
    end
    FuncFile = [Fun_sub_Path filesep DirNII(1).name]; clear DirNII
end

% ===== Find Mask =====
% Read Nii
V = spm_vol(FuncFile);
FunDim = V(1).dim;
FunVoxSize = abs([V(1).mat(1, 1), V(1).mat(2, 2), V(1).mat(3, 3)]);
% Find Mask in config_list
if all(FunDim == [61 73 61]) && all(FunVoxSize == [3 3 3])
    Mask_FilePath = config_list.mask.BrainMask_05_61x73x61;
elseif all(FunDim == [91 109 91]) && all(FunVoxSize == [2 2 2])
    Mask_FilePath = config_list.mask.BrainMask_05_91x109x91;
else
    disp('NO Suitable Mask !!! Please Fill "Custom_Mask_File" in Json.');
    disp(['Your Data Dim and Voxel Size are: [' ...
        num2str(FunDim(1)) ' ' num2str(FunDim(2)) ' ' num2str(FunDim(3)) '], ['...
        num2str(FunVoxSize(1)) ' ' num2str(FunVoxSize(2)) ' ' num2str(FunVoxSize(3)) ']']);
end

end

