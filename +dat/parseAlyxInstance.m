function varargout = parseAlyxInstance(varargin)
%DATA.PARSEALYXINSTANCE Converts input to string for UDP message and back
%   [UDP_string] = DATA.PARSEALYXINSTANCE(AlyxInstance, ref)
%
%   The pattern for 'ref' should be '{date}_{seq#}_{subject}', with two
%   date formats accepted, either 'yyyy-mm-dd' or 'yyyymmdd'.
%   
%   AlyxInstance should be a struct with the following fields, all
%   containing strings: 'baseURL', 'token', 'username'.
%
% Part of Rigbox

% 2017-10 MW created

if nargin > 1 % in [AlyxInstance, ref]
  ai = varargin{1}; % extract AlyxInstance struct
  ref = varargin(2); % extract expRef
  if isstruct(ai) % if there is an AlyxInstance
    c = cellfun(@(fn) ai.(fn), fieldnames(ai), 'UniformOutput', false); % get fieldnames
    varargout = strjoin([c; ref],'\'); % join into single string for UDP
  else % otherwise just output the expRef
    varargout = ref;
  end
else % in [UDP_string]
  C = strsplit(varargin{1},'\'); % split string
  varargout{1} = struct('baseURL', C{1}, 'token', C{2}, 'username', C{3}); % reconstruct AlyxInstance
  varargout{2} = C{4}; % output expRef
end