function [Volume4D, VoxelSize, ImgFileList, Header, VolumnAmount] = read_To4d(ADataDir)
%Build a 4D matrix for REST from series of Brain's volume/(time point). By Xiao-Wei Song
%------------------------------------------------------------------------------------------------------------------------------
% Input:
%     ADataDir  -  The informatino of the dataset, could be:
%                  1. The directory of 3D image data 
%                  2. The filename of one 4D data file
%                  3. a Cell (nFile * 1 cells) of filenames of 3D image data
% Output:
%     AllVolume    - The 4D data matrix (DimX*DimY*DimZ*DimTimePoints)
%     VoxelSize    - The voxel size
%     ImgFileList  - The list of files of image data
%     Header       - The header information of NIfTI image
%     nVolumn      - The number of volumns
%___________________________________________________________________________
%	Copyright(c) 2007~2010
%	State Key Laboratory of Cognitive Neuroscience and Learning in Beijing Normal University
%	Written by Xiao-Wei Song
%	http://resting-fmri.sourceforge.net
% 	Mail to Authors:  <a href="Dawnwei.Song@gmail.com">Xiaowei Song</a>; <a href="ycg.yan@gmail.com">Chaogan Yan</a>
%	Version=1.3;
%	Release=20090321;
%   Revised by YAN Chao-Gan 080610: NIFTI compatible
%   Revised by YAN Chao-Gan, 090321. Data in processing will not be converted to the format 'int16'.
%   Revised by YAN Chao-Gan, 091001. If data has too huge or too many volumes, then it will be loaded into memory in 'single' format.
%   Revised by DONG Zhang-ye, 110817. add 3d/4d *.nii file support, add two funcitons 'Construct4DVolume' for construct the 4D volume and 'initAllvolume' to initialize the 4D volume, add an output: nVolume just for the estimation to the sample length.
%   Revised by YAN Chao-Gan, 111111. Add the support for .nii.gz files.
%   Revised by YAN Chao-Gan, 120119. Also support one 4d file other than a directory.
%   Last revised by YAN Chao-Gan, 120217. Also support a cell of image filenames
inpath_Misc(ADataDir,'Gunzip1stSubGzFile');

if iscell(ADataDir)  ||  (~iscell(ADataDir) && isfolder(ADataDir))
    if iscell(ADataDir) % YAN Chao-Gan, 120217. Also support a cell of image filenames
        if size(ADataDir,1)==1
            ADataDir=ADataDir';
        end
        ImgFileList = ADataDir;
        VolumnAmount = length(ADataDir);
        ADataDir='';
    else
        theFileList = dir(ADataDir);
        ImgFileList ={};
        VolumnAmount=0; % add counter
        for x = 3:size(struct2cell(theFileList),2)
            if (length(theFileList(x).name)>4) && strcmpi(theFileList(x).name(end-3:end), '.hdr')
                if strcmpi(theFileList(x).name(1:end-4), theFileList(x+1).name(1:end-4))
                    ImgFileList=[ImgFileList; {theFileList(x).name}];
                    VolumnAmount = VolumnAmount + 1; % add counter
                else
                    error('*.{hdr,img} should be pairwise. Please re-examin them.');
                end
            else % add *.nii file support DONG 110817
                if ((length(theFileList(x).name)>4) && strcmpi(theFileList(x).name(end-3:end) , '.nii')) || ...
                        ((length(theFileList(x).name)>7) && strcmpi(theFileList(x).name(end-6:end) , '.nii.gz')) %YAN Chao-Gan, 120525. Fixed a bug for file name length.

                    imageNii=[ADataDir,filesep,theFileList(x).name];
                    N=rp_ReadNiiNum(imageNii);
                    VolumnAmount = VolumnAmount + N;
                    ImgFileList=[ImgFileList; {theFileList(x).name}];
                end
            end
        end
        clear theFileList;
        
%         if nVolumn <10,
%             warning('There are too few time points.(i.e. The number of the time points is less than 10)');
%         end
        
        %read the normalized functional images
        % -------------------------------------------------------------------------
        fprintf('\n\t Read 3D EPI functional images: "%s".', ADataDir);
    end
    
    
    theDataType ='double';	%Default data-type I assumed!
    
    readVolume=0;% record the current volume in the cycle
%     rp_waitbar(0.001, ...
%         ImgFileList{1}, ...
%         'Build 3D+time Dataset','Child','NeedCancelBtn');   % initialize the waiting bar,
    for x = 1:size(ImgFileList,1)
        theFilename = fullfile(ADataDir,ImgFileList{x});
        
        if (length(theFilename)>4) && (strcmpi(theFilename(end-3:end), '.hdr') || strcmpi(theFilename(end-3:end), '.img'))
            [theOneTimePoint, VoxelSize, Header] = rp_readfile(theFilename);
            if readVolume==0
                [Volume4D,theDataType]=initAllvolume(theOneTimePoint,VolumnAmount);
                Volume4D =repmat(Volume4D, [1,1,1, VolumnAmount]);
            else
                if theDataType=='uint16',
                    Volume4D(:,:,:,x) = uint16(theOneTimePoint);
                elseif	theDataType=='single',
                    Volume4D(:,:,:,x) = single(theOneTimePoint);
                elseif	theDataType=='double',
                    Volume4D(:,:,:,x) = (theOneTimePoint);
                else
                    rp_misc('ComplainWhyThisOccur');
                end
            end
            readVolume=readVolume+1;
        else % add *.nii file support
            if ((length(theFilename)>4) && strcmpi(theFilename(end-3:end) , '.nii')) || ...
                    ((length(theFilename)>7) && strcmpi(theFilename(end-6:end) , '.nii.gz')) %YAN Chao-Gan, 120525. Fixed a bug for file name length.
                [theOneNiiFileTimePoint, VoxelSize, Header] = rp_readfile(theFilename, 'all');
                N = size(theOneNiiFileTimePoint, 4);
                if readVolume==0
                    [Volume4D,theDataType]=initAllvolume(theOneNiiFileTimePoint,VolumnAmount);
                    Volume4D =repmat(squeeze(Volume4D(:,:,:,1)), [1,1,1, VolumnAmount]);
                end
                if	theDataType=='single'
                    theOneNiiFileTimePoint=single(theOneNiiFileTimePoint);
                end
                %AllVolume=cat(4,AllVolume,theOneNiiFileTimePoint);
                Volume4D(:,:,:,readVolume+1:readVolume+N) = theOneNiiFileTimePoint;
                readVolume=readVolume+N;
            end
        end
%         rp_waitbar(readVolume/nVolumn, ...
%             ImgFileList{x}, ...
%             'Build 3D+time Dataset','Child','NeedCancelBtn');
        
        if ~mod(x,5)
            fprintf('.');
        end
    end
    VoxelSize = VoxelSize';
    fprintf('\n');
    
else % YAN Chao-Gan, 120119. Also support one 4d file other than a directory.
    fprintf('\n\t Read images: "%s".', ADataDir);
    
    [Volume4D, VoxelSize, Header] = rp_readfile(ADataDir);
    ImgFileList=ADataDir;
    VolumnAmount=size(Volume4D,4);
end



function [AllVolume,theDataType]=initAllvolume(theOneTimePoint,nVolumn)
%To initialize the AllVolume
%110819 DONG
AllVolume=theOneTimePoint;
theDataType ='double';
Size_AllVolume=size(AllVolume);
if prod([Size_AllVolume(1:3), nVolumn,8])>1024*1024*1024 % YAN Chao-Gan 091001, If data is with two many volumes, then it will be converted to the format 'single'.
    theDataType ='single';
    AllVolume=single(AllVolume);
end
