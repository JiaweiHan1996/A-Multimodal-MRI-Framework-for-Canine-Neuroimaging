function PathList4SPM=spread_Fodr4SPM(InFodr,ImgTyp)
%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com


switch ImgTyp
    case '.4dnii'
         PathList4SPM=spread_4dImgFodr4SPM(InFodr);
    case '.3dnii'
         PathList4SPM=spread_3dImgFodr4SPM(InFodr,'.3dnii');
    case '.img'
         PathList4SPM=spread_3dImgFodr4SPM(InFodr,'.img');        
    case '.nii.gz'
        inpath_Misc(InFodr,'Gunzip1stSubGzFile');
        PathList4SPM=spread_4dImgFodr4SPM(InFodr);
    otherwise
            error('not exsit Img type');
end


function PathList4SPM=spread_4dImgFodr4SPM(Nii4dFodrPath)
Nii4dPath=inpath_Misc(Nii4dFodrPath,'Get1stSubNiiPath');
Nii4dObject=nifti(Nii4dPath);
PathList4SPM=[];
for i=1:size(Nii4dObject.dat,4)
    PathList4SPM=[PathList4SPM;{[Nii4dPath ',',num2str(i)]}];
end


function PathList4SPM=spread_3dImgFodr4SPM(Img3dFodrPath,DataTyp)
if strcmp(DataTyp,'.3dnii')
    Img3dList=dir_4RegExp(Img3dFodrPath,'*.nii');
elseif strcmp(DataTyp,'.img')
    Img3dList=dir_4RegExp(Img3dFodrPath,'*.img');
end
PathList4SPM=[];
for i=1:length(Img3dList)
        PathList4SPM=[PathList4SPM;{[Img3dFodrPath filesep Img3dList{i}]}];
end

