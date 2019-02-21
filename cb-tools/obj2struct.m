function s = obj2struct(obj)
% OBJ2STRUCT Converts input object into a struct
%   Returns the input but with any non-fundamental object converted to a
%   structure.  If the input does not contain an object, the resulting
%   output will remain unchanged.  
%
%   NB: Does not convert National Instruments object or objects within
%   non-scalar structures.  Cannot currently deal with Java, COM or certain
%   graphics objects.  Function handles are converted to strings.
%
% 2018-05-03 MW created

if isobject(obj)
  if length(obj) > 1
    % If dealing with heterogeneous array of objects, recurse through array
    s = arrayfun(@obj2struct, obj, 'uni', 0);
  elseif isa(obj, 'containers.Map')
    % Convert to scalar struct
    keySet = keys(obj);
    valueSet = values(obj);
    for j = 1:length(keySet)
      m.(keySet{j}) = valueSet{j};
    end
    s = obj2struct(m);
  else % Normal object
    s.ClassContructor = class(obj); % Supply class name for loading object
    names = fieldnames(obj); % Get list of public properties
    for i = 1:length(names)
      if isempty(obj) % Object and therefore all properties are empty
        s.(names{i}) = [];
      elseif isobject(obj.(names{i})) % Property contains an object
        if startsWith(class(obj.(names{i})),'daq.ni.')
          % Do not attempt to save ni daq sessions of channels
          s.(names{i}) = [];
        else % Recurse
          s.(names{i}) = obj2struct(obj.(names{i}));
        end
      elseif iscell(obj.(names{i}))
        % If property contains cell array, run through each element in case
        % any contain an object
        s.(names{i}) = cellfun(@obj2struct, obj.(names{i}), 'uni', 0);
      elseif isstruct(obj.(names{i})) && isscalar(obj.(names{i}))
        % If property contains struct, run through each field in case any
        % contain an object
        s.(names{i}) = structfun(@obj2struct, obj.(names{i}), 'uni', 0);
      elseif isa(obj.(names{i}), 'function_handle')
        % Convert function to string
        s.(names{i}) = func2str(obj.(names{i}));
      elseif isa(obj.(names{i}), 'containers.Map')
        % Convert to scalar struct
        keySet = keys(obj.(names{i}));
        valueSet = values(obj.(names{i}));
        for j = 1:length(keySet)
          m.(keySet{j}) = valueSet{j};
        end
        s.(names{i}) = obj2struct(m);
      else % Property is fundamental object
        s.(names{i}) = obj.(names{i});
      end
    end
  end
elseif iscell(obj)
  % If dealing with cell array, recurse through elements
  s = cellfun(@obj2struct, obj, 'uni', 0);
elseif isstruct(obj) && isscalar(obj)
  % If dealing with structure, recurse through fields
  s = structfun(@obj2struct, obj, 'uni', 0);
elseif isa(obj, 'function_handle')
  % Convert function to string
  s = func2str(obj);
else % Fundamental object, return unchanged
  s = obj;
end
end