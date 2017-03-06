function info = parseScanImageHeader(h)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%ensure inputs or each element of input array is a char
if iscell(h)
  h = mapToCell(@char, h);
else
  h = char(h);
end

%parse state.level1.level2.level...=value<newline>
%classes are:
%empties, e.g. 'dottednames=[]'
%string values, e.g. 'dottednames='some value'
%numerical values, e.g. 'dottednames=-13.3'
% namesOfEmpties = regexp(h, 'state.(?<name>(\w|\.)+)\=\[\][\r\n]', 'names');
% namesToStrings = regexp(h, 'state.(?<name>(\w|\.)+)\=''(?<value>.*?)''[\r\n]', 'names');
% namesToNums = regexp(h, 'state.(?<name>(\w|\.)+)\=(?<value>\-?\d.*?|\-?Inf|NaN)[\r\n]', 'names');

namesOfEmpties = regexp(h, '(?<name>(\w|\.)+)\s?\=\s?\[\][\r\n]', 'names');
namesToStrings = regexp(h, '(?<name>(\w|\.)+)\s?\=\s?''(?<value>.*?)''[\r\n]', 'names');
namesToNums = regexp(h, '(?<name>(\w|\.)+)\s?\=\s?(?<value>\-?\d.*?|\-?Inf|NaN)[\r\n]', 'names');
namesToArrays = regexp(h, '(?<name>(\w|\.)+)\s?\=\s?(?<value>\[[^\r\n]+?\])[\r\n]', 'names');
namesToCells = regexp(h, '(?<name>(\w|\.)+)\s?\=\s?(?<value>{[^\r\n]+?})[\r\n]', 'names');

%parse all
% namesToVals = regexp(h, 'state.(?<name>(\w|\.)+)\=(?<value>.*?)[\r\n]', 'names')

  function s = toStruct(empties, strings, nums, arrays, cells)
    s = struct;
    s = structAssign(s, {empties.name}, []);
    s = structAssign(s, {strings.name}, {strings.value});
    values = {nums.value};
    values = sscanf(sprintf('%s#', values{:}), '%g#')';
    s = structAssign(s, {nums.name}, num2cell(values));
    s = structAssign(s, {arrays.name}, mapToCell(@str2num, {arrays.value}));
    s = structAssign(s, {cells.name}, mapToCell(@eval, {cells.value}));
    if isfield(s, 'state')
      s = s.state;
    elseif isfield(s, 'scanimage')
      s = s.scanimage;
      if isfield(s, 'SI4')
        s = s.SI4;
      end
    end
  end

if iscell(h)
  info = cellfun(@toStruct, namesOfEmpties, namesToStrings, namesToNums, namesToArrays, namesToCells);
else
  info = toStruct(namesOfEmpties, namesToStrings, namesToNums, namesToArrays, namesToCells);
end

end

