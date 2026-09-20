function varargout = mecMask(action, varargin)
%MECMASK Validate TE values and make the default adaptive mask.

switch lower(char(action))
    case 'check'
        varargout{1} = checkTe(varargin{1});
    case 'adapt'
        varargout{1} = adpMask(varargin{1});
    otherwise
        error('MEComb:MaskAction', 'Unknown action: %s', action);
end
end

function tes = checkTe(tes)
tes = double(tes(:)).';
if all(tes > 0 & tes < 1)
    return;
elseif all(tes >= 1)
    tes = tes ./ 1000;
else
    error('MEComb:EchoTimes', 'Echo times must all be seconds or all be milliseconds.');
end
end

function masksum = adpMask(data)
nSamples = size(data, 1);
nEchos = size(data, 2);
good = ~any(isnan(data) | data <= 0, 3);
base = zeros(nSamples, 1);
for iEcho = 1:nEchos
    idx = base == iEcho - 1 & good(:, iEcho);
    base(idx) = iEcho;
end

echoMeans = mean(data, 3);
firstEcho = echoMeans(echoMeans(:, 1) ~= 0, 1);
if isempty(firstEcho)
    dropout = zeros(nSamples, 1);
else
    perc = pctlHigh(firstEcho, 33);
    threshold = echoMeans(echoMeans(:, 1) == perc, :) ./ 3;
    if size(threshold, 1) > 1
        [~, bestIdx] = max(sum(threshold, 2));
        threshold = threshold(bestIdx, :);
    end
    dropout = zeros(nSamples, 1);
    for iEcho = 1:nEchos
        dropout(abs(echoMeans(:, iEcho)) > threshold(iEcho)) = iEcho;
    end
end

masksum = min(base, dropout);
end

function value = pctlHigh(x, p)
x = sort(x(:));
idx = ceil((p / 100) * numel(x));
idx = max(1, min(numel(x), idx));
value = x(idx);
end

