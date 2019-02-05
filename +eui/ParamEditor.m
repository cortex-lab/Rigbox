classdef ParamEditor < handle
  %UNTITLED2 Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    Parameters
  end
  
  properties %(Access = private)
    UIPanel
    GlobalUI
    ConditionalUI
    Parent
    Listener
  end
  
  properties (Dependent)
    Enable
  end
  
  events
    Changed
  end
  
  methods
    function obj = ParamEditor(pars, f)
      if nargin == 0; pars = []; end
      if nargin < 2
        f = figure('Name', 'Parameters', 'NumberTitle', 'off',...
          'Toolbar', 'none', 'Menubar', 'none', 'DeleteFcn', @(~,~)obj.delete);
        obj.Listener = event.listener(f, 'SizeChanged', @(~,~)obj.onResize);
      end
      obj.Parent = f;
      obj.UIPanel = uix.HBox('Parent', f);
      obj.GlobalUI = eui.FieldPanel(obj.UIPanel, obj);
      obj.ConditionalUI = eui.ConditionPanel(obj.UIPanel, obj);
      obj.buildUI(pars);
    end
    
    function delete(obj)
      delete(obj.GlobalUI);
      delete(obj.ConditionalUI);
    end
        
    function set.Enable(obj, value)
      cUI = obj.ConditionalUI;
      fig = obj.Parent;
      if value == true
        arrayfun(@(prop) set(prop, 'Enable', 'on'), findobj(fig,'Enable','off'));
        if isempty(cUI.SelectedCells)
          set(cUI.MakeGlobalButton, 'Enable', 'off');
          set(cUI.DeleteConditionButton, 'Enable', 'off');
          set(cUI.SetValuesButton, 'Enable', 'off');
        end
        obj.Enable = true;
      else
        arrayfun(@(prop) set(prop, 'Enable', 'off'), findobj(fig,'Enable','on'));
        obj.Enable = false;
      end
    end
    
    function clear(obj)
      clear(obj.GlobalUI);
      clear(obj.ConditionalUI);
    end
    
    function buildUI(obj, pars)
      obj.Parameters = pars;
      obj.clear()
      c = obj.GlobalUI;
      names = pars.GlobalNames;
      for nm = names'
        if strcmp(nm, 'randomiseConditions'); continue; end
        if islogical(pars.Struct.(nm{:})) % If parameter is logical, make checkbox
          ctrl = uicontrol('Parent', c.UIPanel, 'Style', 'checkbox', ...
            'Value', pars.Struct.(nm{:}), 'BackgroundColor', 'white');
          addField(c, nm{:}, ctrl);
        else
          [~, ctrl] = addField(c, nm{:});
          ctrl.String = obj.paramValue2Control(pars.Struct.(nm{:}));
        end
      end
      obj.fillConditionTable();
      %%% Special parameters
      if ismember('randomiseConditions', obj.Parameters.Names) && ~pars.Struct.randomiseConditions
        obj.ConditionalUI.ConditionTable.RowName = 'numbered';
        set(obj.ConditionalUI.ContextMenus(2), 'Checked', 'off');
      end
      obj.GlobalUI.onResize();
    end
    
    function setRandomized(obj, value)
      % If randomiseConditions doesn't exist and new value is false, add
      % the parameter and set it to false
      if ~ismember('randomiseConditions', obj.Parameters.Names) && value == false
        description = 'Whether to randomise the conditional paramters or present them in order';
        obj.Parameters.set('randomiseConditions', false, description, 'logical')
      elseif ismember('randomiseConditions', obj.Parameters.Names)
        obj.update('randomiseConditions', logical(value));
      end
      menu = obj.ConditionalUI.ContextMenus(2);
      if value == false
        obj.ConditionalUI.ConditionTable.RowName = 'numbered';
        menu.Checked = 'off';
      else
        obj.ConditionalUI.ConditionTable.RowName = [];
        menu.Checked = 'on';
      end
    end
    
    function fillConditionTable(obj)
      % Build the condition table
      titles = obj.Parameters.TrialSpecificNames;
      [~, trialParams] = obj.Parameters.assortForExperiment;
      if isempty(titles)
        obj.ConditionalUI.ButtonPanel.Visible = 'off';
        obj.ConditionalUI.UIPanel.Visible = 'off';
        obj.GlobalUI.UIPanel.Position(3) = 1;
      else
        obj.ConditionalUI.ButtonPanel.Visible = 'on';
        obj.ConditionalUI.UIPanel.Visible = 'on';
        data = reshape(struct2cell(trialParams), numel(titles), [])';
        data = mapToCell(@(e) obj.paramValue2Control(e), data);
        set(obj.ConditionalUI.ConditionTable, 'ColumnName', titles, 'Data', data,...
          'ColumnEditable', true(1, numel(titles)));
      end
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
    
    function newValue = update(obj, name, value, row)
      % FIXME change name to updateGlobal
      if nargin < 4; row = 1; end
      currValue = obj.Parameters.Struct.(name)(:,row);
      if iscell(currValue)
        % cell holders are allowed to be different types of value
        newValue = obj.controlValue2Param(currValue{1}, value, true);
        obj.Parameters.Struct.(name){:,row} = newValue;
      else
        newValue = obj.controlValue2Param(currValue, value);
        obj.Parameters.Struct.(name)(:,row) = newValue;
      end
      notify(obj, 'Changed');
    end
    
    function globaliseParamAtCell(obj, name, row)
      % Make parameter 'name' a global parameter and set it's value to be
      % that of the specified row.
      %
      % See also EXP.PARAMETERS/MAKEGLOBAL, UI.CONDITIONPANEL/MAKEGLOBAL
      value = obj.Parameters.Struct.(name)(:,row);
      obj.Parameters.makeGlobal(name, value);
      % Refresh the table of conditions
      obj.fillConditionTable;
      % Add new global parameter to field panel
      if islogical(value) % If parameter is logical, make checkbox
        ctrl = uicontrol('Parent', obj.GlobalUI.UIPanel, 'Style', 'checkbox', ...
          'Value', value, 'BackgroundColor', 'white');
        addField(obj.GlobalUI, name, ctrl);
      else
        [~, ctrl] = addField(obj.GlobalUI, name);
        ctrl.String = obj.paramValue2Control(value);
      end
      obj.GlobalUI.onResize();
      obj.notify('Changed');
    end
      
    function onResize(obj)
      %%% resize condition table
      notify(obj.ConditionalUI.ButtonPanel, 'SizeChanged');
      cUI = obj.ConditionalUI.UIPanel;
      gUI = obj.GlobalUI.UIPanel;
      
      pos = obj.GlobalUI.Controls(end).Position;
      colExtent = pos(1) + pos(3) + obj.GlobalUI.Margin;
      colWidth = pos(3) + obj.GlobalUI.Margin + obj.GlobalUI.ColSpacing; % FIXME: inaccurate
      pos = getpixelposition(gUI);
      gUIExtent = pos(3);
      pos = getpixelposition(cUI);
      cUIExtent = pos(3);
      
      extent = get(obj.ConditionalUI.ConditionTable, 'Extent');
      panelWidth = cUI.Position(3);
      if colExtent > gUIExtent && cUIExtent > obj.ConditionalUI.MinWidth
        % If global UI controls are cut off and there is no dead space in
        % the table but the minimum table width hasn't been reached, reduce
        % the conditional UI width: table has scroll bar and global panel
        % does not
        % FIXME calculate how much space required for min control width
%         obj.GlobalUI.MinCtrlWidth
        % Calculate conditional UI width in normalized units
        requiredWidth = (cUI.Position(3) / cUIExtent) * (colExtent - gUIExtent);
        minConditionalWidth = (cUI.Position(3) / cUIExtent) * obj.ConditionalUI.MinWidth;
        if requiredWidth < minConditionalWidth
          % If the required width is smaller that the minimum table width,
          % use minimum table width
          cUI.Position(3) = minConditionalWidth;
        else % Otherwise use this width
          cUI.Position(3) = requiredWidth;
        end
        cUI.Position(1) = 1-cUI.Position(3);
        gUI.Position(3) = 1-cUI.Position(3);
      elseif extent(3) < 1 && colWidth < obj.GlobalUI.MaxCtrlWidth
        % If there is dead table space and the global UI columns are cut
        % off or squashed, reduce the conditional panel
        cUI.Position(3) = cUI.Position(3) - (panelWidth - (panelWidth * extent(3)));
        cUI.Position(1) = cUI.Position(1) + (panelWidth - (panelWidth * extent(3)));
        gUI.Position(3) = cUI.Position(1);
      elseif extent(3) < 1 && colExtent < gUIExtent
        % Plenty of space! Increase conditional UI a bit
        deadspace = gUIExtent - colExtent; % Spece between panels in pixels
        % Convert global UI pixels to relative units
        gUI.Position(3) = (gUI.Position(3) / gUIExtent) * (gUIExtent - (deadspace/2));
        cUI.Position(1) = gUI.Position(3);
        cUI.Position(3) = 1-gUI.Position(3);
      elseif extent(3) >= 1 && colExtent < gUIExtent
        % If the table space is cut off and there is dead space in the
        % global UI panel, reduce the global UI panel
        % If the extra space is minimum, return
        if floor(gUIExtent - colExtent) <= 2; return; end
        deadspace = gUIExtent - colExtent; % Spece between panels in pixels
        gUI.Position(3) = (gUI.Position(3) / gUIExtent) * (gUIExtent - deadspace);
        cUI.Position(3) = 1-gUI.Position(3);
        cUI.Position(1) = gUI.Position(3);
      else
        % Compromise by having both panels take up half the figure
%         [cUI.Position([1,3]),  gUI.Position(3)] = deal(0.5);
      end
      notify(obj.ConditionalUI.ButtonPanel, 'SizeChanged');
    end
  end
  
  methods (Static)
    function data = paramValue2Control(data)
      % convert from parameter value to control value, i.e. a value class
      % that can be easily displayed and edited by the user.  Everything
      % except logicals are converted to charecter arrays.
      switch class(data)
        case 'function_handle'
          % convert a function handle to it's string name
          data = func2str(data);
        case 'logical'
          data = data ~= 0; % If logical do nothing, basically.
        case 'string'
          data = char(data); % Strings not allowed in condition table data
        otherwise
          if isnumeric(data)
            % format numeric types as string number list
            strlist = mapToCell(@num2str, data);
            data = strJoin(strlist, ', ');
          elseif iscellstr(data)
            data = strJoin(data, ', ');
          end
      end
      % all other data types stay as they are
    end
    
    function data = controlValue2Param(currParam, data, allowTypeChange)
      % Convert the values displayed in the UI ('control values') to
      % parameter values.  String representations of numrical arrays and
      % functions are converted back to their 'native' classes.
      if nargin < 4
        allowTypeChange = false;
      end
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

  end
end

