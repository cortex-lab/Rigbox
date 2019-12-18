function varargout = pnet(varargin)
% PNET Mock function for pnet
%  Returns preset output for a given input and spys of calls.  Before
%  assigning outputs for a given socket, call function with 'udpsocket' and
%  the port number to map.
%  
%  Usage:
%    socket = pnet('udpsocket', port)
%    pnet(port, 'setoutput', inputArg, output)
%    history = pnet('gethistory')
%    pnet('clearhistory')
%    varargout = pnet(socket, command, varargin)
%
%  Examples:
%    % Assign output for 'gethost' of port 9999
%    socket = pnet('udpsocket', 9999); 
%    pnet('setoutput', 9999, 'gethost', {randi(99,1,4), 88});
%    [ip, port] = pnet(socket, 'gethost'); % Return pre-set output
%   
%    % Assign different output over multiple calls
%    socket = pnet('udpsocket', 9999); 
%    pnet('setoutput', 9999, 'read', sequence({'start', 'stop'}));
%    msg = pnet(socket, 'read') % 'start'
%    msg = pnet(socket, 'read') % 'stop'
%    msg = pnet(socket, 'read') % []
%
% Part of Rigbox tests

% 2019-10-17 MW created

persistent sockets % Structure of outputs to assign
persistent history % Cell array of input arguments
global INTEST

% Initialize sockets structure
if isempty(sockets)
  sockets = struct.empty;
end

% Process input
switch varargin{1}
  case 'udpsocket'
    % Check the INTEST flag to ensure that calling mock was intended
    if isempty(INTEST) || ~INTEST
      warning('Rigbox:tests:pnet:notInTest', ...
        ['Mock called without INTEST flag;', ...
        'If called within test, first set INTEST to true.'])
    end
    % Record socket creation
    socket = length(sockets)+1; % Number in order of udpsocket calls
    sockets(socket).udpsocket = varargin{2}; % Save port in struct
    varargout{1} = socket; % Return socket number
    % Append input to history array
    history = [history, {varargin}];
    
  case 'setoutput'
    % Set output
    port = varargin{2}; % Port number
    % Find index for given port
    idx = [sockets.udpsocket] == port;
    % Save output for given input string
    sockets(idx).(varargin{3}) = varargin{4}; 
    
  case 'clearhistory'
    % Clear the cache of function calls
    history = [];
    
  case 'gethistory'
    % Return the cache of functions calls
    varargout = {history};
    
  otherwise
    % Return output for given socket number
    
    % Check the INTEST flag to ensure that calling mock was intended
    if isempty(INTEST) || ~INTEST
      warning('Rigbox:tests:pnet:notInTest', ...
        ['Mock called without INTEST flag;', ...
        'If called within test, first set INTEST to true.'])
    end
    
    % Append input to history array
    history = [history, {varargin}];
    % Socket number is index for output map struct
    socket = sockets(varargin{1}); 
    
    % Check input previously set
    if isfield(socket, varargin{2})
      output = socket.(varargin{2});
      if isa(output, 'fun.Seq')
        if isempty(output.rest) % No more in sequence
          socket.(varargin{2}) = []; % remove entry
        else % Reassign rest
          socket.(varargin{2}) = output.rest;
        end
        output = output.first;
        sockets(varargin{1}) = socket; % Update output map
      elseif iscell(output)
        % Trim output to number of output args for dealing out
        output = output(1:nargout);
      end
    end
    
    % Assign outputs
    if nargout > 0 % If nessessary
      if iscell(output)
        % Deal contents of each cell out to the output args
        [varargout{1:nargout}] = deal(output{:});
      elseif ~ischar(output) && ~isempty(output)
        % Deal out each element to the output args
        [varargout{1:nargout}] = output(1:nargout);
      else
        % Output value to all output args
        [varargout{1:nargout}] = deal(output);
      end
    end
    
end
