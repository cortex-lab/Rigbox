function [subjectRef, expDate, expSequence] = parseExpRef(ref)
%DATA.PARSEEXPREF Extracts subject, date and seq from an experiment ref
%   [subject, date, seq] = DATA.PARSEEXPREF(ref)
%
%   The pattern for 'ref' should be '{date}_{seq#}_{subject}', with two
%   date formats accepted, either 'yyyy-mm-dd' or 'yyyymmdd'.
%
%   Experiment refs with the former format can be constructed with from
%   subject, date and sequence number with data.constructExpRef.
%
% Part of Rigbox

% 2013-03 CB created

if isempty(ref)
  subjectRef = cell(size(ref));
  expDate = zeros(size(ref));
  expSequence = zeros(size(ref));
elseif iscell(ref)
  % process and return arrays (a cell array for subjectRef)
  parsed = regexp(ref, dat.expRefRegExp, 'names');
  failed = emptyElems(parsed);
  if any(failed)
    error('''%s'' could not be parsed', first(ref(failed)));
  end
  parsed = cell2mat(parsed);
  subjectRef = reshape({parsed.subject}, size(ref));
  % which 'dates' parsed from the refs are actually in a date format?
  dateFields = {parsed.date};
  dateMatches = ~emptyElems(...
    regexp(dateFields, '\d{4}-\d\d\-\d\d', 'match'));
  if ~isempty(parsed(dateMatches))
    expDate = datenum({parsed(dateMatches).date}, 'yyyy-mm-dd');
  else
    expDate = [];
  end
  if ~all(dateMatches)
    dateFields(dateMatches) = num2cell(expDate);
    expDate = dateFields;
  end
  expDate = reshape(expDate, size(ref));
  expSequence = reshape(cellstr2double({parsed.seq}), size(ref));
else
  % process and return a single string for subjectRef
  parsed = regexp(ref, dat.expRefRegExp, 'names');
  subjectRef = parsed.subject;
  dateMatch = ~isempty(regexp(parsed.date, '\d{4}-\d\d\-\d\d', 'once'));
  if dateMatch
    expDate = datenum(parsed.date, 'yyyy-mm-dd');
  else
    expDate = parsed.date;
  end
  expSequence = cellstr2double(parsed.seq);
%   fields = textscan(sprintf('%s\n', ref),...
%     '%s %u %s', 'delimiter', '_', 'EndOfLine', '\n');
%   expDate = datenum(fields{1}, 'yyyy-mm-dd');
%   expSequence = fields{2};
%   subjectRef = fields{3}{1};
end


end

