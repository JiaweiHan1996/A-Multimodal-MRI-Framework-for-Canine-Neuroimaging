function [OutVolume OutHead] = Reslice_4D(InputFile, OutputFile, NewVoxSize, hld, TargetSpace)
% FORMAT [OutVolume OutHead] = y_Reslice_4D(InputFile, OutputFile, NewVoxSize, hld, TargetSpace)
% Usage: y_Reslice_4D('rest.nii', 'rest_resliced.nii', [3 3 3], 1, 'ImageItself')

if nargin<=4
    TargetSpace='ImageItself';
end

[AllVolume, V] = y_ReadAll(InputFile);
nVolumes = size(AllVolume, 4);

if strcmpi(TargetSpace, 'ImageItself')
    [RefData, RefHead] = y_Read(InputFile);
    origin = RefHead.mat(1:3,4);
    origin = origin + [RefHead.mat(1,1);RefHead.mat(2,2);RefHead.mat(3,3)] - ...
             [NewVoxSize(1)*sign(RefHead.mat(1,1)); NewVoxSize(2)*sign(RefHead.mat(2,2)); NewVoxSize(3)*sign(RefHead.mat(3,3))];
    origin = round(origin./NewVoxSize').*NewVoxSize';
    
    mat = [NewVoxSize(1)*sign(RefHead.mat(1,1)) 0 0 origin(1)
           0 NewVoxSize(2)*sign(RefHead.mat(2,2)) 0 origin(2)
           0 0 NewVoxSize(3)*sign(RefHead.mat(3,3)) origin(3)
           0 0 0 1];
    
    dim = (RefHead.dim(1:3)-1).*diag(RefHead.mat(1:3,1:3))';
    dim = floor(abs(dim./NewVoxSize)) + 1;
    
    TargetInfo.mat = mat;
    TargetInfo.dim = dim;
else
    [RefData, RefHead] = y_Read(TargetSpace);
    TargetInfo.mat = RefHead.mat;
    TargetInfo.dim = RefHead.dim;
end

OutVolumes_4D = zeros([TargetInfo.dim, nVolumes]);

for t = 1:nVolumes
    
    CurrentVolume = AllVolume(:,:,:,t);
    CurrentHead = V;
    CurrentHead.fname = '';  
    CurrentHead.dim = V.dim(1:3);
    CurrentHead.n = [t 1]; 
    M = inv(CurrentHead.mat) * TargetInfo.mat;
    [x1, x2, x3] = ndgrid(1:TargetInfo.dim(1), 1:TargetInfo.dim(2), 1:TargetInfo.dim(3));
    y1 = M(1,1)*x1 + M(1,2)*x2 + (M(1,3)*x3 + M(1,4));
    y2 = M(2,1)*x1 + M(2,2)*x2 + (M(2,3)*x3 + M(2,4));
    y3 = M(3,1)*x1 + M(3,2)*x2 + (M(3,3)*x3 + M(3,4));
    
    d = [hld*[1 1 1]' [1 1 0]'];
    C = spm_bsplinc(CurrentHead, d);
    
    OutVolume = spm_bsplins(C, y1, y2, y3, d);
    
    tiny = 5e-2;
    Mask = true(size(y1));
    Mask = Mask & (y1 >= (1-tiny) & y1 <= (CurrentHead.dim(1)+tiny));
    Mask = Mask & (y2 >= (1-tiny) & y2 <= (CurrentHead.dim(2)+tiny));
    Mask = Mask & (y3 >= (1-tiny) & y3 <= (CurrentHead.dim(3)+tiny));
    OutVolume(~Mask) = 0;
    OutVolumes_4D(:,:,:,t) = OutVolume;
end

OutHead = V;
OutHead.mat = TargetInfo.mat;
OutHead.dim = [TargetInfo.dim, nVolumes];
OutHead.dt = [16 0];  

OutVolume = OutVolumes_4D;
