function Vol_Calc_gm_atlas(opDir, ipDir, Sub_ID, TMP)
% Calculate Volumes of WholeBrain & ROIs
% - opDir: excel output pathway, eg. '...\Results'
% - ipDir: data input pathway, eg. '...\Results\Volumes'
% ========== Initialization ========== %
out_fname = 'Volumes_results_GM_atlas';
xls_path = [opDir filesep out_fname '.xlsx'];

% ========= GM Atlas ==========
Atlas_Info = read_atlas_txt(TMP.atlas_gm_info);
% -----
Atlas_path = TMP.atlas_gm;
Atlas = spm_read_vols(spm_vol(Atlas_path));	Atlas(find(isnan(Atlas_path)))=0;
Label = unique(Atlas);
if Label(1)==0,Label(1) = [];end
num = length(Label);

Sheet1_title = {'Label' 'BrainArea_abbr' 'BrainArea'};
Sheet1(1,:) = Sheet1_title;
ID_All = Atlas_Info.id;
for k = 1:num
    Loc = find(ID_All==Label(k));
    Sheet1((k+1),1) = num2cell(Atlas_Info.id(Loc));
    Sheet1((k+1),2) = Atlas_Info.BA_abbr(Loc);
    Sheet1((k+1),3) = Atlas_Info.BrainArea(Loc);
end
clear k ID_All
xlswrite(xls_path,Sheet1,1);

% ========== Calculate Volumes ========== %
Sheet2 = cell((length(Sub_ID)+1),(num+4));
% set title
Sheet2(1,1:4) = {'Subject','TIV[cm3]','GMV[cm3]','WMV[cm3]'};
for k = 1:num
    s = ['ROIv_',num2str(Label(k)),'[mm3]'];
    Sheet2(1,(k+4)) = {s};
    clear s
end
clear k

for i = 1:length(Sub_ID)
    S_ID = Sub_ID{i};  Sheet2((i+1),1) = Sub_ID(i);
    GMpath = [ipDir filesep 'StandardSpace_' S_ID '_GMD.nii'];
    WMpath = [ipDir filesep 'StandardSpace_' S_ID '_WMD.nii'];
    CSFpath = [ipDir filesep 'StandardSpace_' S_ID '_CSFD.nii'];
    GM = spm_read_vols(spm_vol(GMpath));
    GM(find(isnan(GM)))=0;  GM(find(GM<0))=0;
    WM = spm_read_vols(spm_vol(WMpath));
    WM(find(isnan(WM)))=0;  WM(find(WM<0))=0;
    CSF = spm_read_vols(spm_vol(CSFpath));
    CSF(find(isnan(CSF)))=0;  CSF(find(CSF<0))=0;

    V = spm_vol(GMpath); affine = V.mat; 
    vox = [...
        sqrt(sum(affine(1:3,1).^2)), ... % x 方向
        sqrt(sum(affine(1:3,2).^2)), ... % y 方向
        sqrt(sum(affine(1:3,3).^2))  ... % z 方向
        ];
    % ----- TIV & GMV & WMV Calculate [unit: cm^3]
    vox_vol = vox(1)*vox(2)*vox(3);  % [unit: mm^3]
    GMV = vox_vol*sum(sum(sum(GM)))/1000;  WMV = vox_vol*sum(sum(sum(WM)))/1000;
    CSFV = vox_vol*sum(sum(sum(CSF)))/1000;
    TIV = GMV + WMV + CSFV;
    % ------------------------
    Results(i).name = S_ID;
    Results(i).tiv = TIV;  Results(i).gmv = GMV;  Results(i).wmv = WMV;
    Sheet2((i+1),2:4) = {TIV,GMV,WMV};
    clear GMV WMV TIV
    % ----- ROIv Calculate [unit: mm^3]
    for k = 1:num
        ls = ['ROIv_',num2str(Label(k))];
        Loc = find(Atlas == Label(k));
        ROIv_gm = vox_vol*sum(sum(sum(GM(Loc))));  ROIv_wm = vox_vol*sum(sum(sum(WM(Loc))));
        ROIv = ROIv_gm + ROIv_wm;
        % -----
        s = ['Results(i).',ls,' = ROIv;'];  eval(s);
        Sheet2((i+1),(4+k)) = {ROIv};
        clear ls Loc ROIv_gm ROIv_wm ROIv s
    end
    clear k
    clear S_ID GMpath WMpath GM WM
end
clear i
% ========== Write into excel ========== %
xlswrite(xls_path,Sheet2,2);
Sheet3 = Sheet2';
xlswrite(xls_path,Sheet3,3);

clear num Sheet1_title
save([opDir filesep out_fname '.mat'])
end