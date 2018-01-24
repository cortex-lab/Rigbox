

function expSeq = findNextSeqNum(subject, varargin)
% expSeq = findNextSeqNum(subject[, date])
%
% Returns the next experiment number (aka Sequence number) that should be
% chosen for the given subject. Optionally specify a particular date to
% consider. 

if isempty(varargin)
    expDate = now; %default to today
else
    expDate = varargin{1};
end


% retrieve list of experiments for subject
[~, dateList, seqList] = dat.listExps(subject);

% filter the list by expdate
expDate = floor(expDate);
filterIdx = dateList == expDate;

% find the next sequence number
expSeq = max(seqList(filterIdx)) + 1;
if isempty(expSeq)
  % if none today, max will have returned [], so override this to 1
  expSeq = 1;
end