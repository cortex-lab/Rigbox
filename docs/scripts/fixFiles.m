%% Setup
origDir = pwd;
mess = onCleanup(@()cd(origDir));
root = fileparts(which('addRigboxPaths'));
cd(fullfile(root, 'docs', 'html'))

%% Add image to Timeline.html
filename = 'Timeline.html';
subStr = '<img  height="200" hspace="5" src="Fig7_timeline.png" style="float:right" alt="">';
pattern = '<h1>Timeline</h1><!--introduction-->';
pos = 17;

T = readFile(filename);
T = insertMidLine(T, subStr, pattern, pos);
% Write back into file
fid = fopen(filename, 'w');
for i = 1:numel(T)
  if i == numel(T)
    fprintf(fid,'%s', A{i});
    break
  else
    fprintf(fid,'%s\n', A{i});
  end
end

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

function T = insertMidLine(T, subStr, pattern, pos)
if nargin < 4 || isempty(pos), pos = 'after'; end

% Find line
idx = strfind(T, pattern);
assert(sum(cellfun(@numel,idx)) == 1)
ln = ~cellfun('isempty', idx);

% Modify
switch pos
  case 'before'
    T{ln} = insertBefore(T{ln}, pattern, substr);
  case 'after'
    T{ln} = insertAfter(T{ln}, pattern, substr);
  otherwise
    startIdx = cell2mat(idx) + pos;
    T{ln} = [T{ln}(1:startIdx-1) subStr T{ln}(startIdx:end)];
end

end