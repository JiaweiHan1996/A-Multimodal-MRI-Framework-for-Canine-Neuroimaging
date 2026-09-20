function PP = Normalize_DARTEL(PP)

fprintf(['\nNormalize with DARTEL Starting   ||    ' spm('time') '\n']);
PP = InputCommPara(PP); 


NormalizeDartel_Parameters = NormalizeDartel_basisPara(PP);
matlabbatch = SpmBatch2dartel(NormalizeDartel_Parameters);
spm_jobman('run', matlabbatch);
clear matlabbatch
MoveDartelTemplates(PP);


matlabbatch = SpmBatch2dartel_normalize(NormalizeDartel_Parameters);
parfor i=1:length(matlabbatch)
    current_batch = matlabbatch(i);
    spm_jobman('run', current_batch);
    if exist(NormalizeDartel_Parameters.scans_list{i}, 'file')
        delete(NormalizeDartel_Parameters.scans_list{i});
    else
        fprintf('\n[ERROR] Processed file not found: %s\n', NormalizeDartel_Parameters.scans_list{i});
    end 
end
clear matlabbatch current_batch
PP = OutputCommPara(PP);
fprintf(['\nNormalize with DARTEL Completed   ||    ' spm('time') '\n']);

end

function PP = InputCommPara(PP)



DataList = PP.DataList;
FunPath = PP.FunPath;
if ~isfield(PP, 'RP_Path')
    fprintf('\nError: RealignParameter Folder not exist\n');
    return
end

[d, f, ~] = fileparts(PP.FunPath);
FilePath = d;
out_dir_name_Fun = [f 'W'];
Fun_out_Path = [FilePath filesep out_dir_name_Fun];
if exist(Fun_out_Path, 'dir')
    rmdir(Fun_out_Path, 's');
end
mkdir(Fun_out_Path);

[status, message] = copyfile(FunPath, Fun_out_Path);
if status
    fprintf('\nCopied files from %s to %s\n', FunPath, Fun_out_Path);
else
    fprintf('\nCopy failed: %s\n', message);
end

DataList.FunFolder_Name = out_dir_name_Fun;

% Check if T1 data exists
if strcmp(PP.T1Path, ' ')
    T1DataList = struct();
    fprintf('No T1 data available.\n');
    return;
else
    T1DataList = T1DataList_sort(PP);
end


% Update Sublist if Enum > 1
if isfield(PP, 'Enum') && PP.Enum > 1
    updatedSublist = regexprep(DataList.Sublist, [filesep 'Echo\d+$'], '');
    DataList.Sublist = unique(updatedSublist, 'stable');
end

% Get mean functional files
MeanFun_List = {};
RP_Path = [FilePath filesep 'RealignParameter'];
if ~exist(RP_Path,"dir")
    mkdir(RP_Path)
end
for i = 1:length(DataList.Sublist)
    meanPath = fullfile(RP_Path, DataList.Sublist{i});
    if exist(meanPath, 'dir')
       meanfile = fullfile(meanPath, ['mean' DataList.filename{i}]);
       if exist(meanfile,"file")
            MeanFun_List{end+1,1} = meanfile;
       else
            scans = fullfile(Fun_out_Path, DataList.Sublist{i},DataList.filename{i});
            % Create mean image in RP directory
            meanfile = fullfile(meanPath,['mean' DataList.filename{i}]);
            MeanCalc(scans, meanfile)
            MeanFun_List{end+1,1} = meanfile;
       end
    else
        mkdir(meanPath)
        scans = fullfile(Fun_out_Path, DataList.Sublist{i},DataList.filename{i});
        % Create mean image in RP directory
        meanfile = fullfile(meanPath,['mean' DataList.filename{i}]);
        MeanCalc(scans, meanfile)
        MeanFun_List{end+1,1} = meanfile;
    end
end
PP.MeanFun_List = MeanFun_List;

% Update PP structure
if ~isfield(PP, 'RefEcho_Para')
    PP.RefEcho_Para = struct();
end
PP.RefEcho_Para.MeanFun_List = MeanFun_List;
PP.DataList = DataList;
PP.FunPath = Fun_out_Path;
PP.T1Path = T1DataList.T1Folder_Name;
PP.T1DataList = T1DataList;

end

function PP = OutputCommPara(PP)
%% Post-processing common parameters after slice timing correction
% Update filenames and other parameters after slice timing computation

DataList = PP.DataList;

for i = 1:length(DataList.filename)
    if ischar(DataList.filename{i}) && ~isempty(DataList.filename{i})
        DataList.filename{i} = ['sw' DataList.filename{i}];
    end
end

% Update PP structure
PP.DataList = DataList;

end


function Parameters = NormalizeDartel_basisPara(PP)
% NormalizeDartel_basisPara - Create normalization parameters structure for Dartel

Parameters = struct();
Parameters.ResVoxelSize = PP.Step_W.ResVoxelSize;
DataList = PP.DataList;

% 1. scans_list
scans_list = cell(length(DataList.Sublist), 1);
for i = 1:length(DataList.Sublist)
    scans_list{i} = fullfile(DataList.dataroot_path, ...
                            DataList.FunFolder_Name, ...
                            DataList.Sublist{i}, ...
                            DataList.filename{i});
end
Parameters.scans_list = scans_list;

% 2. MeanFun_List
Parameters.MeanFun_List = PP.RefEcho_Para.MeanFun_List;

% 3. rc1T1_list - organized as cell array for Dartel
rc1T1_list = cell(length(PP.T1DataList.Sublist), 1);
for i = 1:length(PP.T1DataList.Sublist)
    [~, name, ext] = fileparts(PP.T1DataList.filename{i});
    rc1T1_list{i} = fullfile(DataList.dataroot_path, ...
                            PP.T1DataList.T1Folder_Name, ...
                            PP.T1DataList.Sublist{i}, ...
                            ['rc1r' name ext]);
end
Parameters.rc1T1_list = rc1T1_list;

% 4. rc2T1_list - organized as cell array for Dartel
rc2T1_list = cell(length(PP.T1DataList.Sublist), 1);
for i = 1:length(PP.T1DataList.Sublist)
    [~, name, ext] = fileparts(PP.T1DataList.filename{i});
    rc2T1_list{i} = fullfile(DataList.dataroot_path, ...
                            PP.T1DataList.T1Folder_Name, ...
                            PP.T1DataList.Sublist{i}, ...
                            ['rc2r' name ext]);
end
Parameters.rc2T1_list = rc2T1_list;


Parameters.template_path = fullfile(PP.QC_Path, 'TemplatesFromDartel', 'Template_6.nii');

% 5. flowfield_list - original list
flowfield_list = cell(length(PP.T1DataList.Sublist), 1);
for i = 1:length(PP.T1DataList.Sublist)
    [~, name, ext] = fileparts(PP.T1DataList.filename{i});
    flowfield_list{i} = fullfile(DataList.dataroot_path, ...
                                PP.T1DataList.T1Folder_Name, ...
                                PP.T1DataList.Sublist{i}, ...
                                ['u_rc1r' name '_Template' ext]);
end
Parameters.flowfield_list = flowfield_list;


if PP.Snum > 1
    flowfieldforFun_list = cell(length(scans_list), 1);
    for i = 1:length(scans_list)
        
        current_full_sub = PP.DataList.Sublist{i};
        
    
        if contains(current_full_sub, filesep)
            pathParts = strsplit(current_full_sub, filesep);
            subID = pathParts{1};  
        else
            subID = current_full_sub;
        end
        
        % 查找匹配的T1数据
        t1Idx = find(contains(PP.T1DataList.Sublist, subID), 1);
        if ~isempty(t1Idx)
            flowfieldforFun_list{i} = flowfield_list{t1Idx};
        else
            flowfieldforFun_list{i} = '';
        end
    end
    Parameters.flowfieldforFun_list = flowfieldforFun_list;
else
    Parameters.flowfieldforFun_list = Parameters.flowfield_list;
end

end


%% DARTEL Warp for New Segment (6 tissues)
function matlabbatch = SpmBatch2dartel(Parameters)
    images = {
        cellstr(Parameters.rc1T1_list)
        cellstr(Parameters.rc2T1_list)
    };
    matlabbatch{1}.spm.tools.dartel.warp.images = images;
    matlabbatch{1}.spm.tools.dartel.warp.settings.template = 'Template';
    matlabbatch{1}.spm.tools.dartel.warp.settings.rform = 0;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).rparam = [4 2 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).K = 0;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(1).slam = 16;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).rparam = [2 1 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).K = 0;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(2).slam = 8;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).rparam = [1 0.5 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).K = 1;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(3).slam = 4;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).rparam = [0.5 0.25 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).K = 2;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(4).slam = 2;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).rparam = [0.25 0.125 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).K = 4;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(5).slam = 1;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).its = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).rparam = [0.25 0.125 1e-06];
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).K = 6;
    matlabbatch{1}.spm.tools.dartel.warp.settings.param(6).slam = 0.5;
    matlabbatch{1}.spm.tools.dartel.warp.settings.optim.lmreg = 0.01;
    matlabbatch{1}.spm.tools.dartel.warp.settings.optim.cyc = 3;
    matlabbatch{1}.spm.tools.dartel.warp.settings.optim.its = 3;
end

function MoveDartelTemplates(PP)
    % Create TemplatesFromDartel directory in QC folder
    templates_dir = fullfile(PP.QC_Path, 'TemplatesFromDartel');
    if ~exist(templates_dir, 'dir')
        mkdir(templates_dir);
    end
    
    % First subject's directory
    first_sub_dir = fullfile(PP.DataList.dataroot_path, ...
                            PP.T1DataList.T1Folder_Name, ...
                            PP.T1DataList.Sublist{1});
    
    % Move all 6 template files
    for i = 1:6
        src_file = fullfile(first_sub_dir, ['Template_' num2str(i) '.nii']);
        if exist(src_file, 'file')
            movefile(src_file, templates_dir);
            fprintf('Moved: Template_%d.nii\n', i);
        end
    end
    
    fprintf('Dartel templates moved to: %s\n', templates_dir);
end
%% DARTEL Normalize
function matlabbatch = SpmBatch2dartel_normalize(Parameters)
for i = 1:length(Parameters.scans_list)
    matlabbatch{i}.spm.tools.dartel.mni_norm.template = cellstr(Parameters.template_path);
    matlabbatch{i}.spm.tools.dartel.mni_norm.data.subj.flowfield = cellstr(Parameters.flowfieldforFun_list{i});
    matlabbatch{i}.spm.tools.dartel.mni_norm.data.subj.images = cellstr(Parameters.scans_list{i});
    if isempty(Parameters.ResVoxelSize)
        [~,Parameters.ResVoxelSize, ~]=rp_readfile(Parameters.scans_list{i},1);
    end
    matlabbatch{i}.spm.tools.dartel.mni_norm.vox = Parameters.ResVoxelSize;
    matlabbatch{i}.spm.tools.dartel.mni_norm.bb = [-90 -126 -72; 90 90 108];
    matlabbatch{i}.spm.tools.dartel.mni_norm.preserve = 0;
    matlabbatch{i}.spm.tools.dartel.mni_norm.fwhm = [4 4 4];
end
end