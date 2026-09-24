function ResultsDir = ResultsSort(vbmDir,Sub_ID)
    ResultsDir = [vbmDir filesep 'Results'];  mkdir(ResultsDir);
    dstDir_1 = [ResultsDir filesep 'Volumes'];  mkdir(dstDir_1);
    dstDir_2 = [ResultsDir filesep 'SmoothedVolumes'];  mkdir(dstDir_2);
    dataDir = [vbmDir filesep 'data'];
    for i = 1:length(Sub_ID)
        S_ID = Sub_ID{i};
        % mStandardSpace_mwc^
        copyfile([dataDir filesep 'mwmwc1' S_ID '.nii'],...
                 [dstDir_1 filesep 'StandardSpace_' S_ID '_GMD.nii']);
        copyfile([dataDir filesep 'mwmwc2' S_ID '.nii'],...
                 [dstDir_1 filesep 'StandardSpace_' S_ID '_WMD.nii']);
        copyfile([dataDir filesep 'mwmwc3' S_ID '.nii'],...
                 [dstDir_1 filesep 'StandardSpace_' S_ID '_CSFD.nii']);
        % smStandardSpace_mwc^
        movefile([dataDir filesep 'smwmwc1' S_ID '.nii'],...
                 [dstDir_2 filesep 'sStandardSpace_' S_ID '_GMD.nii']);
        movefile([dataDir filesep 'smwmwc2' S_ID '.nii'],...
                 [dstDir_2 filesep 'sStandardSpace_',S_ID,'_WMD.nii']);
        clear S_ID
    end
    clear i
end