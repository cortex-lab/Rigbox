function [expRef, expDate, expSequence] = listExps(subjects)
%DAT.LISTEXPS Lists experiments for given subject(s)
%   [ref, date, seq] = DAT.LISTEXPS(subject) Lists experiment for given
%   subject(s) in date, then sequence number order.
%
% Part of Rigbox

% 2013-03 CB created

% The master 'main' repository is the reference for the existence of
% experiments, as given by the folder structure
mainPath = ensureCell(dat.reposPath('main', 'remote'));

  function [expRef, expDate, expSeq] = subjectExps(subject)
    % finds experiments for individual subjects
    % experiment dates correpsond to date formated folders in subject's
    % folder
    subjectPath = fullfile(mainPath, subject);
    subjectDirs = cellflat(rmEmpty(file.list(subjectPath, 'dirs')));
    dateRegExp = '^(?<year>\d\d\d\d)\-?(?<month>\d\d)\-?(?<day>\d\d)$';
    dateMatch = regexp(subjectDirs, dateRegExp, 'names');
    dateStrs = unique(subjectDirs(~emptyElems(dateMatch)));
    [expDate, expSeq] = mapToCell(@(d) expsForDate(subjectPath, d), dateStrs);
    expDate = cat(1, expDate{:});
    expSeq = cat(1, expSeq{:});
    expRef = dat.constructExpRef(repmat({subject}, size(expDate)), expDate, expSeq);
    %sort them by date first then sequence number
    [~,  isorted] = sort(cellsprintf('%.0d-%03i', expDate, expSeq));
    %remove duplicates that may exist in alternate repos
    [~,ia] = unique(expRef);
    isorted = intersect(isorted,ia,'stable');
    expRef = expRef(isorted);
    expDate = expDate(isorted);
    expSeq = expSeq(isorted);
  end

  function [dates, seqs] = expsForDate(subjectPath, dateStr)
    dateDirs = rmEmpty(file.list(fullfile(subjectPath, dateStr), 'dirs'));
    seqMatch = cell2mat(regexp(cellflat(dateDirs), '(?<seq>\d+)', 'names'));
    if numel(seqMatch) > 0
      seqs = str2double({seqMatch.seq}');
    else
      seqs = [];
    end
    if length(dateStr) > 8
      dateFormat = 'yyyy-mm-dd';
    else
      dateFormat = 'yyyymmdd';
    end
    dates = repmat(datenum(dateStr, dateFormat), size(seqs));
  end

if iscell(subjects)
  [expRef, expDate, expSequence] = mapToCell(@subjectExps, subjects);
else
  [expRef, expDate, expSequence] = subjectExps(subjects);
end

end

