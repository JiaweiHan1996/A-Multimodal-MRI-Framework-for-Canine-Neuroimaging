function [DirStructlist]=dir_List(InDir)

% if the type of InDir is legal
%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com


if 0==exist(InDir,'file')
   error('folder is not exist!');
elseif 2==exist(InDir,'file')
    warning('InDir is File or exists as a file with extension .m.');%if path is equal to .m
elseif 7~=exist(InDir,'file')
    error('the type of InDir is inlegal')
end

% for MAC OS compatablie
% DirStructlist = dir(InDir);
%       if strcmpi(DirStructlist(3).name,'.DS_Store') 
%                 StartIndex=4;
%       else
%                 StartIndex=3;
%       end    
% DirStructlist = DirStructlist(StartIndex:end);
DirStructlist = dir(InDir);
isValidFolder = [DirStructlist.isdir] & ...
                ~ismember({DirStructlist.name}, {'.', '..', '.DS_Store'});
DirStructlist = DirStructlist(isValidFolder);


%___________________________________________________________________________
%	Written by Xi-ze Jia
% 	Mail to Authors:  <a href="willbbetter@gmail.com">Xi-ze Jia</a>;
%	Version=1.10;
%	Release=20140331;
%   Revised by Xi-ze Jia 2014 04 07 if the type of InDir is legal 