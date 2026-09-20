function Postfix=get_Postfix(Option)
%-----------------------------------------------------------
%   Copyright(c) 2015
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 201410
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com

switch Option
    case 'DicomToNifti'
        Postfix='H';
    case 'RemoveFirstTimePoints'
        Postfix='T';        
    case 'SliceTiming'
        Postfix='A';
    case 'Realign'  
        Postfix='R';
    case 'Normalize'
        Postfix='W';
    case 'Normalize_dartel'
        Postfix='w';
    case 'Normalize_sym'
        Postfix='sym';
    case 'T1CoregisterFun'
        Postfix='C';
    case 'T1Segment'
        Postfix='S';
    case 'NewSegment'
        Postfix='E';
    case 'Smooth'
        Postfix='S';
    case 'Detrend'
        Postfix='D';
    case 'Filter'
        Postfix='F';
    case 'RegressOutCov'
        Postfix='C';
    case 'RealignParameter'
        Postfix='RealignParameter';
    case 'PicsForChekNorm'
        Postfix='PicturesForChkNormalization';
    case 'sym_groupt1_mean_temp'
        Postfix='SymmetricGroupT1MeanTemplate';
    case 'ReorientMats'
        Postfix='ReorientMats';
    case 'CovariatesParameter'
        Postfix='CovariatesParameter';
    case 'DegreeCentrality'        
        Postfix='DegreeCentrality';
    case 'VMHC'
        Postfix='VMHC';
    case 'DivideMeanWithinMask'
        Postfix='m';
    case 'CalcZscoreWithinMask'
        Postfix='z';
    otherwise
         error('get_Postfix!!');

end
        