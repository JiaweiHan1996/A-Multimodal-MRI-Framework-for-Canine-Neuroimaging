function newNiiStruct = adjusthdr(new_mat, oriNiiStruct, qb, qc, qd)
    newNiiStruct = oriNiiStruct;
    newNiiStruct.hdr.hist.srow_x = [new_mat(1,:) newNiiStruct.hdr.hist.qoffset_x];
    newNiiStruct.hdr.hist.srow_y = [new_mat(2,:) newNiiStruct.hdr.hist.qoffset_y];
    newNiiStruct.hdr.hist.srow_z = [new_mat(3,:) newNiiStruct.hdr.hist.qoffset_z];
    newNiiStruct.hdr.hist.quatern_b = qb;
    newNiiStruct.hdr.hist.quatern_c = qc;
    newNiiStruct.hdr.hist.quatern_d = qd;
end