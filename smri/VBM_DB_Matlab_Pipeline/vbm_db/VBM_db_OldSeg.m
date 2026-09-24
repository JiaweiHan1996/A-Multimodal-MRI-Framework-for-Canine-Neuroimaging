function VBM_db_OldSeg(T1w, TMP)
    spm('Defaults','fMRI');spm_jobman('initcfg');
	clear matlabbatch
matlabbatch{1}.spm.tools.oldseg.data = T1w;
matlabbatch{1}.spm.tools.oldseg.output.GM = [0 0 1];
matlabbatch{1}.spm.tools.oldseg.output.WM = [0 0 1];
matlabbatch{1}.spm.tools.oldseg.output.CSF = [0 0 1];
matlabbatch{1}.spm.tools.oldseg.output.biascor = 0;
matlabbatch{1}.spm.tools.oldseg.output.cleanup = 0;
matlabbatch{1}.spm.tools.oldseg.opts.tpm = {TMP.GMtpm;TMP.WMtpm;TMP.CSFtpm};
matlabbatch{1}.spm.tools.oldseg.opts.ngaus = [2;2;2;4];
matlabbatch{1}.spm.tools.oldseg.opts.regtype = '';
matlabbatch{1}.spm.tools.oldseg.opts.warpreg = 1;
matlabbatch{1}.spm.tools.oldseg.opts.warpco = 25;
matlabbatch{1}.spm.tools.oldseg.opts.biasreg = 0.0001;
matlabbatch{1}.spm.tools.oldseg.opts.biasfwhm = 60;
matlabbatch{1}.spm.tools.oldseg.opts.samp = 1;
matlabbatch{1}.spm.tools.oldseg.opts.msk = {''};
    % Run SPM batch
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end