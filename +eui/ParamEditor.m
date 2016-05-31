classdef ParamEditor < handle
  %EUI.PARAMEDITOR UI control for configuring experiment parameters
  %   TODO. See also EXP.PARAMETERS.
  %
  % Part of Rigbox

  % 2012-11 CB created  
  
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
    SelectedCells %[row, column;...] of each selected cell
    GlobalControls
  end
  
  events
    Changed
  end
  
  methods
    function obj = ParamEditor(params, parent)
      if nargin < 2
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
    function build(obj, parent)
      obj.Root = uiextras.HBox('Parent', parent, 'Padding', 5, 'Spacing', 5);
      
      globalPanel = uiextras.Panel('Parent', obj.Root,...
        'Title', 'Global', 'Padding', 5);
      obj.GlobalGrid = uiextras.Grid('Parent', globalPanel, 'Padding', 4);
      obj.buildGlobalUI;
      
      conditionPanel = uiextras.Panel('Parent', obj.Root,...
        'Title', 'Conditional', 'Padding', 5);
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
        
        obj.Root.Sizes = [sum(obj.GlobalGrid.ColumnSizes) + 10, -1];
    end
    
    function buildGlobalUI(obj)
      globalParams = obj.Parameters.assortForExperiment;
      [editors, labels, buttons] = cellfun(...
        @(n) obj.addParamUI(n), fieldnames(globalParams), 'UniformOutput', false);
      editors = cell2mat(editors);
      labels = cell2mat(labels);
      buttons = cell2mat(buttons);
      obj.GlobalControls = [labels, editors, buttons];
      obj.GlobalGrid.Children = obj.GlobalControls(:);
      obj.GlobalGrid.ColumnSizes = [180, 200, 40];
      obj.GlobalGrid.Spacing = 1;
      obj.GlobalGrid.RowSizes = repmat(obj.GlobalVSpacing, 1, size(obj.GlobalControls, 1));
    end
    
    function swapConditions(obj, idx1, idx2)
%       params = obj.Parameters.trial
    end
    
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
      else
        %nothing selected, disable buttons
        set(obj.MakeGlobalButton, 'Enable', 'off');
        set(obj.DeleteConditionButton, 'Enable', 'off');
      end
    end
    
    function newCondition(obj)
      disp('adding new condition row');
      cellfun(@obj.addEmptyConditionToParam, obj.Parameters.TrialSpecificNames);
      obj.fillConditionTable();
    end
    
    function deleteSelectedConditions(obj)
      rows = unique(obj.SelectedCells(:,1));
      obj.Parameters.removeConditions(rows);
      obj.fillConditionTable(); %refresh the table of conditions
    end
    
    function globaliseSelectedParameters(obj)
      [cols, iu] = unique(obj.SelectedCells(:,2));
      names = obj.TableColumnParamNames(cols);
      rows = obj.SelectedCells(iu,1); %get rows of unique selected cols
      arrayfun(@obj.globaliseParamAtCell, rows, cols);
      obj.fillConditionTable(); %refresh the table of conditions
      %now add global controls for parameters
      [editors, labels, buttons] = cellfun(@obj.addParamUI, names);
      obj.GlobalControls = [obj.GlobalControls;...
        labels, editors, buttons];
      obj.GlobalGrid.Children = obj.GlobalControls(:);
      obj.GlobalGrid.RowSizes = repmat(obj.GlobalVSpacing, 1, size(obj.GlobalControls, 1));
    end
    
    function globaliseParamAtCell(obj, row, col)
      name = obj.TableColumnParamNames{col};
      value = obj.Parameters.Struct.(name)(:,row);
      obj.Parameters.makeGlobal(name, value);
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
          data = data ~= 0;
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
    end

    function [ctrl, label, buttons] = addParamUI(obj, name)
      parent = obj.GlobalGrid;
      ctrl = [];
      label = [];
      buttons = [];
      value = obj.paramValue2Control(obj.Parameters.Struct.(name));
      title = obj.Parameters.title(name);
      description = obj.Parameters.description(name);
      
      if isnumeric(value)
        value = num2str(value);
      end
      if islogical(value)
        ctrl = uicontrol('Parent', parent,...
          'Style', 'checkbox',...
          'TooltipString', description,...
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

      if ~isempty(ctrl)
        label = uicontrol('Parent', parent,...
          'Style', 'text', 'String', title, 'HorizontalAlignment', 'left',...
          'TooltipString', description);
        bbox = uiextras.HBox('Parent', parent);
        buttons = bbox.UIContainer;
        uicontrol('Parent', bbox, 'Style', 'pushbutton',...
          'String', '[...]',...
          'TooltipString', sprintf(['Make this a condition parameter (i.e. vary by trial).\n'...
            'This will move it to the trial conditions table.']),...
          'FontSize', 7,...
          'Callback', @(~,~) obj.makeTrialSpecific(name, {ctrl, label, bbox}));
        bbox.Sizes = [29];
      end
    end
  end
    
end

