function [z_lower_out, z_upper_out] = robustfov_matlab(input_nii, output_nii, brain_size_mm, perm, flipDims, z_lower_input, z_upper_input)
% robustfov_matlab - Automatically crop MRI field of view (supports 3D/4D), removing the portion below the neck
%   Input:
%       input_nii     : Original NIfTI filename (3D or 4D)
%       output_nii    : (Optional) Output filename. If not provided or empty,
%                       automatically add a "co" prefix under the same path as the input
%       brain_size_mm : (Optional) Preset brain Z-axis physical size (mm), default 150 mm
%       perm          : (Optional) Permutation vector, used to convert the original image
%                       to the target orientation (e.g. [2 1 3] swaps X/Y), default 1:3
%       flipDims      : (Optional) Logical vector of length 3, indicating whether to flip
%                       each spatial dimension (1:x, 2:y, 3:z), default [false false false]
%       z_lower_input : (Optional) User-specified lower crop Z bound (voxel index in the
%                       transformed space). If provided, overrides automatic calculation;
%                       default [] means automatic
%       z_upper_input : (Optional) User-specified upper crop Z bound (voxel index in the
%                       transformed space). If provided, overrides automatic calculation;
%                       default [] means automatic
%   Output:
%       z_lower_out    : Actually used lower crop Z bound (voxel index in the transformed space)
%       z_upper_out    : Actually used upper crop Z bound (voxel index in the transformed space)
%   Dependencies:
%       MATLAB Medical Imaging Toolbox (niftiread/niftiwrite)

    % Handle default values for input arguments
    if nargin < 2 || isempty(output_nii)
        [path, name, ext] = fileparts(input_nii);
        output_nii = fullfile(path, ['co' name ext]);
        fprintf('Output filename unspecified, automatically set to: %s\n', output_nii);
    end
    if nargin < 3 || isempty(brain_size_mm), brain_size_mm = 150; end
    if nargin < 4 || isempty(perm), perm = 1:3; end
    if nargin < 5 || isempty(flipDims), flipDims = [false false false]; end
    if nargin < 6, z_lower_input = []; end
    if nargin < 7, z_upper_input = []; end

    extra_top_mm = 6;          

    perm = perm(:)';
    flipDims = flipDims(:)';

    if ~exist('niftiread', 'file')
        error('Error: niftiread function not found. Please install Medical Imaging Toolbox or use another NIfTI reader.');
    end

    try
        img = niftiread(input_nii);
        info = niftiinfo(input_nii);
    catch ME
        error('Could not read NIfTI file: %s', ME.message);
    end

    orig_sz = size(img);
    ndim = ndims(img);
    if ndim == 3
        is4d = false;
        nvols = 1;
    elseif ndim == 4
        is4d = true;
        nvols = orig_sz(4);
    else
        error('Error: only 3D or 4D NIfTI images are supported.');
    end

    voxsize = info.PixelDimensions(1:3);   

    %% Step 0: Reorient image to a standard orientation (e.g., RAS)
    if is4d && length(perm) == 3
        perm = [perm, 4];
    elseif is4d && length(perm) ~= 4
        error('Error: for 4D data, perm must be a vector of length 3 or 4.');
    end

    img_trans = permute(img, perm);
    for i = 1:3
        if flipDims(i)
            img_trans = flip(img_trans, i);
        end
    end
    trans_sz = size(img_trans);
    trans_sz_spatial = trans_sz(1:3);

    %% 1. Generate reference image for localization (average over time for 4D)
    if is4d
        ref_img = mean(img_trans, 4, 'omitnan');
    else
        ref_img = img_trans;
    end


    ref_img = double(ref_img);

    %% 2. Intensity-based centroid computation (background excluded)
    maxval = max(ref_img(:));
    thresh = 0.1 * maxval;
    mask = ref_img > thresh;

    if ~any(mask, 'all')
        error('Error: no foreground detected. Please adjust the threshold.');
    end

    [X, Y, Z] = ndgrid(1:trans_sz_spatial(1), 1:trans_sz_spatial(2), 1:trans_sz_spatial(3));
    total_intensity = sum(ref_img(mask), 'all');
    cx = sum(X(mask) .* ref_img(mask), 'all') / total_intensity;
    cy = sum(Y(mask) .* ref_img(mask), 'all') / total_intensity;
    cz = sum(Z(mask) .* ref_img(mask), 'all') / total_intensity;
    cz_round = round(cz);
    cz_round = max(1, min(trans_sz_spatial(3), cz_round));

    %% 3. Calculate brain reference intensity (±10 mm near the centroid)
    z_range_vox = round(10 / voxsize(3));
    z_start = max(1, cz_round - z_range_vox);
    z_end   = min(trans_sz_spatial(3), cz_round + z_range_vox);
    brain_intensity = mean(ref_img(:,:,z_start:z_end), 'all', 'omitnan');


    intensity_pos = sum(ref_img(:,:,cz_round:end), 'all');   
    intensity_neg = sum(ref_img(:,:,1:cz_round), 'all');     

    if intensity_pos < intensity_neg
        head_above = true;   
        fprintf('  Head direction: positive (z increasing)\n');
    else
        head_above = false;  
        fprintf('  Head direction: negative (z decreasing)\n');
    end

    %% 4. Neck boundary search (based on head orientation) — automatic calculation only (excluding top-of-head extension)
    thresh_factor = 0.4;          
    consecutive_needed = 3;      
    consecutive = 0;

    if head_above
       
        z_neck = cz_round;
        for z = cz_round:-1:1
            slice_mean = mean(ref_img(:,:,z), 'all', 'omitnan');
            if slice_mean < brain_intensity * thresh_factor
                consecutive = consecutive + 1;
                if consecutive >= consecutive_needed
                    z_neck = z + consecutive - 1;   
                    break;
                end
            else
                consecutive = 0;
                z_neck = z;
            end
        end
        z_lower_auto = max(1, z_neck);
        z_upper_auto = z_lower_auto + round(brain_size_mm / voxsize(3));
        z_upper_auto = min(trans_sz_spatial(3), z_upper_auto);
    else
        
        z_neck = cz_round;
        for z = cz_round:trans_sz_spatial(3)
            slice_mean = mean(ref_img(:,:,z), 'all', 'omitnan');
            if slice_mean < brain_intensity * thresh_factor
                consecutive = consecutive + 1;
                if consecutive >= consecutive_needed
                    z_neck = z - consecutive + 1;   
                    break;
                end
            else
                consecutive = 0;
                z_neck = z;
            end
        end
        z_upper_auto = min(trans_sz_spatial(3), z_neck);
        z_lower_auto = z_upper_auto - round(brain_size_mm / voxsize(3));
        z_lower_auto = max(1, z_lower_auto);
    end

  
    if z_lower_auto > z_upper_auto
        error('Error: invalid automatic crop range. Please check the brain size or orientation detection.');
    end

 
    extra_top_vox = round(extra_top_mm / voxsize(3));
    if extra_top_vox > 0
        if ~head_above
            
            new_upper = z_upper_auto + extra_top_vox;
            if new_upper <= trans_sz_spatial(3)
                z_upper_auto = new_upper;
                fprintf('  Extended %d mm in the head-top direction (upper bound)\n', extra_top_mm);
            else
                z_upper_auto = trans_sz_spatial(3);
                fprintf('  Head-top extension reached the upper image boundary\n');
            end
        else
  
            new_lower = z_lower_auto - extra_top_vox;
            if new_lower >= 1
                z_lower_auto = new_lower;
                fprintf('  Extended %d mm in the head-top direction (lower bound)\n', extra_top_mm);
            else
                z_lower_auto = 1;
                fprintf('  Head-top extension reached the lower image boundary\n');
            end
        end
    end

    %% 5. Final crop range: user-specified range preferred (if provided)
    if ~isempty(z_lower_input) && ~isempty(z_upper_input)
        
        z_lower = round(z_lower_input);
        z_upper = round(z_upper_input);
     
        z_lower = max(1, min(trans_sz_spatial(3), z_lower));
        z_upper = max(1, min(trans_sz_spatial(3), z_upper));
        if z_lower > z_upper
            warning('Warning: invalid user-specified range (lower bound > upper bound). Using automatic range instead.');
            z_lower = z_lower_auto;
            z_upper = z_upper_auto;
        else
            fprintf('  User-specified Z range: [%d, %d] voxels\n', z_lower, z_upper);
        end
    elseif ~isempty(z_lower_input) || ~isempty(z_upper_input)
        
        warning('Warning: both z_lower_input and z_upper_input are required. Using automatic range instead.');
        z_lower = z_lower_auto;
        z_upper = z_upper_auto;
    else
        
        z_lower = z_lower_auto;
        z_upper = z_upper_auto;
    end

   
    z_lower_out = z_lower;
    z_upper_out = z_upper;

    fprintf('  Final crop Z range: [%d, %d] voxels, physical size %.1f mm\n', ...
        z_lower, z_upper, (z_upper - z_lower + 1) * voxsize(3));

    %% 6. Crop image (4th dimension unchanged)
    if is4d
        img_cropped_trans = img_trans(:, :, z_lower:z_upper, :);
    else
        img_cropped_trans = img_trans(:, :, z_lower:z_upper);
    end

    %% 7. Calculate cropped region start index in original image
    orig_spatial_sz = orig_sz(1:3);
    perm_spatial_sz = orig_spatial_sz(perm(1:3));
    start_trans = [1, 1, z_lower];

    
    start_after_flip = start_trans;
    for i = 1:3
        if flipDims(i)
            start_after_flip(i) = perm_spatial_sz(i) - start_trans(i) + 1;
        end
    end

    invperm_spatial = zeros(1,3);
    invperm_spatial(perm(1:3)) = 1:3;
    orig_start = zeros(1,3);
    for j = 1:3
        orig_start(j) = start_after_flip(invperm_spatial(j));
    end

    trans_matrix = eye(4);
    trans_matrix(1,4) = orig_start(1) - 1;
    trans_matrix(2,4) = orig_start(2) - 1;
    trans_matrix(3,4) = orig_start(3) - 1;
    T_new = info.Transform.T * trans_matrix;

    %% 8. Reorient cropped image to original orientation
    img_final = img_cropped_trans;
    for i = 1:3
        if flipDims(i)
            img_final = flip(img_final, i);
        end
    end

    if is4d
        invperm_full = zeros(1,4);
        invperm_full(perm) = 1:4;
        img_final = permute(img_final, invperm_full);
    else
        invperm_spatial_full = zeros(1,3);
        invperm_spatial_full(perm) = 1:3;
        img_final = permute(img_final, invperm_spatial_full);
    end

    %% 9. Update NIfTI header information
    info_cropped = info;
    info_cropped.ImageSize = size(img_final);
    % Note: Transform is not updated here because the user did not provide a
    % transformation matrix. Keeping the original transform would cause spatial
    % positioning errors.
    % To update it correctly, you should construct an affine3d object using T_new
    % and assign it, but this has been commented out in the user's current code.
    % To preserve spatial positioning, uncomment the following two lines:
    % info_cropped.Transform = affine3d(T_new);

    %% 10. Save output file
    try
        niftiwrite(img_final, output_nii, info_cropped);
        fprintf('Crop completed, saved to: %s\n', output_nii);
        if is4d
            fprintf('  Retained %d time points\n', nvols);
        end
    catch ME
        error('Failed to write NIfTI file: %s', ME.message);
    end
end