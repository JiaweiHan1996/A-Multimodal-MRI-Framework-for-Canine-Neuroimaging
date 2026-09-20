function varargout= SphereROI(AOperation, varargin)
%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com


if nargin<1
   AOperation='Init'; 
end


switch upper(AOperation)
    case 'INIT'		    		  %Init	
        
    case 'SETANDQUIT'	  		  %SetAndQuit

    case 'BALLSTR2BALLARRAY'   	  %BallStr2BallArray
          ChekInput(nargin,AOperation);
          varargout{1}=BallStr2BallArray(varargin{1});
    case 'BALLSTR2MASK'           %BallStr2Mask
          ChekInput(nargin,AOperation);
          varargout{1}=Run_BallStr2Mask(nargin,varargin);       
    case 'BALLARRAY2MASK'         %BallArray2Mask 
          ChekInput(nargin,AOperation);
          varargout{1}=Run_BallArray2Mask(nargin,varargin);
    case 'ISBALLARRAY'            %IsBallArray  [CenterX, CenterY, CenterZ, Radius]
          ChekInput(nargin,AOperation);
          varargout{1}=IsBallArray(varargin{1});
    case 'ISBALLSTR'              %IsBallStr  'ROI Center(mm)=(0, 0, 0); Radius=6.00 mm.'
          ChekInput(nargin,AOperation);
          varargout{1}=IsBallStr(varargin{1});
    otherwise
end
        
        
        
end

function ChekInput(NarginValue,AOperation)
    switch upper(AOperation)
           case 'BALLSTR2BALLARRAY'   	  %BallStr2BallArray
                if 2~=NarginValue
                     error('Usage: result =SphereROI( ''BallStr2BallArray'' , ABallStr);');
                 end  
           case 'BALLSTR2MASK'           %BallStr2Mask
                 if NarginValue<3
                     error('Usage: result =SphereROI( ''BallStr2Mask'' , ABallStr, TheReference, [Unit], [OutMaskName]);');
                 end                 
           case 'BALLARRAY2MASK'  %BallArray2Mask
                 if NarginValue<3
                     error('Usage: result =SphereROI( ''BallArray2Mask'' , ABallArray, TheReference, [Unit], [OutMaskName]);');
                 end           
           case 'ISBALLSTR',      %IsBallStr
                 if 2~=NarginValue
                     error('Usage: result =SphereROI( ''IsBallStr'' , AROIDefinition);');
                 end
           case 'ISBALLARRAY'  %IsBallArray [CenterX, CenterY, CenterZ, Radius]
                 if 2~=NarginValue
                     error('Usage: result =SphereROI( ''IsBallArray'' , AROIDefinition);');
                 end

    end
end


function ABallArray=BallStr2BallArray(ABallStr)  %'ROI Center(mm)=(0, 0, 0); Radius=6.00 mm.'
        ABallArray=zeros(1,4);
        
		[posBegin, posEnd] =regexp(ABallStr, '=\(.*\)');
		BallCenter = str2num(ABallStr((posBegin+2):(posEnd-1)));
		ABallArray(1,1:3) =BallCenter;
        
		ABallStr =ABallStr(posEnd+1:end);
        
		[posBegin, posEnd] =regexp(ABallStr, '=.*mm');
		BallRadius = str2num(ABallStr((posBegin+1):(posEnd-2)));
		ABallArray(1,4) =BallRadius;      
end

function SphereMask=Run_BallStr2Mask(NarginValue,VariableCell)
  if (5==NarginValue)&&(4==length(VariableCell))
     SphereMask=BallStr2Mask(VariableCell{1},VariableCell{2}, VariableCell{3}, VariableCell{4});
     %SphereMask=BallStr2Mask(ABallStr,TheReference, Unit, OutMaskName)
  elseif (4==NarginValue)&&(3==length(VariableCell))
     SphereMask=BallStr2Mask(VariableCell{1},VariableCell{2}, VariableCell{3}); 
  elseif (3==NarginValue)&&(2==length(VariableCell))
     SphereMask=BallStr2Mask(VariableCell{1},VariableCell{2}); 
  else
      error('Usage: result =SphereROI( ''BallStr2Mask'' , ABallStr, TheReference, [Unit], [OutMaskName]);');
  end
end

function SphereMask=Run_BallArray2Mask(NarginValue,VariableCell)
  if (5==NarginValue)&&(4==length(VariableCell))
     SphereMask=BallArray2Mask(VariableCell{1},VariableCell{2}, VariableCell{3}, VariableCell{4});
     %SphereMask=BallArray2Mask(ABallArray,TheReference, Unit, OutMaskName)
  elseif (4==NarginValue)&&(3==length(VariableCell))
     SphereMask=BallArray2Mask(VariableCell{1},VariableCell{2}, VariableCell{3}); 
  elseif (3==NarginValue)&&(2==length(VariableCell))
     SphereMask=BallArray2Mask(VariableCell{1},VariableCell{2}); 
  else
      error('Usage: result =SphereROI( ''BallArray2Mask'' , ABallStr, TheReference, [Unit], [OutMaskName]);');
  end
end

function Is_Result=IsBallStr(ABallDefinitionStr)

    if isempty(ABallDefinitionStr)
        Is_Result=0;        
        return;
    end

    [posBegin, posEnd] =regexp(ABallDefinitionStr, '.*ROI\ Center\(mm\)=\(.*\);\ Radius=.*mm\..*');

    if (~isempty(posBegin) && ~isempty(posEnd)) && (posBegin>=1) && (posEnd<=length(ABallDefinitionStr))
        Is_Result =1;
    else	
        Is_Result =0;
    end
    
end



function Is_Result=IsBallArray(ABallDefinitionStr)
Is_Result=strcmpi(int2str(size(ABallDefinitionStr)),int2str([1, 4]));
end