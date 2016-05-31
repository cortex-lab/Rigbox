function block = stripIncompleteTrials(block)
%stripIncompleteTrials Removes any incomplete trials from the block(s).

  function b = strip(b)
    if ~isfield(b, 'numCompletedTrials')
      %if no numCompletedTrials then assume it non were completed (e.g. it
      %crashed before it got going
      b.numCompletedTrials = 0;
    end
    if isfield(b, 'trial')
      % only strip new block type (trial field, not Trials)
      b.trial = b.trial(1:b.numCompletedTrials);
    end
  end

if iscell(block)
  block = mapToCell(@strip, block); % ensure we return a cell
else
  block = arrayfun(@strip, block);
end

end

