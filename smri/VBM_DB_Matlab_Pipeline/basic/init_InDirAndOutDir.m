function InSubfodrlist=init_InDirAndOutDir(InDir,OutDir)
%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com


inpath_Misc(OutDir,'MakeCurrentDir');
InSubfodrlist=dir_NameList(InDir);