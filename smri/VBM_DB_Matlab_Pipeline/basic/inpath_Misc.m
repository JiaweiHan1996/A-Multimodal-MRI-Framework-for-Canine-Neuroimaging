function OutPut=inpath_Misc(InPath,Option)
% inpath_Misc(InPath,'GetPathName');
% inpath_Misc(InPath,'GetPathWholeName');
% inpath_Misc(InPath,'GetPathExt');
% inpath_Misc(InPath,'Get1SubPath_RegExp');
% Output=inpath_Misc(InPath,'MakeCurrentDir');
% inpath_Misc(InPath,'MakeParentDir');
% inpath_Misc(InPath,'UpdateCurrentDir');
%        Output   -    'updatedir'  delete old dir, make new dir
%                 -    'makenewdir' InPath not exist, make new dir
% inpath_Misc(InPath,'Get1stSubPath');
% inpath_Misc(InPath,'Get1stSubImgPath');
% inpath_Misc(InPath,'Get2ndSubPath');
% inpath_Misc(InPath,'GetParentPath');
% inpath_Misc(InPath,'GetParentWholeName');
% inpath_Misc(InPath,'Get1stSubAmount');
% inpath_Misc(InPath,'Get1stSubNiiPath');
% inpath_Misc(InPath,'GetIndir1stSubject1stSubImgPath');
% inpath_Misc(InPath,'Gunzip1stSubGzFile');
% inpath_Misc(InPath,'GunzipNiigzPath');
% inpath_Misc(InPath,'Path4Delete');
% inpath_Misc(InPath,'FodrEmpty');

%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com



switch Option
    case 'GetPathName'
          OutPut=Get_PathName(InPath);   
    case  'GetPathWholeName'
           OutPut=Get_PathWholeName(InPath);   
    case 'GetPathExt'
          OutPut=Get_PathExt(InPath);
    case 'Get1SubPath_RegExp'
          OutPut=Get_1SubPath_RegExp(InPath);
    case 'MakeParentDir'
          Make_ParentDir(InPath);
    case 'GetParentPath'
          OutPut=Get_ParentPath(InPath);
    case 'GetParentWholeName'
          OutPut=Get_ParentWholeName(InPath);
    case 'MakeCurrentDir'
          OutPut=Make_CurrentDir(InPath);
    case 'UpdateCurrentDir'
          OutPut=Update_CurrentDir(InPath);
    case 'Get1stSubPath'
          OutPut=Get_1stSubPath(InPath);
    case 'Get1stSubImgPath'
          OutPut=Get_1stSubImgPath(InPath);
    case 'Get2ndSubPath'
          OutPut=Get_2ndSubPath(InPath);       
    case 'Get1stSubNiiPath'
          OutPut=Get_1stSubNiiPath(InPath);        
    case 'Get1stSubAmount'
          OutPut=Get_1stSubAmount(InPath);
    case 'GetIndir1stSubject1stSubImgPath'
          OutPut=Get_Indir1stSubject1stSubImgPath(InPath);
    case 'Gunzip1stSubGzFile'
          Gunzip_1stSubGzFile(InPath);
    case 'GunzipNiigzPath'
          Gunzip_NiigzPath(InPath);                  
    case 'Path4Delete'
          Path4Delete(InPath);
    case 'FodrEmpty'
          FodrEmpty(InPath);
    otherwise
        error('error in inpath_Misc');
end
        







function PathName=Get_PathName(InPath)
[pathstr, name, ext]=fileparts(InPath);
PathName=name;

function PathWholeName=Get_PathWholeName(InPath)
[pathstr, name, ext]=fileparts(InPath);
PathWholeName=[name ext];

function PathExt=Get_PathExt(InPath)
[pathstr, name, ext]=fileparts(InPath);
PathExt=ext;


function OutPut=Get_1SubPath_RegExp(InPath)
OutPutList=dir(InPath);
if 1== length(OutPutList)
    OutPut=[inpath_Misc(InPath,'GetParentPath') filesep OutPutList.name];
else
    error('Match RegExp is not equal to 1 file!');
end

function Make_ParentDir(InPath)
[pathstr, name, ext]=fileparts(InPath);
if ~isdir(pathstr)
    mkdir(pathstr);
end

function InPath=Make_CurrentDir(InPath)

if ~isdir(InPath)
    mkdir(InPath);
end

function OutPut=Update_CurrentDir(InPath)
if 7==exist(InPath,'dir')
   warning('%s exist, will be replaced',InPath); 
   rmdir(InPath,'s');
   mkdir(InPath);
   OutPut='updatedir';    
else
   mkdir(InPath);
   OutPut='makenewdir';
end

function SubPath=Get_1stSubPath(InPath)
    SubList=dir_NameList(InPath);
    SubPath=[InPath filesep SubList{1}];

function OutPut=Get_1stSubImgPath(InPath)   
NiifileList=dir_4RegExp(InPath,'*.nii');
GzfileList=dir_4RegExp(InPath,'*.nii.gz');
ImgfileList=dir_4RegExp(InPath,'*.img');
if (length(NiifileList)>=1)&&isempty(GzfileList)&&isempty(ImgfileList)
   OutPut=[InPath filesep NiifileList{1}]; 
elseif(length(GzfileList)>=1)&&isempty(NiifileList)&&isempty(ImgfileList)
   Gunzip_1stSubGzFile(InPath);
   OutPut=inpath_Misc(InPath,'Get1stSubNiiPath'); 
elseif(length(ImgfileList)>=1)&&isempty(NiifileList)&&isempty(GzfileList)
   OutPut=[InPath filesep ImgfileList{1}]; 
end
function SubPath=Get_2ndSubPath(InPath)
    SubList=dir_NameList(InPath);
    SubPath=[InPath filesep SubList{2}];

         
function OutPut=Get_1stSubNiiPath(InPath)
SubList=dir_4RegExp(InPath,'*.nii');
OutPut=[InPath filesep SubList{1}];

function FirstSubAmount=Get_1stSubAmount(InPath)
SubList=dir_NameList(InPath);
FirstSubList=dir_NameList([InPath filesep SubList{1}]);
FirstSubAmount=length(FirstSubList);

function OutPut=Get_Indir1stSubject1stSubImgPath(InPath)
    FirstSubjectfodrPath=inpath_Misc(InPath,'Get1stSubPath');
    OutPut=inpath_Misc(FirstSubjectfodrPath,'Get1stSubImgPath');


function Gunzip_1stSubGzFile(InPath)
GzList=dir_4RegExp(InPath,'*.gz');
if ~isempty(GzList)
    gunzip([InPath filesep GzList{1}]);
    delete([InPath filesep GzList{1}]);
end

function NiifilePath=Gunzip_NiigzPath(InPath)
[NiiGz_path, NiiGz_name, NiiGz_ext]=fileparts(InPath);
[Nii_path, Nii_name, Nii_ext]=fileparts(name);
if strcmp(Nii_ext,'.nii')
   gunzip(InPath);
   delete(InPath);
   NiifilePath=[NiiGz_path filesep Nii_name '.nii'];
   if 0==exist(NiifilePath,'file')
      error('error use inpath_Misc,nii.gz file is wrong!');
   end
else
    error('error use inpath_Misc,nii.gz file is wrong!');    
end


function Path4Delete(Path4Delete)
 if isdir(Path4Delete)
     rmdir(Path4Delete,'s');
 elseif 2==exist(Path4Delete,'file')
     delete(Path4Delete);
 end

function FodrEmpty(FodrPath)
SubList=dir_NameList(FodrPath);
for i=1:length(SubList)
    inpath_Misc([FodrPath filesep SubList{i}],'Path4Delete')
end

function ParentPath=Get_ParentPath(InPath)
[pathstr, name, ext]=fileparts(InPath);
ParentPath=pathstr;


function OutPut=Get_ParentWholeName(InPath)
ParentPath=inpath_Misc(InPath,'GetParentPath');
OutPut=inpath_Misc(ParentPath,'GetPathWholeName');