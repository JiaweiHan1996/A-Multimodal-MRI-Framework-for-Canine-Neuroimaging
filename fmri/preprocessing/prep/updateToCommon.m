function [updatedT1Datalist, updatedDatalist, UnprocDatalist] = updateToCommon(T1Datalist, Datalist)

    sublist1 = T1Datalist.Sublist;
    sublist2 = Datalist.Sublist;
    
    str1 = string(sublist1);
    str2 = string(sublist2);
    
    [common, idx1, idx2] = intersect(str1, str2);
    
    removed1 = setdiff(str1, common);
    removed2 = setdiff(str2, common);
    
    updatedT1Datalist = struct();
    updatedDatalist = struct();
    
    fields1 = fieldnames(T1Datalist);
    for i = 1:length(fields1)
        f = fields1{i};
        data = T1Datalist.(f);
        
        if length(data) == length(sublist1)
            updatedT1Datalist.(f) = data(idx1);
        else
            updatedT1Datalist.(f) = data;
        end
    end
    
    fields2 = fieldnames(Datalist);
    for i = 1:length(fields2)
        f = fields2{i};
        data = Datalist.(f);
        
        if length(data) == length(sublist2)
            updatedDatalist.(f) = data(idx2);
        else
            updatedDatalist.(f) = data;
        end
    end
    
    UnprocDatalist.removedFromT1Datalist = cellstr(removed1);
    UnprocDatalist.removedFromDatalist = cellstr(removed2);
    UnprocDatalist.commonSublist = cellstr(common);
    
    fprintf('T1Datalist: %d -> %d (delete %d subjects)\n', length(sublist1), length(common), length(removed1));
    fprintf('Datalist: %d -> %d (delete %d subjects)\n', length(sublist2), length(common), length(removed2));
end