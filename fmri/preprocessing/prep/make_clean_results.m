function make_clean_results(path, name)

if ischar(name)
    name = {name};
end

errors = cell(length(name), 1);
emptyStatus = cellfun(@isempty,name); 
deleted_count = 0;

fprintf('\nStart cleaning up the directory...\n');

for i = 1:length(name)
    try
        if emptyStatus(i) == 0
            target_path = [path filesep name{i}];
            if exist(target_path, 'dir')
                try
                    rmdir(target_path, 's');
                    fprintf('✓ Successfully deleted the directory: %s\n', name{i});
                    deleted_count = deleted_count + 1;
                    
                catch delete_err
                    error_msg = sprintf('Failed to delete the directory "%s": %s', name{i}, delete_err.message);
                    errors{i} = error_msg;
                    fprintf('✗ %s\n', error_msg);
                end
            else
                fprintf('➤ The directory does not exist, Skipping.: %s\n', name{i});
            end
        end
        
    catch outer_err
        error_msg = sprintf('An unexpected error occurred while processing the directory "%s": %s', name{i}, outer_err.message);
        errors{i} = error_msg;
        fprintf('✗ %s\n', error_msg);
    end
end

fprintf('Total number of directories: %d\n', length(name));
fprintf('Successfully deleted: %d\n', deleted_count);
fprintf('Number of failures: %d\n', sum(~cellfun(@isempty, errors)));

if any(~cellfun(@isempty, errors))
    fprintf('\n=== Error details ===\n');
    for i = 1:length(errors)
        if ~isempty(errors{i})
            fprintf('• %s\n', errors{i});
        end
    end
else
    fprintf('✓ All directory cleaning has been completed and no errors occurred.\n');
end

fprintf('The cleaning operation has been completed.\n');

end