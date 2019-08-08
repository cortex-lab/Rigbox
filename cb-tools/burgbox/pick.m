function v = pick(from, key, varargin)
%PICK Retrieves indexed elements from a data structure
%   Encapsulates different MATLAB syntax for retreival from data structures
%
%   * For arrays, numeric keys mean indices:
%   v = PICK(arr, idx) returns values at the specified indices in 'arr', e.g:
%         PICK(2:2:10, [1 2 4]) % like arg1([1 2 4]) returns [2,4,8]
%
%   * For structs & class objects and string key(s), fetch value of the
%   struct's field or object's property:
%   v = PICK(s, f) returns the value of field 'f' in structure 's' (or
%   property 'f' in object 's'). If 's' is a structure or object array,
%   return an array of each elements field or property value. e.g:
%           s.a = 1; s.b = 3;
%           PICK(s, 'a')       % like s.a, returns 1
%           PICK(s, {'a' 'b'}) % selecting two fields, returns {[1] [2]}
%           s(2).a = 2; s(2).b = 4;
%           PICK(s, 'a')       % like [s.a], returns [1 2]
%           PICK(s, {'a' 'b'}) % selecting two fields, returns {[1 2] [3 4]}
%
%   * For containers.Map object's with a valid key type, get keyed value:
%   v = PICK(map, key) returns the value in 'map' of the specified 'key'
%   If key is an array of keys (with valid types for that map), return a 
%   cell array with each element retreived by the corresponding key. e.g:
%           m = containers.Map;
%           m('number') = 1
%           m('word') = 'apple'
%           PICK(m, 'word')            % like m('word'), returns 'apple'
%           PICK(m, {'word' 'number'}) % returns {'apple' [1]}
%
%   When picking from structs, objects and maps, you can
%   also specify a default value to be used when the specified key does not
%   exist in your data structure: pass in a pair of parameters, 'def'
%   followed by the default value (e.g. see (2) below).
%
%   Finally, you can pass in the option 'cell', to return a cell array
%   instead of a standard array (or scalar). This is useful e.g. if you are
%   picking from fields containing strings in a struct array:
%           w(1).a = 'hello'; w(2).a = 'goodbye';
%           PICK(w, 'a', 'cell') % like {w.a}, returns {'hello' 'goodbye'}
%
%   Why is all this useful? A few reasons:
%   1) If a function returns an array or a structure, MATLAB does not allow
%   you to use standard syntax to index it from the function call:
%     e.g. you might only want the third element from some computation:
%           fft(x)(2)           % does not work, must do:
%           y = fft(x);
%           y(2)                % ewww, a whole extra line! Try:
%           y = PICK(fft(x), 2) % tidier, no?
%   2) Defaults are super useful & succint. e.g. default values for settings:
%     e.g.  settings = load('settings');
%           % now normally I have to say:
%           if ~isfield(settings, 'dataPath')
%             mypath = 'default/path'; % default value
%           else
%             mypath = settings.dataPath;
%           end % pretty tedious, when we could just do:
%           mypath = PICK(settings, 'dataPath, 'def', 'default/path') % yay!
%   3) Make code flexible without repetition. If you want code that can
%   e.g. retrieve a bunch of data from some structure and process it, you
%   might want it to be able to handle retrieving from a matrix or a cell
%   array, but without all the 'if iscell(blah) blah{i} else blah(i)'. With
%   PICK you can handle many different data structures with one function call.
%
% Part of Burgbox

% 2013-09 CB created

if iscell(key)
  v = mapToCell(@(k) pick(from, k, varargin{:}), key);
else
  stringArgs = cellfun(@ischar, varargin); %string option params
  [withDefault, default] = namedArg(varargin, 'def');
  cellOut = any(strcmpi(varargin(stringArgs), 'cell'));
  if isa(from, 'containers.Map')
    %% Handle MATLAB maps with key meaning key!
    v = iff(withDefault && ~from.isKey(key), default, @() from(key));
  elseif ischar(key)
    %% Handle structures and class objects with key meaning field/property
    if ~iscell(from)
      if cellOut
        if ~withDefault
          v = reshape({from.(key)}, size(from));
        elseif withDefault && (isfield(from, key) || isAProp(from, key))
          % create cell array, then replace empties with default value
          v = reshape({from.(key)}, size(from));
          [v{emptyElems(v)}] = deal(default);
        else
          % default but field or property does not exist
          v = repmat({default}, size(from));
        end
      else
        if ~withDefault
          if numel(from) == 1
            v = from.(key);
          else
            v = reshape([from.(key)], size(from));
          end
        else
          % if using default but with default array output, first get cell
          % output with defaults applied, then convert back to a MATLAB array:
          v = cell2mat(pick(from, key, varargin{:}, 'cell'));
        end
      end
    else
      if cellOut
        % The following line was changed 2019-08
%         v = mapToCell(@(e) pick(pick(e, key, varargin{:}), 1), from);
        v = mapToCell(@(e) pick(e, key, varargin{:}), from);
      else
        v = cellfun(@(e) pick(e, key, varargin{:}), from);
      end
    end
  elseif iscell(from)
    %% Handle cell arrays with key meaning indices
    if cellOut
      v = from(key);
    else
      v = [from{key}];
    end
  else
    v = from(key);
    if cellOut
      v = num2cell(v);
    end
  end
end

  function b = isAProp(v, name)
    if isstruct(v) || isempty(v)
      b = false;
    else
      b = isprop(v, name);
    end
  end


end

