function l = check()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

branch = strtrim(hg('branch'));

% incoming = hg('incoming', '-b', 'cortexlab');
incoming = hg('incoming', '-b', branch);

[l, err] = upd.parseChangeSets(incoming);
assert(isempty(err), 'Update check failed with "%s"', err);

end