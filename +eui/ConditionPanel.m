classdef ConditionPanel < handle
  %CONDITIONPANEL Deals with formatting trial conditions UI table
  %   Designed to be an element of the EUI.PARAMEDITOR class that manages
  %   the UI elements associated with all Conditional parameters.
  % TODO Add set condition idx
  
  properties
    % Handle to UI Table that represents trial conditions
    ConditionTable
    % Minimum UI Panel width allowed.  See also EUI.PARAMEDITOR/ONRESIZE
    MinWidth = 80
    % Handle to parent UI container
    UIPanel
    % Handle to UI container for buttons
    ButtonPanel
    % Handles to context menu items
    ContextMenus
  end
  
  properties (Access = protected)
    % Handle to EUI.PARAMEDITOR object
    ParamEditor
    % UIControl button for adding a new trial condition (row) to the table
    NewConditionButton
    % UIControl button for deleting trial conditions (rows) from the table
    DeleteConditionButton
    % UIControl button for making conditional parameter (column) global
    MakeGlobalButton
    % UIControl button for setting multiple table cells at once
    SetValuesButton
    % Indicies of selected table cells  as array [row, column;...] of each
    % selected cell
    SelectedCells 
  end
  
  methods
    function obj = ConditionPanel(f, ParamEditor, varargin)
      % FIELDPANEL Panel UI for Conditional parameters 
      %  Input f may be a figure or other UI container object
      %  ParamEditor is a handle to an eui.ParamEditor object.
      % 
      % See also EUI.PARAMEDITOR, EUI.FIELDPANEL
      obj.ParamEditor = ParamEditor;
      obj.UIPanel = uix.VBox('Parent', f);
      % Create a child menu for the uiContextMenus. The input arg is the 
      % figure holding the panel
      c = uicontextmenu(ParamEditor.Root);
      obj.UIPanel.UIContextMenu = c;
      obj.ContextMenus = uimenu(c, 'Label', 'Make Global', ...
        'MenuSelectedFcn', @(~,~)obj.makeGlobal, 'Enable', 'off');
      fcn = @(s,~)obj.ParamEditor.setRandomized(~strcmp(s.Checked, 'on'));
      obj.ContextMenus(2) = uimenu(c, 'Label', 'Randomize conditions', ...
        'MenuSelectedFcn', fcn, 'Checked', 'on', 'Tag', 'randomize button');
      obj.ContextMenus(3) = uimenu(c, 'Label', 'Sort by selected column', ...
        'MenuSelectedFcn', @(~,~)obj.sortByColumn, ...
        'Tag', 'sort by', 'Enable', 'off');
      % Create condition table
      p = uix.Panel('Parent', obj.UIPanel, 'BorderType', 'none');
      obj.ConditionTable = uitable('Parent', p,...
        'FontName', 'Consolas',...
        'RowName', [],...
        'RearrangeableColumns', 'on',...
        'Units', 'normalized',...
        'Position',[0 0 1 1],...
        'UIContextMenu', c,...
        'CellEditCallback', @obj.onEdit,...
        'CellSelectionCallback', @obj.onSelect);
      % Create button panel to hold condition control buttons
      obj.ButtonPanel = uix.HBox('Parent', obj.UIPanel);
      % Define some common properties
      props.Style = 'pushbutton';
      props.Units = 'normalized';
      props.Parent = obj.ButtonPanel;
      % Create out four buttons
      obj.NewConditionButton = uicontrol(props,...
        'String', 'New condition',...
        'TooltipString', 'Add a new condition',...
        'Callback', @(~, ~) obj.newCondition());
      obj.DeleteConditionButton = uicontrol(props,...
        'String', 'Delete condition',...
        'TooltipString', 'Delete the selected condition',...
        'Enable', 'off',...
        'Callback', @(~, ~) obj.deleteSelectedConditions());
       obj.MakeGlobalButton = uicontrol(props,...
         'String', 'Globalise parameter',...
         'TooltipString', sprintf(['Make the selected condition-specific parameter global (i.e. not vary by trial)\n'...
            'This will move it to the global parameters section']),...
         'Enable', 'off',...
         'Callback', @(~, ~) obj.makeGlobal());
       obj.SetValuesButton = uicontrol(props,...
         'String', 'Set values',...
         'TooltipString', 'Set selected values to specified value, range or function',...
         'Enable', 'off',...
         'Callback', @(~, ~) obj.setSelectedValues());
       obj.ButtonPanel.Widths = [-1 -1 -1 -1];
       obj.UIPanel.Heights = [-1 25];
    end
    
    function onEdit(obj, src, eventData)
      % ONEDIT Callback for edits to condition table
      %  Updates the underlying parameter struct, changes the UI table
      %  data. The src object should be the UI Table that has been edited,
      %  and eventData contains the table indices of the edited cell.
      %
      % See also FILLCONDITIONTABLE, EUI.PARAMEDITOR/UPDATE
      row = eventData.Indices(1);
      col = eventData.Indices(2);
      assert(all(cellfun(@strcmpi, erase(obj.ConditionTable.ColumnName, ' '), ...
        obj.ParamEditor.Parameters.TrialSpecificNames)), 'Unexpected condition names')
      paramName = obj.ParamEditor.Parameters.TrialSpecificNames{col};
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
      % CLEAR Clear all table data
      %  Clears all trial condition data from UI Table
      % 
      % See also EUI.PARAMEDITOR/BUILDUI, EUI.PARAMEDITOR/CLEAR
      set(obj.ConditionTable, 'ColumnName', [], ...
        'Data', [], 'ColumnEditable', false);
    end
    
    function delete(obj)
      % DELETE Deletes the UI container
      %   Called when this object or its parent ParamEditor is deleted
      % See also CLEAR
      delete(obj.UIPanel);
    end
    
    function onSelect(obj, ~, eventData)
      % ONSELECT Callback for when table cells are (de-)selected
      %   If at least one cell is selected, ensure buttons and menu items
      %   are enabled, otherwise disable them.
      if nargin > 2; obj.SelectedCells = eventData.Indices; end
      controls = ...
        [obj.MakeGlobalButton, ...
        obj.DeleteConditionButton, ...
        obj.SetValuesButton, ...
        obj.ContextMenus([1,3])];
      set(controls, 'Enable', iff(size(obj.SelectedCells, 1) > 0, 'on', 'off'));
    end

    function makeGlobal(obj)
      % MAKEGLOBAL Make condition parameter (table column) global
      %  Find all selected columns are turn into global parameters, using
      %  the value of the first selected cell as the global parameter
      %  value.
      %
      % See also eui.ParamEditor/globaliseParamAtCell
      if isempty(obj.SelectedCells)
        disp('nothing selected')
        return
      end
      PE = obj.ParamEditor;
      [cols, iu] = unique(obj.SelectedCells(:,2));
      names = PE.Parameters.TrialSpecificNames(cols);
      rows = num2cell(obj.SelectedCells(iu,1)); %get rows of unique selected cols
      cellfun(@PE.globaliseParamAtCell, names, rows);
      % If only numRepeats remains, globalise it
      if isequal(PE.Parameters.TrialSpecificNames, {'numRepeats'})
        PE.Parameters.Struct.numRepeats(1,1) = sum(PE.Parameters.Struct.numRepeats);
        PE.globaliseParamAtCell('numRepeats', 1)
      end
    end
    
    function deleteSelectedConditions(obj)
      %DELETESELECTEDCONDITIONS Removes the selected conditions from table
      % The callback for the 'Delete condition' button.  This removes the
      % selected conditions from the table and if less than two conditions
      % remain, globalizes them.
      %
      % See also EXP.PARAMETERS, GLOBALISESELECTEDPARAMETERS
      rows = unique(obj.SelectedCells(:,1));
      names = obj.ConditionTable.ColumnName;
      numConditions = size(obj.ConditionTable.Data,1);
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
          obj.ParamEditor.Parameters.removeConditions(rows);
          notify(obj.ParamEditor, 'Changed')
      end
      % Refresh the table of conditions
      obj.fillConditionTable();
    end
    
    function setSelectedValues(obj) 
      % SETSELECTEDVALUES Set multiple fields in conditional table at once
      %  Generates an input dialog for setting multiple trial conditions at
      %  once.  Also allows the use of function handles for more complex
      %  values.
      % 
      %  Examples:
      %   (1:10:100) % Sets selected rows to [1 11 21 31 41 51 61 71 81 91]
      %   @(~)randi(100) % Assigned random integer to each selected row
      %   @(a)a*50 % Multiplies each condition value by 50
      %   false % Sets all selected rows to false
      % 
      % See also SETNEWVALS, ONEDIT
      PE = obj.ParamEditor;
      cols = obj.SelectedCells(:,2); % selected columns
      uCol = unique(obj.SelectedCells(:,2));
      rows = obj.SelectedCells(:,1); % selected rows
      % get current values of selected cells
      currVals = arrayfun(@(u)obj.ConditionTable.Data(rows(cols==u),u), uCol, 'UniformOutput', 0);
      names = PE.Parameters.TrialSpecificNames(uCol); % selected column names
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
            cellfun(@(a)PE.controlValue2Param(2,a),...
            currVals(length(newVals)+1:end),'UniformOutput',0)];
        end
        ic = strcmp(PE.Parameters.TrialSpecificNames, paramName); % find edited param names
        % update param struct
        PE.Parameters.Struct.(paramName)(:,rows(cols==find(ic))) = cell2mat(newVals);
        % update condtion table with strings
        obj.ConditionTable.Data(rows(cols==find(ic)),ic)...
          = cellfun(@(a)PE.paramValue2Control(a), newVals', 'UniformOutput', 0);
      end
      notify(obj.ParamEditor, 'Changed');
    end
    
    function sortByColumn(obj)
      % SORTBYCOLUMN Sort all conditions by selected column
      %  If the selected column is already sorted in ascended order then
      %  the conditions are ordered in descending order instead.
      %  TODO Sort by multiple columns
      %  @body currently all conditions are sorted by first selected column
      if isempty(obj.SelectedCells)
        disp('nothing selected')
        return
      end
      PE = obj.ParamEditor;
      % Get selected column name and retrieve data
      cols = unique(obj.SelectedCells(:,2));
      names = PE.Parameters.TrialSpecificNames(cols);
      toSort = PE.Parameters.Struct.(names{1});
      direction = iff(issorted(toSort','rows'), 'descend', 'ascend');
      [~, I] = sortrows(toSort', direction);
      % Update parameters with new permutation
      for p = PE.Parameters.TrialSpecificNames'
        data = PE.Parameters.Struct.(p{:});
        PE.Parameters.Struct.(p{:}) = data(:,I);
      end
      obj.fillConditionTable % Redraw table
    end
    
    function fillConditionTable(obj)
      % FILLCONDITIONTABLE Build the condition table
      %  Populates the UI Table with trial specific parameters, where each
      %  row is a trial condition (that is, a parameter column) and each
      %  column is a different trial specific parameter
      P = obj.ParamEditor.Parameters;
      titles = P.title(P.TrialSpecificNames);
      [~, trialParams] = P.assortForExperiment;
      if isempty(titles)
        obj.ButtonPanel.Visible = 'off';
        obj.UIPanel.Visible = 'off';
        obj.ParamEditor.Parent.Widths = [-1, 1];
      else
        obj.ButtonPanel.Visible = 'on';
        obj.UIPanel.Visible = 'on';
        obj.ParamEditor.Parent.Widths = [-1, -1];
      end
      data = reshape(struct2cell(trialParams), numel(titles), [])';
      data = mapToCell(@(e) obj.ParamEditor.paramValue2Control(e), data);
      set(obj.ConditionTable, 'ColumnName', titles, 'Data', data,...
        'ColumnEditable', true(1, numel(titles)));
    end
    
    function newCondition(obj)
      % Adds a new trial condition (row) to the ConditionTable
      %  Adds new row and populates it with sensible 'default' values.
      %  These are mostly zeros or empty values.  
      % See also eui.ParamEditor/addEmptyConditionToParam
      PE = obj.ParamEditor;
      cellfun(@PE.addEmptyConditionToParam, ...
        PE.Parameters.TrialSpecificNames);
      obj.fillConditionTable();
    end
    
  end
  
end