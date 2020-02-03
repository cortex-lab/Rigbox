%% Test distribution of an input array with distrubute function
arr = 1:5;
[a, b, c] = distribute(arr);
assert(a == 1 && b == 2 && c == 3)