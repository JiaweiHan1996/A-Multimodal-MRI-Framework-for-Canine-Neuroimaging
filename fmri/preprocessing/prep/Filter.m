function PP = Filter(PP)
%% update: 20251107

fprintf(['\nFilter Starting    ||    ' spm('time') '\n']);

[Parameters, PP] = Filter_basisPara(PP);

for i = 1:length(Parameters.scans_list)
%%
    [filepath, name, ext] = fileparts(Parameters.scans_list{i});
    out_FunImg_name = ['f' name ext];
    out_FunImg_path = [filepath filesep out_FunImg_name];
    % Load TR
    TR = PP.DataList.TR(i);
    % Load Mask
    mask_file = Parameters.mask_list{i};
    old_bandpass(Parameters.scans_list{i}, out_FunImg_path, TR, Parameters.band_high, Parameters.band_low, 'Yes', mask_file);
    delete(Parameters.scans_list{i});
    delete(mask_file);
    
end; clear i

PP = OutputCommPara(PP);

fprintf(['\nFilter Completed    ||    ' spm('time') '\n']);

end

function [Parameters, PP] = Filter_basisPara(PP)
% ===== Load PP =====

DataList = PP.DataList;
[d, f, ~] = fileparts(PP.FunPath);
FilePath = d;
out_dir_name_Fun = [f 'F'];
Fun_out_Path = [FilePath filesep out_dir_name_Fun];
if exist(Fun_out_Path, 'dir')
    rmdir(Fun_out_Path, 's');
end
mkdir(Fun_out_Path);

% Copy data and get scans list
[status, message] = copyfile(PP.FunPath, Fun_out_Path);
if status
    fprintf('\nSuccessfully copied all files from %s to %s\n', PP.FunPath, Fun_out_Path);
else
    fprintf('\n[ERROR] Copy failed: %s\n', message);
end
DataList.FunFolder_Name = out_dir_name_Fun;

scans_list = cell(length(DataList.Sublist), 1);
for i = 1:length(DataList.Sublist)
    scans_list{i} = fullfile(DataList.dataroot_path, ...
                                DataList.FunFolder_Name, ...
                                DataList.Sublist{i}, ...
                                DataList.filename{i});
    V = spm_vol(scans_list{i});

    dim_3d = V(1).dim;

    mask = ones(dim_3d, 'uint8');
    Vout = V(1);
    Vout.fname = fullfile(DataList.dataroot_path, ...
                                DataList.FunFolder_Name, ...
                                DataList.Sublist{i}, ...
                                'OnesMask.nii');
    Vout.dt = [2 0];
    spm_write_vol(Vout, mask);
    mask_list{i} = Vout.fname;
end

Parameters.scans_list = scans_list;
Parameters.mask_list = mask_list;

% Band
Parameters.band_low = PP.Step_F.Band(1);         % e.g. 0.01
Parameters.band_high = PP.Step_F.Band(2);        % e.g. 0.08

PP.DataList = DataList;
PP.FunPath = Fun_out_Path;

end

function PP = OutputCommPara(PP)
% Update filenames and other parameters after Smooth

DataList = PP.DataList;

for i = 1:length(DataList.filename)
    if ischar(DataList.filename{i}) && ~isempty(DataList.filename{i})
        DataList.filename{i} = ['f' DataList.filename{i}];
    end
end

% Update PP structure
PP.DataList = DataList;

end

