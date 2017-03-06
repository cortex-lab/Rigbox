function service = remoteProcedureCalls(url, username, password)
%IO.REMOTEPROCEDURECALLS Call remote functions on a server
%   s = IO.REMOTEPROCEDURECALLS(url, [username], [password]) returns an
%   interface for creating function proxies for remote function calls.
%   To create a function for calling a named remote function, call 
%   s.new(fname), e.g:
%
%     rfuns = IO.REMOTEPROCEDURECALLS('http://someservice.com/api')
%     echo = rfuns.new('echo'); % create proxy for remote 'echo' function
%     response = echo('hello'); % response = 'hello'
%
%   Note: This currently implements remote procedure calls using JSONRPC
%   over HTTP. Authorisation logon is currently hacked & specialised.
%
% Part of Burgbox

% 2014-02 CB created

noCredentials = nargin < 3;

cookie = '';
callUrl = sprintf('%s/call/jsonrpc', url);
service.new = @proxyfun;
service.login = @ensureLogin;


%% helper functions
  function f = proxyfun(fname)
    %Creates a proxy function that calls a named remote function
    f = @(varargin) jsonrpchttp(fname, varargin);
  end
    
  function ensureLogin()
    %Checks the cookie-defined session is logged in, if not tries to login
    assert(~noCredentials, 'Remote service requires login but no credentials were given.');
    logonUrl = sprintf('%s/login.json', url);
    [result, success, info]  = jsonhttp(logonUrl, '');
    assert(success, 'Burgbox:remote:failedRequest', 'Failed with ''%s''', result);
    if isempty(result.username) %not logged on
      credentials = http_paramsToString({'username' username 'password' password}, 1);
      [result, success, info]  = jsonhttp(logonUrl, credentials);
      assert(success && ~isempty(result.username), 'Burgbox:remote:invalidCredentials',...
        'Failed to login with given credentials.');
    end
  end

  function result = jsonrpchttp(fname, args)
    %Performs a remote procedure call on a JSONRPC over HTTP service
    %% setup request
    request = struct('method', fname, 'params', {args}, 'id', randi(1e6));
    body = savejson('', request);
    %% send http
    [response, success, info]  = jsonhttp(callUrl, body);
    %% if fail, attempt login and try again
    if info.status.value == 401
      ensureLogin();
      [response, success, info]  = jsonhttp(callUrl, body);
    end
    assert(success, 'Burgbox:remote:failedRequest',...
      'Server request failed with ''%s''', response);
    assert(response.id == request.id, 'Burgbox:remote:failedCall',...
      'Response id did not match that sent');
    assert(isempty(response.error), 'Burgbox:remote:failedCall',...
      'Remote call failed with ''%s''', pick(response.error, 'message', 'def', ''));
    result = response.result;
    result = dateify(dateify(result, 'added'), 'DOB');
  end

  function [response, success, info] = jsonhttp(url, body)
    %Makes a http POST request and parses the response assuming it is JSON
    header = struct('name', {'Cookie'}, 'value', {cookie});
    [response, info] = urlread2(url, 'POST', body, header);
    if isfield(info.firstHeaders, 'Set_Cookie')
      % todo, this is a hack, need to use Path field properly
      newCookie = rmfield(paramsToStruct(info.firstHeaders.Set_Cookie), 'Path');
      cookieName = first(fieldnames(newCookie));
      cookieValue = newCookie.(cookieName);
      cookieField = sprintf('%s=%s', cookieName, cookieValue);
      cookie = cookieField;
    end
    success = info.isGood;
    if success
      response = loadjson(response, 'SimplifyCell', true);
    end
  end

  function s = dateify(s, field)
    %Parses the specified field of the structure (if any) as a date to turn
    %it into a MATLAB datenum
    if isfield(s, field)
      datenums = num2cell(datenum({s.(field)}));
      [s.(field)] = datenums{:};
    end
  end

  function s = paramsToStruct(p)
    %Turns semi-colon separated name=value pairs into a corresponding
    %structure with fields with each name/value.
    pairs = strtrim(strsplit(p, ';'));
    [params, values] = mapToCell(@(pair) destructure(strsplit(pair, '=')), pairs);
    s = cell2struct(values, params, 2);
  end

  function [varargout] = destructure(c)
    %Pulls elements from a single cell input into multiple output
    %arguments.
    varargout = c(1:nargout);
  end

end