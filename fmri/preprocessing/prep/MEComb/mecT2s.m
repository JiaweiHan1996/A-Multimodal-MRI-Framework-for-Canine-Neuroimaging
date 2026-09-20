function varargout = mecT2s(action, varargin)
%MECT2S Fit and correct the T2* map used for optimal combination.

switch lower(char(action))
    case 'fit'
        varargout{1} = fitT2s(varargin{:});
    case 'fix'
        varargout{1} = fixT2s(varargin{:});
    otherwise
        error('MEComb:DecayAction', 'Unknown action: %s', action);
end
end

function t2s = fitT2s(data, tes, masksum)
tes = double(tes(:)).';
masksum = masksum(:);
nSamples = size(data, 1);
nVols = size(data, 3);
echosToRun = unique(masksum).';
if any(echosToRun == 1) && ~any(echosToRun == 2)
    echosToRun = sort([echosToRun, 2]);
end
echosToRun = echosToRun(echosToRun >= 2);

t2s = zeros(nSamples, 1);
for echoNum = echosToRun
    if echoNum == 2
        idx = masksum > 0 & masksum <= 2;
    else
        idx = masksum == echoNum;
    end
    if ~any(idx)
        continue;
    end
    subset = data(idx, 1:echoNum, :);
    nVox = sum(idx);
    data2d = reshape(permute(subset, [3, 2, 1]), echoNum * nVols, nVox);
    x = [ones(echoNum, 1), -tes(1:echoNum).'];
    betas = repelem(x, nVols, 1) \ log(abs(double(data2d)) + 1);
    t2s(idx) = 1 ./ betas(2, :).';
end
end

function t2s = fixT2s(t2s, tes)
t2s = double(t2s);
t2s(isinf(t2s)) = 0.5;
t2s(t2s <= 0) = 0.001;
t2s = floorT2(t2s, tes);
end

function t2s = floorT2(t2s, tes)
nonzero = t2s ~= 0;
temp = zeros(numel(tes), numel(t2s));
temp(:, nonzero) = exp(-tes(:) ./ t2s(nonzero).');
bad = any(temp == 0, 1).' & nonzero;
t2s(bad) = min(-tes) / log(eps(class(t2s)));
end





