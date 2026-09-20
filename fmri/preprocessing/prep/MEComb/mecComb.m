function optcom = mecComb(data, tes, masksum, t2s)
%MECCOMB T2*-weighted optimal combination with adaptive echo counts.

optcom = combine(data, tes, masksum, t2s);
end

function combined = combine(data, tes, masksum, t2s)
tes = double(tes(:)).';
masksum = masksum(:);
if size(data, 2) ~= numel(tes) || numel(masksum) ~= size(data, 1)
    error('MEComb:CombineShape', 'Echo, mask, and data dimensions do not match.');
end

combined = zeros(size(data, 1), size(data, 3));
echosToRun = unique(masksum).';
if any(echosToRun == 1) && ~any(echosToRun == 2)
    echosToRun = sort([echosToRun, 2]);
end
echosToRun = echosToRun(echosToRun >= 2);
for echoNum = echosToRun
    if echoNum == 2
        idx = masksum > 0 & masksum <= 2;
    else
        idx = masksum == echoNum;
    end
    if any(idx)
        combined(idx, :) = wAvg(data(idx, 1:echoNum, :), ...
            tes(1:echoNum), t2s(idx));
    end
end
end

function combined = wAvg(data, tes, t2s)
weights = tes .* exp(-tes ./ t2s(:));
weights = repmat(weights, [1, 1, size(data, 3)]);
denominator = reshape(sum(weights, 2), size(data, 1), size(data, 3));
numerator = reshape(sum(double(data) .* weights, 2), size(data, 1), size(data, 3));
combined = zeros(size(numerator));
idx = denominator ~= 0;
combined(idx) = numerator(idx) ./ denominator(idx);
end

