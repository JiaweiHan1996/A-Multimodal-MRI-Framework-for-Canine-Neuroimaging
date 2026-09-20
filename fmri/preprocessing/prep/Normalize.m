function PP = Normalize(PP)

fprintf(['\nNormalize Starting   ||    ' spm('time') '\n']);
PP = InputCommPara(PP); 


Parameters_Normalize = Normalize_basisPara(PP);
if isfield(PP, 'IsOld_Segment') && PP.IsOld_Segment == 1
    matlabbatch = SpmBatch2normalize_old_Fun(Parameters_Normalize, PP.Config_INFO.Template);   
    parfor i = 1:length(matlabbatch)
        current_batch = matlabbatch(i);
        spm_jobman('run', current_batch);
        if exist(Parameters_Normalize.scans_list{i}, 'file')
            delete(Parameters_Normalize.scans_list{i});
        else
            fprintf('\n[ERROR] Processed file not found: %s\n', output_file);
        end
    end
    clear matlabbatch current_batch
else
    matlabbatch = SpmBatch2normalize_Fun(Parameters_Normalize, PP.Config_INFO.Template);   
    parfor i = 1:length(matlabbatch)
        current_batch = matlabbatch(i);
        spm_jobman('run', current_batch);
        if exist(Parameters_Normalize.scans_list{i}, 'file')
            delete(Parameters_Normalize.scans_list{i});
        else
            fprintf('\n[ERROR] Processed file not found: %s\n', output_file);
        end
    end
    clear matlabbatch current_batch
end


PP = OutputCommPara(PP);
fprintf(['\nNormalize Completed   ||    ' spm('time') '\n']);

end

function PP = InputCommPara(PP)
% InputCommPara - Prepare common parameters before calculation

DataList = PP.DataList;
FunPath = PP.FunPath;

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
       if DataList.filename{i}(1) == 'c'
           filename = DataList.filename{i}(2:end);
       else
           filename = DataList.filename{i};
       end
       meanfile = fullfile(meanPath, ['mean' filename]);
       if exist(meanfile,"file")
            MeanFun_List{end+1,1} = meanfile;
       else
            if DataList.filename{i}(1) == 'c'
                 filename = DataList.filename{i}(2:end);
            end
            scans = fullfile(FunPath(1:end-1), DataList.Sublist{i},filename);
            % Create mean image in RP directory
            meanfile = fullfile(meanPath,['mean' filename]);
            MeanCalc(scans, meanfile)
            MeanFun_List{end+1,1} = meanfile;
       end
    else
        mkdir(meanPath)
        if DataList.filename{i}(1) == 'c'
             filename = DataList.filename{i}(2:end);
        end
        scans = fullfile(FunPath(1:end-1), DataList.Sublist{i},filename);
        % Create mean image in RP directory
        meanfile = fullfile(meanPath,['mean' DataList.filename{i}]);
        MeanCalc(scans, meanfile)
        MeanFun_List{end+1,1} = meanfile;
    end
end
PP.MeanFun_List = MeanFun_List;
PP.DataList = DataList;
PP.FunPath = Fun_out_Path;
end

function PP = OutputCommPara(PP)
% Update filenames and other parameters after Normalize

DataList = PP.DataList;
for i = 1:length(DataList.filename)
    if ischar(DataList.filename{i}) && ~isempty(DataList.filename{i})
        DataList.filename{i} = ['w' DataList.filename{i}];
    end
end


% Update PP structure
PP.DataList = DataList;

end


function Parameters = Normalize_basisPara(PP)
% Normalize_basisPara - Create normalization parameters structure

Parameters = struct();
Parameters.ResVoxelSize = PP.Step_W.ResVoxelSize;
DataList = PP.DataList;
T1DataList = PP.T1DataList;
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
Parameters.MeanFun_List = PP.MeanFun_List;

% Check if T1 data exists
if ~isfield(PP, 'T1DataList') || isempty(PP.T1DataList) || ~isfield(PP.T1DataList, 'Sublist')
    % No T1 data available, return early
    return;
end

j=0;
snMat_list = cell(length(Parameters.scans_list), 1);
if isfield(PP, 'IsOld_Segment') && PP.IsOld_Segment == 1
    if isfield(PP, 'Step_W') && isfield(PP.Step_W, 'IsT1_BET') && PP.Step_W.IsT1_BET == 1
        % 3. snMat_list with BET
        for i = 1:length(Parameters.scans_list)
            if PP.Snum > 1
                path = fileparts(scans_list{i});
                parts = split(path, '\');
                sub_id = parts{end-1};
                sess_id = parts{end};
                if mod(i,PP.Snum)==1
                   j = j + 1;
                end
                [~, name, ~] = fileparts(PP.T1DataList.filename{j});
                snMat_list{i} = fullfile(DataList.dataroot_path, ...
                                        T1DataList.T1Folder_Name, ...
                                        sub_id, sess_id, ['r' name '_brain_seg_sn.mat']);
            else
                path = fileparts(scans_list{i});
                parts = split(path, '\');
                sub_id = parts{end};
                [~, name, ~] = fileparts(PP.T1DataList.filename{i});
                snMat_list{i} = fullfile(DataList.dataroot_path, ...
                                        T1DataList.T1Folder_Name, ...
                                        sub_id, ['r' name '_brain_seg_sn.mat']);
            end
        end
        
    else
        % 3. snMat_list
        for i = 1:length(Parameters.scans_list)
            if PP.Snum > 1
                path = fileparts(scans_list{i});
                parts = split(path, '\');
                sub_id = parts{end-1};
                sess_id = parts{end};
                if mod(i,PP.Snum)==1
                   j = j + 1;
                end
                [~, name, ~] = fileparts(PP.T1DataList.filename{j});
                snMat_list{i} = fullfile(DataList.dataroot_path, ...
                                        T1DataList.T1Folder_Name, ...
                                        sub_id, sess_id, ['r' name '_seg_sn.mat']);
            else
                path = fileparts(scans_list{i});
                parts = split(path, '\');
                sub_id = parts{end};
                [~, name, ~] = fileparts(PP.T1DataList.filename{i});
                snMat_list{i} = fullfile(DataList.dataroot_path, ...
                                        T1DataList.T1Folder_Name, ...
                                        sub_id, ['r' name '_seg_sn.mat']);
            end
        end
    end
    Parameters.snMat_list = snMat_list;        
else
    j=0;
    % 4. yT1_list
    yT1_list = cell(length(Parameters.scans_list), 1);
    for i = 1:length(Parameters.scans_list)
        if PP.Snum > 1
            path = fileparts(scans_list{i});
            parts = split(path, '\');
            sub_id = parts{end-1};
            sess_id = parts{end};
            if mod(i,PP.Snum)==1
               j = j + 1;
            end
            [~, name, ext] = fileparts(PP.T1DataList.filename{j});
            yT1_list{i} = fullfile(DataList.dataroot_path, ...
                                    T1DataList.T1Folder_Name, ...
                                    sub_id, sess_id, ['y_r' name ext]);
        else
            path = fileparts(scans_list{i});
            parts = split(path, '\');
            sub_id = parts{end};
            [~, name, ext] = fileparts(PP.T1DataList.filename{i});
            yT1_list{i} = fullfile(DataList.dataroot_path, ...
                                    T1DataList.T1Folder_Name, ...
                                    sub_id, ['y_r' name ext]);
        end
        Parameters.yT1_list = yT1_list;
    end
end

% mT1_list
j=0;
mT1_list = cell(length(Parameters.scans_list), 1);
if isfield(PP, 'Step_W') && isfield(PP.Step_W, 'IsT1_BET') && PP.Step_W.IsT1_BET == 1
    % 3. mT1_list with BET
    for i = 1:length(Parameters.scans_list)
        if PP.Snum > 1
            path = fileparts(scans_list{i});
            parts = split(path, '\');
            sub_id = parts{end-1};
            sess_id = parts{end};
            if mod(i,PP.Snum)==1
               j = j + 1;
            end
            [~, name, ext] = fileparts(PP.T1DataList.filename{j});
            mT1_list{i} = fullfile(DataList.dataroot_path, ...
                                    T1DataList.T1Folder_Name, ...
                                    sub_id, sess_id,['mr' name '_brain' ext]);
        else
            path = fileparts(scans_list{i});
            parts = split(path, '\');
            sub_id = parts{end};
            [~, name, ext] = fileparts(PP.T1DataList.filename{i});
            mT1_list{i} = fullfile(DataList.dataroot_path, ...
                                    T1DataList.T1Folder_Name, ...
                                    sub_id, ['mr' name '_brain' ext]);
        end
    end
else
    j=0;
    % 3. mT1_list
    for i = 1:length(Parameters.scans_list)
        if PP.Snum > 1
            path = fileparts(scans_list{i});
            parts = split(path, '\');
            sub_id = parts{end-1};
            sess_id = parts{end};
            if mod(i,PP.Snum)==1
               j = j + 1;
            end
            [~, name, ext] = fileparts(PP.T1DataList.filename{j});
            mT1_list{i} = fullfile(DataList.dataroot_path, ...
                                    T1DataList.T1Folder_Name, ...
                                    sub_id, sess_id, ['mr' name ext]);
        else
            path = fileparts(scans_list{i});
            parts = split(path, '\');
            sub_id = parts{end};
            [~, name, ext] = fileparts(PP.T1DataList.filename{i});
            mT1_list{i} = fullfile(DataList.dataroot_path, ...
                                    T1DataList.T1Folder_Name, ...
                                    sub_id, ['mr' name ext]);
        end
    end
end
Parameters.mT1_list = mT1_list;
end



%% New Normalize 
function matlabbatch = SpmBatch2normalize_Fun(Parameters, Template)
for i =1:length(Parameters.scans_list)
    matlabbatch{i}.spm.spatial.normalise.write.subj.def = cellstr(Parameters.yT1_list{i});
    matlabbatch{i}.spm.spatial.normalise.write.subj.resample = cellstr(Parameters.scans_list{i});
    BB = round(spm_get_bbox(Template));
    matlabbatch{i}.spm.spatial.normalise.write.roptions.bb = BB;
    % if isempty(Parameters.ResVoxelSize)
    %     [~,Parameters.ResVoxelSize, ~]=rp_readfile(Parameters.scans_list{i},1);
    % end
    matlabbatch{i}.spm.spatial.normalise.write.woptions.vox = Parameters.ResVoxelSize;
    matlabbatch{i}.spm.spatial.normalise.write.woptions.interp = 4;
    matlabbatch{i}.spm.spatial.normalise.write.woptions.prefix = 'w';
end
end


%% Old Normalize 
function matlabbatch = SpmBatch2normalize_old_Fun(Parameters, Template)
for i =1:length(Parameters.scans_list)
    matlabbatch{i}.spm.spatial.normalise.write.subj.matname = cellstr(Parameters.snMat_list{i});
    matlabbatch{i}.spm.spatial.normalise.write.subj.resample = cellstr(Parameters.scans_list{i});
    matlabbatch{i}.spm.spatial.normalise.write.roptions.preserve = 0;
    BB = round(spm_get_bbox(Template));
    matlabbatch{i}.spm.spatial.normalise.write.roptions.bb = BB;
    % if isempty(Parameters.ResVoxelSize)
    %     [~,Parameters.ResVoxelSize, ~]=rp_readfile(Parameters.scans_list{i},1);
    %     Parameters.ResVoxelSize = round(Parameters.ResVoxelSize);
    % end
    matlabbatch{i}.spm.spatial.normalise.write.roptions.vox = Parameters.ResVoxelSize;
    matlabbatch{i}.spm.spatial.normalise.write.roptions.interp = 4;
    matlabbatch{i}.spm.spatial.normalise.write.roptions.wrap = [0 0 0];
    matlabbatch{i}.spm.spatial.normalise.write.roptions.prefix = 'w';
end
end
