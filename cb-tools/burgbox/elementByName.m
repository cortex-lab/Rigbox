function idx = elementByName(arr, name)
%ELEMENTBYNAME Index of named struct element
%   ELEMENTBYNAME(arr, name) Returns the index of the struct element in the
%   struct array 'arr' with the name field set to 'name'
%
% Part of Burgbox

% 2014-02 CB created

idx = find(strcmp({arr.name}, name));

end

