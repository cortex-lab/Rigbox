function [cs, err] = parseChangeSets(str)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

rexp = 'user:\ {8}(?<user>.*?)\ndate:\ {8}(?<date>.*?)\nsummary:\ {5}(?<summary>.*?)\n';
cs = regexp(str, rexp, 'names');
err = [];

if isempty(cs)
  % if no field matches are found, assume that either no change sets are
  % available (and check for corresponding message) or that there was an
  % error
  if ~isempty(regexp(str, '\nno changes found', 'once'))
    % no new change sets, return empty struct
    cs = struct('user', {}, 'date', {}, 'summary', {});
  else
    err = first(regexp(str, 'abort: (.*?)\n', 'tokens', 'once'));
  end
  return
end

dformat = java.text.SimpleDateFormat('EEE MMM dd HH:mm:ss yyyy Z');
cal = java.util.Calendar.getInstance();

dns = mapToCell(@hgDateToDatenum, {cs.date});
[cs.date] = dns{:};

  function dn = hgDateToDatenum(strs)
    cal.setTime(dformat.parse(strs));
    javaSerialDate = cal.getTimeInMillis() + cal.get(cal.ZONE_OFFSET) + cal.get(cal.DST_OFFSET);
    dn = datenum([1970 1 1 0 0 javaSerialDate / 1000]);
  end

end

