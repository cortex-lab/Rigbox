function fixFiles(filenames)
% This function will automatically publish all Rigbox documentation scripts
% to html, the output folder being docs/html.  Scripts in the following
% directories are published:
%
% docs\scripts
% alyx-matlab\docs
% 
% Currently the Signals docs are kept in the main repo however this may
% change in the future.  This file should be run whenever a change is made
% to one of the scripts.
%
% Inputs:
%   filenames can be list of script names (e.g. 'Parameters.m'), 'all'
%   (default) or 'changed'.  If 'changed' is present, all scripts
%   considered untracked/modified by Git are published.
%
% Examples:
%   fixFiles() % Re-publish all scripts
%   fixFiles('all') 
%   fixFiles('changed') % Publish all modified scripts
%   fixFiles({'index.m, 'changed'}) % Publish index.m and all changed
%   fixFiles(["index.m", "Parameters.m"]) % Publish two scripts
%
% See also...
%
% https://uk.mathworks.com/help/matlab/matlab_prog/marking-up-matlab-comments-for-publishing.html
% https://uk.mathworks.com/help/matlab/matlab_prog/specifying-output-preferences-for-publishing.html
%
% 2020-02-18 MW created

%% Setup 
origDir = pwd;
mess = onCleanup(@()cd(origDir));

% Documentation locations
rigbox = getOr(dat.paths, 'rigbox');
outputDir = fullfile(rigbox, 'docs', 'html');
scriptPaths = fullfile(rigbox, {'docs/scripts', 'alyx-matlab/docs'});
exclude = ["fixFiles.m", "ReadMe.md"]; % Files to exclude
% Files whose code should be evaluated
evalOn = ["using_test_gui.m", "SignalsPrimer.m"];

%% Files to publish
% Find all doc files
docFiles = cellflat(mapToCell(@(p) file.list(p, 'files'), scriptPaths));
docFiles = setdiff(docFiles, exclude); % Remove excluded

% Apply input restrictions
if nargin > 0 && ~any(strcmp(filenames, 'all'))
  filenames = convertStringsToChars(filenames);
  if any(strcmp(filenames, 'changed'))
    changedFiles = cellflat(changedViaGit(scriptPaths));
    filenames = iff(iscell(filenames), ...
      @() vertcat(filenames(:), changedFiles), changedFiles);
  end
  docFiles = intersect(docFiles, filenames);
end

%% Publish files
options = {...
  'format', 'html', ....
  'outputDir', outputDir};

% Publish each file
for f = docFiles'
  fprintf('Publishing %s\n', f)
  cd(first(scriptPaths(file.exists(fullfile(scriptPaths, f)))))
  publish(f, 'evalCode', endsWith(f, evalOn), options{:});
end

%% Fix up our files
toFix = @(f) ismember(strrep(f,'html','m'), docFiles);
cd(outputDir)

%% Timeline.html
% Add image to Timeline.html
filename = 'Timeline.html';
if toFix(filename)
  subStr = '<img  height="200" hspace="5" src="Fig7_timeline.png" style="float:right" alt="">';
  pattern = '<h1>Timeline</h1><!--introduction-->';
  pos = 17;
  
  T = readFile(filename);
  T = insert(T, subStr, pattern, pos);
  writeFile(filename, T)
end

%% using_test_gui.html
% Colour error text
filename = 'using_test_gui';
if toFix(filename)
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
end

%% paper_examples.html
% Add width attribute to images
filename = 'paper_examples.html';
if toFix(filename)
  pattern = strcat('src="./images/Fig', {'3','6'});
  subStr = 'width="500" ';
  
  T = readFile(filename);
  for s = pattern
    T = insert(T, subStr, s, 'before', 1);
  end
  writeFile(filename, T)
end

%% install.html
% Add notes as popups
filename = 'install.html';
if toFix(filename)
T = readFile(filename);
iBody = contains(T, '<!--introduction-->');
body = T{iBody};
sections = split(string(body), '<h2');
notesSection = sections(contains(sections, '>Notes</h2>'));
notes = extractBetween(notesSection, '<li>', '</li>');

tooltipCSS = [
".tooltip {"
"  position: relative;"
"  display: inline-block;"
"  border-bottom: 1px dotted black;"
"}"

".tooltip .tooltiptext {"
"  visibility: hidden;"
"  width: 300px;"
"  background-color: #555;"
"  color: #fff;"
"  text-align: center;"
"  border-radius: 6px;"
"  padding: 5px;"
"  position: absolute;"
"  z-index: 1;"
"  bottom: 125%;"
"  left: 50%;"
"  margin-left: -60px;"
"  opacity: 0;"
"  transition: opacity 0.3s;"
"}"

".tooltip .tooltiptext::after {"
"  content: "";"
"  position: absolute;"
"  top: 100%;"
"  left: 50%;"
"  margin-left: -5px;"
"  border-width: 5px;"
"  border-style: solid;"
"  border-color: #555 transparent transparent transparent;"
"}"

".tooltip:hover .tooltiptext {"
"  visibility: visible;"
"  opacity: 1;"
"}"

".tooltip:focus .tooltiptext {"
"  visibility: visible;"
"  opacity: 1;"
"}"
];

% Find line after final CSS style def
Ti = circshift(startsWith(T, 'table td '),1);
assert(isempty(T{Ti}))
T{Ti} = char(join(tooltipCSS, [newline newline])); % Insert CSS for tooltips

% Add tooltip span
[startIdx, endIdx] = regexp(body, 'See note \d');
newBody = cell(2, length(startIdx)+1);
newBody(1,:) = strsplit(body, 'See note \d+', 'DelimiterType', 'RegularExpression');
for i = 1:length(startIdx)
  bit = startIdx(i):endIdx(i); % 'See note x'
  n = str2double(regexp(body(bit), '(\d+)', 'tokens', 'once')); % note number
  preStr = ['<span class="tooltip" tabindex="' num2str(i) '">'];
  postStr = ['<span class="tooltiptext">' char(notes(n)) '</span></span>'];
  newBody{2,i} = [preStr body(bit) postStr]; % Wrap note as tooltip
end
% Assign altered text
T{iBody} = horzcat(newBody{:});

% Fix '|...|' parse fail
T = cellfun(@(s) strrep(s, '''|', '''<tt>'), T, 'uni', 0);
T = cellfun(@(s) strrep(s, '|''', '</tt>'''), T, 'uni', 0);

writeFile(filename, T)
end

%% paths_conflicts.html
% Remove <User> anchor
filename = 'paths_conflicts.html';
if toFix(filename)
  pattern = '<a href="User">User</a>';
  subStr = '&lt;User&gt;';
  T = readFile(filename);
  T = insert(T, subStr, pattern, 'replace', 1);
  writeFile(filename, T)
end

%% using_signals.html
% Replace Greek symbols with html unicode
filename = 'using_signals.html';
if toFix(filename)
  T = readFile(filename);
  pattern = [
    "exp((-x'.^2./2*?(1)^2 + -y'.^2./2*?(2)^2))";
    "cos((6.2832*(x.*cos((?(2) - 1.5708)) + y.*sin((?(2) - 1.5708)))./? + ?))";
    "exp((-x'.^2./2*?(1)^2 + -y'.^2./2*?(2)^2)).*cos((6.2832*(x.*cos((?(2) - 1.5708)) + y.*sin((?(2) - 1.5708)))./? + ?))"];
  replace = [
    "exp((-x'.^2./2*&theta;(1)^2 + -y'.^2./2*&theta;(2)^2))";
    "cos((6.2832*(x.*cos((&lambda;(2) - 1.5708)) + y.*sin((&lambda;(2) - 1.5708)))./&sigma; + &phi;))";
    "exp((-x'.^2./2*&theta;(1)^2 + -y'.^2./2*&theta;(2)^2)).*cos((6.2832*(x.*cos((&lambda;(2) - 1.5708)) + y.*sin((&lambda;(2) - 1.5708)))./&sigma; + &phi;))"];
  i = find(contains(T, '<pre>Gaussian'),1);
  i = i:i+numel(pattern)-1;
  [T(i)] = mapToCell(@strrep, T(i)', pattern, replace);
  writeFile(filename, T)
end

end
%% Helpers
function T = readFile(filename)
% READFILE Read text from file
%
%  Input:
%    filename (char): full file path of html doc to read
%
%  Output:
%    T (cellstr): cell array of text, where each element is a single line
%

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
%   Note: all occurances on a single line are replaced, regardless of `n`
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
  case 'replace'
    T{ln(n)} = strrep(T{ln(n)}, pattern, subStr);
  otherwise
    startIdx = cell2mat(idx) + pos;
    T{ln(n)} = [T{ln(n)}(1:startIdx-1) subStr T{ln(n)}(startIdx:end)];
end

end

function writeFile(filename, T)
% WRITEFILE Write back into file
%
%  Inputs:
%    filename (char): full file path of html doc to write
%    T (cellstr): cell array of text to write to file
%
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

function changedFiles = changedViaGit(dirPaths)
% CHANGEDVIAGIT List changed repo files
%  List the files in dirPaths that Git says have been modified.  Untracked
%  files are also returned.
%
%  Inputs:
%    dirPaths (cellstr|char|string): the Git directory paths to check
%
%  Outputs:
%    changedFiles (cellstr): cell array of file names that Git says are
%      different to the HEAD.  Note that the full paths aren't returned,
%      only filename.ext.
%

% Return all files that Git says have changed
if iscell(dirPaths) || (isstring(dirPaths) && ~isStringScalar(dirPaths))
  % Recurse on directories
  changedFiles = mapToCell(@changedViaGit, dirPaths);
else
  [exitCode, cmdOut] = git.runCmd('status', 'dir', dirPaths, 'echo', false);
  assert(exitCode == 0)
  cmdOut = strsplit(cmdOut{:}, newline);
  changedFiles = regexp(cmdOut, '(?<=^\t.*)\w*.m$', 'match');
end
changedFiles = rmEmpty(cellflat(changedFiles));
end