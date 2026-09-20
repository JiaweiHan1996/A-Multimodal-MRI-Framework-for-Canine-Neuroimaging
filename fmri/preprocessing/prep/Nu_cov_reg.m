function PP = Nu_cov_reg(PP)

fprintf(['\nCovs_Regressing Starting   ||    ' spm('time') '\n']);
[Parameters, PP] = CovsRegress_basisPara(PP);
indir_RegressOutCov(Parameters, PP);
if  PP.Step_C.IsWholeBrain || PP.Step_C.IsCSF || PP.Step_C.IsWhiteMatter || PP.Step_C.IsHeadMotion
    PP = OutputCommPara(PP);
    fprintf(['\nCovs_Regressing Completed   ||    ' spm('time') '\n']);
else
    fprintf('\nAll parameters of Covs_Regressing were 0, Covs_Regressing is not effective!!! \n');
end


end

function [Parameters, PP] = CovsRegress_basisPara(PP)

DataList = PP.DataList;
T1DataList = PP.T1DataList;

if isfield(PP.Step_C,'IsHeadMotion') && PP.Step_C.IsHeadMotion > 0
    if ~isfield(PP, 'RP_Path') || ~exist(PP.RP_Path,"dir")
        fprintf('\nRealignParameter folder is NOT Exist !!! \n');
        return
    end
end
RP_Path = PP.RP_Path;
Para_comm.InDirRealignParameter = RP_Path;

[d, f, ~] = fileparts(PP.FunPath);
FilePath = d;
out_dir_name_Fun = [f 'C'];
Fun_out_Path = [FilePath filesep out_dir_name_Fun];
if exist(Fun_out_Path, 'dir')
    rmdir(Fun_out_Path, 's');
end
mkdir(Fun_out_Path);

% CovariatesParameter
CP_Path = [FilePath filesep 'CovariatesParameter'];
if exist(CP_Path, 'dir')
    rmdir(CP_Path, 's');
end
mkdir(CP_Path);

% Copy data and get scans list
[status, message] = copyfile(PP.FunPath, Fun_out_Path);
if status
    fprintf('\nSuccessfully copied all files from %s to %s\n', PP.FunPath, Fun_out_Path);
else
    fprintf('\n[ERROR] Copy failed: %s\n', message);
end
DataList.FunFolder_Name = out_dir_name_Fun;

scans_list = cell(length(DataList.Sublist), 1);
T1ToFunList = cell(length(DataList.Sublist), 1);
% T1brainToFunList = cell(length(DataList.Sublist), 1);
rT1ToFunList = cell(length(DataList.Sublist), 1);
c1ToFunList = cell(length(DataList.Sublist), 1);
c2ToFunList = cell(length(DataList.Sublist), 1);
c3ToFunList = cell(length(DataList.Sublist), 1);
c2brainToFunList = cell(length(DataList.Sublist), 1);
c3brainToFunList = cell(length(DataList.Sublist), 1);
rc2ToFunList = cell(length(DataList.Sublist), 1);
rc3ToFunList = cell(length(DataList.Sublist), 1);
brainToFunList = cell(length(DataList.Sublist), 1);

% Get mean functional files
MeanFun_List = cell(length(DataList.Sublist), 1);
j=0;
for i = 1:length(DataList.Sublist)
    scans_list{i} = fullfile(DataList.dataroot_path, ...
                                DataList.FunFolder_Name, ...
                                DataList.Sublist{i}, ...
                                DataList.filename{i});

    CPtxt_list{i} = fullfile(CP_Path, DataList.Sublist{i}, 'RegressOut_Covariables.txt');
    json_list{i} = fullfile(DataList.dataroot_path, ...
                                DataList.FunFolder_Name, ...
                                DataList.Sublist{i}, ...
                                DataList.json_name{i});
    % match T1 and meanFun
    [~,FunFolderName,~] = fileparts(PP.FunPath);
    if ~contains(FunFolderName, "W")  %In original space
        % match T1 and meanFun
        if PP.Snum > 1
            
            path = fileparts(scans_list{i});
            parts = split(path, '\');
            sub_id = parts{end-1};
            sess_id = parts{end};
            if mod(i,PP.Snum)==1
               j = j + 1;
            end
            rT1ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, ['r' T1DataList.filename{j}]);
            c1ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, ['c1r' T1DataList.filename{j}]);
            c2ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, ['c2r' T1DataList.filename{j}]);
            c3ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, ['c3r' T1DataList.filename{j}]);
            brainToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, 'Brain_mask.nii');
        else
            path = fileparts(scans_list{i});
            parts = split(path, '\');
            sub_id = parts{end};
            rT1ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, ['r' T1DataList.filename{i}]);
            c1ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, ['c1r' T1DataList.filename{i}]);
            c2ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, ['c2r' T1DataList.filename{i}]);
            c3ToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, ['c3r' T1DataList.filename{i}]);
            brainToFunList{i} = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, 'Brain_mask.nii');
        end
        rc2ToFunList{i} = fullfile(CP_Path, ...
                                    DataList.Sublist{i}, ...
                                    'WMmask_FunSpace.nii');
        rc3ToFunList{i} = fullfile(CP_Path, ...
                                    DataList.Sublist{i}, ...
                                    'CSFmask_FunSpace.nii');
        brainToFunList{i} = fullfile(CP_Path, ...
                                    DataList.Sublist{i}, ...
                                    'Brainmask_FunSpace.nii');

        meanPath = fullfile(RP_Path, DataList.Sublist{i});
        if exist(meanPath, 'dir')
           meanfile = fullfile(meanPath, ['mean' DataList.filename{i}]);
           if exist(meanfile,"file")
                MeanFun_List{i,1} = meanfile;
           else
                scans = fullfile(Fun_out_Path, DataList.Sublist{i},DataList.filename{i});
                % Create mean image in RP directory
                meanfile = fullfile(meanPath,['mean' DataList.filename{i}]);
                MeanCalc(scans, meanfile)
                MeanFun_List{i,1} = meanfile;
           end
        else
            mkdir(meanPath)
            scans = fullfile(Fun_out_Path, DataList.Sublist{i},DataList.filename{i});
            % Create mean image in RP directory
            meanfile = fullfile(meanPath,['mean' DataList.filename{i}]);
            MeanCalc(scans, meanfile)
            MeanFun_List{i,1} = meanfile;
        end
    end
end
Parameters.scans_list = scans_list;
Parameters.json_list = json_list;
Parameters.CPtxt_list = CPtxt_list;
Parameters.MeanFun_List = MeanFun_List;
Parameters.T1ToFunList = T1ToFunList;
% Parameters.T1brainToFunList = T1brainToFunList;
Parameters.c1ToFunList = c1ToFunList;
Parameters.c2ToFunList = c2ToFunList;
Parameters.c3ToFunList = c3ToFunList;
Parameters.c2brainToFunList = c2brainToFunList;
Parameters.c3brainToFunList = c3brainToFunList;
Parameters.rT1ToFunList = rT1ToFunList;
Parameters.rc2ToFunList = rc2ToFunList;
Parameters.rc3ToFunList = rc3ToFunList;
Parameters.brainToFunList = brainToFunList;
PP.MeanFun_List = MeanFun_List;
%%
Para_comm.IsWholeBrain = PP.Step_C.IsWholeBrain;
Para_comm.IsCSF = PP.Step_C.IsCSF;
Para_comm.IsWhiteMatter = PP.Step_C.IsWhiteMatter;
Para_comm.IsHeadMotion = PP.Step_C.IsHeadMotion;
Para_comm.IsOtherCovariatesROI = 0;
Para_comm.ImgCovModel = 4;
Para_comm.IsRemoveIntercept = 1;
Para_comm.PolynomialTrend = 1;


PP.DataList = DataList;
PP.FunPath = Fun_out_Path;
PP.CP_Path = CP_Path;
Parameters.Para_comm = Para_comm;
end

function PP = OutputCommPara(PP)

DataList = PP.DataList;
for i = 1:length(DataList.Sublist)
    subject_dir = fullfile(DataList.dataroot_path, ...
                          DataList.FunFolder_Name, ...
                          DataList.Sublist{i});
    cov_file = fullfile(subject_dir, 'CovRegressed_4DVolume.nii');
    if exist(cov_file, 'file')
        if iscell(DataList.filename)
            old_name = DataList.filename{i};
            new_name = ['c' old_name];
            DataList.filename{i} = new_name;
        else
            old_name = DataList.filename;
            new_name = ['c' old_name];
            DataList.filename = new_name;
        end
        new_file = fullfile(subject_dir, new_name);
        original_file = fullfile(subject_dir, old_name);
        if PP.Step_C.AddMean
            data1 = read_To4d(original_file);
            mean_img = mean(data1, 4);
            [data2, ~, ~, Header, ~] = read_To4d(cov_file);
            result_data = single(data2) + single(mean_img);
            write_To4dNifti(result_data, Header, new_file);
            delete(original_file);
            delete(cov_file);
            clear data1 mean_img data2 result_data 
        else
            if ispc
                system(['move "' cov_file '" "' new_file '"']);
            else
                system(['mv "' cov_file '" "' new_file '"']);
            end
            delete(original_file);
        end
        
    end
    
end

PP.DataList = DataList;

end

function indir_RegressOutCov(Parameters, PP)

for i = 1:length(Parameters.scans_list)                                                        
    Cov_sub_Path = fullfile(PP.CP_Path, PP.DataList.Sublist{i});
    Fun_sub_Path = fullfile(PP.FunPath, PP.DataList.Sublist{i});
    Parameters.Para_comm.CovariablesTextfilepath = Parameters.CPtxt_list{i};
    [~,FunFolderName,~] = fileparts(PP.FunPath);
    if contains(FunFolderName, "W")  %In MNI space
        ReslicedMaskPath = Reslice_DefaultMask(Fun_sub_Path, Cov_sub_Path, PP);
    else %In Original space
        ReslicedMaskPath = Reslice_DefaultMask(Fun_sub_Path, Cov_sub_Path, PP, Parameters.rT1ToFunList{i},...
            Parameters.c1ToFunList{i}, Parameters.c2ToFunList{i}, Parameters.c3ToFunList{i}, ...
            Parameters.rc2ToFunList{i}, Parameters.rc3ToFunList{i}, Parameters.brainToFunList{i});
    end
    if ~isempty(ReslicedMaskPath)
        CovariatesROIList = Generate_CovROIlist(Parameters.Para_comm, ReslicedMaskPath);
    else
        CovariatesROIList = [];
    end
    out_CovariablesTextfilepath(Fun_sub_Path, Cov_sub_Path, PP.DataList.Sublist{i}, CovariatesROIList, Parameters.Para_comm);
  
end; clear i;
clear ReslicedMaskPath CovariatesROIList
clear Fun_sub_Path Cov_sub_Path
%%
if  PP.Step_C.IsWholeBrain || PP.Step_C.IsCSF || PP.Step_C.IsWhiteMatter || PP.Step_C.IsHeadMotion
    parfor i = 1:length(Parameters.scans_list)   
        Cov_sub_Path = fullfile(PP.CP_Path, PP.DataList.Sublist{i});
        Fun_sub_Path = fullfile(PP.FunPath, PP.DataList.Sublist{i});
        CovariablesTextfilepath = Parameters.CPtxt_list{i};    
        infodr_RegressOutCov(Fun_sub_Path, [PP.FunPath filesep PP.DataList.Sublist{i}], '', CovariablesTextfilepath);
    end
    clear i;clear CovariablesTextfilepath
end

end


%%
function ReslicedMaskPath = Reslice_DefaultMask(Fun_Indir, Cov_OutDir, PP, rT1ToFun, ...
    c1ToFun, c2ToFun, c3ToFun, rc2ToFun, rc3ToFun, brainToFun)

TargetSpace = inpath_Misc(Fun_Indir, 'Get1stSubImgPath');
[~, NewVoxSize, ~] = read_To3d(TargetSpace, 1);
mkdir(Cov_OutDir);

if nargin == 3  %In MNI space
    DefaultmaskList1 = {PP.Config_INFO.Mask.Brain, ...
        PP.Config_INFO.Mask.CSF, ...
        PP.Config_INFO.Mask.WM};
    maskList = DefaultmaskList1;
else     %In Original space
    if exist(rT1ToFun, 'file') == 2
        maskList = OriSpaceMaskGen(c1ToFun, c2ToFun, c3ToFun, rc2ToFun, rc3ToFun, brainToFun);
    else
        fprintf('\nWarning: "Covs_Regressing" before "Normalize!"\n');
        fprintf('Tissue segmentation results from T1w image not detected!\n');
        maskList = [];
    end
end

hld = 1;
if ~isempty(maskList)
    for i = 1:length(maskList)
        [~, mask_name, ~] = fileparts(maskList{i});
        reslice_Image(maskList{i}, ...
            [Cov_OutDir filesep 'Resampled_' mask_name '.nii'], ...
            NewVoxSize, hld, TargetSpace);
        clear mask_name
    end
    [~, mask_name, ~] = fileparts(maskList{1});
    ReslicedMaskPath.BrainMask=[Cov_OutDir filesep 'Resampled_' mask_name '.nii']; clear mask_name
    [~, mask_name, ~] = fileparts(maskList{2});
    ReslicedMaskPath.CsfMask=[Cov_OutDir filesep 'Resampled_' mask_name '.nii']; clear mask_name
    [~, mask_name, ~] = fileparts(maskList{3});
    ReslicedMaskPath.WhiteMask=[Cov_OutDir filesep 'Resampled_' mask_name '.nii']; clear mask_name
else
    ReslicedMaskPath = [];
end
end

%%
function CovROI = Generate_CovROIlist(Parameter, ReslicedMaskPath)
    CovROI=[];
    
    if isfield(Parameter,'IsWholeBrain')&&(1==Parameter.IsWholeBrain)
       CovROI=[CovROI;{ReslicedMaskPath.BrainMask}];
    end
    
    if isfield(Parameter,'IsCSF')&&(1==Parameter.IsCSF)
       CovROI=[CovROI;{ReslicedMaskPath.CsfMask}];
    end
    
    if isfield(Parameter,'IsWhiteMatter')&&(1==Parameter.IsWhiteMatter)
       CovROI=[CovROI;{ReslicedMaskPath.WhiteMask}];
    end
    
    if isfield(Parameter,'IsOtherCovariatesROI')&&(1==Parameter.IsOtherCovariatesROI)
       CovROI=[CovROI;Parameter.OtherCovariatesROIList]; 
    end

    
end

%%
function out_CovariablesTextfilepath(Fun_data_Path, Cov_out_Path, SubfodrNam, CovariatesROIList, Parameter)
        if (Parameter.IsHeadMotion == 1)
            rp_file = [Parameter.InDirRealignParameter filesep SubfodrNam filesep 'rp*'];
            Rpfile = inpath_Misc(rp_file,'Get1SubPath_RegExp');
            RpCovariablesMat=load(Rpfile);
            RPCovMat = RpCovariablesMat;
        elseif (Parameter.IsHeadMotion == 2)
            rp_file = [Parameter.InDirRealignParameter filesep SubfodrNam filesep 'rp*'];
            Rpfile = inpath_Misc(rp_file,'Get1SubPath_RegExp');
            RpCovariablesMat=load(Rpfile);
            RPCovMat = [RpCovariablesMat, [zeros(1,size(RpCovariablesMat,2));RpCovariablesMat(1:end-1,:)]];
        elseif (Parameter.IsHeadMotion == 3)
            rp_file = [Parameter.InDirRealignParameter filesep SubfodrNam filesep 'rp*'];
            Rpfile = inpath_Misc(rp_file,'Get1SubPath_RegExp');
            RpCovariablesMat=load(Rpfile);
            RPCovMat = [RpCovariablesMat,  RpCovariablesMat.^2];
        elseif (Parameter.IsHeadMotion == 4)
            rp_file = [Parameter.InDirRealignParameter filesep SubfodrNam filesep 'rp*'];
            Rpfile = inpath_Misc(rp_file,'Get1SubPath_RegExp');
            RpCovariablesMat=load(Rpfile);
            RPCovMat = [RpCovariablesMat, [zeros(1,size(RpCovariablesMat,2));RpCovariablesMat(1:end-1,:)], RpCovariablesMat.^2, [zeros(1,size(RpCovariablesMat,2));RpCovariablesMat(1:end-1,:)].^2];
        else
            RPCovMat=[];
        end

        if ~isempty(CovariatesROIList)
            Signal_Matrix = Extract_ROISignal(Fun_data_Path, CovariatesROIList,...
                                        [Cov_out_Path filesep 'Covariates']);  
        end
        if ~isempty(CovariatesROIList)
            CovTC=load([Cov_out_Path filesep 'ROISignals_Covariates.txt']);
            CovariablesMatrix=[RPCovMat, CovTC];
        else
            CovariablesMatrix=RPCovMat;
        end
        
        save(Parameter.CovariablesTextfilepath, 'CovariablesMatrix', '-ASCII', '-DOUBLE','-TABS');

end

