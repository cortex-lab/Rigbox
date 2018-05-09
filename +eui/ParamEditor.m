classdef ParamEditor < handle
  %EUI.PARAMEDITOR UI control for configuring experiment parameters
  %   TODO. See also EXP.PARAMETERS.
  %
  % Part of Rigbox

  % 2012-11 CB created  
  % 2017-03 MW/NS Made global panel scrollable & improved performance of
  % buildGlobalUI.
  % 2017-03 MW Added set values button
  
  properties
    GlobalVSpacing = 20
    Parameters
  end
  
  properties (Dependent)
    Enable
  end
  
  properties (Access = private)
    Root
    GlobalGrid
    ConditionTable
    TableColumnParamNames = {}
    NewConditionButton
    DeleteConditionButton
    MakeGlobalButton
    SetValuesButton
    SelectedCells %[row, column;...] of each selected cell
    GlobalControls
  end
  
  events
    Changed
  end
  
  methods
    function obj = ParamEditor(params, parent)
      if nargin < 2 % Can call this function to display parameters is new window
        parent = figure('Name', 'Parameters', 'NumberTitle', 'off',...
          'Toolbar', 'none', 'Menubar', 'none');
      end
      obj.Parameters = params;
      obj.build(parent);
    end
    
    function delete(obj)
      disp('ParamEditor destructor called');
      if obj.Root.isvalid
        obj.Root.delete();
      end
    end
    
    function value = get.Enable(obj)
      value = obj.Root.Enable;
    end
    
    function set.Enable(obj, value)
      obj.Root.Enable = value;
    end
  end
  
  methods %(Access = protected)
    function build(obj, parent) % Build parameters panel
      obj.Root = uiextras.HBox('Parent', parent, 'Padding', 5, 'Spacing', 5); % Add horizontal container for Global and Conditional panels
%       globalPanel = uiextras.Panel('Parent', obj.Root,... % Make 'Global' parameters panel
%         'Title', 'Global', 'Padding', 5);
      globPanel = uiextras.Panel('Parent', obj.Root,... % Make 'Global' parameters panel
        'Title', 'Global', 'Padding', 5);
      globalPanel = uix.ScrollingPanel('Parent', globPanel,... % Make 'Global' scroll panel
        'Padding', 5);
      
      obj.GlobalGrid = uiextras.Grid('Parent', globalPanel, 'Padding', 4); % Make grid for parameter fields
      obj.buildGlobalUI; % Populate Global panel
      globalPanel.Heights = sum(obj.GlobalGrid.RowSizes)+45;
      
      conditionPanel = uiextras.Panel('Parent', obj.Root,...
        'Title', 'Conditional', 'Padding', 5); % Make 'Conditional' parameters panel
      conditionVBox = uiextras.VBox('Parent', conditionPanel);
      obj.ConditionTable = uitable('Parent', conditionVBox,...
        'FontName', 'Consolas',...
        'RowName', [],...
        'CellEditCallback', @obj.cellEditCallback,...
        'CellSelectionCallback', @obj.cellSelectionCallback);
      obj.fillConditionTable();
      conditionButtonBox = uiextras.HBox('Parent', conditionVBox);
      conditionVBox.Sizes = [-1 25];
      obj.NewConditionButton = uicontrol('Parent', conditionButtonBox,...
        'Style', 'pushbutton',...
        'String', 'New condition',...
        'TooltipString', 'Add a new condition',...
        'Callback', @(~, ~) obj.newCondition());
      obj.DeleteConditionButton = uicontrol('Parent', conditionButtonBox,...
        'Style', 'pushbutton',...
        'String', 'Delete condition',...
        'TooltipString', 'Delete the selected condition',...
        'Enable', 'off',...
        'Callback', @(~, ~) obj.deleteSelectedConditions());
       obj.MakeGlobalButton = uicontrol('Parent', conditionButtonBox,...
         'Style', 'pushbutton',...
         'String', 'Globalise parameter',...
         'TooltipString', sprintf(['Make the selected condition-specific parameter global (i.e. not vary by trial)\n'...
            'This will move it to the global parameters section']),...
         'Enable', 'off',...
         'Callback', @(~, ~) obj.globaliseSelectedParameters());
       obj.SetValuesButton = uicontrol('Parent', conditionButtonBox,...
         'Style', 'pushbutton',...
         'String', 'Set values',...
         'TooltipString', 'Set selected values to specified value, range or function',...
         'Enable', 'off',...
         'Callback', @(~, ~) obj.setSelectedValues());
        
        obj.Root.Sizes = [sum(obj.GlobalGrid.ColumnSizes) + 32, -1];
    end
    
    function buildGlobalUI(obj) % Function to essemble global parameters
      globalParamNames = fieldnames(obj.Parameters.assortForExperiment); % assortForExperiment divides params into global and trial-specific parameter structures
      obj.GlobalControls = gobjects(length(globalParamNames),3); % Initialize object array (faster than assigning to end of array which results in two calls to constructor)  
      for i=1:length(globalParamNames) % using for loop (sorry Chris!) to populate object array 2017-02-14 MW
          [obj.GlobalControls(i,1), obj.GlobalControls(i,2), obj.GlobalControls(i,3)]... % [editors, labels, buttons]
              = obj.addParamUI(globalParamNames{i});
      end
      % Above code replaces the following as after 2014a, MATLAB doesn't no
      % longer uses numrical handles but instead uses object arrays
%       [editors, labels, buttons] = cellfun(...
%         @(n) obj.addParamUI(n), fieldnames(globalParams), 'UniformOutput', false);
%       editors = cell2mat(editors);
%       labels = cell2mat(labels);
%       buttons = cell2mat(buttons);
%       obj.GlobalControls = [labels, editors, buttons];
%       obj.GlobalGrid.Children = obj.GlobalControls(:);

%       obj.GlobalGrid.Children =
%       blah = cat(1,obj.GlobalControls(:,1),obj.GlobalControls(:,2),obj.GlobalControls(:,3));
%       Doesn't work for some reason - MW 2017-02-15

      child_handles = allchild(obj.GlobalGrid); % Get child handles for GlobalGrid
      child_handles = [child_handles(end-1:-3:1); child_handles(end:-3:1); child_handles(end-2:-3:1)]; % Reorder them so all labels come first, then ctrls, then buttons
%       child_handles = [child_handles(2:3:end); child_handles(3:3:end); child_handles(1:3:end)]; % Reorder them so all labels come first, then ctrls, then buttons
      obj.GlobalGrid.Contents = child_handles; % Set children to new order
      % uistack

      obj.GlobalGrid.ColumnSizes = [180, 200, 40]; % Set column sizes
      obj.GlobalGrid.Spacing = 1;
      obj.GlobalGrid.RowSizes = repmat(obj.GlobalVSpacing, 1, size(obj.GlobalControls, 1));
    end
    
%     function swapConditions(obj, idx1, idx2) % Function started, never
%     finished - MW 2017-02-15
% %       params = obj.Parameters.trial
%     end
    
    function addEmptyConditionToParam(obj, name)
      assert(obj.Parameters.isTrialSpecific(name),...
        'Tried to add a new condition to global parameter ''%s''', name);
      % work out what the right 'empty' is for the parameter
      currValue = obj.Parameters.Struct.(name);
      if isnumeric(currValue)
        newValue = zeros(size(currValue, 1), 1, class(currValue));
      elseif islogical(currValue)
        newValue = false(size(currValue, 1), 1);
      elseif iscell(currValue)
        if numel(currValue) > 0
          if iscellstr(currValue)
            % if all elements are strings, default to a blank string
            newValue = {''};
          elseif isa(currValue{1}, 'function_handle')
            % first element is a function handle, so create with a @nop
            % handle
            newValue = {@nop};
          else
            % misc cell case - default to empty element
            newValue = {[]};
          end
        else
          % misc case - default to empty element
          newValue = {[]};
        end
      else
        error('Adding empty condition for ''%s'' type not implemented', class(currValue));
      end
      obj.Parameters.Struct.(name) = cat(2, obj.Parameters.Struct.(name), newValue);
    end
    
    function cellSelectionCallback(obj, src, eventData)
      obj.SelectedCells = eventData.Indices;
      if size(eventData.Indices, 1) > 0
        %cells selected, enable buttons
        set(obj.MakeGlobalButton, 'Enable', 'on');
        set(obj.DeleteConditionButton, 'Enable', 'on');
        set(obj.SetValuesButton, 'Enable', 'on');
      else
        %nothing selected, disable buttons
        set(obj.MakeGlobalButton, 'Enable', 'off');
        set(obj.DeleteConditionButton, 'Enable', 'off');
        set(obj.SetValuesButton, 'Enable', 'off');
      end
    end
    
    function newCondition(obj)
      disp('adding new condition row');
      cellfun(@obj.addEmptyConditionToParam, obj.Parameters.TrialSpecificNames);
      obj.fillConditionTable();
    end
    
    function deleteSelectedConditions(obj)
      %DELETESELECTEDCONDITIONS Removes the selected conditions from table
      % The callback for the 'Delete condition' button.  This removes the
      % selected conditions from the table and if less than two conditions
      % remain, globalizes them.
      %     TODO: comment function better, index in a clearer fashion
      %
      % See also EXP.PARAMETERS, GLOBALISESELECTEDPARAMETERS
      rows = unique(obj.SelectedCells(:,1));
      % If the number of remaining conditions is 1 or less...
      names = obj.Parameters.TrialSpecificNames;
      numConditions = size(obj.Parameters.Struct.(names{1}),2);
      if numConditions-length(rows) <= 1
          remainingIdx = find(all(1:numConditions~=rows,1));
          if isempty(remainingIdx); remainingIdx = 1; end
          % change selected cells to be all fields (except numRepeats which
          % is assumed to always be the last column)
          obj.SelectedCells =[ones(length(names)-1,1)*remainingIdx, (1:length(names)-1)'];
          %... globalize them
          obj.globaliseSelectedParameters;
          obj.Parameters.removeConditions(rows)
%           for i = 1:numel(names)
%               newValue = iff(any(remainingIdx), obj.Struct.(names{i})(:,remainingIdx), obj.Struct.(names{i})(1));
%               % If the parameter is Num repeats, set the value
%               if strcmp(names{i}, 'numRepeats')
%                   obj.Struct.(names{i}) = newValue;
%               else
%                   obj.makeGlobal(names{i}, newValue);
%               end
%           end
      else % Otherwise delete the selected conditions as usual
      obj.Parameters.removeConditions(rows);
      end
      obj.fillConditionTable(); %refresh the table of conditions
    end
    
    function globaliseSelectedParameters(obj)
      [cols, iu] = unique(obj.SelectedCells(:,2));
      names = obj.TableColumnParamNames(cols);
      rows = obj.SelectedCells(iu,1); %get rows of unique selected cols
      arrayfun(@obj.globaliseParamAtCell, rows, cols);
      obj.fillConditionTable(); %refresh the table of conditions
      %now add global controls for parameters
      newGlobals = gobjects(length(names),3); % Initialize object array (faster than assigning to end of array which results in two calls to constructor)  
      for i=length(names):-1:1 % using for loop (sorry Chris!) to initialize and populate object array 2017-02-15 MW
          [newGlobals(i,1), newGlobals(i,2), newGlobals(i,3)]... % [editors, labels, buttons]
              = obj.addParamUI(names{i});
      end

%       [editors, labels, buttons] = arrayfun(@obj.addParamUI, names); %
%       2017-02-15 MW can no longer use arrayfun with object outputs
      idx = size(obj.GlobalControls, 1); % Calculate number of current Global params
      new = numel(newGlobals);
      obj.GlobalControls = [obj.GlobalControls; newGlobals]; % Add new globals to object
      ggHandles = obj.GlobalGrid.Contents;
      ggHandles = [ggHandles(1:idx); ggHandles((end-new+2):3:end);...
          ggHandles(idx+1:idx*2); ggHandles((end-new+1):3:end);... 
          ggHandles(idx*2+1:idx*3); ggHandles((end-new+3):3:end)]; % Reorder them so all labels come first, then ctrls, then buttons
      obj.GlobalGrid.Contents = ggHandles; % Set children to new order
     
      % Reset sizes
      obj.GlobalGrid.RowSizes = repmat(obj.GlobalVSpacing, 1, size(obj.GlobalControls, 1));
      set(get(obj.GlobalGrid, 'Parent'),...
          'Heights', sum(obj.GlobalGrid.RowSizes)+45); % Reset height of globalPanel
      obj.GlobalGrid.ColumnSizes = [180, 200, 40]; 
      obj.GlobalGrid.Spacing = 1;
    end
    
    function globaliseParamAtCell(obj, row, col)
      name = obj.TableColumnParamNames{col};
      value = obj.Parameters.Struct.(name)(:,row);
      obj.Parameters.makeGlobal(name, value);
    end
    
    function setSelectedValues(obj) % Set multiple fields in conditional table
      disp('updating table cells');
      cols = obj.SelectedCells(:,2); % selected columns
      uCol = unique(obj.SelectedCells(:,2));
      rows = obj.SelectedCells(:,1); % selected rows
      % get current values of selected cells
      currVals = arrayfun(@(u)obj.ConditionTable.Data(rows(cols==u),u), uCol, 'UniformOutput', 0);
      names = obj.TableColumnParamNames(uCol); % selected column names
      promt = cellfun(@(a,b) [a ' (' num2str(sum(cols==b)) ')'],...
          names, num2cell(uCol), 'UniformOutput', 0); % names of columns & num selected rows
      defaultans = cellfun(@(c) c(1), currVals);
      answer = inputdlg(promt,'Set values', 1, cellflat(defaultans)); % prompt for input
      if isempty(answer) % if user presses cancel
          return
      end
      % set values for each column
      cellfun(@(a,b,c) setNewVals(a,b,c), answer, currVals, names, 'UniformOutput', 0); 
        function newVals = setNewVals(userIn, currVals, paramName)
            % check array orientation
            currVals = iff(size(currVals,1)>size(currVals,2),currVals',currVals);
          if strStartsWith(userIn,'@') % anon function
              func_h = str2func(userIn);
              % apply function to each cell
              currVals = cellfun(@str2double,currVals, 'UniformOutput', 0); % convert from char
              newVals = cellfun(func_h, currVals, 'UniformOutput', 0); 
          elseif any(userIn==':') % array syntax
              arr = eval(userIn);
              newVals = num2cell(arr); % convert to cell array
          elseif any(userIn==','|userIn==';') % 2D arrays
            C = strsplit(userIn, ';');
            newVals = cellfun(@(c)textscan(c, '%f',...
            'ReturnOnError', false,...
            'delimiter', {' ', ','}, 'MultipleDelimsAsOne', 1),...
            C);
          else % single value to copy across all cells
              userIn = str2double(userIn); 
              newVals = num2cell(ones(size(currVals))*userIn);
          end
          
          if length(newVals)>length(currVals) % too many new values
              newVals = newVals(1:length(currVals)); % truncate new array 
          elseif length(newVals)<length(currVals) % too few new values
              % populate as many cells as possible
              newVals = [newVals ...
                  cellfun(@(a)obj.controlValue2Param(2,a),...
                  currVals(length(newVals)+1:end),'UniformOutput',0)]; 
          end
         ic = strcmp(obj.TableColumnParamNames,paramName); % find edited param names
         % update param struct
         obj.Parameters.Struct.(paramName)(:,rows(cols==find(ic))) = cell2mat(newVals);
         % update condtion table with strings
         obj.ConditionTable.Data(rows(cols==find(ic)),ic)...
             = cellfun(@(a)obj.paramValue2Control(a), newVals', 'UniformOutput', 0);
        end
      notify(obj, 'Changed');
    end
    
    function cellEditCallback(obj, src, eventData)
      disp('updating table cell');
      row = eventData.Indices(1);
      col = eventData.Indices(2);
      paramName = obj.TableColumnParamNames{col};
      currValue = obj.Parameters.Struct.(paramName)(:,row);
      if iscell(currValue)
        % cell holders are allowed to be different types of value
        newParam = obj.controlValue2Param(currValue{1}, eventData.NewData, true);
        obj.Parameters.Struct.(paramName){:,row} = newParam;
      else
        newParam = obj.controlValue2Param(currValue, eventData.NewData);
        obj.Parameters.Struct.(paramName)(:,row) = newParam;
      end
      % if successful update the cell with default formatting
      data = get(src, 'Data');
      reformed = obj.paramValue2Control(newParam);
      if iscell(reformed)
        % the reformed data type is a cell, this should be a one element
        % wrapping cell
        if numel(reformed) == 1
          reformed = reformed{1};
        else
          error('Cannot handle data reformatted data type');
        end        
      end
      data{row,col} = reformed;      
      set(src, 'Data', data);
      %notify listeners of change
      notify(obj, 'Changed');
    end
    
    function updateGlobal(obj, param, src)
      currParamValue = obj.Parameters.Struct.(param);
      switch get(src, 'style')
        case 'checkbox'
          newValue = logical(get(src, 'value'));
          obj.Parameters.Struct.(param) = newValue;
        case 'edit'
          newValue = obj.controlValue2Param(currParamValue, get(src, 'string'));
          obj.Parameters.Struct.(param) = newValue;
          % if successful update the control with default formatting and
          % modified colour
          set(src, 'String', obj.paramValue2Control(newValue),...
            'ForegroundColor', [1 0 0]); %red indicating it has changed
          %notify listeners of change
          notify(obj, 'Changed');
      end
    end

    function [data, paramNames, titles] = tableData(obj)
      [~, trialParams] = obj.Parameters.assortForExperiment;
      paramNames = fieldnames(trialParams);
      titles = obj.Parameters.title(paramNames);
      data = reshape(struct2cell(trialParams), numel(paramNames), [])';
      data = mapToCell(@(e) obj.paramValue2Control(e), data);
    end
    
    function data = controlValue2Param(obj, currParam, data, allowTypeChange)
      if nargin < 4
        allowTypeChange = false;
      end
      % convert from control value to parameter value
      switch class(currParam)
        case 'function_handle'
          data = str2func(data);
        case 'logical'
          data = data ~= 0;
        case 'char'
          % do nothing - strings stay as strings
        otherwise
          if isnumeric(currParam)
            % parse string as numeric vector
            try
              C = textscan(data, '%f',...
                'ReturnOnError', false,...
                'delimiter', {' ', ','}, 'MultipleDelimsAsOne', 1);
              data = C{1};
            catch ex
              % if a type change is allowed, then a numeric can become a
              % string, otherwise rethrow the parse error
              if ~allowTypeChange
                rethrow(ex);
              end
            end
          elseif iscellstr(currParam)
            C = textscan(data, '%s',...
                'ReturnOnError', false,...
                'delimiter', {' ', ','}, 'MultipleDelimsAsOne', 1);
            data = C{1};%deblank(num2cell(data, 2));
          else
            error('Cannot update unimplemented type ''%s''', class(currParam));
          end
      end
    end
    
    function data = paramValue2Control(obj, data)
      % convert from parameter value to control value
      switch class(data)
        case 'function_handle'
          % convert a function handle to it's string name
          data = func2str(data);
        case 'logical'
          data = data ~= 0; % If logical do nothing, basically.
        otherwise
          if isnumeric(data)
            % format numeric types as string number list
            strlist = mapToCell(@num2str, data);
            data = strJoin(strlist, ', ');
          elseif iscellstr(data)
            data = strJoin(data, ', ');
          end
      end
      % all other data types stay as they are, including e.g. strings
    end
    
    function fillConditionTable(obj)
      [data, params, titles] = obj.tableData;
      set(obj.ConditionTable, 'ColumnName', titles, 'Data', data,...
        'ColumnEditable', true(1, numel(titles)));
      obj.TableColumnParamNames = params;
    end
    
    function makeTrialSpecific(obj, paramName, ctrls)
      [uirow, ~] = find(obj.GlobalControls == ctrls{1});
      assert(numel(uirow) == 1, 'Unexpected number of matching global controls');
      cellfun(@(c) delete(c), ctrls);
      obj.GlobalControls(uirow,:) = [];
      obj.GlobalGrid.RowSizes(uirow) = [];
      obj.Parameters.makeTrialSpecific(paramName);
      obj.fillConditionTable();
      set(get(obj.GlobalGrid, 'Parent'),...
          'Heights', sum(obj.GlobalGrid.RowSizes)+45); % Reset height of globalPanel
    end

    function [ctrl, label, buttons] = addParamUI(obj, name) % Adds ui element for each parameter
      parent = obj.GlobalGrid; % Made by build function above
      ctrl = [];
      label = [];
      buttons = [];
      if iscell(name) % 2017-02-14 MW function now called with arrayFun (instead of cellFun)
        name = name{1,1}; 
      end
      value = obj.paramValue2Control(obj.Parameters.Struct.(name));  % convert from parameter value to control value (everything but logical values become strings)
      title = obj.Parameters.title(name);
      description = obj.Parameters.description(name);
      
%       if isnumeric(value) % Why? All this would do is convert logical values to char; everything else dealt with by paramValue2Control.  MW 2017-02-15
%         value = num2str(value);
%       end
      if islogical(value) % If parameter is logical, make checkbox
        ctrl = uicontrol('Parent', parent,...
          'Style', 'checkbox',...
          'TooltipString', description,...
          'Value', value,... % Added 2017-02-15 MW set checkbox to what ever the parameter value is
          'Callback', @(src, e) obj.updateGlobal(name, src));
      elseif ischar(value)
        ctrl = uicontrol('Parent', parent,...
          'BackgroundColor', [1 1 1],...
          'Style', 'edit',...
          'String', value,...
          'TooltipString', description,...
          'UserData', name,... % save the name of the parameter in userdata
          'HorizontalAlignment', 'left',...
          'Callback', @(src, e) obj.updateGlobal(name, src));
%       elseif iscellstr(value)
%         lines = mkStr(value, [], sprintf('\n'), []);
%         ctrl = uicontrol('Parent', parent,...
%           'BackgroundColor', [1 1 1],...
%           'Style', 'edit',...
%           'Max', 2,... %make it multiline
%           'String', lines,...
%           'TooltipString', description,...
%           'HorizontalAlignment', 'left',...
%           'UserData', name,... % save the name of the parameter in userdata
%           'Callback', @(src, e) obj.updateGlobal(name, src));
      end

      if ~isempty(ctrl) % If control box is made, add label and conditional button
        label = uicontrol('Parent', parent,...
          'Style', 'text', 'String', title, 'HorizontalAlignment', 'left',...
          'TooltipString', description); % Why not use bui.label? MW 2017-02-15
        bbox = uiextras.HBox('Parent', parent); % Make HBox for button
        % UIContainer no longer present in GUILayoutToolbox, it used to
        % call uipanel with the following args:  
        % 'Units', 'Normalized'; 'BorderType', 'none')
%         buttons = bbox.UIContainer; 
        buttons = uicontrol('Parent', bbox, 'Style', 'pushbutton',... % Make 'conditional parameter' button
          'String', '[...]',...
          'TooltipString', sprintf(['Make this a condition parameter (i.e. vary by trial).\n'...
            'This will move it to the trial conditions table.']),...
          'FontSize', 7,...
          'Callback', @(~,~) obj.makeTrialSpecific(name, {ctrl, label, bbox}));
        bbox.Sizes = 29; % Resize button height to 29px
      end
    end
  end
    
end

