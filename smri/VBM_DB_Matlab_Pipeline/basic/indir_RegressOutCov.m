function indir_RegressOutCov(Fun_Indir, Fun_Outdir, Cov_OutDir, Parameter, config_list, Snum)
%% update: 20250928
%Parameter.IsWholeBrain
%Parameter.IsCSF
%Parameter.IsWhiteMatter
%Parameter.IsHeadMotion_Rigidbody6
%Parameter.IsOtherCovariatesROI
%Parameter.IsRemoveIntercept
%Parameter.PolynomialTrend
%Parameter.InDirRealignParameter
%Parameter.OtherCovariatesROIList
%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201502
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com
%   fixed bug line about Parameter.CovariablesTextfilepath 170201 by jiaxize

    inpath_Misc(Fun_Outdir, 'MakeCurrentDir');
    inpath_Misc(Cov_OutDir, 'MakeCurrentDir');

    SubfodrList = dir_NameList(Fun_Indir);
    
    %%
    for i = 1:length(SubfodrList)
        Fun_sub_Path = [Fun_Indir filesep SubfodrList{i}];
        Cov_sub_Path = [Cov_OutDir filesep SubfodrList{i}];
        
        if Snum > 1                                                     % ===== Multi-Session =====
            for sess = 1:Snum
                Fun_sess_Path = [Fun_sub_Path filesep 'S' num2str(sess)];
                Cov_sess_Path = [Cov_sub_Path filesep 'S' num2str(sess)];
                if ~exist(Fun_sess_Path, 'dir')
                    clear Fun_sess_Path Cov_sess_Path
                    continue
                end
                
                Parameter.CovariablesTextfilepath = [Cov_sess_Path filesep 'RegressOut_Covariables.txt'];
                ReslicedMaskPath = Reslice_DefaultMask(Fun_sess_Path, Cov_sess_Path, config_list);
                CovariatesROIList = Generate_CovROIlist(Parameter, ReslicedMaskPath);
                out_CovariablesTextfilepath(Fun_sess_Path, Cov_sess_Path, ...
                    [SubfodrList{i} filesep 'S' num2str(sess)], CovariatesROIList, Parameter);
                clear ReslicedMaskPath CovariatesROIList
                
                clear Fun_sess_Path Cov_sess_Path
            end
            
        else                                                                 % ===== Single-Session =====
            Parameter.CovariablesTextfilepath = [Cov_sub_Path filesep 'RegressOut_Covariables.txt'];
            ReslicedMaskPath = Reslice_DefaultMask(Fun_sub_Path, Cov_sub_Path, config_list);
            CovariatesROIList = Generate_CovROIlist(Parameter, ReslicedMaskPath);
            out_CovariablesTextfilepath(Fun_sub_Path, Cov_sub_Path, SubfodrList{i}, CovariatesROIList, Parameter);
            clear ReslicedMaskPath CovariatesROIList
        end

        clear Fun_sub_Path Cov_sub_Path
    end; clear i

    %%
    for i = 1:length(SubfodrList)
        Fun_sub_Path = [Fun_Indir filesep SubfodrList{i}];
        Cov_sub_Path = [Cov_OutDir filesep SubfodrList{i}];

        if Snum > 1                                                     % ===== Multi-Session =====
            for sess = 1:Snum
                Fun_sess_Path = [Fun_sub_Path filesep 'S' num2str(sess)];
                Cov_sess_Path = [Cov_sub_Path filesep 'S' num2str(sess)];
                if ~exist(Fun_sess_Path, 'dir')
                    clear Fun_sess_Path Cov_sess_Path
                    continue
                end
                
                CovariablesTextfilepath = [Cov_sess_Path filesep 'RegressOut_Covariables.txt'];
                infodr_RegressOutCov(Fun_sess_Path, ...
                                    [Fun_Outdir filesep SubfodrList{i} filesep 'S' num2str(sess)], ...
                                    '', Parameter, CovariablesTextfilepath);
                % Copy Json
                DirJson = dir([Fun_sess_Path filesep '*.json']);
                Json_Path = [Fun_sess_Path filesep DirJson(1).name];
                copyfile(Json_Path, [Fun_Outdir filesep SubfodrList{i} filesep 'S' num2str(sess)]);
                                
                 clear CovariablesTextfilepath
            end
            
        else                                                                 % ===== Single-Session =====
            CovariablesTextfilepath = [Cov_sub_Path filesep 'RegressOut_Covariables.txt'];
            infodr_RegressOutCov(Fun_sub_Path, [Fun_Outdir filesep SubfodrList{i}], ...
                                  '', Parameter, CovariablesTextfilepath);
            % Copy Json
            DirJson = dir([Fun_sub_Path filesep '*.json']);
            Json_Path = [Fun_sub_Path filesep DirJson(1).name];
            copyfile(Json_Path, [Fun_Outdir filesep SubfodrList{i}]);
            
            clear CovariablesTextfilepath DirJson Json_Path
        end
        
        clear Fun_sub_Path
    end; clear i

end

%%
function ReslicedMaskPath = Reslice_DefaultMask(Fun_Indir, Cov_OutDir, config_list)

[D,F,E] = fileparts(Fun_Indir);
TargetSpace = inpath_Misc(Fun_Indir, 'Get1stSubImgPath');
[Outdata, NewVoxSize, Header] = read_To3d(TargetSpace, 1);
hld = 1;

DefaultmaskList1 = {config_list.mask.BrainMask_05_91x109x91, ...
    config_list.mask.CsfMask_07_91x109x91, ...
    config_list.mask.WhiteMask_09_91x109x91};
% DefaultmaskList2 = {config_list.mask.BrainMask_05_61x73x61, ...
%     config_list.mask.CsfMask_07_61x73x61, ...
%     config_list.mask.WhiteMask_09_61x73x61};

% if NewVoxSize(1) == 2
%     DefaultmaskList = DefaultmaskList1;
% else
%     DefaultmaskList = DefaultmaskList2;
% end
if NewVoxSize(1) == 2
    DefaultmaskList = DefaultmaskList1;
end

mkdir(Cov_OutDir);
for i = 1:length(DefaultmaskList)
    [~, mask_name, ~] = fileparts(DefaultmaskList{i});
    reslice_Image(DefaultmaskList{i}, ...
        [Cov_OutDir filesep 'Resampled_' mask_name '.nii'], ...
        NewVoxSize, hld, TargetSpace);
    clear mask_name
end

[~, mask_name, ~] = fileparts(DefaultmaskList{1});
ReslicedMaskPath.BrainMask=[Cov_OutDir filesep 'Resampled_' mask_name '.nii']; clear mask_name
[~, mask_name, ~] = fileparts(DefaultmaskList{2});
ReslicedMaskPath.CsfMask=[Cov_OutDir filesep 'Resampled_' mask_name '.nii']; clear mask_name
[~, mask_name, ~] = fileparts(DefaultmaskList{3});
ReslicedMaskPath.WhiteMask=[Cov_OutDir filesep 'Resampled_' mask_name '.nii']; clear mask_name

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
    
%     if isfield(Parameter,'IsOtherCovariatesROI')&&(1==Parameter.IsOtherCovariatesROI)
%        CovROI=[CovROI;Parameter.OtherCovariatesROIList]; 
%     end

    
end

%%
function out_CovariablesTextfilepath(Fun_data_Path, Cov_out_Path, SubfodrNam, CovariatesROIList, Parameter)
% SubfodrNam = 'Sub_01'
% SubfodrNam = ['Sub_01' filesep 'S1']

        Signal_Matrix = Extract_ROISignal(Fun_data_Path, CovariatesROIList,...
                                        [Cov_out_Path filesep 'Covariates']);
                                
        if (Parameter.IsHeadMotion_Rigidbody6 == 1)
            Rpfile = inpath_Misc([Parameter.InDirRealignParameter filesep SubfodrNam filesep 'rp*'],...
                               'Get1SubPath_RegExp');
            RpCovariables=load(Rpfile);
        else
            RpCovariables=[];
        end
        
        
        if ~isempty(CovariatesROIList)
            CovTC=load([Cov_out_Path filesep 'ROISignals_Covariates.txt']);
            CovariablesMatrix=[RpCovariables, CovTC];
        else
            CovariablesMatrix=RpCovariables;
        end
        
        save(Parameter.CovariablesTextfilepath, 'CovariablesMatrix', '-ASCII', '-DOUBLE','-TABS');

end
