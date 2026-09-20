function [maxMotion_txtPath] = maxMotionText(RMS, QC_Path)
% ----- Author: jiawei.han -----
% Usage: Save head motion by subjects
% Max_motion [col_1, col_2, col_3] <---> [Max_Translation, Max_Rotation, Max_displacement]

txtPath = [QC_Path filesep 'subjects_remove_criteria.txt'];

%% ========== Write txt header ==========

txt_header = 'According different levels of [Max Translation] and [Max Rotation], we picked these subjects:\n';
fid = fopen(txtPath, 'w');
fprintf(fid, txt_header);
fclose(fid);    clear fid txt_header

%% ========== Judegment ==========

k1 = 0; k2 = 0; k3 = 0; k4 = 0; k5 = 0;
for i = 1:length(RMS)
    subj = RMS(i).SID;
    subj_maxm = abs(RMS(i).MAX(1:2));      % Max_Translation, Max_Rotation
    
    if max(subj_maxm) >= 1
        k1 = k1+1;
        list_gt1{k1} = subj;
    end
    
    if max(subj_maxm) >= 1.5
        k2 = k2+1;
        list_gt1p5{k2} = subj;
    end
    
    if max(subj_maxm) >= 2
        k3 = k3+1;
        list_gt2{k3} = subj;
    end
    
    if max(subj_maxm) >= 2.5
        k4 = k4+1;
        list_gt2p5{k4} = subj;
    end
    
    if max(subj_maxm) >= 3
        k5 = k5+1;
        list_gt3{k5} = subj;
    end

end
clear i

%% ========== Write List into txt ==========

fid = fopen(txtPath, 'a');

info = '\n===== Motion >= 3mm/3deg =====\n';
fprintf(fid, info);
if exist('list_gt3')
    for i = 1:length(list_gt3)
        fprintf(fid, list_gt3{i});
        fprintf(fid, '\n');
    end
else
    fprintf(fid, 'None\n');
end
clear info

info = '\n===== Motion >= 2.5mm/2.5deg =====\n';
fprintf(fid, info);
if exist('list_gt2p5')
    for i = 1:length(list_gt2p5)
        fprintf(fid, list_gt2p5{i});
        fprintf(fid, '\n');
    end
else
    fprintf(fid, 'None\n');
end
clear info

info = '\n===== Motion >= 2mm/2deg =====\n';
fprintf(fid, info);
if exist('list_gt2')
    for i = 1:length(list_gt2)
        fprintf(fid, list_gt2{i});
        fprintf(fid, '\n');
    end
else
    fprintf(fid, 'None\n');
end
clear info

info = '\n===== Motion >= 1.5mm/1.5deg =====\n';
fprintf(fid, info);
if exist('list_gt1p5')
    for i = 1:length(list_gt1p5)
        fprintf(fid, list_gt1p5{i});
        fprintf(fid, '\n');
    end
else
    fprintf(fid, 'None\n');
end
clear info

info = '\n===== Motion >= 1mm/1deg =====\n';
fprintf(fid, info);
if exist('list_gt1')
    for i = 1:length(list_gt1)
        fprintf(fid, list_gt1{i});
        fprintf(fid, '\n');
    end
else
    fprintf(fid, 'None\n');
end
clear info

fclose(fid);


maxMotion_txtPath = txtPath;

end