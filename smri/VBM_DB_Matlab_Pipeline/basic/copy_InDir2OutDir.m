function copy_InDir2OutDir(InDir,OutDir,Option,Parameter)
%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com


if nargin<=3
    Parameter='';
    if nargin<=2
        Option='All';
    end
end


InSubfodrList=init_InDirAndOutDir(InDir,OutDir);
    switch Option
        case 'All'
            copy_all_InDir2OutDir(InDir,OutDir,InSubfodrList);  
        case 'RegularExpression'
            CpRegExp=Parameter;
            copy_UseRegularExpression(InDir,OutDir,InSubfodrList,CpRegExp);
    end

    
    

    
    
function copy_all_InDir2OutDir(InDir,OutDir,InSubfodrList)
for i=1:length(InSubfodrList)
    copyfile([InDir filesep InSubfodrList{i}],[OutDir filesep InSubfodrList{i}]);    
end

function copy_UseRegularExpression(InDir,OutDir,SubfodrList,CpRegExp)
for i=1:length(SubfodrList)   
    FileList4Copy=get_Copylist([InDir filesep SubfodrList{i}],CpRegExp);
    copy_FileList(FileList4Copy,[InDir filesep SubfodrList{i}],[OutDir filesep SubfodrList{i}]);
end



function FileList4Copy=get_Copylist(InSubfodrPath,CpRegExp)
FileList4Copy=dir_4RegExp(InSubfodrPath,CpRegExp);
if(isempty(FileList4Copy))  
   fprintf('\n%s\n',InSubfodrPath);
   fprintf('%s not exist\n',CpRegExp);  
end


function copy_FileList(FileList4Copy,InSubfodrPath,OutSubfodrPath)
if ~isempty(FileList4Copy)
   inpath_Misc(OutSubfodrPath,'MakeCurrentDir');
end
for i=1:length(FileList4Copy)
    copyfile([InSubfodrPath filesep FileList4Copy{i}],[OutSubfodrPath filesep FileList4Copy{i}]);
end