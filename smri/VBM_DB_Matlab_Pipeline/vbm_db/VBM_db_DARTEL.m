function VBM_db_DARTEL(Sub_ID, opDir, TMP)

    fprintf('Now is Running DARTEL ...\nIt might take a long time, please wait ...\n')
    
    % ----- Step 1: Reslice data that DARTEL needed ----- %
    for i = 1:length(Sub_ID), seg_sn(i,1) = {[opDir filesep Sub_ID{i} '_seg_sn.mat']}; end
    clear i
    DARTEL_InitialImport(seg_sn,opDir);
    
    % ----- Step 2: Create Templates with rc1/rc2/rc3 data ----- %
    for i = 1:length(Sub_ID),rc1(i,1) = {[opDir filesep 'rc1' Sub_ID{i} '.nii']};end
    clear i
    for i = 1:length(Sub_ID),rc2(i,1) = {[opDir filesep 'rc2' Sub_ID{i} '.nii']};end
    clear i
    for i = 1:length(Sub_ID),rc3(i,1) = {[opDir filesep 'rc3' Sub_ID{i} '.nii']};end
    clear i
    DARTEL_CreateTemplates(rc1,rc2,rc3);
    
    % ----- Step 3: Native seg normalise to own Template ----- %
    for i = 1:length(Sub_ID),urc(i,1) = {[opDir filesep 'u_rc1' Sub_ID{i} '_Template.nii']};end
    clear i
    for i = 1:length(Sub_ID),c1(i,1) = {[opDir filesep 'c1',Sub_ID{i} '.nii']};end
    clear i
    for i = 1:length(Sub_ID),c2(i,1) = {[opDir filesep 'c2' Sub_ID{i} '.nii']};end
    clear i
    for i = 1:length(Sub_ID),c3(i,1) = {[opDir filesep 'c3' Sub_ID{i} '.nii']};end
    clear i
    DARTEL_CreateWarped(urc,c1,c2,c3);
    
    % ----- Step 4: Estimate own Templates to std Templates ----- %
    SrcImg = [opDir filesep 'Template_6.nii,1'];  % GM Template
    OldNorm_Est(SrcImg,TMP.GMtpm);  clear SrcImg
    movefile([opDir filesep 'Template_6_sn.mat'],[opDir filesep 'Template_6_gm_sn.mat']);
    SrcImg = [opDir filesep 'Template_6.nii,2'];  % WM Template
    OldNorm_Est(SrcImg,TMP.WMtpm);  clear SrcImg
    movefile([opDir filesep 'Template_6_sn.mat'],[opDir filesep 'Template_6_wm_sn.mat']);
    SrcImg = [opDir filesep 'Template_6.nii,3'];  % CSF Template
    OldNorm_Est(SrcImg,TMP.CSFtpm);  clear SrcImg
    movefile([opDir filesep 'Template_6_sn.mat'],[opDir filesep 'Template_6_csf_sn.mat']);
    
    % ----- Step 5: Normalise mwc data to std Templates ----- %
    for i = 1:length(Sub_ID),WriImgs(i,1) = {[opDir filesep 'mwc1' Sub_ID{i} '.nii']};end
    clear i
    OldNorm_Wri([opDir filesep 'Template_6_gm_sn.mat'],WriImgs);  % Norm mwc1^ images
    clear WriImgs
    for i = 1:length(Sub_ID),WriImgs(i,1) = {[opDir filesep 'mwc2' Sub_ID{i} '.nii']};end
    clear i
    OldNorm_Wri([opDir filesep 'Template_6_wm_sn.mat'],WriImgs);  % Norm mwc1^ images
    clear WriImgs
    for i = 1:length(Sub_ID),WriImgs(i,1) = {[opDir filesep 'mwc3' Sub_ID{i} '.nii']};end
    clear i
    OldNorm_Wri([opDir filesep 'Template_6_csf_sn.mat'],WriImgs);  % Norm mwc1^ images
    clear WriImgs
end



%% ========== DARTEL Functions ========== %%
function DARTEL_InitialImport(seg_sn,opDir)
    spm('Defaults','fMRI');spm_jobman('initcfg');
	clear matlabbatch
matlabbatch{1}.spm.tools.dartel.initial.matnames = seg_sn(:);  % n*1 cell
matlabbatch{1}.spm.tools.dartel.initial.odir = {opDir};
matlabbatch{1}.spm.tools.dartel.initial.bb = [NaN NaN NaN; NaN NaN NaN];
matlabbatch{1}.spm.tools.dartel.initial.vox = NaN;
matlabbatch{1}.spm.tools.dartel.initial.image = 0;
matlabbatch{1}.spm.tools.dartel.initial.GM = 1;
matlabbatch{1}.spm.tools.dartel.initial.WM = 1;
matlabbatch{1}.spm.tools.dartel.initial.CSF = 1;
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end
% ----------

function DARTEL_CreateTemplates(rc1, rc2, rc3)
    spm('Defaults','fMRI');spm_jobman('initcfg');
	clear matlabbatch
matlabbatch{1}.spm.tools.dartel.warp.images = {rc1(:); rc2(:); rc3(:)}';
matlabbatch{1}.spm.tools.dartel.warp.settings.template = 'Template';
matlabbatch{1}.spm.tools.dartel.warp.settings.rform = 2;
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
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end
% ----------

function DARTEL_CreateWarped(urc, c1, c2, c3)
    spm('Defaults','fMRI');spm_jobman('initcfg');
	clear matlabbatch
matlabbatch{1}.spm.tools.dartel.crt_warped.flowfields = urc(:);
matlabbatch{1}.spm.tools.dartel.crt_warped.images = {c1(:); c2(:); c3(:)}';
matlabbatch{1}.spm.tools.dartel.crt_warped.jactransf = 1;
matlabbatch{1}.spm.tools.dartel.crt_warped.K = 6;
matlabbatch{1}.spm.tools.dartel.crt_warped.interp = 1;
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end
% ----------

function OldNorm_Est(SrcImg,TmpImg)
    spm('Defaults','fMRI');spm_jobman('initcfg');
	clear matlabbatch
matlabbatch{1}.spm.tools.oldnorm.est.subj.source = {SrcImg};  % Template_6
matlabbatch{1}.spm.tools.oldnorm.est.subj.wtsrc = '';
matlabbatch{1}.spm.tools.oldnorm.est.eoptions.template = {TmpImg};
matlabbatch{1}.spm.tools.oldnorm.est.eoptions.weight = '';
matlabbatch{1}.spm.tools.oldnorm.est.eoptions.smosrc = 0;
matlabbatch{1}.spm.tools.oldnorm.est.eoptions.smoref = 2;
matlabbatch{1}.spm.tools.oldnorm.est.eoptions.regtype = 'subj';
matlabbatch{1}.spm.tools.oldnorm.est.eoptions.cutoff = 25;
matlabbatch{1}.spm.tools.oldnorm.est.eoptions.nits = 0;
matlabbatch{1}.spm.tools.oldnorm.est.eoptions.reg = 1;
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end
% ----------

function OldNorm_Wri(Tmp_sn,WriImgs)
    spm('Defaults','fMRI');spm_jobman('initcfg');
	clear matlabbatch
matlabbatch{1}.spm.tools.oldnorm.write.subj.matname = {Tmp_sn};
matlabbatch{1}.spm.tools.oldnorm.write.subj.resample = WriImgs(:);
matlabbatch{1}.spm.tools.oldnorm.write.roptions.preserve = 1;
matlabbatch{1}.spm.tools.oldnorm.write.roptions.bb = [NaN NaN NaN;NaN NaN NaN];
matlabbatch{1}.spm.tools.oldnorm.write.roptions.vox = [NaN NaN NaN];
matlabbatch{1}.spm.tools.oldnorm.write.roptions.interp = 7;
matlabbatch{1}.spm.tools.oldnorm.write.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.tools.oldnorm.write.roptions.prefix = 'w';
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end
% ----------