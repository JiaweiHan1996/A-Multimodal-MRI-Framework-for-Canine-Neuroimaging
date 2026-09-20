function spm_image_dsp(action, varargin)
%%

SVNid = '$Rev: 7573 $';

global st
global FileList
global reo_f

if ~nargin, action = 'Init'; end

if ~any(strcmpi(action,{'init','reset','display','resetorient'})) && ...
        (isempty(st) || ~isfield(st,'vols') || isempty(st.vols{1}))
    warning('spm:spm_image_dsp:lostInfo','Lost image information. Resetting.');
    spm_image_dsp('Reset');
    return;
end

switch lower(action)
    
    case {'init','display'}
    % Display image
    %----------------------------------------------------------------------
    reo_f = 0;
    spm('FnBanner',mfilename,SVNid);                                    %-#
    % <----- jiawei.han -----
%     if isempty(varargin)
%         [P, sts] = spm_select(1,'image','Select image');
%         if ~sts, return; end
%     else
%         P = varargin{1};
%     end
    if isempty(varargin)
        [P, sts] = spm_select(1,'image','Select image');
        if ~sts, return; end
    else
        FileList = varargin{1};
        P = FileList{1};
    end
    % ----- jiawei.han ----->
    if ischar(P), P = spm_vol(P); end
    if isempty(P), return; end
    P = P(1);

    cmd = 'spm_image_dsp(''display'',''%s'')';
    exactfname = @(f) [f.fname ',' num2str(f.n(1))];
    fprintf('Display %s\n',spm_file(exactfname(P),'link',cmd));
    
    init_display(P);
    while reo_f == 0
        pause(1);
    end
    
    
    case 'repos'
    % The widgets for translation, rotation or zooms have been modified
    %----------------------------------------------------------------------
    h = findobj(st.fig,'Tag','spm_image_dsp:reorient'); if isempty(h), spm_image_dsp('Reset'); end
    B = get(h,'UserData');
    trz = varargin{1};
    if numel(varargin) == 2
        try, B(trz) = varargin{2}; end
        trzs = {'t1' 't2' 't3' 'r1' 'r2' 'r3' 'z1' 'z2' 'z3'};
        ho = findobj(st.fig,'Tag',sprintf('spm_image_dsp:reorient:%s',trzs{trz}));
        set(ho,'String',num2str(B(trz)));
    else
        try, B(trz) = eval(get(gcbo,'String')); end
        set(gcbo,'String',num2str(B(trz)));
    end
    st.vols{1}.premul = spm_matrix(B);
    set(h,'UserData',B);
    % spm_orthviews('MaxBB');
    spm_image_dsp('Zoom');
    spm_image_dsp('Update');
    
    
    case 'shopos'
    % The position of the crosshairs has been moved
    %----------------------------------------------------------------------
    XYZmm = spm_orthviews('Pos');
    XYZ   = spm_orthviews('Pos',1);
    h = findobj(st.fig,'Tag','spm_image_dsp:mm'); if isempty(h), spm_image_dsp('Reset'); end
    set(h,'String',sprintf('%.1f %.1f %.1f',XYZmm));
    h = findobj(st.fig,'Tag','spm_image_dsp:vx'); if isempty(h), spm_image_dsp('Reset'); end
    set(h,'String',sprintf('%.1f %.1f %.1f',XYZ));
    h = findobj(st.fig,'Tag','spm_image_dsp:intensity'); if isempty(h), spm_image_dsp('Reset'); end
    set(h,'String',sprintf('%g',spm_sample_vol(st.vols{1},XYZ(1),XYZ(2),XYZ(3),st.hld)));
    
    
    case 'setposmm'
    % Move the crosshairs to the specified position {mm}
    %----------------------------------------------------------------------
    h = findobj(st.fig,'Tag','spm_image_dsp:mm'); if isempty(h), spm_image_dsp('Reset'); end
    pos = sscanf(get(h,'String'), '%g %g %g');
    if length(pos)~=3
        pos = spm_orthviews('Pos');
    end
    spm_orthviews('Reposition',pos);
    
    
    case 'setposvx'
    % Move the crosshairs to the specified position {vx}
    %----------------------------------------------------------------------
    h = findobj(st.fig,'Tag','spm_image_dsp:vx'); if isempty(h), spm_image_dsp('Reset'); end
    pos = sscanf(get(h,'String'), '%g %g %g');
    if length(pos)~=3
        pos = spm_orthviews('pos',1);
    end
    tmp = st.vols{1}.premul*st.vols{1}.mat;
    pos = tmp(1:3,:)*[pos ; 1];
    spm_orthviews('Reposition',pos);

    
    case 'addblobs'
    % Add blobs to the image - in full colour
    %----------------------------------------------------------------------
    [f, sts] = spm_select([1 6],{'image','^SPM\.mat$','xml'});
    if ~sts, return; else f = cellstr(f); end
    spm_figure('Clear','Interactive');
    colours = [1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];
    cnames  = 'Red blobs|Yellow blobs|Green blobs|Cyan blobs|Blue blobs|Magenta blobs';
    h = findobj(st.fig,'Tag','spm_image_dsp:overlay'); if isempty(h), spm_image_dsp('Reset'); end
    for i=1:numel(f)
        c = spm_input(['Colour for ' spm_file(f{i},'short25')],'+1','m',cnames,[1 2 3 4 5 6],i);
        if strcmp(spm_file(f{i},'filename'),'SPM.mat')
            load(f{i});
            [SPM,xSPM] = spm_getSPM(SPM);
            if isempty(xSPM), continue; end
            spm_orthviews('AddColouredBlobs',1,xSPM.XYZ,xSPM.Z,xSPM.M,colours(c,:));
        elseif strcmp(spm_file(f{i},'ext'),'xml')
            xA = spm_atlas('load',f{i});
            if numel(xA.VA) == 1 % assume a single image is a label image
                VM = spm_atlas('mask',xA);
                %[Z,XYZmm] = spm_read_vols(VM);
                %XYZ = VM.mat\[XYZmm;ones(1,size(XYZmm,2))];
                %m  = find(Z);
                %spm_orthviews('AddColouredBlobs',1,XYZ(:,m),Z(m),VM.mat,colours(c,:));
                spm_orthviews('AddColouredImage',1,VM,colours(c,:));
            else
                V = spm_atlas('prob',xA);
                spm_orthviews('AddColouredImage',1,V,colours(c,:));
            end
        else
            spm_orthviews('AddColouredImage',1,f{i},colours(c,:));
        end
    end
    set(h,'String','Remove Overlay','Callback','spm_image_dsp(''RemoveBlobs'');');
    spm_orthviews('Redraw');

    
    case {'removeblobs','rmblobs'}
    % Remove all blobs from the images
    %----------------------------------------------------------------------
    spm_orthviews('RemoveBlobs',1);
    h = findobj(st.fig,'Tag','spm_image_dsp:overlay'); if isempty(h), spm_image_dsp('Reset'); end
    set(h,'String','Add Overlay...','Callback','spm_image_dsp(''AddBlobs'');');
    spm_orthviews('Redraw');

    
    case 'window'
    % Window
    %----------------------------------------------------------------------
    h = findobj(st.fig,'Tag','spm_image_dsp:window'); if isempty(h), spm_image_dsp('Reset'); end
    op = get(h,'Value');
    if op == 1
        spm_orthviews('Window',1); % automatic
    elseif op == 2
        spm_orthviews('Window',1,spm_input('Range','+1','e','',2));
    else
        pc = spm_input('Percentiles', '+1', 'w', '3 97', 2, 100);
        spm('Pointer', 'Watch');
        wn = spm_summarise(st.vols{1}, 'all', @(X) spm_percentile(X, pc));
        spm_orthviews('Window', 1, wn);
        spm('Pointer', 'Arrow');
    end
    
    
    case 'reorient'
    % Reorient images
    %----------------------------------------------------------------------
    h = findobj(st.fig,'Tag','spm_image_dsp:reorient'); if isempty(h), spm_image_dsp('Reset'); end
    B = get(h,'UserData');
    M = spm_matrix(B);
    if det(M)<=0
        spm('alert!','This will flip the images',mfilename,0,1);
    end
    % <----- jiawei.han -----
    P = {spm_file(st.vols{1}.fname, 'number', st.vols{1}.n)};
    p = spm_fileparts(st.vols{1}.fname);
    % <----- jiawei.han -----
%     [P, sts] = spm_select(Inf, 'image', {'Image(s) to reorient'}, P, p);
%     if ~sts
%         disp('Reorientation cancelled.');
%         return
%     end
%     P = cellstr(P);
%     sv = questdlg('Save reorientation matrix for future reference?', ...
%         'Save Matrix', 'Yes', 'No', 'No');
%     if strcmpi(sv, 'yes')
%         if ~isempty(P{1})
%             [p,n]   = spm_fileparts(P{1});
%             fnm     = fullfile(p, [n '_reorient.mat']);
%         else
%             fnm     = 'reorient.mat';
%         end
%         [f,p] = uiputfile(fnm);
%         if ~isequal(f,0)
%             save(fullfile(p,f), 'M', spm_get_defaults('mat.format'));
%         end
%     end
    % ----- jiawei.han ----->
    if length(FileList) > 1
        for k = 2:length(FileList)
            P(k, 1) = {FileList{k}};
        end; clear k
    end
    % ----- jiawei.han ----->
    if isempty(P{1}), return, end
    P = spm_select('expand',P);
    Mats = zeros(4,4,numel(P));
    spm_progress_bar('Init',numel(P),'Reading current orientations',...
        'Images Complete');
    for i=1:numel(P)
        Mats(:,:,i) = spm_get_space(P{i});
        spm_progress_bar('Set',i);
    end
    spm_progress_bar('Init',numel(P),'Reorienting images',...
        'Images Complete');
    for i=1:numel(P)
        spm_get_space(P{i},M*Mats(:,:,i));
        spm_progress_bar('Set',i);
    end
    spm_progress_bar('Clear');
    tmp = spm_get_space([st.vols{1}.fname ',' num2str(st.vols{1}.n)]);
    % <----- jiawei.han -----
%     if sum((tmp(:)-st.vols{1}.mat(:)).^2) > 1e-8
%         spm_image_dsp('Init',st.vols{1}.fname);
%     end
    spm_figure('Close');            % jiawei.han
    reo_f = 1;
    % ----- jiawei.han ----->

    
    case 'setorigin'
    % Set origin to crosshair
    %----------------------------------------------------------------------
    pos = spm_orthviews('Pos');
    h = findobj(st.fig,'Tag','spm_image_dsp:reorient'); if isempty(h), spm_image_dsp('Reset'); end
    B = get(h,'UserData');
    spm_image_dsp('Repos', 1, B(1)-pos(1));
    spm_image_dsp('Repos', 2, B(2)-pos(2));
    spm_image_dsp('Repos', 3, B(3)-pos(3));
    spm_orthviews('Reposition',[0 0 0]');
    
    
    case 'resetorient'
    % Reset orientation of images
    %----------------------------------------------------------------------
    % warning('Action ''ResetOrient'' is deprecated.');
    if ~isempty(varargin)
        P = varargin{1};
    else
        [P,sts] = spm_select([1 Inf], 'image','Images to reset orientation of');
        if ~sts, return; end
    end
    P = cellstr(P);
    spm_progress_bar('Init',numel(P),'Resetting orientations',...
        'Images Complete');
    for i=1:numel(P)
        V    = spm_vol(P{i});
        M    = V.mat;
        vox  = sqrt(sum(M(1:3,1:3).^2));
        if det(M(1:3,1:3))<0, vox(1) = -vox(1); end
        orig = (V.dim(1:3)+1)/2;
        off  = -vox.*orig;
        M    = [vox(1) 0      0      off(1)
                0      vox(2) 0      off(2)
                0      0      vox(3) off(3)
                0      0      0      1];
        spm_get_space(P{i},M);
        spm_progress_bar('Set',i);
    end
    spm_progress_bar('Clear');
    % tmp = spm_get_space([st.vols{1}.fname ',' num2str(st.vols{1}.n)]);
    % if sum((tmp(:)-st.vols{1}.mat(:)).^2) > 1e-8
    %     spm_image_dsp('Init',st.vols{1}.fname);
    % end

    
    case 'update'
    % Modify the positional information in the right hand panel
    %----------------------------------------------------------------------
    mat = st.vols{1}.premul*st.vols{1}.mat;
    Z = spm_imatrix(mat);
    Z = Z(7:9);

    h = findobj(st.fig,'Tag','spm_image_dsp:hdr:vx'); if isempty(h), spm_image_dsp('Reset'); end
    set(h, 'String', sprintf('%.3g x %.3g x %.3g', Z));

    O = mat\[0 0 0 1]'; O=O(1:3)';
    h = findobj(st.fig,'Tag','spm_image_dsp:hdr:orig'); if isempty(h), spm_image_dsp('Reset'); end
    set(h, 'String', sprintf('%.3g %.3g %.3g', O));

    R = spm_imatrix(mat);
    R = spm_matrix([0 0 0 R(4:6)]);
    R = R(1:3,1:3);

    tmp2 = sprintf('%+5.3f %+5.3f %+5.3f',R(1,1:3)); tmp2(tmp2=='+') = ' ';
    h = findobj(st.fig,'Tag','spm_image_dsp:hdr:m1'); if isempty(h), spm_image_dsp('Reset'); end
    set(h, 'String', tmp2);
    tmp2 = sprintf('%+5.3f %+5.3f %+5.3f',R(2,1:3)); tmp2(tmp2=='+') = ' ';
    h = findobj(st.fig,'Tag','spm_image_dsp:hdr:m2'); if isempty(h), spm_image_dsp('Reset'); end
    set(h, 'String', tmp2);
    tmp2 = sprintf('%+5.3f %+5.3f %+5.3f',R(3,1:3)); tmp2(tmp2=='+') = ' ';
    h = findobj(st.fig,'Tag','spm_image_dsp:hdr:m3'); if isempty(h), spm_image_dsp('Reset'); end
    set(h, 'String', tmp2);

    tmp = R*diag(Z) - mat(1:3,1:3);
    h = findobj(st.fig,'Tag','spm_image_dsp:hdr:shear'); if isempty(h), spm_image_dsp('Reset'); end
    if sum(tmp(:).^2)>1e-6
        set(h, 'String', 'Warning: shears involved');
    else
        set(h, 'String', '');
    end

    
    case 'zoom'
    % Zoom in
    %----------------------------------------------------------------------
    [zl, rl] = spm_orthviews('ZoomMenu');
    h = findobj(st.fig,'Tag','spm_image_dsp:zoom'); if isempty(h), spm_image_dsp('Reset'); end
    % Values are listed in reverse order
    cz = numel(zl)-get(h,'Value')+1;
    spm_orthviews('Zoom',zl(cz),rl(cz));

    
    case 'xhairs'
    % Display/hide crosshair
    %----------------------------------------------------------------------
    h = findobj(st.fig,'Tag','spm_image_dsp:xhairs'); if isempty(h), spm_image_dsp('Reset'); end
    if get(h,'UserData')
        spm_orthviews('Xhairs','off');
        set(h,'String','Show Crosshair');
    else
        spm_orthviews('Xhairs','on');
        set(h,'String','Hide Crosshair');
    end
    set(h,'UserData',~get(h,'UserData'));

    
    case 'reset'
    % Reset
    %----------------------------------------------------------------------
    spm_orthviews('Reset');
    spm_figure('Clear','Graphics');

    
    otherwise
    % Otherwise
    %----------------------------------------------------------------------
    if spm_existfile(action)
        fprintf('Correct syntax is: spm_image_dsp(''Display'',''%s'')\n',action);
        spm_image_dsp('Display', action);
    else
        error('Unknown action ''%s''.', action);
    end
end


%==========================================================================
function init_display(P)

global st

fg = spm_figure('GetWin','Graphics');
spm_image_dsp('Reset');
spm_orthviews('Image', P, [0.0 0.45 1 0.55]);
if isempty(st.vols{1}), return; end

spm_orthviews('AddContext',1);
spm_orthviews('MaxBB');
st.callback = 'spm_image_dsp(''shopos'');';

WS = spm('WinScale');

u0 = uipanel(fg,'Units','Pixels','Title','','Position',[40 25 200 325].*WS,...
    'DeleteFcn','spm_image_dsp(''reset'');');

% Crosshair position
%--------------------------------------------------------------------------
u1 = uipanel('Parent',u0,'Units','Pixels','Title','','Position',[5 225 189 94].*WS,...
    'BorderType','Line', 'HighlightColor',[0 0 0]);
uicontrol('Parent',u1,'Style','Text', 'Position',[2 67 131 020].*WS,...
    'String','Crosshair Position','FontWeight','bold');
uicontrol('Parent',u1,'Style','PushButton', 'Position',[135 69 050 020].*WS,...
    'String','Origin',...
    'Callback','spm_orthviews(''Reposition'',[0 0 0]);','ToolTipString','Move crosshair to origin');
uicontrol('Parent',u1,'Style','Text', 'Position',[10 45 35 020].*WS,'String','mm:');
uicontrol('Parent',u1,'Style','Text', 'Position',[10 25 35 020].*WS,'String','vx:');
uicontrol('Parent',u1,'Style','Text', 'Position',[10  1 65 020].*WS,'String','Intensity:');

uicontrol('Parent',u1,'Style','Edit', 'Position',[50 45 135 020].*WS,...
    'String','', 'Tag','spm_image_dsp:mm', 'BackgroundColor',[1 1 1],...
    'Callback','spm_image_dsp(''setposmm'')','ToolTipString','Move crosshair to mm coordinates');
uicontrol('Parent',u1,'Style','Edit', 'Position',[50 25 135 020].*WS,...
    'String','', 'Tag','spm_image_dsp:vx','BackgroundColor',[1 1 1], ...
    'Callback','spm_image_dsp(''setposvx'')','ToolTipString','Move crosshair to voxel coordinates');
uicontrol('Parent',u1,'Style','Text', 'Position',[80 1  85 020].*WS,...
    'String','', 'Tag','spm_image_dsp:intensity');

% Widgets for re-orienting images
%--------------------------------------------------------------------------
B = [0 0 0  0 0 0  1 1 1  0 0 0];
u2 = uipanel('Parent',u0,'Units','Pixels','Title','','Position',[5 5 189 214].*WS,...
    'BorderType','Line', 'HighlightColor',[0 0 0], 'Tag','spm_image_dsp:reorient', 'UserData', B);
uicontrol('Parent',u2,'Style','Text', 'Position',[5 190 100 016].*WS,'String','right  {mm}');
uicontrol('Parent',u2,'Style','Text', 'Position',[5 170 100 016].*WS,'String','forward  {mm}');
uicontrol('Parent',u2,'Style','Text', 'Position',[5 150 100 016].*WS,'String','up  {mm}');
uicontrol('Parent',u2,'Style','Text', 'Position',[5 130 100 016].*WS,'String','pitch  {rad}');
uicontrol('Parent',u2,'Style','Text', 'Position',[5 110 100 016].*WS,'String','roll  {rad}');
uicontrol('Parent',u2,'Style','Text', 'Position',[5  90 100 016].*WS,'String','yaw  {rad}');
uicontrol('Parent',u2,'Style','Text', 'Position',[5  70 100 016].*WS,'String','resize  {x}');
uicontrol('Parent',u2,'Style','Text', 'Position',[5  50 100 016].*WS,'String','resize  {y}');
uicontrol('Parent',u2,'Style','Text', 'Position',[5  30 100 016].*WS,'String','resize  {z}');

uicontrol('Parent',u2,'Style','Edit', 'Position',[105 190 065 020].*WS,'String','0','Callback','spm_image_dsp(''repos'',1)','ToolTipString','Translation','Tag','spm_image_dsp:reorient:t1','BackgroundColor',[1 1 1]);
uicontrol('Parent',u2,'Style','Edit', 'Position',[105 170 065 020].*WS,'String','0','Callback','spm_image_dsp(''repos'',2)','ToolTipString','Translation','Tag','spm_image_dsp:reorient:t2','BackgroundColor',[1 1 1]);
uicontrol('Parent',u2,'Style','Edit', 'Position',[105 150 065 020].*WS,'String','0','Callback','spm_image_dsp(''repos'',3)','ToolTipString','Translation','Tag','spm_image_dsp:reorient:t3','BackgroundColor',[1 1 1]);
uicontrol('Parent',u2,'Style','Edit', 'Position',[105 130 065 020].*WS,'String','0','Callback','spm_image_dsp(''repos'',4)','ToolTipString','Rotation','Tag','spm_image_dsp:reorient:r1','BackgroundColor',[1 1 1]);
uicontrol('Parent',u2,'Style','Edit', 'Position',[105 110 065 020].*WS,'String','0','Callback','spm_image_dsp(''repos'',5)','ToolTipString','Rotation','Tag','spm_image_dsp:reorient:r2','BackgroundColor',[1 1 1]);
uicontrol('Parent',u2,'Style','Edit', 'Position',[105  90 065 020].*WS,'String','0','Callback','spm_image_dsp(''repos'',6)','ToolTipString','Rotation','Tag','spm_image_dsp:reorient:r3','BackgroundColor',[1 1 1]);
uicontrol('Parent',u2,'Style','Edit', 'Position',[105  70 065 020].*WS,'String','1','Callback','spm_image_dsp(''repos'',7)','ToolTipString','Zoom','Tag','spm_image_dsp:reorient:z1','BackgroundColor',[1 1 1]);
uicontrol('Parent',u2,'Style','Edit', 'Position',[105  50 065 020].*WS,'String','1','Callback','spm_image_dsp(''repos'',8)','ToolTipString','Zoom','Tag','spm_image_dsp:reorient:z2','BackgroundColor',[1 1 1]);
uicontrol('Parent',u2,'Style','Edit', 'Position',[105  30 065 020].*WS,'String','1','Callback','spm_image_dsp(''repos'',9)','ToolTipString','Zoom','Tag','spm_image_dsp:reorient:z3','BackgroundColor',[1 1 1]);

uicontrol('Parent',u2,'Style','Pushbutton','Position',[5 5 90 020].*WS,'String','Set Origin',...
    'Callback','spm_image_dsp(''setorigin'')','ToolTipString','Set origin to crosshair position');
uicontrol('Parent',u2,'Style','Pushbutton','Position',[95 5 90 020].*WS,'String','Reorient...',...
    'Callback','spm_image_dsp(''reorient'')','ToolTipString','Modify position information of selected images');

% Header information
%--------------------------------------------------------------------------
u0 = uipanel(fg,'Units','Pixels','Title','','Position',[280 25 280 325].*WS);
u1 = uipanel('Parent',u0,'Units','Pixels','Title','','Position',[5 80 269 239].*WS,...
    'BorderType','Line','HighlightColor',[0 0 0]);

uicontrol('Parent',u1, 'Style','Text', 'Position', [5 215 50 016].*WS,...
    'String','File:', 'HorizontalAlignment','right');
str = spm_file(st.vols{1}.fname,'short25');
uicontrol('Parent',u1, 'Style','Text','Position', [55 215 210 016].*WS,...
    'String',str, 'HorizontalAlignment','left', 'FontWeight','bold');
uicontrol('Parent',u1, 'Style','Text', 'Position', [5 195 100 016].*WS,...
    'String','Dimensions:', 'HorizontalAlignment','right');
str = sprintf('%d x %d x %d', st.vols{1}.dim(1:3));
uicontrol('Parent',u1, 'Style','Text', 'Position', [105 195 160 016].*WS,...
    'String',str, 'HorizontalAlignment','left', 'FontWeight','bold');
uicontrol('Parent',u1, 'Style','Text', 'Position', [5 175 100 016].*WS,...
    'String','Datatype:', 'HorizontalAlignment','right');
str = spm_type(st.vols{1}.dt(1));
uicontrol('Parent',u1, 'Style','Text', 'Position', [105 175 160 016].*WS,...
    'String',str, 'HorizontalAlignment','left', 'FontWeight','bold');
uicontrol('Parent',u1, 'Style','Text', 'Position', [5 155 100 016].*WS,...
    'String','Intensity:', 'HorizontalAlignment','right');
str = 'varied';
if size(st.vols{1}.pinfo,2) == 1
    if st.vols{1}.pinfo(2)
        str = sprintf('Y = %g X + %g', st.vols{1}.pinfo(1:2)');
    else
        str = sprintf('Y = %g X', st.vols{1}.pinfo(1)');
    end
end
uicontrol('Parent',u1, 'Style','Text', 'Position', [105 155 160 016].*WS,...
    'String',str, 'HorizontalAlignment','left', 'FontWeight','bold');

if isfield(st.vols{1}, 'descrip')
    str = st.vols{1}.descrip;
    uicontrol('Parent',u1,'Style','Text', 'Position', [5 135 260 016].*WS,...
        'String',str, 'HorizontalAlignment','center', 'FontWeight','bold');
end

% Positional information
%--------------------------------------------------------------------------
mat = st.vols{1}.premul*st.vols{1}.mat;
Z = spm_imatrix(mat);
Z = Z(7:9);
uicontrol('Parent',u1,'Style','Text', 'Position',[5 105 100 016].*WS,...
    'HorizontalAlignment','right', 'String','Vox size:');
uicontrol('Parent',u1,'Style','Text', 'Position',[105 105 160 016].*WS,...
    'String', sprintf('%.3g x %.3g x %.3g', Z), 'Tag','spm_image_dsp:hdr:vx',...
    'HorizontalAlignment','left', 'FontWeight','bold');

O = mat\[0 0 0 1]'; O=O(1:3)';
uicontrol('Parent',u1,'Style','Text','Position', [5 85 100 016].*WS,...
    'HorizontalAlignment','right', 'String','Origin:');
uicontrol('Parent',u1,'Style','Text', 'Position',[105 85 160 016].*WS,...
    'String',sprintf('%.3g %.3g %.3g', O), 'Tag','spm_image_dsp:hdr:orig',...
    'HorizontalAlignment','left', 'FontWeight','bold');

R = spm_imatrix(mat);
R = spm_matrix([0 0 0 R(4:6)]);
R = R(1:3,1:3);

uicontrol('Parent',u1,'Style','Text', 'Position', [5 65 100 016].*WS,...
    'HorizontalAlignment','right', 'String','Dir Cos:');
tmp2 = sprintf('%+5.3f %+5.3f %+5.3f', R(1,1:3)); tmp2(tmp2=='+') = ' ';
uicontrol('Parent',u1,'Style','Text', 'Position', [105 65 160 016].*WS,...
    'String',tmp2, 'Tag','spm_image_dsp:hdr:m1',...
    'HorizontalAlignment','left', 'FontWeight','bold');
tmp2 = sprintf('%+5.3f %+5.3f %+5.3f', R(2,1:3)); tmp2(tmp2=='+') = ' ';
uicontrol('Parent',u1,'Style','Text', 'Position', [105 45 160 016].*WS,...
    'String',tmp2, 'Tag','spm_image_dsp:hdr:m2',...
    'HorizontalAlignment','left', 'FontWeight','bold');
tmp2 = sprintf('%+5.3f %+5.3f %+5.3f', R(3,1:3)); tmp2(tmp2=='+') = ' ';
uicontrol('Parent',u1,'Style','Text', 'Position', [105 25 160 016].*WS,...
    'String',tmp2, 'Tag','spm_image_dsp:hdr:m3',...
    'HorizontalAlignment','left', 'FontWeight','bold');

tmp = R*diag(Z) - mat(1:3,1:3);
if sum(tmp(:).^2)>1e-6
    str = 'Warning: shears involved';
else
    str = '';
end
uicontrol('Parent',u1,'Style','Text', 'Position', [5 5 260 016].*WS,...
    'String',str, 'Tag','spm_image_dsp:hdr:shear',...
    'HorizontalAlignment','center','FontWeight','bold');

% Assorted other buttons
%--------------------------------------------------------------------------
u2 = uipanel('Parent',u0,'Units','Pixels','Title','','Position',[5 5 269 70].*WS,...
    'BorderType','Line', 'HighlightColor',[0 0 0]);
zl = spm_orthviews('ZoomMenu');
czlabel = cell(size(zl));
% List zoom steps in reverse order
zl = zl(end:-1:1);
for cz = 1:numel(zl)
    if isinf(zl(cz))
        czlabel{cz} = 'Full Volume';
    elseif isnan(zl(cz))
        czlabel{cz} = 'BBox (Y > ...)';
    elseif zl(cz) == 0
        czlabel{cz} = 'BBox (nonzero)';
    else
        czlabel{cz} = sprintf('%dx%dx%dmm', 2*zl(cz), 2*zl(cz), 2*zl(cz));
    end
end
uicontrol('Parent',u2,'Style','Popupmenu', 'Position',[5 45 125 20].*WS,...
    'String',czlabel, 'Tag','spm_image_dsp:zoom',...
    'Callback','spm_image_dsp(''zoom'')','ToolTipString','Zoom in by different amounts');
c = 'if get(gcbo,''Value'')==1, spm_orthviews(''Space''), else, spm_orthviews(''Space'', 1);end;spm_image_dsp(''zoom'')';
uicontrol('Parent',u2,'Style','Popupmenu', 'Position',[5 25 125 20].*WS,...
    'String',char('World Space','Voxel Space'),...
    'Callback',c,'ToolTipString','Display in aquired/world orientation');
uicontrol('Parent',u2,'Style','Popupmenu', 'Position',[5  5 125 20].*WS,...
    'String',char('Auto Window','Manual Window', 'Percentiles Window'), 'Tag','spm_image_dsp:window',...
    'Callback','spm_image_dsp(''window'');','ToolTipString','Range of voxel intensities displayed');
uicontrol('Parent',u2,'Style','Pushbutton', 'Position',[140 45 125 20].*WS,...
    'String','Hide Crosshair', 'Tag','spm_image_dsp:xhairs', 'UserData', true,...
    'Callback','spm_image_dsp(''Xhairs'');','ToolTipString','Show/hide crosshair');
uicontrol('Parent',u2,'Style','Popupmenu', 'Position',[140 25 125 20].*WS,...
    'String',char('NN interp.','Trilinear interp.','Sinc interp.'),...
    'UserData',[0 1 -4],'Value',2,...
    'Callback','spm_orthviews(''Interp'',subsref(get(gcbo,''UserData''),substruct(''()'',{get(gcbo,''Value'')})))',...
    'ToolTipString','Interpolation method for displaying images');
uicontrol('Parent',u2,'Style','Pushbutton', 'Position',[140 5 125 20].*WS,...
    'String','Add Overlay...', 'Tag','spm_image_dsp:overlay',...
    'Callback','spm_image_dsp(''addblobs'');','ToolTipString','Superimpose activations');
