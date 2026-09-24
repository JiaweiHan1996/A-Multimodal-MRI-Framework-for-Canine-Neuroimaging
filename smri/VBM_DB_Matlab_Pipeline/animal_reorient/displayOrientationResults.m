function selectedIdx = displayOrientationResults(templateNii, results)
    screenSize = get(0, 'ScreenSize');
    screenW = screenSize(3);
    screenH = screenSize(4);
    
    figW = min(screenW * 0.8, screenW - 50);
    figH = min(screenH * 0.85, screenH - 100);
    figW = max(figW, 1000);
    figH = max(figH, 700);
    figLeft = (screenW - figW) / 2;
    figBottom = (screenH - figH) / 2;
    
    fig = figure('Name', 'Confirmation of body position rotation results', ...
                 'NumberTitle', 'off', ...
                 'Position', [figLeft, figBottom, figW, figH], ...
                 'Color', 'k', ...
                 'Units', 'normalized');
    
    templateVol = templateNii.img;
    if ndims(templateVol) > 3
        templateVol = templateVol(:,:,:,1);
    end
    templateMin = min(templateVol(:));
    templateMax = max(templateVol(:))/2;
    

    resMin = inf;
    resMax = -inf;
    for i = 1:length(results)
        vol = results{i}.img;
        if ndims(vol) > 3
            vol = vol(:,:,:,1);
        end
        resMin = min(resMin, min(vol(:)));
        resMax = max(resMax, max(vol(:))/2);
    end
    
    ax_template = subplot(6, 8, [1:16], 'Units', 'normalized');
    showOrthoview(templateNii, ax_template, 'Template');
    set(ax_template, 'Tag', '0', 'UserData', 0);
    
    resultAxes = gobjects(8, 1);
    for idx = 1:8
        rowStart = 3 + 2*floor((idx-1)/4);
        col = mod(idx-1,4)*2 + 1;
        positions = [
            (rowStart-1)*8 + col, ...
            (rowStart-1)*8 + col+1, ...
            rowStart*8 + col, ...
            rowStart*8 + col+1
        ];
        ax = subplot(6, 8, positions, 'Units', 'normalized');
        showOrthoview(results{idx}, ax, sprintf('Result %d', idx));
        resultAxes(idx) = ax;
        set(ax, 'Tag', num2str(idx), 'UserData', idx, 'ButtonDownFcn', @selectImage);
        set(get(ax, 'Children'), 'HitTest', 'on', 'ButtonDownFcn', @selectImage);
    end
    
    allAxes = [ax_template; resultAxes];
    shiftUp = 0.03;
    heightReduce = 0.01;
    for i = 1:length(allAxes)
        pos = get(allAxes(i), 'Position');
        pos(2) = pos(2) + shiftUp;
        pos(4) = pos(4) - heightReduce;
        if pos(2) < 0.05
            pos(2) = 0.05;
        end
        set(allAxes(i), 'Position', pos);
    end
    
 
    panelW = 0.25;                           
    panelH = min(0.12, 120/figH);           
    panelX = 1 - panelW - 0.02;           
    panelY = 0.01;                     
    ctrlPanel = uipanel('Parent', fig, ...
                'Units', 'normalized', ...
                'Position', [panelX, panelY, panelW, panelH], ...
                'Title', 'Brightness (Min/Max) - Enter applies', ...
                'TitlePosition', 'centertop', ...
                'BackgroundColor', [0.2 0.2 0.2], ...
                'ForegroundColor', 'w', ...
                'FontSize', 10);
    

    labelW = 0.22;
    editW = 0.22;
    spacing = 0.03;
    row1Y = 0.6;      
    row2Y = 0.25;     
    editH = 0.2;     
    
    uicontrol('Parent', ctrlPanel, 'Style', 'text', ...
              'String', 'T Min:', ...
              'Units', 'normalized', ...
              'Position', [0.05, row1Y, labelW, editH], ...
              'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'w', ...
              'HorizontalAlignment', 'right');
    templateMinEdit = uicontrol('Parent', ctrlPanel, 'Style', 'edit', ...
                                'String', num2str(templateMin), ...
                                'Units', 'normalized', ...
                                'Position', [0.05+labelW+spacing, row1Y, editW, editH], ...
                                'BackgroundColor', 'w', 'ForegroundColor', 'k');
    uicontrol('Parent', ctrlPanel, 'Style', 'text', ...
              'String', 'Max:', ...
              'Units', 'normalized', ...
              'Position', [0.05+labelW+spacing+editW+2*spacing, row1Y, 0.08, editH], ...
              'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'w', ...
              'HorizontalAlignment', 'right');
    templateMaxEdit = uicontrol('Parent', ctrlPanel, 'Style', 'edit', ...
                                'String', num2str(templateMax), ...
                                'Units', 'normalized', ...
                                'Position', [0.05+labelW+spacing+editW+2*spacing+0.08+spacing, row1Y, editW, editH], ...
                                'BackgroundColor', 'w', 'ForegroundColor', 'k');
    
    uicontrol('Parent', ctrlPanel, 'Style', 'text', ...
              'String', 'R Min:', ...
              'Units', 'normalized', ...
              'Position', [0.05, row2Y, labelW, editH], ...
              'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'w', ...
              'HorizontalAlignment', 'right');
    resultMinEdit = uicontrol('Parent', ctrlPanel, 'Style', 'edit', ...
                              'String', num2str(resMin), ...
                              'Units', 'normalized', ...
                              'Position', [0.05+labelW+spacing, row2Y, editW, editH], ...
                              'BackgroundColor', 'w', 'ForegroundColor', 'k');
    uicontrol('Parent', ctrlPanel, 'Style', 'text', ...
              'String', 'Max:', ...
              'Units', 'normalized', ...
              'Position', [0.05+labelW+spacing+editW+2*spacing, row2Y, 0.08, editH], ...
              'BackgroundColor', [0.2 0.2 0.2], 'ForegroundColor', 'w', ...
              'HorizontalAlignment', 'right');
    resultMaxEdit = uicontrol('Parent', ctrlPanel, 'Style', 'edit', ...
                              'String', num2str(resMax), ...
                              'Units', 'normalized', ...
                              'Position', [0.05+labelW+spacing+editW+2*spacing+0.08+spacing, row2Y, editW, editH], ...
                              'BackgroundColor', 'w', 'ForegroundColor', 'k');
    
    selectionText = uicontrol('Style', 'text', ...
                  'Units', 'normalized', ...
                  'Position', [0.01, 0.01, 0.12, 0.04], ...
                  'String', 'Selected: None', 'Tag', 'selectionText', ...
                  'BackgroundColor', 'k', 'ForegroundColor', 'w');
    
    uicontrol('Style', 'pushbutton', ...
              'Units', 'normalized', ...
              'Position', [0.14, 0.01, 0.1, 0.05], ...
              'String', 'Confirm Selection', 'Tag', 'confirmButton', ...
              'Callback', @(src,evt)uiresume(fig));
    
    function selectImage(src, ~)
        if strcmp(get(src, 'Type'), 'axes')
            ax = src;
        else
            ax = ancestor(src, 'axes');
        end
        idx = get(ax, 'UserData');
        allAxes = findobj(fig, 'Type', 'axes');
        for i = 1:length(allAxes)
            set(allAxes(i), 'LineWidth', 0.5, 'XColor', 'w', 'YColor', 'w');
        end
        set(ax, 'LineWidth', 3, 'XColor', 'y', 'YColor', 'y');
        selectedIdx = idx;
        if selectedIdx == 0
            set(selectionText, 'String', 'Selected: Template');
        else
            set(selectionText, 'String', sprintf('Selected: Result %d', selectedIdx));
        end
    end

    function applyTemplateBrightness(~,~)
        newMin = str2double(get(templateMinEdit, 'String'));
        newMax = str2double(get(templateMaxEdit, 'String'));
        if isnan(newMin) || isnan(newMax) || newMin >= newMax
            errordlg('Invalid brightness range: Min must be less than Max.', 'Input Error');
            return;
        end
        set(ax_template, 'CLim', [newMin, newMax]);
        drawnow;
    end

    function applyResultBrightness(~,~)
        newMin = str2double(get(resultMinEdit, 'String'));
        newMax = str2double(get(resultMaxEdit, 'String'));
        if isnan(newMin) || isnan(newMax) || newMin >= newMax
            errordlg('Invalid brightness range: Min must be less than Max.', 'Input Error');
            return;
        end
        for i = 1:length(resultAxes)
            set(resultAxes(i), 'CLim', [newMin, newMax]);
        end
        drawnow;
    end

    function editKeyPress(~, evt, targetType)
        if any(strcmp(evt.Key, {'return', 'enter', 'numpadenter'}))
            switch targetType
                case 'template'
                    applyTemplateBrightness();
                case 'results'
                    applyResultBrightness();
            end
        end
    end
    
    set(templateMinEdit, 'KeyPressFcn', @(src,evt) editKeyPress(src,evt,'template'));
    set(templateMaxEdit, 'KeyPressFcn', @(src,evt) editKeyPress(src,evt,'template'));
    set(resultMinEdit,   'KeyPressFcn', @(src,evt) editKeyPress(src,evt,'results'));
    set(resultMaxEdit,   'KeyPressFcn', @(src,evt) editKeyPress(src,evt,'results'));
    
    set(templateMinEdit, 'Callback', @applyTemplateBrightness);
    set(templateMaxEdit, 'Callback', @applyTemplateBrightness);
    set(resultMinEdit,   'Callback', @applyResultBrightness);
    set(resultMaxEdit,   'Callback', @applyResultBrightness);
    
    uiwait(fig);
    if ishandle(fig)
        close(fig);
    end
end

function showOrthoview(niiStruct, ax, titleText)
    vol = niiStruct.img;
    if ndims(vol) > 3
        vol = vol(:,:,:,1);
    end
    imgMin = min(vol(:));
    imgMax = max(vol(:))/2;
    
    [nx, ny, nz] = size(vol);
    sag_slice = squeeze(vol(round(nx/2), :, :));
    cor_slice = squeeze(vol(:, round(ny/2), :));
    ax_slice  = squeeze(vol(:, :, round(nz/1.5)));
    
    sag_slice = imrotate(sag_slice, 90);
    cor_slice = imrotate(cor_slice, 90);
    ax_slice  = imrotate(ax_slice, 90);
    
    h_sag = size(sag_slice,1); w_sag = size(sag_slice,2);
    h_cor = size(cor_slice,1); w_cor = size(cor_slice,2);
    h_ax  = size(ax_slice,1);  w_ax  = size(ax_slice,2);
    
    maxH = max([h_sag, h_cor, h_ax]);
    maxW = max([w_sag, w_cor, w_ax]);
    
    bgVal = imgMin;
    canvasSag = repmat(bgVal, maxH, maxW);
    canvasCor = repmat(bgVal, maxH, maxW);
    canvasAx  = repmat(bgVal, maxH, maxW);
    
    offsetY_sag = floor((maxH - h_sag)/2);
    offsetX_sag = floor((maxW - w_sag)/2);
    canvasSag(offsetY_sag+1:offsetY_sag+h_sag, offsetX_sag+1:offsetX_sag+w_sag) = sag_slice;
    
    offsetY_cor = floor((maxH - h_cor)/2);
    offsetX_cor = floor((maxW - w_cor)/2);
    canvasCor(offsetY_cor+1:offsetY_cor+h_cor, offsetX_cor+1:offsetX_cor+w_cor) = cor_slice;
    
    offsetY_ax = floor((maxH - h_ax)/2);
    offsetX_ax = floor((maxW - w_ax)/2);
    canvasAx(offsetY_ax+1:offsetY_ax+h_ax, offsetX_ax+1:offsetX_ax+w_ax) = ax_slice;
    
    sepWidth = 5;
    separator = ones(maxH, sepWidth) * double(imgMax);
    vseparator = ones(sepWidth, maxW*2 + sepWidth) * double(imgMax);
    
    topRow = [canvasSag, separator, canvasCor];
    bottomRow = [canvasAx, separator, zeros(size(canvasAx))];
    combinedImg = [topRow; vseparator; bottomRow];
    
    imagesc(combinedImg, 'Parent', ax, [imgMin, imgMax]);
    colormap(ax, 'gray');
    axis(ax, 'image');
    axis(ax, 'off');
    title(ax, titleText, 'Color', 'w', 'FontSize', 12);
    
    set(get(ax, 'Children'), 'HitTest', 'on', 'ButtonDownFcn', get(ax, 'ButtonDownFcn'));
end