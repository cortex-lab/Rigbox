%% repelems_test
% Currently outputs are unexpected for matrices and when the size of the
% second input doesn't match the first.  This function was designed for use
% by exp.Parameters/toConditionServer

%% Test simple 1-by-n array
assert(isequal(repelems([0 1 2], [2 1 3]), [0 0 1 2 2 2]))

%% Test simple 1-by-n array
assert(isequal(repelems([0 1 2], [2 0 3]), [0 0 2 2 2]))

%% Test function with none-scalar struct
% This is a similar form to how it is used by exp.Parameters
array.field = [1;1];
array(2).field = [2;2];
rarr = repelems(array, [2 5]);
assert(isequal([rarr.field], [1 1 2 2 2 2 2; 1 1 2 2 2 2 2]))

% %% Test n-by-n array
% assert(isequal(repelems([0 1 2; 3 4 5], [2 0 2; 2 0 2]), [0 0 1 2 2 2]))