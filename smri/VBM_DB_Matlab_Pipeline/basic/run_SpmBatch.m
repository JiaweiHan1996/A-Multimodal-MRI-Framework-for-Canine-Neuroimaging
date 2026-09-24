function run_SpmBatch(spm_batch)
%-----------------------------------------------------------
%	Center for Cognition and Brain Disorders, Hangzhou Normal University, Hangzhou 310015, China
%	Written by JIA Xi-Ze 20141028
%	http://www.restfmri.net/
% 	Mail to Authors: jxz.rest@gmail.com, jiaxize@foxmail.com
%	Version=1.0;


%     [SPMversion,c]=spm('Ver');
%     if strcmp(SPMversion,'SPM5')
%        spm_jobman('run',spm_batch.jobs);
%     elseif strcmp(SPMversion,'SPM8')
%        spm_batch.jobs = spm_jobman('spm5tospm8',{spm_batch.jobs});
%        spm_jobman('run',spm_batch.jobs);
%    elseif strcmp(SPMversion,'SPM12')
%        spm_batch.jobs = spm_jobman('convert',spm_batch.jobs);
%        spm_jobman('run',spm_batch.jobs);
%     else
%        uiwait(msgbox('The current SPM version is not supported. Please install SPM8 or SPM12 first.','Invalid SPM Version.'));
%     end
spm_batch.jobs = spm_jobman('convert',spm_batch.jobs);
spm_jobman('run',spm_batch.jobs);
end


