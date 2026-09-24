function originAlignmentPrompt(outputname, templatePath)

%     userChoice = questdlg('是否进行原点对齐？', ...
%                          '原点对齐设置', ...
%                          '是', '否', '是');
    userChoice = '是';

    switch userChoice
        case '是'
            
            try
                spm('FnBanner'); 
            catch
                error('SPM toolbox not loaded! Please run spm(''fmri'') to load SPM');
            end
            
            [path, ~, ext_input] = fileparts(outputname);
            [~, ~, ext_temp] = fileparts(templatePath);
            
            if strcmp(ext_temp,'.gz')
                gunzip(templatePath);
                if exist(templatePath, 'file')
                    delete(templatePath);
                end
                templatePath = templatePath(1:end-3);
            end
            
            if strcmp(ext_input, '.gz')
                gunzip(outputname);
                if exist(outputname, 'file')
                    delete(outputname);
                end
                outputname = outputname(1:end-3);
            end
                
            outputname_png = fullfile(path, 'Template_Origin.png');
            fg = spm_figure('CreateWin', 'Graphics', 'Graphics', 'off');
            spm_figure('Clear', fg);
            spm_image('init', templatePath);
            spm_orthviews('Reposition',[0 0 0]');
            saveas(gcf, outputname_png)
            close(fg);

            spm_image('Display', outputname);
            disp('Please adjust the origin in the SPM window (use the "Set Origin" button or click on the image to set a new origin).');
            disp('After adjustment, click the "Done" button in the dialog that appears below to continue...');
            
            hWait = figure('Name', '原点对齐等待', ...
                           'NumberTitle', 'off', ...
                           'Position', [300, 300, 300, 100], ...
                           'MenuBar', 'none', ...
                           'ToolBar', 'none', ...
                           'Resize', 'off', ...
                           'WindowStyle', 'normal'); 
            uicontrol('Style', 'text', ...
                      'String', '请在SPM窗口中调整原点，完成后点击下方按钮。', ...
                      'Position', [10, 50, 280, 30], ...
                      'BackgroundColor', get(hWait, 'Color'));
            uicontrol('Style', 'pushbutton', ...
                      'String', '完成', ...
                      'Position', [100, 10, 100, 30], ...
                      'Callback', @(src, evt) uiresume(hWait));
            
            uiwait(hWait);
            
            if ishandle(hWait)
                close(hWait);
            end
            
            spm_figure('Close', 'Graphics'); 

            disp(['Origin alignment completed: ', outputname]);
            
        case '否'
            disp('User canceled the origin alignment operation');
            return;
            
        otherwise
            disp('Operation canceled');
            return;
    end
end