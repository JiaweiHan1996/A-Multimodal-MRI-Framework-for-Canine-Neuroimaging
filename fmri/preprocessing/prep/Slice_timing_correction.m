function PP = Slice_timing_correction(PP)


fprintf(['\nSlice Timing Starting    ||    ' spm('time') '\n']);

[Parameters, PP] = SliceTiming_basisPara(PP);

matlabbatch = SpmBatch2SliceTiming(Parameters);

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
fprintf(['\nSlice Timing Completed    ||    ' spm('time') '\n']);
end

function PP = OutputCommPara(PP)
%% Post-processing common parameters after slice timing correction
% Update filenames and other parameters after slice timing computation

DataList = PP.DataList;

for i = 1:length(DataList.filename)
    if ischar(DataList.filename{i}) && ~isempty(DataList.filename{i})
        DataList.filename{i} = ['a' DataList.filename{i}];
    end
end

% Update PP structure
PP.DataList = DataList;

end

function [Parameters, PP] = SliceTiming_basisPara(PP)
% ===== Load PP =====
DataList = PP.DataList;
[d, f, ~] = fileparts(PP.FunPath);
FilePath = d;
out_dir_name_Fun = [f 'A'];
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

% get TR
Parameters.TR = DataList.TR;

% get Slice parameters
if isempty(PP.Step_A.Slice_Order)
    % Load Json
    for i = 1:length(DataList.filename)
        Json_Path = fullfile(DataList.dataroot_path, ...
                        DataList.FunFolder_Name, ...
                        DataList.Sublist{i}, ...
                        DataList.json_name{i});
        if ~exist(Json_Path, 'file') == 2
            fprintf(['\nLog: Lack Json File, Skip "' DataList.Sublist{i} '" to get Slice_Order\n']);
            return
        end
   
        JSON = spm_jsonread(Json_Path);
        slicetiming = JSON.SliceTiming(:);
        clear JSON
        Parameters.Slice_Number(i,1) = length(slicetiming);
        [Slice_Order, ReferenceSlice] = slice_sorting(length(slicetiming), slicetiming);
        Parameters.Slice_Order{i} = Slice_Order;
        if isempty(PP.Step_A.Ref_Slice)
            Parameters.Ref_Slice(i,1) = ReferenceSlice;
        else
            Parameters.Ref_Slice(i,1) = Slice_Order(ceil(length(slicetiming)/2));
        end
    end
else
    error_flag_sub=[];
    for i = 1:length(scans_list)
        header = spm_vol(scans_list{i});
        slice_number = header(1).dim(3);
        if length(PP.Step_A.Slice_Order)==slice_number
            Parameters.Slice_Number = repmat(length(PP.Step_A.Slice_Order), length(PP.DataList.filename), 1);
        else
            fprintf('LOG: [WARNING] Slice_Order mismatch at %s, skip...\n',scans_list(i));
            error_flag_sub(end+1) = i;
            continue;
        end
    end
    if ~isempty(error_flag_sub)
        scans_list(error_flag_sub) = [];
        DataList.Sublist(error_flag_sub) = [];
        DataList.filename(error_flag_sub) = [];
        DataList.json_name(error_flag_sub) = [];
        DataList.TR(error_flag_sub) = [];
    end
    Parameters.scans_list = scans_list;
    Parameters.Slice_Order = repmat({PP.Step_A.Slice_Order}, length(PP.DataList.filename), 1);
    if isempty(PP.Step_A.Ref_Slice)
        Ref_Slice = PP.Step_A.Slice_Order(ceil(length(PP.Step_A.Slice_Order)/2));
        Parameters.Ref_Slice = repmat(Ref_Slice, length(PP.DataList.filename), 1);
    else
        Parameters.Ref_Slice = repmat(PP.Step_A.Ref_Slice, length(PP.DataList.filename), 1);
    end
end

PP.DataList = DataList;
PP.FunPath = Fun_out_Path;
end


function matlabbatch = SpmBatch2SliceTiming(Parameters)
    for i = 1:length(Parameters.scans_list)
        matlabbatch{i}.spm.temporal.st.scans = {cellstr(Parameters.scans_list{i})};
        matlabbatch{i}.spm.temporal.st.nslices = Parameters.Slice_Number(i);
        matlabbatch{i}.spm.temporal.st.tr = Parameters.TR(i);
        matlabbatch{i}.spm.temporal.st.ta = Parameters.TR(i) - Parameters.TR(i)/Parameters.Slice_Number(i);
        matlabbatch{i}.spm.temporal.st.so = Parameters.Slice_Order{i};
        matlabbatch{i}.spm.temporal.st.refslice = Parameters.Ref_Slice(i);
        matlabbatch{i}.spm.temporal.st.prefix = 'a';
    end
end


%%
function [Slice_order, ReferenceSlice] = slice_sorting(Slice_number, SliceTiming)

[~, Slice_order] = sort(SliceTiming);

if length(Slice_order) < Slice_number
     Slice_order=[Slice_order, Slice_number];
end

ReferenceSlice=Slice_order(ceil(Slice_number/2));

end

