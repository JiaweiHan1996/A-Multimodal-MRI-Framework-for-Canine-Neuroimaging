function PP = Detrend(PP)
%% update: 20251107
fprintf(['\nDetrend Starting   ||    ' spm('time') '\n']);

[Parameters, PP] = Detrend_basisPara(PP);

for i = 1:length(Parameters.scans_list)
     [filepath, name, ext] = fileparts(Parameters.scans_list{i});
    [AllVolume,~,~, Header,~] = read_To4d(Parameters.scans_list{i});
    AllVolume = run_Detrend(AllVolume, 10);
    out_FunImg_name = ['d' name ext];
    out_FunImg_path = [filepath filesep out_FunImg_name];
    save_Detrend(AllVolume, Header, out_FunImg_path);
    if exist(Parameters.scans_list{i}, 'file')
        delete(Parameters.scans_list{i});
    else
        fprintf('\n[ERROR] Processed file not found: %s\n', output_file);
    end
end

%% PP
PP = OutputCommPara(PP);

fprintf(['\nDetrend Completed   ||    ' spm('time') '\n']);

end

function [Parameters, PP] = Detrend_basisPara(PP)
% ===== Load PP =====
DataList = PP.DataList;
[d, f, ~] = fileparts(PP.FunPath);
FilePath = d;
out_dir_name_Fun = [f 'D'];
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


PP.DataList = DataList;
PP.FunPath = Fun_out_Path;
end

function PP = OutputCommPara(PP)
% Update filenames and other parameters after Detrend

DataList = PP.DataList;

for i = 1:length(DataList.filename)
    if ischar(DataList.filename{i}) && ~isempty(DataList.filename{i})
        DataList.filename{i} = ['d' DataList.filename{i}];
    end
end

% Update PP structure
PP.DataList = DataList;

end

%%
function AllVolume=run_Detrend(AllVolume,CutNumber)

DimX = size(AllVolume,1);
DimY = size(AllVolume,2);
DimZ = size(AllVolume,3);
nDimTimePoint =size(AllVolume,4);

AllVolume=reshape(AllVolume,[],nDimTimePoint)';
theMean=mean(AllVolume);
SegmentLength = ceil(size(AllVolume,2) / CutNumber);
for iCut=1:CutNumber
    if iCut~=CutNumber
        Segment = (iCut-1)*SegmentLength+1 : iCut*SegmentLength;
    else
        Segment = (iCut-1)*SegmentLength+1 : size(AllVolume,2);
    end
    
    AllVolume(:,Segment) = detrend(AllVolume(:,Segment));
    
end

AllVolume=AllVolume+repmat(theMean,[nDimTimePoint,1]);
AllVolume=reshape(AllVolume',[DimX, DimY, DimZ, nDimTimePoint]);
end

%%
function save_Detrend(AllVolume,Header,outdir_FunImg)

Header_Out = Header;
Header_Out.pinfo = [1;0;0];
Header_Out.dt    =[16,0];

write_To4dNifti(AllVolume,Header_Out,outdir_FunImg);
end