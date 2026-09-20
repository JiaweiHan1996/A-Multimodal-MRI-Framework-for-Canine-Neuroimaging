function PP = smoothing(PP)

fprintf(['\nSmooth Starting    ||    ' spm('time') '\n']);

[Parameters, PP] = Smoothing_basisPara(PP);

matlabbatch = SpmBatch2normalize_smoothing(Parameters);

spm('defaults', 'FMRI');
spm_jobman('initcfg');

parfor i = 1:length(matlabbatch)
    try
        fprintf('\nProcessing: %s\n', Parameters.scans_list{i});
        current_batch = matlabbatch(i);
        spm_jobman('run', current_batch);
        if exist(Parameters.scans_list{i}, 'file')
            delete(Parameters.scans_list{i});
        else
            fprintf('\n[ERROR] Processed file not found: %s\n', output_file);
        end
    catch ME
        fprintf('\n[ERROR] Failed to process %s: %s\n', Parameters.scans_list{i}, ME.message);
    end
end

PP = OutputCommPara(PP);

fprintf(['\nSmooth Completed    ||    ' spm('time') '\n']);

end

function [Parameters, PP] = Smoothing_basisPara(PP)
% ===== Load PP =====
DataList = PP.DataList;
[d, f, ~] = fileparts(PP.FunPath);
FilePath = d;
out_dir_name_Fun = [f 'S'];
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
end

Parameters.scans_list = scans_list;

Parameters.FWHM = PP.Step_S.FWHM;

PP.DataList = DataList;
PP.FunPath = Fun_out_Path;
end

function PP = OutputCommPara(PP)
% Update filenames and other parameters after Smooth

DataList = PP.DataList;

for i = 1:length(DataList.filename)
    if ischar(DataList.filename{i}) && ~isempty(DataList.filename{i})
        DataList.filename{i} = ['s' DataList.filename{i}];
    end
end

% Update PP structure
PP.DataList = DataList;

end

%%
function matlabbatch = SpmBatch2normalize_smoothing(Parameters)
for i = 1:length(Parameters.scans_list)
    matlabbatch{i}.spm.spatial.smooth.data = cellstr(Parameters.scans_list{i});
    matlabbatch{i}.spm.spatial.smooth.fwhm =Parameters.FWHM;
end
end