function PP = Segment(PP, config_list)

fprintf(['\nSegment Starting   ||    ' spm('time') '\n']);
    if isfield(PP.Step_W, 'IsT1_BET') && PP.Step_W.IsT1_BET == 1
        exe_betPath = config_list.tools_and_mats.deepbet_tool;
        parfor i = 1:length(PP.T1DataList.T1_List)
            T1_img = PP.T1DataList.T1_List{i};
            T1_BETbatch(T1_img, exe_betPath);
        end
    end

    Parameters_Coregistration = Coregistration_basisPara(PP);
    if isfield(PP.Step_W, 'IsT1_BET') && PP.Step_W.IsT1_BET == 1  
        matlabbatch1 =  SpmBatch2coregistration(Parameters_Coregistration.MeanFun_List, Parameters_Coregistration.T1brain_List);
        matlabbatch2 =  SpmBatch2coregistration(Parameters_Coregistration.T1brain_List, Parameters_Coregistration.T1_List);
        parfor i = 1:length(Parameters_Coregistration.T1_List)
            current_batch1 = matlabbatch1(i);
            spm_jobman('run', current_batch1);
            current_batch2 = matlabbatch2(i);
            spm_jobman('run', current_batch2);
        end
        clear matlabbatch1 matlabbatch2 current_batch1 current_batch2
    else
        matlabbatch =  SpmBatch2coregistration(Parameters_Coregistration.MeanFun_List, Parameters_Coregistration.T1_List);
        parfor i = 1:length(matlabbatch)
            current_batch = matlabbatch(i);
            spm_jobman('run', current_batch);
        end
        clear matlabbatch current_batch
    end

    if isfield(PP, 'IsOld_Segment') && PP.IsOld_Segment == 1
        fprintf(['\nOld Segment Starting   ||    ' spm('time') '\n']);
        matlabbatch = SpmBatch2segmentation_old(Parameters_Coregistration.rT1_List, PP.Config_INFO.TPM);
        parfor i=1:length(matlabbatch)
            current_batch = matlabbatch(i);
            spm_jobman('run', current_batch);
        end
        clear matlabbatch current_batch
    else
        if isfield(PP.Step_W, 'IsDARTEL') && PP.Step_W.IsDARTEL == 1
            fprintf(['\nSegment for DARTEL Starting   ||    ' spm('time') '\n']);
            matlabbatch = SpmBatch2segmentation_dartel(Parameters_Coregistration.rT1_List, PP.Config_INFO.TPM);
        else
            fprintf(['\nNew Segment Starting   ||    ' spm('time') '\n']);
            matlabbatch = SpmBatch2segmentation(Parameters_Coregistration.rT1_List, PP.Config_INFO.TPM);
        end
        parfor i=1:length(matlabbatch)
            current_batch = matlabbatch(i);
            spm_jobman('run', current_batch);
        end
        clear matlabbatch current_batch
    end

    fprintf(['\nSegment Completed   ||    ' spm('time') '\n']);
end

function T1_BETbatch(T1_img, exe_betPath)
% ProcessSingleSubjectBET - Perform BET operation for a single subject
%
% Inputs:
%   T1_img - Full path to T1 image file
%   exe_betPath - Path to BET executable

if isempty(T1_img) || ~exist(T1_img, 'file')
    fprintf('Error: T1 file not found: %s\n', T1_img);
    return;
end
fprintf('Executing BET for: %s\n', T1_img);
s_bet = [exe_betPath ' -i "' T1_img '"']; 
dos(s_bet); 
clear s_bet;
fprintf('Completed BET for: %s\n', T1_img);
end

function Parameters = Coregistration_basisPara(PP)
DataList = PP.DataList;
T1DataList = PP.T1DataList;
% Get mean functional files
MeanFun_List = {};
[d, ~, ~] = fileparts(PP.FunPath);
FilePath = d;
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
            scans = fullfile(PP.FunPath, DataList.Sublist{i},DataList.filename{i});
            % Create mean image in RP directory
            meanfile = fullfile(meanPath,['mean' DataList.filename{i}]);
            MeanCalc(scans, meanfile)
            MeanFun_List{end+1,1} = meanfile;
       end
    else
        mkdir(meanPath)
        scans = fullfile(PP.FunPath, DataList.Sublist{i},DataList.filename{i});
        % Create mean image in RP directory
        meanfile = fullfile(meanPath,['mean' DataList.filename{i}]);
        MeanCalc(scans, meanfile)
        MeanFun_List{end+1,1} = meanfile;
    end
end

PP.MeanFun_List = MeanFun_List;
Parameters.MeanFun_List = PP.MeanFun_List;

% T1_List matching
if PP.Snum > 1
    j = 0;
    T1_List = cell(size(Parameters.MeanFun_List));
    for i = 1:length(Parameters.MeanFun_List)
        meanpath = fileparts(Parameters.MeanFun_List{i});
        parts = split(meanpath, '\');
        sub_id = parts{end-1};
        sess_id = parts{end};
        if mod(i,PP.Snum)==1
           j = j + 1;
        end
        t1_sess_path = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, T1DataList.filename{j});
        t1_sess_folder = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id);
        mkdir(t1_sess_folder)
        copyfile(T1DataList.T1_List{j}, t1_sess_folder)
        T1_List{i} = t1_sess_path;
    end
    Parameters.T1_List = T1_List;
else
    Parameters.T1_List = PP.T1DataList.T1_List;
end

% T1brain_List only if BET was performed
% if isfield(PP, 'Step_W') && isfield(PP.Step_W, 'IsT1_BET') && PP.Step_W.IsT1_BET == 1
%     if PP.Snum > 1
%         T1brain_List = cell(size(Parameters.MeanFun_List));
%         for i = 1:length(Parameters.MeanFun_List)
%             meanpath = fileparts(Parameters.MeanFun_List{i});
%             parts = split(meanpath, '\');
%             sub_id = parts{end-1};
%             sess_id = parts{end};
%             t1_sess_path = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, T1DataList.filename);  
%             t1Idx = find(contains(PP.T1DataList.Sublist, subID), 1);
%             if ~isempty(t1Idx)
%                 T1brain_List{i} = PP.T1DataList.T1brain_List{t1Idx};
%             else
%                 T1brain_List{i} = '';
%             end
%         end
%         Parameters.T1brain_List = T1brain_List;
%     else
%         Parameters.T1brain_List = PP.T1DataList.T1brain_List;
%     end
% end

% rT1_List matching
rT1_List = cell(size(Parameters.MeanFun_List));
if PP.Snum > 1
    j = 0;
    for i = 1:length(Parameters.MeanFun_List)
        meanpath = fileparts(Parameters.MeanFun_List{i});
        parts = split(meanpath, '\');
        sub_id = parts{end-1};
        sess_id = parts{end};
        if mod(i,PP.Snum)==1
           j = j + 1;
        end
        rt1_sess_path = fullfile(DataList.dataroot_path, T1DataList.T1Folder_Name, sub_id, sess_id, ['r' T1DataList.filename{j}]);
        rT1_List{i} = rt1_sess_path;
    end
else
    for i = 1:length(Parameters.MeanFun_List)
        rT1_List{i} = fullfile(DataList.dataroot_path, ...
                        T1DataList.T1Folder_Name, ...
                        T1DataList.Sublist{i}, ...
                        ['r' T1DataList.filename{i}]);
    end
end
Parameters.rT1_List = rT1_List;
end

%% Coregistration
function matlabbatch =  SpmBatch2coregistration(Ref_Img_List, Source_Img_List)
for i = 1:length(Ref_Img_List)
    matlabbatch{i}.spm.spatial.coreg.estwrite.ref = cellstr(Ref_Img_List{i});
    matlabbatch{i}.spm.spatial.coreg.estwrite.source = cellstr(Source_Img_List{i});
    matlabbatch{i}.spm.spatial.coreg.estwrite.other = {''};
    matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
    matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
    matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    matlabbatch{i}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
    matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.interp = 4;
    matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
    matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.mask = 0;
    matlabbatch{i}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';
end
end

%% New Segment
function matlabbatch = SpmBatch2segmentation(T1Img_list, tpm_path)

for i =1:length(T1Img_list)
    % Channel
    matlabbatch{i}.spm.spatial.preproc.channel.vols = cellstr(T1Img_list{i});
    matlabbatch{i}.spm.spatial.preproc.channel.biasreg = 0.001;
    matlabbatch{i}.spm.spatial.preproc.channel.biasfwhm = 60;
    matlabbatch{i}.spm.spatial.preproc.channel.write = [0 1];
    % Tissue
    matlabbatch{i}.spm.spatial.preproc.tissue(1).tpm = cellstr(tpm_path.GM_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(1).ngaus = 1;
    matlabbatch{i}.spm.spatial.preproc.tissue(1).native = [1 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(1).warped = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(2).tpm = cellstr(tpm_path.WM_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(2).ngaus = 1;
    matlabbatch{i}.spm.spatial.preproc.tissue(2).native = [1 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(2).warped = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(3).tpm = cellstr(tpm_path.CSF_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(3).ngaus = 2;
    matlabbatch{i}.spm.spatial.preproc.tissue(3).native = [1 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(3).warped = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(4).tpm = cellstr(tpm_path.Skull_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(4).ngaus = 3;
    matlabbatch{i}.spm.spatial.preproc.tissue(4).native = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(4).warped = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(5).tpm = cellstr(tpm_path.Scalp_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(5).ngaus = 4;
    matlabbatch{i}.spm.spatial.preproc.tissue(5).native = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(5).warped = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(6).tpm = cellstr(tpm_path.Background_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(6).ngaus = 2;
    matlabbatch{i}.spm.spatial.preproc.tissue(6).native = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(6).warped = [0 0];
    % Warp
    matlabbatch{i}.spm.spatial.preproc.warp.mrf = 1;
    matlabbatch{i}.spm.spatial.preproc.warp.cleanup = 1;
    matlabbatch{i}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
    matlabbatch{i}.spm.spatial.preproc.warp.affreg = 'mni';
    matlabbatch{i}.spm.spatial.preproc.warp.fwhm = 0;
    matlabbatch{i}.spm.spatial.preproc.warp.samp = 3;
    matlabbatch{i}.spm.spatial.preproc.warp.write = [1 1];
end
end

%% New Segment for dartel
function matlabbatch = SpmBatch2segmentation_dartel(T1Img_list, tpm_path)
for i = 1:length(T1Img_list)
    matlabbatch{i}.spm.spatial.preproc.channel.vols = cellstr(T1Img_list{i});
    matlabbatch{i}.spm.spatial.preproc.channel.biasreg = 0.0001;
    matlabbatch{i}.spm.spatial.preproc.channel.biasfwhm = 60;
    matlabbatch{i}.spm.spatial.preproc.channel.write = [0 0];
    % Tissue
    matlabbatch{i}.spm.spatial.preproc.tissue(1).tpm = cellstr(tpm_path.GM_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(1).ngaus = 2;
    matlabbatch{i}.spm.spatial.preproc.tissue(1).native = [1 1];
    matlabbatch{i}.spm.spatial.preproc.tissue(1).warped = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(2).tpm = cellstr(tpm_path.WM_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(2).ngaus = 2;
    matlabbatch{i}.spm.spatial.preproc.tissue(2).native = [1 1];
    matlabbatch{i}.spm.spatial.preproc.tissue(2).warped = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(3).tpm = cellstr(tpm_path.CSF_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(3).ngaus = 2;
    matlabbatch{i}.spm.spatial.preproc.tissue(3).native = [1 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(3).warped = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(4).tpm = cellstr(tpm_path.Skull_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(4).ngaus = 3;
    matlabbatch{i}.spm.spatial.preproc.tissue(4).native = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(4).warped = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(5).tpm = cellstr(tpm_path.Scalp_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(5).ngaus = 4;
    matlabbatch{i}.spm.spatial.preproc.tissue(5).native = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(5).warped = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(6).tpm = cellstr(tpm_path.Background_Path);
    matlabbatch{i}.spm.spatial.preproc.tissue(6).ngaus = 2;
    matlabbatch{i}.spm.spatial.preproc.tissue(6).native = [0 0];
    matlabbatch{i}.spm.spatial.preproc.tissue(6).warped = [0 0];
    % Warp
    matlabbatch{i}.spm.spatial.preproc.warp.mrf = 0;
    matlabbatch{i}.spm.spatial.preproc.warp.reg = 4;
    matlabbatch{i}.spm.spatial.preproc.warp.affreg = 'mni';
    matlabbatch{i}.spm.spatial.preproc.warp.samp = 3;
    matlabbatch{i}.spm.spatial.preproc.warp.write = [0 0];
end
end

%% Old Segment
function matlabbatch = SpmBatch2segmentation_old(T1Img_list, tpm_path)
for i =1:length(T1Img_list)
    matlabbatch{i}.spm.tools.oldseg.data = cellstr(T1Img_list{i});
    matlabbatch{i}.spm.tools.oldseg.output.GM = [0 0 1];
    matlabbatch{i}.spm.tools.oldseg.output.WM = [0 0 1];
    matlabbatch{i}.spm.tools.oldseg.output.CSF = [0 0 1];
    matlabbatch{i}.spm.tools.oldseg.output.biascor = 1;
    matlabbatch{i}.spm.tools.oldseg.output.cleanup = 0;
    matlabbatch{i}.spm.tools.oldseg.opts.tpm = {
        tpm_path.GM_Path
        tpm_path.WM_Path
        tpm_path.CSF_Path
        };
    matlabbatch{i}.spm.tools.oldseg.opts.ngaus = [2; 2; 2; 4];
    matlabbatch{i}.spm.tools.oldseg.opts.regtype = 'mni';
    matlabbatch{i}.spm.tools.oldseg.opts.warpreg = 1;
    matlabbatch{i}.spm.tools.oldseg.opts.warpco = 25;
    matlabbatch{i}.spm.tools.oldseg.opts.biasreg = 0.0001;
    matlabbatch{i}.spm.tools.oldseg.opts.biasfwhm = 60;
    matlabbatch{i}.spm.tools.oldseg.opts.samp = 1;
end
end

