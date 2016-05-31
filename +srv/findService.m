function s = findService(id, varargin)
%SRV.FINDSERVICE Returns experiment service(s) with specified id(s)
%   TODO. See also EXP.SERVICE, EXP.BASICSERVICES.
%
% Part of Rigbox

% 2013-06 CB created

services = srv.basicServices;

ids = mapToCell(@(s) s.Id, services);

  function s = find(id)
    s = services(strcmp(ids, id));
    assert(numel(s) > 0, 'No service with id ''%s'' found', id);
    assert(~(numel(s) > 1), 'More than one service with id ''%s'' found', id);
    s = s{1};
  end

if nargin > 1
  %when called with multiple arguments, assume that each one is an id, so
  %just convert to a standard call with a single cell array argument
  s = srv.findService(cat(2, id, varargin));
elseif iscell(id)
  s = mapToCell(@find, id);
else
  s = find(id);
end

end

