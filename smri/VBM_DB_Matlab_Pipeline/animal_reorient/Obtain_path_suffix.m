function [path, filename, ext] = Obtain_path_suffix(fullpath)
    [path, tmp_filename, ~] = fileparts(fullpath);
    match = regexp(fullpath, '\.nii(\.gz)?$', 'match', 'once');
    if ~isempty(match)
        ext = match;
    else
        ext = '';
    end
    if strcmp(ext,'.nii')
        filename = tmp_filename;
    else
        filename = tmp_filename(1:end-4);
    end
end