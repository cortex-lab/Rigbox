function [ref, AlyxInstance] = parseAlyxInstance(varargin)
%DATA.PARSEALYXINSTANCE Converts input to string for UDP message and back
%   [UDP_string] = DATA.PARSEALYXINSTANCE(ref, AlyxInstance)
%   [ref, AlyxInstance] = DATA.PARSEALYXINSTANCE(UDP_string)
%
%   The pattern for 'ref' should be '{date}_{seq#}_{subject}', with two
%   date formats accepted, either 'yyyy-mm-dd' or 'yyyymmdd'.
%   
%   AlyxInstance should be a struct with the following fields, all
%   containing strings: 'baseURL', 'token', 'username'.
%
% Part of Rigbox

% 2017-10 MW created

if nargin > 1 % in [ref, AlyxInstance]
  ref = varargin{1}; % extract expRef
  ai = varargin{2}; % extract AlyxInstance struct
  if isstruct(ai) % if there is an AlyxInstance
    c = cellfun(@(fn) ai.(fn), fieldnames(ai), 'UniformOutput', false); % get fieldnames
    ref = strjoin([ref; c],'\'); % join into single string for UDP, otherwise just output the expRef
  end
else % in [UDP_string]
  C = strsplit(varargin{1},'\'); % split string
  ref = C{1}; % output expRef
  if numel(C)>1 % if UDP string included AlyxInstance
    AlyxInstance = struct('baseURL', C{2}, 'token', C{3}, 'username', C{4}); % reconstruct AlyxInstance
  else
    AlyxInstance = []; % if input was just an expRef, output empty AlyxInstance
  end
end