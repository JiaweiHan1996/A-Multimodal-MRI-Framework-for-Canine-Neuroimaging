function ParameterOutput=get_Parameters(Option)
%ParameterOutput=get_Parameters('All')
%ParameterOutput=get_Parameters('MainFunctionPath')
%ParameterOutput=get_Parameters('SpmFunctionPath')
%TemplatePath=get_Parameters('TemplatePath')
%FunctionName=get_Parameters('FunctionName')
%FunctionName=get_Parameters('Ch2FileName')
%ParameterOutput=get_Parameters('MainFunctionWholeName')
%ParameterOutput=get_Parameters('ParaSavePath')
%MaskPath=get_Parameters('MaskPath')
%get_Parameters('CurrentVersion')  

%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com


    if nargin<=0
       Option='All';
    end

    switch upper(Option)

        case 'ALL' %'All'
            ParameterOutput=out_AllParameters();
        case 'MAINFUNCTIONWHOLENAME' %MainFunctionWholeName
            ParameterOutput=out_MainFunctionWholeName();            
        case 'MAINFUNCTIONPATH' %'MainFunctionPath' 
            ParameterOutput=out_MainFunctionPath();
        case 'SPMFUNCTIONPATH' %'SpmFunctionPath'
            ParameterOutput=out_SpmFunctionPath();
        case upper('CurrentVersion')
            ParameterOutput='RESTplus_V1.0_beta';
        case 'TEMPLATEPATH' %'TemplatePath' 
            ParameterOutput=out_TemplatePath();
        case 'MASKPATH' %'MaskPath' 
            ParameterOutput=out_MaskPath();
        case 'FUNCTIONNAME' %FunctionName
            ParameterOutput=out_FunctionName();
        case 'CH2FILENAME'%Ch2FileName
            ParameterOutput=out_Ch2FileName();
        case 'MNI152FILENAME'%Ch2FileName
            ParameterOutput=out_MNI152FileName();
        case 'PARASAVEPATH_BASIC'%ParaSavePath_Basic
            ParameterOutput=out_ParaSavePath_Basic();
        case upper('ParaSavePath_Advance')
            ParameterOutput=out_ParaSavePath_Advance();
    end
end

function ParameterOutput=out_AllParameters()
    ParameterOutput.MainFunctionPath=out_MainFunctionPath();
    ParameterOutput.SpmFunctionPath=out_SpmFunctionPath();
    ParameterOutput.TemplatePath=out_TemplatePath();
end

function ParameterOutput=out_MainFunctionWholeName()
    ParameterOutput='restplus.m';
end
function ParameterOutput=out_TemplatePath()
    MainFunPath=out_MainFunctionPath();
    ParameterOutput=[MainFunPath filesep 'Template'];
end

function ParameterOutput=out_MaskPath()
    MainFunPath=out_MainFunctionPath();
    ParameterOutput=[MainFunPath filesep 'mask'];
end
function ParameterOutput=out_MainFunctionPath()
    [ParameterOutput, Name, Ext] = fileparts(which(get_Parameters('MainFunctionWholeName')));
end

function ParameterOutput=out_SpmFunctionPath()
    [ParameterOutput, Name, Ext] = fileparts(which('spm.m'));
end

function ParameterOutput=out_FunctionName()
       ParameterOutput='Restpro';
end

function ParameterOutput=out_Ch2FileName()
    ParameterOutput='ch2.nii';
end

function ParameterOutput=out_MNI152FileName()
    ParameterOutput='MNI152.nii';
end

function ParameterOutput=out_ParaSavePath_Basic()
      ParameterOutput=[get_Parameters('MainFunctionPath') filesep 'ParaSave' filesep 'BasicVersion'];
end

function ParameterOutput=out_ParaSavePath_Advance()
        ParameterOutput=[get_Parameters('MainFunctionPath') filesep 'ParaSave' filesep 'AdvanceVersion'];
end