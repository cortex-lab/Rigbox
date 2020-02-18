%% Setup
origDir = pwd;
mess = onCleanup(@()cd(origDir));
root = fileparts(which('addRigboxPaths'));
cd(fullfile(root, 'docs', 'html'))

%% Timeline.html
% Add image to Timeline.html
filename = 'Timeline.html';
subStr = '<img  height="200" hspace="5" src="Fig7_timeline.png" style="float:right" alt="">';
pattern = '<h1>Timeline</h1><!--introduction-->';
pos = 17;

T = readFile(filename);
T = insert(T, subStr, pattern, pos);
writeFile(filename, T)

%% using_test_gui.html
% Colour error text
filename = 'using_test_gui.html';
pattern = '<p>Error using bombWorld/timeSampler';
subStr = '<pre class="error">';

T = readFile(filename);
T = insert(T, subStr, pattern, 'before');
T = insert(T, '</pre>', 'timeSampler)</p>', 'after');
% Add breaks
lines = {...
  '<p>Caused by:'...
  'mapping Node 61 to 62:'...
  'input [0; 0.1; 0.09] produced an error:'...
  '     Expected char; was double instead.'...
  'examples\bombWorld.m (line 22)'};
for l = lines
  T = insert(T, '<br />', l, 'after', 1);
end
writeFile(filename, T)


%% Helpers
function T = readFile(filename)
% Load file
fid = fopen(filename,'r');
i = 1;
tline = fgetl(fid);
T{i} = tline;
while true
  i = i+1;
  tline = fgetl(fid);
  if tline == -1
    break
  else
    T{i} = tline;
  end
end
fclose(fid);
end

function T = insert(T, subStr, pattern, pos, n)
% INSERT Insert text into one line
%   Inputs:
%     T (cellstr): A cell array of lines from a file
%     subStr (char): The str to insert
%     pattern (char): The search pattern
%     pos (int|char): The postion with respect to the search pattern where
%       to insert subStr.  Either an index location in pattern, or 'first'
%       / 'last'.
%     n (int): The number in the order of pattern matches to insert subStr.
%       Default assumes only one instance of pattern.
if nargin < 4 || isempty(pos), pos = 'after'; end
if nargin < 5, n = 1; end

% Find line
idx = strfind(T, pattern);
if nargin < 5
  assert(sum(cellfun(@numel,idx)) == 1)
else
  assert(sum(cellfun(@numel,idx)) >= n)
end
ln = find(~cellfun('isempty', idx), n, 'first');

% Modify
switch pos
  case 'before'
    T{ln(n)} = insertBefore(T{ln(n)}, pattern, subStr);
  case 'after'
    T{ln(n)} = insertAfter(T{ln(n)}, pattern, subStr);
  otherwise
    startIdx = cell2mat(idx) + pos;
    T{ln(n)} = [T{ln(n)}(1:startIdx-1) subStr T{ln(n)}(startIdx:end)];
end

end

function writeFile(filename, T)
% Write back into file
fid = fopen(filename, 'w');
for i = 1:numel(T)
  if i == numel(T)
    fprintf(fid,'%s', T{i});
    break
  else
    fprintf(fid,'%s\n', T{i});
  end
end
end