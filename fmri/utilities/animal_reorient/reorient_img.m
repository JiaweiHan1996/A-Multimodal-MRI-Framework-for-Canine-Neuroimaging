function [selectedIdx, outputname,perm, flipDims] = reorient_img (inputpath, T1w_Template_path, flip_flag, Index)

files = dir(fullfile(inputpath, '*.nii*'));


isValidFile = ~[files.isdir] & ...  
    (~cellfun(@isempty, regexpi({files.name}, '\.nii$|\.nii\.gz$', 'once')));


validFiles = files(isValidFile);


path_nii_num = arrayfun(@(x) fullfile(inputpath, x.name), validFiles, 'UniformOutput', false);

if length(path_nii_num) > 1
    inputPath = path_nii_num{length(path_nii_num)};
else
    inputPath = path_nii_num{1};
end

inputNii = load_untouch_nii(inputPath);
templateNii = load_nii(T1w_Template_path);

%%%%%%%%%%%%%%% 20260322 %%%%%%%%%%%%%%%%%%%%
if size(inputNii.img) > 3
    [~,~,input_Header]=rp_readfile(inputPath,1);
else
    [~,~,input_Header]=rp_readfile(inputPath);
end
%%%%%%%%%%%%%%% 20260322 %%%%%%%%%%%%%%%%%%%%

results = cell(8, 1);
results_img_reorient = cell(8, 1);

voxel_size = original_voxel(inputNii);
results_mat = construct_new_matrix(voxel_size);

for i = 1:8
    [qb, qc, qd] = affine2quat(results_mat{i});
    newNiiStruct = adjusthdr(results_mat{i}, inputNii, qb, qc, qd);
    results{i} = newNiiStruct;
    adjustedNii = adjustNiiOrientation(results{1}, newNiiStruct.hdr.hist.srow_x, newNiiStruct.hdr.hist.srow_y, newNiiStruct.hdr.hist.srow_z);
    results_img_reorient{i} = adjustedNii;
end

if isempty(Index)
        selectedIdx = displayOrientationResults(templateNii, results_img_reorient);
else
    selectedIdx = Index;
end

if flip_flag
    fprintf('Flipping left and right...\n');
    selectedNii = results{selectedIdx};
    
    results_mat{selectedIdx}(1,:) = -results_mat{selectedIdx}(1,:);
    flip_lr = results_mat{selectedIdx};
    [qb, qc, qd] = affine2quat(flip_lr);
    newNiiStruct = adjusthdr(flip_lr, selectedNii, qb, qc, qd);
    results{selectedIdx} = newNiiStruct;
end

[path, filename, ext] = Obtain_path_suffix(inputPath);
outputname = fullfile(path, [filename, '_reoriented', ext]);
%save_untouch_nii(results{selectedIdx}, outputname);

%%%%%%%%%%%%%%% 20260322 %%%%%%%%%%%%%%%%%%%%
data = double(results{selectedIdx}.img);
input_Header.mat = [results{selectedIdx}.hdr.hist.srow_x; results{selectedIdx}.hdr.hist.srow_y; ...
    results{selectedIdx}.hdr.hist.srow_z; [0 0 0 1]];
input_Header.dim = results{selectedIdx}.hdr.dime.dim(2:4);


write_To4dNifti(data, input_Header, outputname);
%%%%%%%%%%%%%%% 20260322 %%%%%%%%%%%%%%%%%%%%

disp(['Orientation rotation completed: ', outputname]);
R = results_mat{1} \ results_mat{selectedIdx};
[~, perm] = max(abs(R), [], 2);
flipDims = diag(R(perm,:)) < 0;
end

