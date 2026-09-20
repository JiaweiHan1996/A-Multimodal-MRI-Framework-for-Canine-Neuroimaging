function results = construct_new_matrix(voxel_size)

base = eye(3);
results = cell(8, 1);
index = 1;

for swap = [false, true]      
    for sign2 = [1, -1]       
        for sign3 = [1, -1]  
            mat = base;      
            
            if swap
                temp = mat(2, :);
                mat(2, :) = mat(3, :);
                mat(3, :) = temp;
            end
            
            mat(2, :) = mat(2, :) * sign2;
            mat(3, :) = mat(3, :) * sign3;
            
            results{index} = mat .* repmat(voxel_size, 3, 1);
            index = index + 1;
        end
    end
end