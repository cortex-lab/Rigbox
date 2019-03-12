classdef ParamEditor < handle
  %UNTITLED2 Summary of this class goes here
  %   ParamEditor deals with setting the paramters via a GUI
  
  properties
    Parameters
  end
  
  properties (Access = {?eui.ConditionPanel, ?eui.FieldPanel})
    UIPanel
    GlobalUI
    ConditionalUI
    Parent
    Root
    Listener
  end
  
  properties (Dependent)
    Enable
  end
  
  events
    Changed
  end
  
  methods
    function obj = ParamEditor(pars, parent)
      if nargin == 0; pars = []; end
      if nargin < 2
        parent = figure('Name', 'Parameters', 'NumberTitle', 'off',...
          'Toolbar', 'none', 'Menubar', 'none', 'DeleteFcn', @(~,~)obj.delete);
      end
      obj.Root = parent;
      while ~isa(obj.Root, 'matlab.ui.Figure'); obj.Root = obj.Root.Parent; end
%       obj.Listener = event.listener(parent, 'SizeChanged', @(~,~)obj.onResize);
      obj.Parent = uix.HBox('Parent', parent);
      obj.GlobalUI = eui.FieldPanel(obj.Parent, obj);
      obj.ConditionalUI = eui.ConditionPanel(obj.Parent, obj);
      obj.buildUI(pars);
      % FIXME Current hack for drawing params first time
      pos = obj.Root.Position;
      obj.Root.Position = pos+0.01;
      obj.Root.Position = pos;
    end
    
    function selected = getSelected(obj)
      % GETSELECTED Return the object currently in focus
      %  Returns handle to the object currently in focus in the figure,
      %  that is, the object last clicked on by the user.  This is used by
      %  the FieldPanel context menu to determine which parameter was
      %  selected.
      %
      % See also EUI.FIELDPANEL
      selected = obj.Root.CurrentObject;
    end
    
    function delete(obj)
      delete(obj.GlobalUI);
      delete(obj.ConditionalUI);
    end
        
    function set.Enable(obj, value)
      cUI = obj.ConditionalUI;
      parent = obj.Parent; % FIXME: use tags instead?
      if value == true
        arrayfun(@(prop) set(prop, 'Enable', 'on'), findobj(parent,'Enable','off'));
        if isempty(cUI.SelectedCells)
          set(cUI.MakeGlobalButton, 'Enable', 'off');
          set(cUI.DeleteConditionButton, 'Enable', 'off');
          set(cUI.SetValuesButton, 'Enable', 'off');
        end
        obj.Enable = true;
      else
        arrayfun(@(prop) set(prop, 'Enable', 'off'), findobj(parent,'Enable','on'));
        obj.Enable = false;
      end
    end
    
    function clear(obj)
      clear(obj.GlobalUI);
      clear(obj.ConditionalUI);
    end
    
    function buildUI(obj, pars)
      obj.Parameters = pars;
      obj.clear() % Clear the current parameter UI elements
      if isempty(pars); return; end % Nothing to build
      c = obj.GlobalUI; % Handle to FieldPanel object
      names = pars.GlobalNames; % Names of the global parameters
      for nm = names'
        % RandomiseConditions is a special parameter represented in the
        % context menu, don't create global param field
        if strcmp(nm, 'randomiseConditions'); continue; end
        if islogical(pars.Struct.(nm{:})) % If parameter is logical, make checkbox
          ctrl = uicontrol('Parent', c.UIPanel, 'Style', 'checkbox', ...
            'Value', pars.Struct.(nm{:}));
          addField(c, nm{:}, ctrl);
        else % Otherwise create the default field; a text box
          [~, ctrl] = addField(c, nm{:});
          ctrl.String = obj.paramValue2Control(pars.Struct.(nm{:}));
        end
      end
      % Populate the trial conditions table
      obj.ConditionalUI.fillConditionTable();
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
        obj.updateGlobal('randomiseConditions', logical(value));
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
        
    function addEmptyConditionToParam(obj, name)
      % Add a new trial specific condition to the table
      % See also EUI.CONDITIONPANEL/NEWCONDITION
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
    
    function newValue = updateGlobal(obj, name, value, row)
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
      obj.ConditionalUI.fillConditionTable;
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
      % ONRESIZE Resize widths of the two panels
      %  To maximize space resize the widths of the Conditional and Global
      %  panels
      %
      % FIXME Resize buggy due to tolerences
      
      % If there are no conditional params assume Condition table is hidden
      % and GlobalUI takes up all space
      if numel(obj.Parameters.TrialSpecificNames) == 0; return; end
      cUI = obj.ConditionalUI.UIPanel;
      gUI = obj.GlobalUI.UIPanel;
      
      % The position of the end column in the Global panel (in pixels)
      pos = obj.GlobalUI.Controls(end).Position;
      colExtent = pos(1) + pos(3) + obj.GlobalUI.Margin;
      colWidth = pos(3) + obj.GlobalUI.Margin + obj.GlobalUI.ColSpacing; % FIXME: inaccurate
      % The amount of space the Global panel takes up in pixels
      pos = getpixelposition(gUI);
      gUIExtent = pos(3);
      % The amount of space the Conditional panel takes up in pixels
      pos = getpixelposition(cUI);
      cUIExtent = pos(3);
      % The actual extent of the table in pixels
      extent = get(obj.ConditionalUI.ConditionTable, 'Extent');
      requiredTableWidth = extent(3);
      
      if floor(gUIExtent - colExtent) <= 2 && cUIExtent < obj.ConditionalUI.MinWidth
        % No space at all. Compromise by having both panels take up half
        % the figure
        obj.Parent.Widths = [-1 -1];
      elseif floor(gUIExtent - colExtent) <= 2 && cUIExtent > obj.ConditionalUI.MinWidth
        % If global UI controls are cut off and there is no dead space in
        % the table but the minimum table width hasn't been reached, reduce
        % the conditional UI width: table has scroll bar and global panel
        % does not
        minRequiredGlobal = cUIExtent - (colExtent - gUIExtent);
        if minRequiredGlobal < obj.ConditionalUI.MinWidth && sign(minRequiredGlobal) == 1
          % If the extra space taken by Global doesn't reduce Conditional
          % beyond its minimum, use the Global's minimum
          obj.Parent.Widths = [colExtent -1];
        elseif minRequiredGlobal > requiredTableWidth && sign(minRequiredGlobal) == 1
          % If the required width is smaller that the required table width,
          % use required table width
          obj.Parent.Widths = [-1 requiredTableWidth];
        else
          % If the required width is smaller that the minimum table width,
          % use minimum table width
          obj.Parent.Widths = [-1 obj.ConditionalUI.MinWidth];
        end
      elseif requiredTableWidth < cUIExtent && colWidth < obj.GlobalUI.MaxCtrlWidth
        % If there is dead table space and the global UI columns are cut
        % off or squashed, reduce the conditional panel
        % If the extra space is minimum, return
        if floor(cUIExtent - requiredTableWidth) <= 2 && ...
            sign(floor(cUIExtent - requiredTableWidth)) == 1
          return
        end
        obj.Parent.Widths = [colExtent -1];%[-1 requiredTableWidth];
      elseif requiredTableWidth < cUIExtent && colExtent < gUIExtent
        % Plenty of space! Increase conditional UI a bit
        deadspace = gUIExtent - colExtent; % Spece between panels in pixels
        obj.Parent.Widths = [-1 cUIExtent +  deadspace/2];
      elseif requiredTableWidth >= cUIExtent && colExtent < gUIExtent
        % If the table space is cut off and there is dead space in the
        % global UI panel, reduce the global UI panel
        % If the extra space is minimum, return
        if floor(gUIExtent - colExtent) <= 2; return; end
        % Get total space
        deadspace = gUIExtent - colExtent; % Spece between panels in pixels
        obj.Parent.Widths = [-1 cUIExtent + (deadspace/2)];
%         cUI.Position(3) = 1-gUI.Position(3);
%         cUI.Position(1) = gUI.Position(3);
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

