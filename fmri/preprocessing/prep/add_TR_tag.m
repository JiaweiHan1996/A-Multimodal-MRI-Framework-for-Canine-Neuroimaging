function add_TR_tag(wri_nii_path, ref_header)
% 4D Nii
    if ischar(ref_header)     % Nii Path
        ref_img = spm_vol(ref_header);
        TR_tag = ref_img(1).private.timing;
    elseif isstruct(ref_header)     % Nii Header
        TR_tag = ref_header(1).private.timing;
    else
        fprintf('No Reference Image/Header !\n');
        return
    end

    wri_img = spm_vol(wri_nii_path);
    Wri_Mtx = spm_read_vols(wri_img);
    
    for tp = 1:length(wri_img)
        wri_img(tp).private.timing = TR_tag;
        spm_write_vol(wri_img(tp), Wri_Mtx(:,:,:,tp));
    end; clear tp
    
end

