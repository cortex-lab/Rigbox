classdef Parameters < handle
  % EXP.PARAMETERS A store & methods for managing experiment parameters
  %   A class for managing a parameter structure used by the exp.Experiment
  %   base class.  Methods validate and sort the parameters making it
  %   convenient to add, view, modify and assort your parameters.
  %   
  %   Examples:
  %     P = exp.Parameters(); % A new parameter set
  %     % Add a new global parameter
  %     P.set('onsetToneFreq', 11000, 'Hz', 'Frequency of the onset tone')
  %     % Add a conditional parameter
  %     P.set('onsetToneAmplitude', 0:.1:1, 'normalized', ...
  %       'Relative amplitude of the onset tone')
  %     % Define the total number of trials
  %     P.set('numRepeats', 10, '#', 'No. of repeats of each condition')
  %     cs = P.toConditionServer() % Assort and randomize for experiment
  %
  % See also EUI.PARAMEDITOR
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
      % SET Set a named parameter value
      %  SET(OBJ, NAME, VALUE[, DESCRIPTION, UNITS]) sets the value of a
      %  parameter.  If the parameter doesn't already exist, a new one is
      %  added.  
      %
      %  Inputs:
      %    name (char): The parameter name to set
      %    value (*): The value of the parameter.  The number of columns must
      %      be 1 or equal to numTrialConditions (or for chars the number
      %      of rows)
      %    description (char): Optional.  A description of the parameter
      %    units (char): Optional.  The parameter units
      %
      %  Example 1: Add a new parameter called targetAltitude
      %    description = 'Visual angle of target centre above horizon';
      %    P.set('targetAltitude', 90, description,  '°')
      %
      %  Example 2: Set the values for a trial condition
      %    values = randsample(0:45:135, P.numTrialConditions, true);
      %    P.set('orientation', values)
      %
      % See also DESCRIPTION, NUMTRIALCONDITIONS
      
      % Check value dimentions are valid
      dim = iff(ischar(value), 1, 2); % rows are trial conditions for chars
      if size(value, dim) > 1
        % Attempting to set a conditional parameter so it should match the
        % number of trial conditions
        nConditions = numTrialConditions(obj);
        assert(nConditions == 0 || nConditions == size(value, dim),...
          'Rigbox:exp:Parameters:numTrialConditionsMismatch', ...
          'Wrong number of trials for conditional parameter. Should be %d, was %d\n',...
           nConditions, size(value, dim));
      end
      
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
      %
      % See also DESCRIPTION
      if iscell(name) % A list of names to recurse over
        str = mapToCell(@obj.title, name);
      else
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
    end
    
    function str = description(obj, name)
      % DESCRIPTION Returns the description for a given parameter
      %  Input name must be a fieldname in Struct or cell array thereof.
      %  The returned str is the description of that parameter 
      %
      %  Example:
      %    P = exp.Parameters(exp.choiceWorldParams)
      %    str = description(P, 'rewardVolume') % returns description
      %
      % See also DESCRIPTION, TITLE, SET
      if iscell(name) % A list of names to recurse over
        str = mapToCell(@obj.description, name);
      else % A single name
        assert(isfield(obj.Struct, name), 'Parameter ''%s'' not found', name);
        % add the units details, if any
        descripName = [name 'Description'];
        str = getOr(obj.Struct, descripName, '');
      end
    end
    
    function removeConditions(obj, indices)
      % REMOVECONDITIONS Removes values of trial conditions at indicies
      %  The values are the given indices are removes from all trial
      %  conditional parameters.
      %
      %  Example:
      %    % Remove first and seventh trial conditions
      %    P = exp.Parameters(exp.choiceWorldParams)
      %    removeConditions(P, [1,7])
      %
      % See also ISTRIALCONDITIONAL
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
      % ISTRIALSPECIFIC Checks whether parameter(s) is trial specific
      %  Returns true if parameter name is trial specific.  Parameters are
      %  trial specific if they have more than one column, unless they are
      %  char arrays, in which case they are trial specific if they have
      %  more than one row.  
      %
      %  Input:
      %   name (char|cellstr): parameter name(s) to check
      %
      %  Output:
      %   b (logical): logical array the length of name, true if parameter
      %     is trial specific
      %
      %  Example:
      %   P = exp.Parameters(exp.choiceWorldParams);
      %   TF = isTrialSpecific(P, {'visCueContrast', 'cueSigma'})
      %
      % See also MAKETRIALSPECIFIC

      isSpecific = @(n) obj.IsTrialSpecific.(n);
      if iscell(name)
        b = cellfun(@(n) isSpecific(n), name);
      else
        b = isSpecific(name);
      end
    end
    
    function makeTrialSpecific(obj, name)
      % MAKETRIALSPECIFIC Makes parameter trial conditional
      %  If the named parameter is already trial specific (number of
      %  columns > 1) an exception is thrown, otherwise the parameter value
      %  is replicated accross all trial conditions.  If the parameter is a
      %  is a char, it is converted to a cellstr first.
      %
      %  Example:
      %    % Remove first and seventh trial conditions
      %    P = exp.Parameters(exp.choiceWorldParams)
      %    makeTrialSpecific(P, 'onsetToneRelAmp')
      %
      % See also ISTRIALCONDITIONAL, NUMTRIALCONDITIONS
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
      % MAKEGLOBAL Makes named trial condition a global parameter
      %  MAKEGLOBAL(OBJ, NAME[, NEWVALUE]) If the named parameter is
      %  already global (number of columns == 1) an exception is thrown,
      %  otherwise the value of the first column is kept and the others
      %  discarded.  Optionally a new value can be set instead.
      %
      %  Example:
      %    % Make 'repeatIncorrectTrial' globally false
      %    P = exp.Parameters(exp.choiceWorldParams)
      %    makeGlobal(P, 'repeatIncorrectTrial', false)
      %
      % See also MAKETRIALSPECIFIC, NUMTRIALCONDITIONS

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
      % NUMTRIALCONDITIONS Returns the number of trial conditions
      %  Returns the number of trial conditions, defined as the maximum
      %  number of non-single columns.  If all parameters have only one
      %  column, n = 0.
      %
      %  Output:
      %   n (int): the total number of trial conditions
      %
      %  Example:
      %   P = exp.Parameters(exp.choiceWorldParams);
      %   n = P.numTrialConditions % 12
      %
      % See also ISTRIALSPECIFIC
      trialParamNames = obj.TrialSpecificNames;
      trialParamLen = cellfun(@(n) size(obj.Struct.(n), 2), trialParamNames);
      if ~isempty(trialParamLen)
        n = trialParamLen(1);
        assert(all(trialParamLen == n),...
          'Rigbox:exp:Parameters:numTrialConditionsMismatch',...
          'Not all trial-specific parameters are the same length (ncols).');
      else
        n = 0;
      end
    end
    
    function [globalParams, trialParams] = assortForExperiment(obj)
      % ASSORTFOREXPERIMENT Assort into global and trial-specific 
      %  Divide parameters into global and trial-specific parameter
      %  structures for use in an experiment.  In contrast to the
      %  `toConditionServer` method, the trial-specific parameters are not
      %  replicated.
      %
      %  Outputs:
      %   globalParams: a scalar struct of all global parameters
      %   trialParams: a non-scalar struct of all trial-specific parameters
      %
      % See also TOCONDITIONSERVER

      % Group trial-specific parameters into a struct with length of
      % parameters the second dimension (number of columns) specifies
      % parameters for different trials
      trialParamNames = obj.TrialSpecificNames;
      obj.numTrialConditions(); % this asserts that all trial params have same len
      trialParamValues = mapToCell(...
        @(n) iff(~iscell(obj.Struct.(n)), @() num2cell(obj.Struct.(n), 1), obj.Struct.(n)),...
        trialParamNames);
      
      % Group global parameters
      globalParamNames = obj.GlobalNames;
      globalParamValues = cellfun(@(n) obj.Struct.(n), globalParamNames,...
        'UniformOutput', false);
      % concatenate trial parameter
      trialParamValues = cat(1, trialParamValues{:});
      if isempty(trialParamValues), trialParamValues = {}; end
      trialParams = cell2struct(trialParamValues, trialParamNames, 1)';
      globalParams = cell2struct(globalParamValues, globalParamNames, 1);
    end
    
    function [cs, globalParams, trialParams] = toConditionServer(obj, randomOrder)
      % TOCONDITIONSERVER Send parameters to a condition server
      %  Assorts, repeats and permutes parameters for use in a live
      %  experiment.  The trial-specific parameters are replicated based
      %  on numRepeats parameter.
      %
      %  Input (Optional):
      %   randomOrder (logical): If true, the trial-specific parameters
      %     are randomized.  If not provided, the value of the
      %     'randomiseConditions' field is used.  If no such field exists,
      %     the conditions are randomly permuted by default.
      %
      %  Outputs:
      %   cs (exp.PresetConditionServer): A condition server object for
      %     iterating over parameters each trial.
      %   globalParams (struct): a scalar struct of all global parameters.
      %   trialParams (struct): a non-scalar struct of all trial-specific
      %     parameters.  The length is defined by the 'numRepeats'
      %     parameter.  Parameter order is randomized by default.
      %
      %   Example:
      %    P = exp.Parameters(exp.choiceWorldParams)
      %    cs = P.toConditionServer();
      %
      % See also EXP.PRESETCONDITIONSERVER
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
    
    function l = namesFromFields(obj)
      % NAMESFROMFIELDS Returns list of formatted names for the fields
      %  Makes cell array of parameter names, converting camelCase to Space
      %  Seperated Words, e.g. 'repeatIncorrectTrial' -> 'Repeat Incorrect
      %  Trial'.
      %
      %  Example:
      %    P = exp.Parameters(exp.choiceWorldParams)
      %    P.Names % Get list of formatted names
      %
      % See also GET.NAME, SET.STRUCT
      fields = fieldnames(obj.pStruct);
      isinfo = cellfun(@(f) strEndsWith(f, {'Description', 'Units'}), fields);
      l = fields(~isinfo & ~strcmp(fields, 'type'));
    end
  end
    
end

