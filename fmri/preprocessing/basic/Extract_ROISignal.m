function Signal_Matrix=Extract_ROISignal(AllVolume, ROIDefCell, OutputName,IsMultipleLabel,MaskDataIn)
%use unit
% AllVolumn 4d matrix
% AllVolumn 4d nii
% AllVolumn 3d folder

%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com


    if nargin<=4
        MaskDataIn='';
        if nargin<=3
            IsMultipleLabel=0;
            if nargin<=2
                OutputName='';
            end
        end
    end
   
  Signal_CellMatrix=cell(1,length(ROIDefCell));  
  for i=1:length(ROIDefCell)
      Signal_CellMatrix{1,i}=Extract_OneROISignal(AllVolume, ROIDefCell{i},IsMultipleLabel,MaskDataIn);
  end
 Signal_Matrix=cell2mat(Signal_CellMatrix);

 OutputFiles(OutputName,Signal_Matrix);
end

function Signal_Matrix=Extract_OneROISignal(AllVolume,ROIDef,IsMultipleLabel,MaskDataIn)
   [AllVolume,Header,BrainSize]=Init_Input(AllVolume);   
   ROImask=Creat_ROImask(ROIDef,Header,BrainSize,IsMultipleLabel);
   Signal_Matrix=Get_Signal(ROImask,AllVolume,MaskDataIn);
end


function [AllVolumeMatrix,Header,BrainSize]=Init_Input(AllVolume)
    fprintf('\n\t Extractiang ROI signals...');
    if brief_misc('IsNiftifile',AllVolume)||(exist(AllVolume,'file')==7)
        [AllVolumeMatrix, VoxelSize, ImgFileList, Header, VolumnAmount] =read_To4d(AllVolume);
    elseif isnumeric(AllVolume) 
        AllVolumeMatrix=AllVolume;
    else
        error('Wrong input type, please check: input value of Extract_ROISignal');
    end    
    [DimX DimY DimZ TimePoints]=size(AllVolumeMatrix);
    BrainSize = [DimX,DimY,DimZ];
end



function ROImask=Creat_ROImask(ROIDef,Header,BrainSize,IsMultipleLabel)
     if strcmpi(int2str(size(ROIDef)),int2str(BrainSize)) % MaskMatrix
           ROImask=ROIDef; 
     elseif SphereROI('IsBallArray', ROIDef) %BallArray [CenterX, CenterY, CenterZ, Radius]
           ROImask=SphereROI('BallArray2Mask', ROIDef,Header);
     elseif SphereROI('IsBallStr', ROIDef)   %BallStr 'ROI Center(mm)=(0, 0, 0); Radius=6.00 mm.'
           ROImask=SphereROI('BallStr2Mask', ROIDef,Header);         
     elseif brief_misc('IsNiftifile',ROIDef)  %Nifti file   
           [ROImask,VoxDim,Header] =read_To3d(ROIDef);
     else
           error(sprintf('Wrong ROI definition, please check: \n%s', ROIDef));
     end
     
     if 1~=IsMultipleLabel
        ROImask=logical(ROImask);
     end
     
end



function Signal_Matrix=Get_Signal(ROImask,AllVolume,MaskDataIn)
   [Brain2D_TPxN,nDimTimePoints]=ConvertBrain(AllVolume,MaskDataIn);
   MaskLable=unique(ROImask);
   MaskLable(~logical(MaskLable))=[];
   Signal_Matrix = zeros(nDimTimePoints,length(MaskLable));
   for i=1:length(MaskLable)
       Signal_Matrix(:,i) = mean(Brain2D_TPxN(:,find(ROImask==MaskLable(i))),2);
   end
end



function [Brain2D_TPxN,nDimTimePoints]=ConvertBrain(AllVolume,MaskDataIn)
    [DimX DimY DimZ nDimTimePoints]=size(AllVolume);
    MaskMatrix = load_MaskFile(MaskDataIn,[DimX,DimY,DimZ]);
    Msk2D_1xN=reshape(MaskMatrix,1,[]);
    Brain2D_NxTP=reshape(AllVolume,[],nDimTimePoints);
    Brain2D_TPxN=ctranspose(Brain2D_NxTP);
    Brain2D_TPxN=Brain2D_TPxN(:,logical(Msk2D_1xN));
end

function OutputFiles(OutputName,Signal_Matrix)
[pathstr, name, ext] = fileparts(OutputName);
inpath_Misc(OutputName,'MakeParentDir');
save([fullfile(pathstr,['ROISignals_', name]), '.mat'], 'Signal_Matrix');
save([fullfile(pathstr,['ROISignals_', name]), '.txt'], 'Signal_Matrix', '-ASCII', '-DOUBLE','-TABS');

ROICorrelation = corrcoef(Signal_Matrix);
save([fullfile(pathstr,['ROICorrelation_', name]), '.mat'], 'ROICorrelation')
save([fullfile(pathstr,['ROICorrelation_', name]), '.txt'], 'ROICorrelation', '-ASCII', '-DOUBLE','-TABS')

ROICorrelation_FisherZ = 0.5 * log((1 + ROICorrelation)./(1- ROICorrelation));
save([fullfile(pathstr,['ROICorrelation_FisherZ_', name]), '.mat'], 'ROICorrelation_FisherZ')
save([fullfile(pathstr,['ROICorrelation_FisherZ_', name]), '.txt'], 'ROICorrelation_FisherZ', '-ASCII', '-DOUBLE','-TABS')
end
