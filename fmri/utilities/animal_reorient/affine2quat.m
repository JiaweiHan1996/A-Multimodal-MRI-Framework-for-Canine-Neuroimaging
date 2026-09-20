function [qb, qc, qd] = affine2quat(affine_matrix)
% Compute quatern_b, quatern_c, quatern_d from a 4x4 affine matrix
% Input:  affine_matrix - 4x4 affine transformation matrix
% Output: qb, qc, qd - quaternion components


R = affine_matrix(1:3, 1:3);
scales = sqrt(sum(R.^2)); 
R = R ./ repmat(scales, 3, 1); 


T = trace(R) + 1;

if T > 0.00000001
    S = 0.5 / sqrt(T);
    qw = 0.25 / S;
    qx = (R(3,2) - R(2,3)) * S;
    qy = (R(1,3) - R(3,1)) * S;
    qz = (R(2,1) - R(1,2)) * S;
else
    
    if R(1,1) > R(2,2) && R(1,1) > R(3,3)
        S = 2 * sqrt(1 + R(1,1) - R(2,2) - R(3,3));
        qw = (R(3,2) - R(2,3)) / S;
        qx = 0.25 * S;
        qy = (R(1,2) + R(2,1)) / S;
        qz = (R(1,3) + R(3,1)) / S;
    elseif R(2,2) > R(3,3)
        S = 2 * sqrt(1 + R(2,2) - R(1,1) - R(3,3));
        qw = (R(1,3) - R(3,1)) / S;
        qx = (R(1,2) + R(2,1)) / S;
        qy = 0.25 * S;
        qz = (R(2,3) + R(3,2)) / S;
    else
        S = 2 * sqrt(1 + R(3,3) - R(1,1) - R(2,2));
        qw = (R(2,1) - R(1,2)) / S;
        qx = (R(1,3) + R(3,1)) / S;
        qy = (R(2,3) + R(3,2)) / S;
        qz = 0.25 * S;
    end
end


if qw < 0
    qw = -qw;
    qx = -qx;
    qy = -qy;
    qz = -qz;
end

qb = qx;
qc = qy;
qd = qz;
end