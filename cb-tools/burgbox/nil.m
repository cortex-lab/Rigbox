function n = nil
%NIL Returns a global object meaning 'nothing'
%   n = NIL returns a global object that stands for 'nothing'. It (only)
%   equals itself, isempty(nil) returns true, and numel(nil) returns 0.
%   Note that while [] stands for something (an empty vector), nil really
%   stands for nothing, similar to null in other languages.
%
% Part of Burgbox

% 2013-10 CB created

n = fun.EmptySeq.Nil;

end