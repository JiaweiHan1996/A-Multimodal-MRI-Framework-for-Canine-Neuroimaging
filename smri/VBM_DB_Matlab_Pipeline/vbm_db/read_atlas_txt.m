function Atlas_Info = read_atlas_txt(txt_path)

fid = fopen(txt_path, 'r');

data_cell = textscan(fid, '%d %s %[^\n]', 'Delimiter', {' ', '\t'}, ...
                     'MultipleDelimsAsOne', true, 'CommentStyle', '');
fclose(fid);

% Extract
indices = data_cell{1};        % index
BA_abbr = data_cell{2};          % Abbr.
BrainArea = data_cell{3};   % Full Name

Atlas_Info = table(indices, BA_abbr, BrainArea, 'VariableNames', ...
             {'id', 'BA_abbr', 'BrainArea'});

end

