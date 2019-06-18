function b = expExists(expRef)
%DAT.EXPEXISTS Confirm existence of experiment(s) with reference
%   b = DAT.EXPEXISTS(expRef) Returns true is expRef exists, where expRef
%   is an experiment reference string or cell array thereof.  For an
%   experiment to exist the correct folder structure must be present in the
%   main repository's master location.
%
% See Also DAT.LISTEXPS, DAT.PATHS
%
% Part of Rigbox

% 2013-03 CB created

if iscell(expRef)
  b = cellfun(@check, expRef);
else
  b = check(expRef);
end

  function b = check(expRef)
    % ensure the standard folder given the reference exists
    b = file.exists(dat.expPath(expRef, 'main', 'master'));
  end

end