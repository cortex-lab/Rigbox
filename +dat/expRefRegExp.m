function s = expRefRegExp()
%DAT.EXPREFREGEXP Regular expression for parsing Rigging experiment refs
%   s = expRefRegExp() returns a regular expression string for parsing
%   Rigging experiment refs into tokens for date fields, sequence number
%   and subject.
%
%   The pattern for 'ref' should be '{date}_{seq#}_{subject}'.
%
% Part of Rigbox

% 2014-01 CB created

s = '(?<date>^[0-9\-]+)_(?<seq>\d+)_(?<subject>\w+)';

end