function ref = constructExpRef(subjectRef, expDate, expSequence)
%DAT.CONSTRUCTEXPREF Constructs an experiment reference string
%   ref = DAT.CONSTRUCTEXPREF(subject, date, seq) constructs and returns a
%   standard format string reference, for the experiment using the 'subject',
%   the 'date' of the experiment (a MATLAB datenum), and the daily sequence
%   number of the experiment, 'seq' (must be an integer).
%
% Part of Rigbox

% 2013-03 CB created

% tabulate the args to get complete rows
[subjectRef, expDate, expSequence, singleArgs] = ...
  tabulateArgs(subjectRef, expDate, expSequence);

% Convert the experiment datenums to strings
expDate = mapToCell(@(d) iff(ischar(d), d, @() datestr(d, 'yyyy-mm-dd')), expDate);

% Format the reference strings using elements from each property
ref = cellsprintf('%s_%i_%s', expDate, expSequence, subjectRef);

if singleArgs
  % if non-cell inputs were supplied, make sure we don't return a cell
  ref = ref{1};
end

end

