function [struct1] = add_all_structure_fields(struct1, struct2)
%add_all_structure_fields takes all fields that are a part of struct1 and
%adds them to struct2

% see: https://www.mathworks.com/matlabcentral/answers/229604-how-to-copy-field-contents-of-one-struct-to-another
for fn = fieldnames(struct2)'
   struct1.(fn{1}) = struct2.(fn{1});
end

end

