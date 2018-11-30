function [ref, AlyxInstance] = parseAlyxInstance(varargin)
%DAT.PARSEALYXINSTANCE Converts input to string for UDP message and back
%   [UDP_string] = DATA.PARSEALYXINSTANCE(ref, AlyxInstance)
%   [ref, AlyxInstance] = DATA.PARSEALYXINSTANCE(UDP_string)
%
%   The pattern for 'ref' should be '{date}_{seq#}_{subject}', with two
%   date formats accepted, either 'yyyy-mm-dd' or 'yyyymmdd'.
%   
%   AlyxInstance should be a struct with the following fields, all
%   containing strings: 'baseURL', 'token', 'username'[, 'subsessionURL'].
%
% Part of Rigbox

% 2017-10 MW created

if nargin > 1 % in [ref, AlyxInstance]
  ref = varargin{1}; % extract expRef
  ai = varargin{2}; % extract AlyxInstance struct
  if isstruct(ai) % if there is an AlyxInstance
    ai = orderfields(ai); % alphabetize fields
    % remove water remaining_water field
    if isfield(ai, 'remaining_water')
      ai = rmfield(ai, 'remaining_water');
    end
    fname = fieldnames(ai); % get fieldnames
    emp = structfun(@isempty, ai); % find empty fields
    if any(emp); ai = rmfield(ai, fname(emp)); end % remove the empty fields
    c = cellfun(@(fn) ai.(fn), fieldnames(ai), 'UniformOutput', false); % get fieldnames
    ref = strjoin([ref; c],'\'); % join into single string for UDP, otherwise just output the expRef
  end
else % in [UDP_string]
  C = strsplit(varargin{1},'\'); % split string
  ref = C{1}; % output expRef
  if numel(C)>4 % if UDP string included AlyxInstance
    AlyxInstance = struct('baseURL', C{2}, 'subsessionURL', C{3},...
        'token', C{4}, 'username', C{5}); % reconstruct AlyxInstance
  elseif numel(C)>1 % if AlyxInstance has no subsession set
    AlyxInstance = struct('baseURL', C{2}, 'token', C{3}, 'username', C{4}); % reconstruct AlyxInstance
  else
    AlyxInstance = []; % if input was just an expRef, output empty AlyxInstance
  end
end