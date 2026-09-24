function adjustedNii = adjustNiiOrientation(originalNii, newSrowX, newSrowY, newSrowZ)

    adjustedNii = originalNii;
    

    adjustedNii.hdr.hist.srow_x = newSrowX;
    adjustedNii.hdr.hist.srow_y = newSrowY;
    adjustedNii.hdr.hist.srow_z = newSrowZ;
    

    origMat = [originalNii.hdr.hist.srow_x; 
               originalNii.hdr.hist.srow_y; 
               originalNii.hdr.hist.srow_z;
               0 0 0 1];
               
    newMat = [newSrowX; 
              newSrowY; 
              newSrowZ;
              0 0 0 1];
    

    transformMat = origMat / newMat; 

    R = transformMat(1:3, 1:3);
    

    [~, perm] = max(abs(R), [], 2);
    flipDims = diag(R(perm,:)) < 0;
    
    img = originalNii.img;
    if ndims(img) > 3
        img = img(:,:,:,1); 
        adjustedNii.hdr.dime.dim(5) = 1;
    end

    img = permute(img, perm);
    
    for i = 1:3
        if flipDims(i)
            img = flip(img, i);
        end
    end
    
    adjustedNii.img = img;
    
    dims = size(img);
    adjustedNii.hdr.dime.dim(2:4) = dims(1:3);
        
end
