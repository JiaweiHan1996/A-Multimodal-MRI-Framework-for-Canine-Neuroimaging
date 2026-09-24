function VBM_db_Smooth(data,k)
    spm('Defaults','fMRI');spm_jobman('initcfg');
	clear matlabbatch
matlabbatch{1}.spm.spatial.smooth.data = data;      % n*1 cell
matlabbatch{1}.spm.spatial.smooth.fwhm = [k k k];	% Advise: 3mm
matlabbatch{1}.spm.spatial.smooth.dtype = 0;
matlabbatch{1}.spm.spatial.smooth.im = 0;
matlabbatch{1}.spm.spatial.smooth.prefix = 's';
    % Run SPM batch
    spm_jobman('run',matlabbatch);
    clear matlabbatch
end