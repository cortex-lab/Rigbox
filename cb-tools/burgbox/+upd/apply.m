function nChangeSets = apply()
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here

pulled = hg('pull');

if ~isempty(...
    regexp(pulled, 'searching for changes\nno changes found', 'once'))
  nChangeSets = 0;
else
  pullmatch = regexp(pulled,...
    '\nadded (?<nChangeSets>\d+) changesets with .*?\n\(run ''hg (?<hg>\w+)''.*?\)\n',...
    'names', 'once');
  if ~isempty(pullmatch)
    % there were changesets pulled, so we can update now
    nChangeSets = str2double(pullmatch.nChangeSets);
    switch pullmatch.hg
      case 'update'
        update = hg('update');
        upmatch = regexp(update,...
          '(\d+) files updated, (\d+) files merged, (\d+) files removed, (\d+) files unresolved\n',...
          'once');
        fprintf('Applied %i new changeset(s):\n%s', nChangeSets, update);
        if isempty(upmatch)
          handleError(update);
        end
      case 'heads'
        error('Update requires merge (probably because changes were committed locally)');
%         merge = hg('merge');
%         mergematch = regexp(merge,...
%           '(\d+) files updated, (\d+) files merged, (\d+) files removed, (\d+) files unresolved\n',...
%           'once');        
%         if isempty(mergematch)
%           handleError(merge);
%         end
%         fprintf('Applied %i new changeset(s):\n%s', nChangeSets, merge);
      otherwise
        error('Unexpected pull result: "%s"', pulled)
    end
  else
    % presumably an error occurred
    handleError(pulled);
  end
end

  function handleError(result)
    abortMsg = first(regexp(result, 'abort: (.*?)\n', 'tokens', 'once'));
    error('Update failed with "%s"', abortMsg);
  end

end