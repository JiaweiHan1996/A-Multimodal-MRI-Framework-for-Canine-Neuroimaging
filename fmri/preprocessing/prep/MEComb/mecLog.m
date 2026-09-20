function varargout = mecLog(action, varargin)
%MECLOG Record MEComb progress and timing.

switch lower(char(action))
    case 'init'
        varargout{1} = initLog(varargin{:});
    case 'start'
        [varargout{1}, varargout{2}] = startLog(varargin{:});
    case 'done'
        varargout{1} = doneLog(varargin{:});
    case 'fail'
        varargout{1} = failLog(varargin{:});
    case 'end'
        varargout{1} = endLog(varargin{:});
    otherwise
        error('MEComb:LogAction', 'Unknown action: %s', action);
end
end

function logger = initLog(showProgress)
logger = struct('showProgress', logical(showProgress), ...
    'stage', '', 'totalTimer', tic, 'finished', false);
emitLog(logger, sprintf('[%s] MEComb started', timeStr()));
end

function [logger, timer] = startLog(logger, stage, note)
timer = tic;
logger.stage = stage;
emitLog(logger, sprintf('[%s] START %s %s', timeStr(), stage, note));
end

function logger = doneLog(logger, timer, note)
seconds = toc(timer);
emitLog(logger, sprintf('[%s] DONE  %s %.6f s %s', ...
    timeStr(), logger.stage, seconds, note));
logger.stage = '';
end

function logger = failLog(logger, timer, exception)
seconds = toc(timer);
emitLog(logger, sprintf('[%s] FAIL  %s %.6f s %s', ...
    timeStr(), logger.stage, seconds, exception.message));
logger.stage = '';
end

function logger = endLog(logger)
if logger.finished
    return;
end
emitLog(logger, sprintf('[%s] DONE  99_total %.6f s', ...
    timeStr(), toc(logger.totalTimer)));
emitLog(logger, sprintf('[%s] MEComb finished', timeStr()));
logger.finished = true;
end

function emitLog(logger, line)
if logger.showProgress
    fprintf('%s\n', line);
end
end

function value = timeStr()
value = datestr(now, 'yyyy-mm-dd HH:MM:SS');
end
