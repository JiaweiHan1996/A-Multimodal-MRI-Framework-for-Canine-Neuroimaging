function DirList4RegExp=dir_4RegExp(InPath,RegExp)
%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com


DirList4RegExp={dir([InPath filesep RegExp])};
DirList4RegExp={DirList4RegExp{1}(:).name};