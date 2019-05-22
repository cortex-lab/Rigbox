classdef Parameters < handle
  %EXP.PARAMETERS A store & methods for managing experiment parameters
  %   TODO. See also EUI.PARAMEDITOR.
  %
  % Part of Rigbox

  % 2012-11 CB created  
  
  properties (Dependent)
    Struct %a struct representation of parameters and their info
  end
  
  properties (Dependent, SetAccess = private)
    Names %list of all parameter names
    TrialSpecificNames %list of all trial conditional parameters
    GlobalNames %list of all global parameters (i.e. not conditional)
  end
  
  properties (Access = private)
    pStruct = struct
    pNames = {}
    IsTrialSpecific = struct
  end
  
  methods
    function obj = Parameters(paramsStruct)
      if nargin > 0
        obj.Struct = paramsStruct;
      end
    end

    function s = get.Struct(obj)
      s = obj.pStruct;
    end
    
    function n = get.Names(obj)
      n = obj.pNames;
    end
    
    function set(obj, name, value, description, units)
      
%       if size(value, 2) > 1
%         % Attempting to set a conditional parameter so it should match the 
%         nConditions = numTrialConditions(obj);
%         assert(nConditions == 0 || nConditions == size(value, 2),...
%           'Wrong number of trials for conditional parameter. Should be %d, was %d\n',...
%                   nConditions, size(value, 2));
%       end
      
      newField = ~isfield(obj.Struct, name);
      obj.Struct.(name) = value;
      % add param to list of names if it's a new field
      if newField
        obj.pNames = [obj.pNames; name];
      end
      if nargin > 4 && ~isempty(units)
        obj.Struct.([name 'Units']) = units;
      elseif isfield(obj.Struct, [name 'Units'])
        % if no units specified but a units field exists, remove it
        obj.pStruct = rmfield(obj.pStruct, [name 'Units']);
      end
      if nargin < 4
        description = [];
      end
      obj.Struct.([name 'Description']) = description;
    end
    
    function set.Struct(obj, s)
      obj.pStruct = s;
      obj.pNames = obj.namesFromFields;
      n = numel(obj.pNames);
      obj.IsTrialSpecific = struct;
      isTrialSpecificDefault = @(n) ...
        ~strcmp(n, 'randomiseConditions') &&... % randomiseConditions always global
        ((ischar(obj.pStruct.(n)) &&  size(obj.pStruct.(n), 1) > 1) ||... % Number of rows > 1 for chars
        (~ischar(obj.pStruct.(n)) &&  size(obj.pStruct.(n), 2) > 1)); % Number of columns > 1 for all others
      for i = 1:n
        name = obj.pNames{i};
        obj.IsTrialSpecific.(name) = isTrialSpecificDefault(name);
      end
    end
    
    function str = title(obj, name)
      % TITLE Turns param struct field name into title for UI label
      %  Input name must be a fieldname in Struct or cell array thereof.
      %  The returned str is the fieldname with a space inserted between
      %  upper case letters, and the first letter capitalized.  If units
      %  field is present, the unit is added to the string in brackets
      %
      %  Example:
      %    obj.title('numRepeats') % returns 'Num repeats'
      %    obj.title({'numRepeats', 'rewardVolume'}) 
      %    % returns {'Num repeats', 'Reward volume (ul)'}
      % See also INDIVTITLE
      if iscell(name)
        str = mapToCell(@obj.indivTitle, name);
      else
        str = obj.indivTitle(name);
      end
    end
    
    function str = description(obj, name)
      if iscell(name)
        str = mapToCell(@obj.indivDescrip, name);
      else
        str = obj.indivDescrip(name);
      end
    end
    
    function removeConditions(obj, indices)
      names = obj.TrialSpecificNames;
      for i = 1:numel(names)
        obj.Struct.(names{i})(:,indices) = [];
      end
    end
    
    function n = get.TrialSpecificNames(obj)
      n = obj.Names(obj.isTrialSpecific(obj.Names));
    end
    
    function n = get.GlobalNames(obj)
      n = obj.Names(~obj.isTrialSpecific(obj.Names));
    end
    
    function b = isTrialSpecific(obj, name)
      isSpecific = @(n) obj.IsTrialSpecific.(n);
      if iscell(name)
        b = cellfun(@(n) isSpecific(n), name);
      else
        b = isSpecific(name);
      end
    end
    
    function makeTrialSpecific(obj, name)
      assert(~obj.isTrialSpecific(name), '''%s'' is already trial-specific', name);
      currValue = obj.Struct.(name); % Current value of parameter
      n = numTrialConditions(obj); % Number of trial conditions (table rows)
      if n < 1; n = 2; end % If there are none, let's add two conditions
      % Repeat value accross all trial conditions
      if isnumeric(currValue) || islogical(currValue) || isstring(currValue)
        newValue = repmat(currValue, 1, n);
      else
        newValue = repmat({currValue}, 1, n);
      end
      % update the struct directly
      obj.pStruct.(name) = newValue;
      % update our record of whether the parameter is trial-specific
      obj.IsTrialSpecific.(name) = true;
    end
    
    function makeGlobal(obj, name, newValue)
      % takes the first condition value and applies as global value
      assert(obj.isTrialSpecific(name), '''%s'' is already global', name);
      if nargin < 3
        %by default, use the first condition value for the new global value
        currValue = obj.Struct.(name);
        if iscell(currValue)
          newValue = currValue{:,1};
        else
          newValue = currValue(:,1);
        end
      end
      obj.Struct.(name) = newValue;
      % update our record of whether the parameter is trial-specific
      obj.IsTrialSpecific.(name) = false;
    end
    
    function n = numTrialConditions(obj)
      trialParamNames = obj.TrialSpecificNames;
      trialParamLen = cellfun(@(n) size(obj.Struct.(n), 2), trialParamNames);
      if ~isempty(trialParamLen)
        n = trialParamLen(1);
        assert(all(trialParamLen == n),...
        'Not all trial-specific parameters are the same length (ncols).');
      else
        n = 0;
      end
    end
    
    function [globalParams, trialParams] = assortForExperiment(obj)
      % Divide into global and trial-specific parameter structures

      %% group trial-specific parameters into a struct with length of parameters
      % the second dimension (number of columns) specifies parameters for
      % different trials
      trialParamNames = obj.TrialSpecificNames;
      obj.numTrialConditions(); % this asserts that all trial params have same len
      trialParamValues = mapToCell(...
        @(n) iff(~iscell(obj.Struct.(n)), @() num2cell(obj.Struct.(n), 1), obj.Struct.(n)),...
        trialParamNames);
      
      %% group global parameters
      globalParamNames = obj.GlobalNames;
      globalParamValues = cellfun(@(n) obj.Struct.(n), globalParamNames,...
        'UniformOutput', false);
      % concatenate trial parameter
      trialParamValues = cat(1, trialParamValues{:});
      if isempty(trialParamValues) % Removed MW 30.01.19
        trialParamValues = {};
      end
      trialParams = cell2struct(trialParamValues, trialParamNames, 1)';
      globalParams = cell2struct(globalParamValues, globalParamNames, 1);
    end
    
    function [cs, globalParams, trialParams] = toConditionServer(obj, randomOrder)
      if nargin < 2
        randomOrder = pick(obj.Struct, 'randomiseConditions', 'def', true);
      end
      [globalParams, trialParams] = obj.assortForExperiment;
      % repeat conditions numRepeats times
      if obj.isTrialSpecific('numRepeats')
        % There is a specific number of repeats for each trial condition.
        % We also remove the numRepeats parameter from the trialParams
        % since the trial elements are literally repeated now
        nreps = [trialParams.numRepeats];
        trialParams = rmfield(trialParams, 'numRepeats');
        trialParams = repelems(trialParams, nreps);
      else
        % There is a global number of repeats
        % We also remove the numRepeats parameter from the globalParams
        % since the trial elements are literally repeated now
        nreps = globalParams.numRepeats;
        trialParams = iff(isempty(trialParams), ...
          @()repelems(struct, nreps),...
          @()repmat(trialParams, 1, nreps));
        globalParams = rmfield(globalParams, 'numRepeats');
      end
      if randomOrder
        trialParams = trialParams(randperm(numel(trialParams)));
      end
      cs = exp.PresetConditionServer(globalParams, trialParams);
    end

  end
  
  methods (Access = protected)
    function str = indivTitle(obj, name)
      assert(isfield(obj.Struct, name));
      words = lower(regexprep(name, '([a-z])([A-Z])', '$1 $2'));
      words(1) = upper(words(1));
      str = words;
      % add the units details, if any
      unitField = [name 'Units'];
      if isfield(obj.Struct, unitField) && ~isempty(obj.Struct.(unitField))
        units = obj.Struct.(unitField);
        if ~strcmp(units, {'normalised', 'logical', '#'})
          str = sprintf('%s (%s)', str, units);
        end
      end
    end
    
    function str = indivDescrip(obj, name)
      assert(isfield(obj.Struct, name));
      % add the units details, if any
      descripName = [name 'Description'];
      if isfield(obj.Struct, descripName)
        str = obj.Struct.(descripName);
      else
        str = '';
      end
    end
    
    function l = namesFromFields(obj)
      fields = fieldnames(obj.pStruct);
      isinfo = cellfun(@(f) strEndsWith(f, {'Description', 'Units'}), fields);
      l = fields(~isinfo & ~strcmp(fields, 'type'));
    end
  end
    
end

