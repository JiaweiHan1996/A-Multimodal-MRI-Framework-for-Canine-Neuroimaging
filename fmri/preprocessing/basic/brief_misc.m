function varargout= brief_misc(AOperation,varargin)
% brief_misc('IsNiftifile',input1);
% ListboxStr=brief_misc('GetSublistboxStr4StartDir',WorkDirectory,StartFun,StartT1);
%  brief_misc('CellArray2Listboxstr',CellArray);
%  brief_misc('ListboxStr2CellArray',Listboxstr);
%  brief_misc('Cell2txt',InCell,OutText,WriteMode);
%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com



    switch upper(AOperation)
        case 'ISNIFTIFILE' %IsNiftifile
             ChekInput(AOperation,nargin);
             varargout{1}=IsImgfile(varargin{1});
        case 'GETSUBLISTBOXSTR4STARTDIR' %GetSublistboxStr4StartDir
            ChekInput(AOperation,nargin);
            varargout{1}=get_SublistboxStr4StartDir(varargin{1},varargin{2},varargin{3});
        case 'CELLARRAY2LISTBOXSTR' %CellArray2Listboxstr
             ChekInput(AOperation,nargin);
             varargout{1}=CellArray2Listboxstr(varargin{1});
        case 'LISTBOXSTR2CELLARRAY' %ListboxStr2CellArray
             ChekInput(AOperation,nargin)
             varargout{1}=Listboxstr2CellArray(varargin{1});
        case 'CELL2TXT'%Cell2txt
             ChekInput(AOperation,nargin)
             rp_cell2txt(varargin{1},varargin{2},varargin{3});
            
    end
end


function ChekInput(AOperation,NarginValue)
    switch upper(AOperation)
        case 'ISNIFTIFILE' %IsNiftifile
             if 2~=NarginValue
                 error('Usage: result =brief_misc( ''IsNiftifile'' , TheInput);');
             end 
        case 'GETSUBLISTBOXSTR4STARTDIR' %GetSublistboxStr4StartDir
             if 4~=NarginValue
                 error('Usage: result =brief_misc( ''GetSublistboxStr4StartDir'' , WorkDirectory,StartFun,StartT1);');
             end
        case 'CELLARRAY2LISTBOXSTR' %CellArray2Listboxstr
             if 2~=NarginValue
                 error('Usage: result =brief_misc( ''CellArray2Listboxstr'' , InputCellArray);');
             end   
        case 'LISTBOXSTR2CELLARRAY' %ListboxStr2CellArray
             if 2~=NarginValue
                 error('Usage: result =brief_misc( ''ListboxStr2CellArray'' , Input ListboxStr);');
             end      
        case 'CELL2TXT'%Cell2txt
             if 4~=NarginValue
                 error('Usage: result =brief_misc( ''Cell2txt'' , InCell , OutText);');
             end              
    end

end

function IsResult=IsImgfile(TheInput)
   if exist(TheInput,'file')==2
       FileExt=inpath_Misc(TheInput,'GetPathExt');
       if strcmpi(FileExt, '.img') || strcmpi(FileExt, '.hdr') || strcmpi(FileExt, '.nii') || strcmpi(FileExt, '.nii.gz') 
          IsResult=1;
       else
           IsResult=0;
       end
   else
       IsResult=0;
   end
end


function ListboxStr=get_SublistboxStr4StartDir(WorkDirectory,StartFun,StartT1)

   if isdir([WorkDirectory filesep StartFun])
          SubfodrList=dir_NameList([WorkDirectory filesep StartFun]);
   elseif isdir([WorkDirectory filesep StartT1])
          SubfodrList=dir_NameList([WorkDirectory filesep StartT1]);
   else
       msgbox('Folder is not exist!');
       return;
       
   end
   ListboxStr=brief_misc('CellArray2Listboxstr',SubfodrList);
end


function Listboxstr=CellArray2Listboxstr(CellArray)
    Listboxstr='';
    
   for i=1:length(CellArray)
       if isempty(Listboxstr)
           Listboxstr=CellArray{i};
       else
           Listboxstr=[Listboxstr '|' CellArray{i}];
       end
   end
end

function CellArray=Listboxstr2CellArray(Listboxstr)


if isempty(Listboxstr)
    CellArray='';
elseif ~isempty(Listboxstr)
    for i=1:size(Listboxstr,1)
        CellArray{i,1}=Listboxstr(i,:);
    end    
end
end



function rp_cell2txt(InCell,OutText,WriteMode)
%write cell to a txt file  By Xi-ze Jia
%---------------------------------------------------------------------------
%function cell2txt(InCell,OutText)
% Input:
%     InCell     -   Cell matrix                    
%     OutText    -   path of output text
%     WriteMode  -   'w'
%                    'a+'
%___________________________________________________________________________
%	Written by Xi-ze Jia
% 	Mail to Authors:  <a href="willbbetter@gmail.com">Xi-ze Jia</a>;
%	Version =1.00;
%	Release=20140518;


if ~ischar(OutText)
    disp('txt path is wrong');
    return
end

fid = fopen(OutText,WriteMode);
[DimRow,DimColumn] = size(InCell);
for i = 1 : DimRow
    for k = 1 : DimColumn
        fprintf(fid,'%s\t',InCell{i,k});
    end
    fprintf(fid,'\n');
end

fclose(fid);
end
