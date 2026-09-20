function varargout = mecIO(action, varargin)
%MECIO Read masked echoes and write the combined NIfTI.

switch lower(char(action))
    case 'load'
        [varargout{1:nargout}] = loadData(varargin{:});
    case 'write'
        varargout{1} = writeNii(varargin{:});
    otherwise
        error('MEComb:IoAction', 'Unknown action: %s', action);
end
end

function [data, mask, info] = loadData(echoFiles, maskFile)
echoImgs = cell(3, 1);
refInfo = struct();
for iEcho = 1:3
    echoFile = char(echoFiles{iEcho});
    if exist(echoFile, 'file') ~= 2
        error('MEComb:FileNotFound', 'Echo file not found: %s', echoFile);
    end
    echoImgs{iEcho} = niftiread(echoFile);
    if iEcho == 1
        refInfo = niftiinfo(echoFile);
    end
end

refSize = size4d(echoImgs{1});
for iEcho = 2:3
    if ~isequal(size4d(echoImgs{iEcho}), refSize)
        error('MEComb:EchoShape', 'All echo images must have matching dimensions.');
    end
end

if isempty(maskFile)
    mask = true(refSize(1), refSize(2), refSize(3));
else
    mask = squeeze(niftiread(char(maskFile))) ~= 0;
    if ~isequal(size(mask), refSize(1:3))
        error('MEComb:MaskShape', 'Mask and echo images must have matching spatial dimensions.');
    end
end

nSamples = nnz(mask);
nVols = refSize(4);
data = zeros(nSamples, 3, nVols, 'like', echoImgs{1});
maskC = permute(mask, [3, 2, 1]);
for iEcho = 1:3
    for iVol = 1:nVols
        volume = permute(echoImgs{iEcho}(:, :, :, iVol), [3, 2, 1]);
        data(:, iEcho, iVol) = volume(maskC);
    end
end
info = refInfo;
end

function outFile = writeNii(values, mask, outFile, refInfo)
if size(values, 1) ~= nnz(mask)
    error('MEComb:WriteShape', 'optcom rows must match true voxels in all1mask.');
end
outDir = fileparts(outFile);
if exist(outDir, 'dir') ~= 7
    mkdir(outDir)
end

[hdr, ~, filetype, machine] = load_untouch_header_only(refInfo.Filename);
if filetype ~= 2
    error('MEComb:Reference', 'The reference echo must be an uncompressed .nii file.');
end
hdr.dime.dim = [4, size(mask), size(values, 2), 1, 1, 1];
hdr.dime.datatype = 16;
hdr.dime.bitpix = 32;
hdr.dime.pixdim(6:8) = 1;
hdr.dime.vox_offset = 352;
hdr.dime.scl_slope = 0;
hdr.dime.scl_inter = 0;

fid = fopen(outFile, 'w', machine);
if fid < 0
    error('MEComb:Write', 'Unable to create output: %s', outFile);
end
save_untouch_nii_hdr(hdr, fid);
fwrite(fid, zeros(1, 4, 'uint8'), 'uint8');
dataBytes = prod(double(size(mask))) * double(size(values, 2)) * 4;
chunk = zeros(1, 1024 * 1024, 'uint8');
while dataBytes > 0
    nBytes = min(dataBytes, numel(chunk));
    fwrite(fid, chunk(1:nBytes), 'uint8');
    dataBytes = dataBytes - nBytes;
end
fclose(fid);

for iVol = 1:size(values, 2)
    volume = unmask(values(:, iVol), mask);
    save_untouch_slice(volume, outFile, 1:size(mask, 3), iVol);
end
end

function volume = unmask(values, mask)
maskC = permute(logical(mask), [3, 2, 1]);
volumeC = zeros(size(maskC), 'single');
volumeC(maskC) = single(values);
volume = permute(volumeC, [3, 2, 1]);
end

function s = size4d(img)
s = size(img);
if numel(s) < 4
    s = [s, ones(1, 4 - numel(s))];
end
end


