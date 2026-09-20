function output=Reslice(Fun_path,T1_path)


%%

spm('defaults', 'FMRI');
spm_jobman('initcfg');

[d, f, e] = fileparts(Fun_path);
FilePath=d;
cd(FilePath)

SubfodrList=dir_NameList(Fun_path);
for i=1:length(SubfodrList)
    if exist([T1_path filesep SubfodrList{i}],'dir')
        fn_name=spm_select('list',[Fun_path filesep SubfodrList{i}],'.*nii');
        fn_path=[Fun_path filesep SubfodrList{i} filesep fn_name];
        
        DirList4RegExp=dir([T1_path filesep SubfodrList{i} filesep 'co*.nii']);
        structural_fn=[T1_path filesep SubfodrList{i} filesep DirList4RegExp.name];
        
        SpmBatch{i} = output_SpmBatch2Reslice(fn_path,structural_fn);
    end
end

parfor i=1:length(SubfodrList)
    if  exist([T1_path filesep SubfodrList{i}],'dir')
        run_SpmBatch(SpmBatch{i});
    end
end
clear jobs;

for i=1:length(SubfodrList)
    if  exist([T1_path filesep SubfodrList{i}],'dir')
        [d, f, e] = fileparts(SpmBatch{1,i}.jobs{1,1}.spm.spatial.coreg.write.source{7});
        output{i}.rstructural_fn = [d filesep 'r' f e];
        output{i}.rgm_fn = [d filesep 'rc1' f e];
        output{i}.rwm_fn = [d filesep 'rc2' f e];
        output{i}.rcsf_fn = [d filesep 'rc3' f e];
        output{i}.rbone_fn = [d filesep 'rc4' f e];
        output{i}.rsoft_fn = [d filesep 'rc5' f e];
        output{i}.rair_fn = [d filesep 'rc6' f e];
    end
end
end


function SpmBatch = output_SpmBatch2Reslice(fn_path,structural_fn)
%%
% Ref
SpmBatch.jobs{1}.spm.spatial.coreg.write.ref = {[fn_path ',1']};
% Source
source_fns = {};
[d1, f1, e1] = fileparts(structural_fn);
for j = 1:6
    source_fns{j} = [d1 filesep 'c' num2str(j) f1 e1];
end
source_fns{7} = structural_fn;
SpmBatch.jobs{1}.spm.spatial.coreg.write.source = source_fns';
% Roptions
SpmBatch.jobs{1}.spm.spatial.coreg.write.roptions.interp = 4;
SpmBatch.jobs{1}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
SpmBatch.jobs{1}.spm.spatial.coreg.write.roptions.mask = 0;
SpmBatch.jobs{1}.spm.spatial.coreg.write.roptions.prefix = 'r';
end
