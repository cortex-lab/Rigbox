classdef ConditionPanel < handle
  %UNTITLED Summary of this class goes here
  %   Detailed explanation goes here
  % TODO Document
  % TODO Add sort by column
  % TODO Add set condition idx
  % TODO Use tags for menu items
  
  properties
    ConditionTable
    MinWidth = 80
%     MaxWidth = 140
%     Margin = 4
    UIPanel
    ButtonPanel
    ContextMenus
  end
  
  properties %(Access = protected)
    ParamEditor
    Listener
    NewConditionButton
    DeleteConditionButton
    MakeGlobalButton
    SetValuesButton
    SelectedCells %[row, column;...] of each selected cell
  end
  
  methods
    function obj = ConditionPanel(f, ParamEditor, varargin)
      obj.ParamEditor = ParamEditor;
      obj.UIPanel = uipanel('Parent', f, 'BorderType', 'none',...
          'BackgroundColor', 'white', 'Position',  [0.5 0.05 0.5 0.95]);
      % Create a child menu for the uiContextMenus
      c = uicontextmenu;
      obj.UIPanel.UIContextMenu = c;
      obj.ContextMenus = uimenu(c, 'Label', 'Make Global', 'MenuSelectedFcn', @(~,~)obj.makeGlobal);
      fcn = @(s,~)obj.ParamEditor.setRandomized(~strcmp(s.Checked, 'on'));
      obj.ContextMenus(2) = uimenu(c, 'Label', 'Randomize conditions', ...
        'MenuSelectedFcn', fcn, 'Checked', 'on', 'Tag', 'randomize button');
      obj.ContextMenus(3) = uimenu(c, 'Label', 'Sort by selected column', ...
        'MenuSelectedFcn', @(~,~)disp('feature not yet implemented'), 'Tag', 'sort by');
      % Create condition table
      obj.ConditionTable = uitable('Parent', obj.UIPanel,...
        'FontName', 'Consolas',...
        'RowName', [],...
        'RearrangeableColumns', true,...
        'Units', 'normalized',...
        'Position',[0 0 1 1],...
        'UIContextMenu', c,...
        'CellEditCallback', @obj.onEdit,...
        'CellSelectionCallback', @obj.onSelect);
      % Create button panel to hold condition control buttons
      obj.ButtonPanel = uipanel('BackgroundColor', 'white',...
          'Position', [0.5 0 0.5 0.05], 'BorderType', 'none');
      % Create callback so that width of button panel is slave to width of
      % conditional UIPanel
      b = obj.ButtonPanel;
      fcn = @(s)set(obj.ButtonPanel, 'Position', ...
        [s.Position(1) b.Position(2) s.Position(3) b.Position(4)]);
      obj.Listener = event.listener(obj.UIPanel, 'SizeChanged', @(s,~)fcn(s));
      % Define some common properties
      props.BackgroundColor = 'white';
      props.Style = 'pushbutton';
      props.Units = 'normalized';
      props.Parent = obj.ButtonPanel;
      % Create out four buttons
      obj.NewConditionButton = uicontrol(props,...
        'String', 'New condition',...
        'Position',[0 0 1/4 1],...
        'TooltipString', 'Add a new condition',...
        'Callback', @(~, ~) obj.newCondition());
      obj.DeleteConditionButton = uicontrol(props,...
        'String', 'Delete condition',...
        'Position',[1/4 0 1/4 1],...
        'TooltipString', 'Delete the selected condition',...
        'Enable', 'off',...
        'Callback', @(~, ~) obj.deleteSelectedConditions());
       obj.MakeGlobalButton = uicontrol(props,...
         'String', 'Globalise parameter',...
         'Position',[2/4 0 1/4 1],...
         'TooltipString', sprintf(['Make the selected condition-specific parameter global (i.e. not vary by trial)\n'...
            'This will move it to the global parameters section']),...
         'Enable', 'off',...
         'Callback', @(~, ~) obj.makeGlobal());
       obj.SetValuesButton = uicontrol(props,...
         'String', 'Set values',...
         'Position',[3/4 0 1/4 1],...
         'TooltipString', 'Set selected values to specified value, range or function',...
         'Enable', 'off',...
         'Callback', @(~, ~) obj.setSelectedValues());
    end

    function onEdit(obj, src, eventData)
      disp('updating table cell');
      row = eventData.Indices(1);
      col = eventData.Indices(2);
      paramName = obj.ConditionTable.ColumnName{col};
      newValue = obj.ParamEditor.update(paramName, eventData.NewData, row);
      reformed = obj.ParamEditor.paramValue2Control(newValue);
      % If successful update the cell with default formatting
      data = get(src, 'Data');
      if iscell(reformed)
        % The reformed data type is a cell, this should be a one element
        % wrapping cell
        if numel(reformed) == 1
          reformed = reformed{1};
        else
          error('Cannot handle data reformatted data type');
        end        
      end
      data{row,col} = reformed;      
      set(src, 'Data', data);
    end
    
    function clear(obj)
      set(obj.ConditionTable, 'ColumnName', [], ...
        'Data', [], 'ColumnEditable', false);
    end
    
    function delete(obj)
      disp('delete called');
      delete(obj.UIPanel);
    end
    
    function onSelect(obj, ~, eventData)
      obj.SelectedCells = eventData.Indices;
      if size(eventData.Indices, 1) > 0
        % cells selected, enable buttons
        set(obj.MakeGlobalButton, 'Enable', 'on');
        set(obj.DeleteConditionButton, 'Enable', 'on');
        set(obj.SetValuesButton, 'Enable', 'on');
        set(obj.ContextMenus(1), 'Enable', 'on');
        set(obj.ContextMenus(3), 'Enable', 'on');
      else
        % nothing selected, disable buttons
        set(obj.MakeGlobalButton, 'Enable', 'off');
        set(obj.DeleteConditionButton, 'Enable', 'off');
        set(obj.SetValuesButton, 'Enable', 'off');
        set(obj.ContextMenus(1), 'Enable', 'off');
        set(obj.ContextMenus(3), 'Enable', 'off');
      end
    end

    function makeGlobal(obj)
      if isempty(obj.SelectedCells)
        disp('nothing selected')
        return
      end
      [cols, iu] = unique(obj.SelectedCells(:,2));
      names = obj.ConditionTable.ColumnName(cols);
      rows = num2cell(obj.SelectedCells(iu,1)); %get rows of unique selected cols
      PE = obj.ParamEditor;
      cellfun(@PE.globaliseParamAtCell, names, rows);
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
      names = obj.ConditionTable.ColumnName;
      numConditions = size(obj.ConditionTable.Data,2);
      % If the number of remaining conditions is 1 or less...
      if numConditions-length(rows) <= 1
          remainingIdx = find(all(1:numConditions~=rows,1));
          if isempty(remainingIdx); remainingIdx = 1; end
          % change selected cells to be all fields (except numRepeats which
          % is assumed to always be the last column)
          obj.SelectedCells =[ones(length(names),1)*remainingIdx, (1:length(names))'];
          %... globalize them
          obj.makeGlobal;
      else % Otherwise delete the selected conditions as usual
          obj.ParamEditor.Parameters.removeConditions(rows); %FIXME: Should be in ParamEditor
      end
      % Refresh the table of conditions FIXME: Should be in ParamEditor
      obj.ParamEditor.fillConditionTable();
    end
    
    function setSelectedValues(obj) % Set multiple fields in conditional table
      disp('updating table cells');
      cols = obj.SelectedCells(:,2); % selected columns
      uCol = unique(obj.SelectedCells(:,2));
      rows = obj.SelectedCells(:,1); % selected rows
      % get current values of selected cells
      currVals = arrayfun(@(u)obj.ConditionTable.Data(rows(cols==u),u), uCol, 'UniformOutput', 0);
      names = obj.ConditionTable.ColumnName(uCol); % selected column names
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
            cellfun(@(a)ui.ParamEditor.controlValue2Param(2,a),...
            currVals(length(newVals)+1:end),'UniformOutput',0)];
        end
        ic = strcmp(obj.ConditionTable.ColumnName, paramName); % find edited param names
        % update param struct
        obj.ParamEditor.Parameters.Struct.(paramName)(:,rows(cols==find(ic))) = cell2mat(newVals);
        % update condtion table with strings
        obj.ConditionTable.Data(rows(cols==find(ic)),ic)...
          = cellfun(@(a)ui.ParamEditor.paramValue2Control(a), newVals', 'UniformOutput', 0);
      end
      notify(obj.ParamEditor, 'Changed');
    end
    
    function newCondition(obj)
      disp('adding new condition row');
      PE = obj.ParamEditor;
      cellfun(@PE.addEmptyConditionToParam, ...
        PE.Parameters.TrialSpecificNames);
      obj.ParamEditor.fillConditionTable();
    end
    
    
  end
  
end