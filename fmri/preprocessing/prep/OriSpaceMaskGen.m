function maskList = OriSpaceMaskGen(c1ToFun, c2ToFun, c3ToFun, rc2ToFun, rc3ToFun, brainToFun)
[d, f0, e0] = fileparts(c1ToFun);
brain_mask_path = fullfile(d, 'Brain_mask.nii');

% brain mask to FunSpace
V_gm = spm_vol(c1ToFun);
V_wm = spm_vol(c2ToFun);
V_csf = spm_vol(c3ToFun);
gm_data = spm_read_vols(V_gm);
wm_data = spm_read_vols(V_wm);
csf_data = spm_read_vols(V_csf);

brain_data = gm_data + wm_data + csf_data;
brain_mask = brain_data > 0;  

brain_mask_uint8 = uint8(brain_mask);

V_out = V_wm;
V_out.fname =  brain_mask_path;
V_out.dt = [2 0];  
spm_write_vol(V_out, brain_mask_uint8);

if ~isempty(rc2ToFun) && ~isempty(rc3ToFun) && ~isempty(brainToFun)
    erode_mask(c2ToFun, rc2ToFun)
    erode_mask(c3ToFun, rc3ToFun)
    copyfile(brain_mask_path, brainToFun)
    maskList{1} =  brainToFun;
    maskList{2} =  rc2ToFun;
    maskList{3} =  rc3ToFun;
end
    maskList{1} = brain_mask_path;
end

function erode_mask(input_file, output_file)
    V = spm_vol(input_file);
    data = spm_read_vols(V);
    mask = data > 0.99; 
    V.fname = output_file;
    V.dt = [16 0];  
    spm_write_vol(V, double(mask));
end