function voxel_size = original_voxel(nii_struct)
V1_flag = nii_struct.hdr.hist.srow_x(1);
if V1_flag < 0
    x_voxel_szie = nii_struct.hdr.dime.pixdim(2) * -1;
else
    x_voxel_szie = nii_struct.hdr.dime.pixdim(2);
end
y_voxel_szie = nii_struct.hdr.dime.pixdim(3);
z_voxel_szie = nii_struct.hdr.dime.pixdim(4);
voxel_size = [x_voxel_szie, y_voxel_szie, z_voxel_szie];

end