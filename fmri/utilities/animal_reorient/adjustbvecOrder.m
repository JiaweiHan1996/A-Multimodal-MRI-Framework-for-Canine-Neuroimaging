function adjustbvecOrder(oriNiiStruct, finalNiiStruct, bvec_file)

    origMat = [oriNiiStruct.hdr.hist.srow_x; 
               oriNiiStruct.hdr.hist.srow_y; 
               oriNiiStruct.hdr.hist.srow_z;
               0 0 0 1];
               
    newMat = [finalNiiStruct.hdr.hist.srow_x; 
               finalNiiStruct.hdr.hist.srow_y; 
               finalNiiStruct.hdr.hist.srow_z;
               0 0 0 1];
    

    transformMat = origMat / newMat; 
    

    R = transformMat(1:3, 1:3);
    

    [~, perm] = max(abs(R), [], 2);
    flipDims = diag(R(perm,:)) < 0;
    
    bvec_matrix = load(bvec_file);
    

    new_bvec = bvec_matrix(perm,:);
       

    for i = 1:3
        if flipDims(i)
            new_bvec(i, :) = -new_bvec(i, :);
        end
    end

    fid=fopen([bvec_file(1:end-5), '.reoriented_bvec'],'w');
    for i=1:size(new_bvec,1)
        fprintf(fid,'%f ',new_bvec(i,:));
        fprintf(fid,'\r\n');
    end
    fclose(fid);
end