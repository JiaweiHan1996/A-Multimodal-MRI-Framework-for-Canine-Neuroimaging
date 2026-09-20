function out_path = trans_imghdr2nii(img_path)
% update: 2025-09-26

[d, f, e] = fileparts(img_path);
if ~strcmp(e, 'img')
    img_path = spm_select(1, 'img$', 'Please Select .img File');
end
if isempty(img_path)
    return
end

out_path = [d filesep f '.nii'];

%
V = spm_vol(img_path);
M = spm_read_vols(V);
V.fname = out_path;
spm_write_vol(V, M);

%
disp(['Nifti Saved:    ' out_path]);

end