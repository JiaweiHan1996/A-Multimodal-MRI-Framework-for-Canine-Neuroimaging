function MaskMatrix = load_MaskFile(MaskDataIn,BrainSize)
% BrainSize=[x,y,z]
% Variable must be named mask in Mask mat file
%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com


    MaskType=Judge_MaskType(MaskDataIn);
    MaskMatrix=CreatMaskMatrix(MaskType,BrainSize,MaskDataIn);
    MaskMatrix=MaskMatrixChek(MaskMatrix,BrainSize);
end

function MaskType=Judge_MaskType(MaskDataIn)
    if ( strcmp(MaskDataIn, '')|| (isnumeric(MaskDataIn) && MaskDataIn==0) )
        MaskType='NoMask';
    elseif ( strcmpi(MaskDataIn, 'Default')||( isnumeric(MaskDataIn) && MaskDataIn==1) )
        MaskType='DefaultMask';
    else
        if (ischar(MaskDataIn))
            if strcmpi(MaskDataIn(end-3:end), '.img') || strcmpi(MaskDataIn(end-3:end), '.nii')
               MaskType='MaskFile';
            else			
               MaskType='MaskMat';
            end
        else
            error('There are no appropriate mask file.');
        end
    end
end


function MaskMatrix=CreatMaskMatrix(AOperation,BrainSize,MaskDataIn)  

    switch upper(AOperation)
        case 'NOMASK' %NoMask
              MaskMatrix=ones(BrainSize);
        case 'DEFAULTMASK' %DefaultMask
              MaskMatrix=LoadDefaultMask(BrainSize);
        case 'MASKFILE' %MaskFile
              [MaskMatrix, MaskVoxDim, MaskHeader]=read_To3d(MaskDataIn);            
        case 'MASKMAT' %MaskMat
              MaskMatrix=LoadMaskMat(MaskDataIn);
    end
end


function MaskMatrix=LoadDefaultMask(BrainSize)
%BrainSize=[AX, AY, AZ];

MainPath=get_Parameters('MainFunctionPath');
switch int2str(BrainSize)
	    case '79  95  69'   % 'default''[2 2 2]'
	        [MaskMatrix, MaskVoxDim, MaskHeader]=read_To3d([MainPath '/mask/BrainMask_05_79x95x69.img']); 
	    case '53  63  46'   % 'default''[3 3 3]'	        
			[MaskMatrix, MaskVoxDim, MaskHeader]=read_To3d([MainPath '/mask/BrainMask_05_53x63x46.img']); 
	    case '91  109   91'  % 'template''[2 2 2]'	        
			[MaskMatrix, MaskVoxDim, MaskHeader]=read_To3d([MainPath '/mask/BrainMask_05_91x109x91.img']); 
	    case '61  73  61'   % 'template' '[3 3 3]'	        
			[MaskMatrix, MaskVoxDim, MaskHeader]=read_To3d([MainPath '/mask/BrainMask_05_61x73x61.img']);
	    otherwise
	        error(sprintf('There are no appropriate default mask file:\n\tVolume size=79*95*69 ,Voxel size=2*2*2;\n\tVolume size=53*63*46, Voxel size=3*3*3;\n\tVolume size=91*109*91, Voxel size=2*2*2;\n\tVolume size=61*73*61, Voxel size=3*3*3;\n Please set MaskDataIn = 0.'));
	end %end switch
end

function MaskMatrix=LoadMaskMat(MaskDataIn)
         load(MaskDataIn);  
         if 1==exist('mask','var')
            MaskMatrix=mask;
         else
            error('Variable must be named mask in Mask mat file!');
         end
end


function MaskMatrix=MaskMatrixChek(MaskMatrix,BrainSize)

    MaskMatrix =logical(MaskMatrix); 

    if ndims(MaskMatrix)~=3
        error('mask error, mask is not 3d');
    end	

    if ~all(size(MaskMatrix)==BrainSize)		
        error(sprintf('\n\tMask does not match.\n\tMask size is %dx%dx%d, not same with required size %dx%dx%d',size(mask), [AX, AY, AZ]));
    end
end