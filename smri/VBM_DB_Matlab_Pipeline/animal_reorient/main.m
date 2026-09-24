clc;clear all;

ss = get(0, 'ScreenSize');
text_info = {'Before running the code, add the NIfTI_20140122 and spm12 toolboxes to the MATLAB working path.',...
              '----------------------------------------------------------------------',...
              'This tool can rotate animal images from special body positions to the template standard position (including structural, functional, and diffusion images), and can perform origin alignment as needed. It supports dcm and nii(.gz) data formats.', ...
              '----------------------------------------------------------------------',...
              'If the direction table corresponding to the diffusion images also needs to be adjusted, name the bvec file the same as the nii file, e.g.:', ...
              'D:\test\dMRI_sub1.nii  D:\test\dMRI_sub1.bvec   D:\test\dMRI_sub1.bval ...', ...
               'If the input is dcm, no additional processing is required.'};
hw = 600; hh = 220;
hl = (ss(3)-hw)/2; hb = (ss(4)-hh)/2;
h = dialog('name', 'Readme', 'position', [hl, hb, hw, hh]);
uicontrol('parent', h, 'style', 'text', 'string', text_info,...          
               'position', [20, 20, hw-20*2, hh-20*2], 'Horizontal', 'left', 'fontsize', 12);
uicontrol('parent', h, 'style', 'pushbutton', 'position',...        
                [(hw-50)/2 20 50 20], 'string', 'È·¶¨ or OK', 'callback', 'delete(gcbf)');
waitfor(h); clear h
clear text_info hw hh hl hb


tmp_choose = questdlg('Please select the path containing the dcm or nii files',...
                        'File Selection',...
                        'Select Path','Cancel','Select Path');

if strcmpi(tmp_choose,'Select Path')
    filter = {'*.dcm;*.nii;*.nii.gz'};
    [fileName, pathName] = uigetfile(filter, 'Please select the file to be processed');
    if isequal(fileName, 0) || isequal(pathName, 0)
        error('NOT select file, script will be end...')
    else
        if ~isempty(strfind(fileName,'nii'))
            inputPath = fullfile(pathName, fileName);
        else
            dcmpath = pathName;
            fullPath = mfilename('fullpath');
            [scriptDir, ~, ~] = fileparts(fullPath);
            exe_path = ['!' scriptDir filesep 'dcm2niix.exe'];
            eval([exe_path,' -o ',dcmpath,' ',dcmpath]);
            
            files = dir(fullfile(dcmpath, '*.nii*'));
            

            isValidFile = ~[files.isdir] & ...  
                (~cellfun(@isempty, regexpi({files.name}, '\.nii$|\.nii\.gz$', 'once')));
            
            validFiles = files(isValidFile);
            
            path_nii_num = arrayfun(@(x) fullfile(dcmpath, x.name), validFiles, 'UniformOutput', false);
            
            if length(path_nii_num) > 1
                inputPath = path_nii_num{length(path_nii_num)};
            else
                inputPath = path_nii_num{1};
            end
        end
    end
else
	error('NOT select file, script will be end...')
end

is_bvec_exist = 0;
[path, filename, ext] = Obtain_path_suffix(inputPath);
if exist(path, 'dir') ~= 7
    error('Path does not exist: %s', path);
end
bvec_path = fullfile(path, [filename, '.bvec']);

if exist(bvec_path, 'file') == 2
    is_bvec_exist = 1;
else
    is_bvec_exist = 0;
end

tmp_choose = questdlg('Please select the path containing the template file',...
                        'File Selection',...
                        'Select Path','Cancel','Select Path');

if strcmpi(tmp_choose,'Select Path')
    filter = {'*.nii;*.nii.gz'};
    [fileName, pathName] = uigetfile(filter, 'Please select the template file');
    if isequal(fileName, 0) || isequal(pathName, 0)
        error('NOT select file, script will be end...')
    else
        templatePath = fullfile(pathName, fileName);
    end
else
    error('NOT select file, script will be end...')
end


inputNii = load_untouch_nii(inputPath);
templateNii = load_nii(templatePath);
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

selectedIdx = displayOrientationResults(templateNii, results_img_reorient);

flip_flag = 0;

flipChoice = questdlg('Do you need to flip the image left-right (horizontal mirror)?', ...
                     'Left-Right Flip Setting', ...
                     'Yes', 'No', 'No');

if strcmpi(flipChoice, 'ÊÇ')
    fprintf('Flipping left-right...\n');
    selectedNii = results{selectedIdx};
    
    results_mat{selectedIdx}(1,:) = -results_mat{selectedIdx}(1,:);
    flip_lr = results_mat{selectedIdx};
    [qb, qc, qd] = affine2quat(flip_lr); 
    newNiiStruct = adjusthdr(flip_lr, selectedNii, qb, qc, qd);
    results{selectedIdx} = newNiiStruct;
    
    if is_bvec_exist
        bvec_matrix = load(bvec_path);
        bvec_matrix(1, :) = -bvec_matrix(1, :);
        
        fid = fopen([bvec_path(1:end-5), '.flipped_bvec'], 'w');
        for i = 1:size(bvec_matrix, 1)
            fprintf(fid, '%f ', bvec_matrix(i, :));
            fprintf(fid, '\r\n');
        end
        fclose(fid);
        fprintf('Generated flipped bvec file\n');
    end
    flip_flag = 1;
    fprintf('Left-right flip completed\n');
else
    fprintf('User canceled the left-right flip operation\n');
end

outputname = fullfile(path, [filename, '_reoriented', ext]);
save_untouch_nii(results{selectedIdx}, outputname);
disp(['Body rotation performed on file: ', outputname]);
if is_bvec_exist && flip_flag
    adjustbvecOrder(results_img_reorient{1}, results_img_reorient{selectedIdx}, [bvec_path(1:end-5), '.flipped_bvec']);
    delete([bvec_path(1:end-5), '.flipped_bvec']);
elseif is_bvec_exist && flip_flag == 0
    adjustbvecOrder(results_img_reorient{1}, results_img_reorient{selectedIdx}, bvec_path);
end

originAlignmentPrompt(outputname, templatePath);