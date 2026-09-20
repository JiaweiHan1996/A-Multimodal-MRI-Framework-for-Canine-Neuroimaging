function result = runComb(varargin)
%RUNCOMB Create T2*-weighted combined data from three echoes.

rootDir = fileparts(mfilename('fullpath'));

opts = struct('echo_files', {{}}, 'echo_times', [], 'mask_file', '', ...
    'outputDir', '', 'outputName', 'desc-denoised_bold.nii', ...
    'showProgress', true);
if mod(numel(varargin), 2) ~= 0
    error('MEComb:Options', 'Inputs must be name-value pairs.');
end
for iArg = 1:2:numel(varargin)
    name = lower(char(varargin{iArg}));
    switch name
        case 'echo_files'
            opts.echo_files = varargin{iArg + 1};
        case 'echo_times'
            opts.echo_times = varargin{iArg + 1};
        case 'mask_file'
            opts.mask_file = varargin{iArg + 1};
        case 'outputdir'
            opts.outputDir = varargin{iArg + 1};
        case 'outputname'
            opts.outputName = varargin{iArg + 1};
        case 'showprogress'
            opts.showProgress = logical(varargin{iArg + 1});
        otherwise
            error('MEComb:Options', 'Unknown option: %s', name);
    end
end

if ~iscell(opts.echo_files) || numel(opts.echo_files) ~= 3
    error('MEComb:EchoFiles', 'echo_files must contain exactly three NIfTI files.');
end
if numel(opts.echo_times) ~= 3
    error('MEComb:EchoTimes', 'echo_times must contain exactly three values.');
end
if isempty(opts.outputDir)
    error('MEComb:Inputs', 'outputDir is required.');
end

logger = mecLog('init', opts.showProgress);
stageTimer = [];
try
    [logger, stageTimer] = mecLog('start', logger, ...
        '01_load', '');
    [data, mask, refInfo] = mecIO('load', opts.echo_files, opts.mask_file);
    logger = mecLog('done', logger, stageTimer, sprintf( ...
        'shape=%dx%dx%d; voxels=%d', size(data, 1), size(data, 2), ...
        size(data, 3), nnz(mask)));

    [logger, stageTimer] = mecLog('start', logger, ...
        '02_mask', '');
    tes = mecMask('check', opts.echo_times);
    masksum = mecMask('adapt', data);
    logger = mecLog('done', logger, stageTimer, sprintf( ...
        'keep=%d; echo3=%d', nnz(masksum > 0), nnz(masksum == 3)));

    [logger, stageTimer] = mecLog('start', logger, ...
        '03_fit', 'loglin');
    t2s = mecT2s('fit', data, tes, masksum);
    logger = mecLog('done', logger, stageTimer, '');

    [logger, stageTimer] = mecLog('start', logger, ...
        '04_fix', '');
    t2s = mecT2s('fix', t2s, tes);
    logger = mecLog('done', logger, stageTimer, '');

    [logger, stageTimer] = mecLog('start', logger, ...
        '05_combine', 't2s');
    optcom = mecComb(data, tes, masksum, t2s);
    logger = mecLog('done', logger, stageTimer, sprintf( ...
        'shape=%dx%d', size(optcom, 1), size(optcom, 2)));

    [logger, stageTimer] = mecLog('start', logger, ...
        '06_write', opts.outputDir);
    outFile = fullfile(opts.outputDir, opts.outputName);
    mecIO('write', optcom, mask, outFile, refInfo);
    logger = mecLog('done', logger, stageTimer, outFile);
    logger = mecLog('end', logger);
catch ME
    if ~isempty(stageTimer) && ~isempty(logger.stage)
        logger = mecLog('fail', logger, stageTimer, ME);
    end
    mecLog('end', logger);
    rethrow(ME);
end

result = struct('outputFile', outFile);
end
