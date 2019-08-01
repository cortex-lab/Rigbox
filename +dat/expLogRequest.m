function [result, info] = expLogRequest(instruction, varargin)
%DAT.EXPLOGREQUEST Submits a request to the experiment log
%   Detailed explanation goes here

global RiggingCache

if nargin < 2
  args = struct;
elseif nargin == 2 && isstruct(varargin{1})
else
  args = varargin2struct(varargin{:});
end

experimentLogURL = pick(dat.paths, 'experimentLogURL');

if ~isfield(RiggingCache, 'expLogCookies')
  % no cookie, so we can't be logged in
  ensureLogin()
end

%% now do the main request
body = http_paramsToString(struct2params(args, true), 1);
url = sprintf('%s/call/json/%s', experimentLogURL, instruction);
[result, success, info]  = jsonhttp(url, body);
if info.status.value == 401
  % we weren't logged in, try to, then try again
  ensureLogin();
  [result, success, info]  = jsonhttp(url, body);
end
assert(success, 'Server request failed with ''%s''', result);

%% helper functions
  function ensureLogin()
    logonUrl = sprintf('%s/login.json', experimentLogURL);
    [result, success, info]  = jsonhttp(logonUrl, '');
    assert(success);
    if isempty(result.username)
      fprintf('Attempting to login...');
      credentials.username = 'test';
      credentials.password = 'test';
      credentials = http_paramsToString(struct2params(credentials, false), 1);
      [result, success, info]  = jsonhttp(logonUrl, credentials);
      assert(success && ~isempty(result.username));
      fprintf('logged in as ''%s''\n', result.username);
    end
  end

  function [result, success, info] = jsonhttp(url, body)
    if ~isfield(RiggingCache, 'expLogCookies')
      RiggingCache.expLogCookies = '';
    elseif ~isempty(RiggingCache.expLogCookies)
%       disp('Using cached cookie');
    end
    header = struct('name', 'Cookie', 'value', RiggingCache.expLogCookies);
    
    [result, info] = urlread2(url, 'POST', body, header);
    if isfield(info.firstHeaders, 'Set_Cookie')
      cookie = rmfield(paramsToStruct(info.firstHeaders.Set_Cookie), 'Path');
      cookieName = first(fieldnames(cookie));
      cookieValue = cookie.(cookieName);
      cookieField = sprintf('%s=%s', cookieName, cookieValue);
      if ~isequal(cookieField, RiggingCache.expLogCookies)
%         disp('Recieved new cookie');
        RiggingCache.expLogCookies = cookieField;
      end
    end
    success = info.isGood;
    if success
      result = loadjson(result, 'SimplifyCell', true);
      result = dateify(dateify(result, 'added'), 'DOB');
    end
  end

  function p = struct2params(s, json)
    fields = fieldnames(s);
    p = cell(1, 2*numel(fields));
    vals = struct2cell(s);
    if json
      % now json encode each value
      vals = mapToCell(@(v) savejson('', v), vals);
    end
    p(1:2:end) = fields;
    p(2:2:end) = vals;
  end

  function s = dateify(s, field)
    if isfield(s, field)
      datenums = num2cell(datenum({s.(field)}));
      [s.(field)] = datenums{:};
    end
  end

  function s = paramsToStruct(p)
    pairs = strtrim(strsplit(p, ';'));
    [params, values] = mapToCell(@(pair) destructure(strsplit(pair, '=')), pairs);
    s = cell2struct(values, params, 2);
  end

  function [varargout] = destructure(c)
    varargout = c(1:nargout);
  end

end