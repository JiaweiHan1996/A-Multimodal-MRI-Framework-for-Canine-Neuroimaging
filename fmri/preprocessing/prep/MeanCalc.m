function MeanCalc(Scans, outputScans)
V = spm_vol(Scans);
Y = spm_read_vols(V);

if ndims(Y) == 4
    meanY = mean(Y, 4);
else
    meanY = Y;
end
meanV = V(1);
meanV.fname = outputScans;
meanV.dt = [16 0];
meanV.descrip = 'Mean image';
meanV.n = [1 1];
spm_write_vol(meanV, meanY);
end