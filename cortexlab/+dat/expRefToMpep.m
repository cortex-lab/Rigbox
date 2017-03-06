function [subject, seriesNum, expNum] = expRefToMpep(ref)
%DAT.EXPREFTOMPEP Turns info in an experiment ref into mpep parts
%   [subject, seriesNum, expNum] = DAT.EXPREFTOMPEP(ref) takes the rigging
%   experiment reference 'ref', and extracts the subject, date and sequence
%   number and maps those to Mpep's subject, series and experiment number
%   respectively.
%
% Part of Cortex Lab Rigbox customisations

% 2014-01 CB created

% in mpep language we use the digits of the experiment date yyyymmdd
% as the 'series number', and the sequence number as the mpep
% 'experiment number'.
[subject, date, seq] = dat.parseExpRef(ref);
if ~ischar(date)
  seriesNum = str2double(datestr(date, 'yyyymmdd'));
else
  seriesNum = str2double(date);
end
expNum = seq;


end

