classdef FieldPanel < handle
  %FIELDPANEL Deals with formatting global parameter UI elements
  %   Designed to be an element of the EUI.PARAMEDITOR class that manages
  %   the UI elements associated with all Global parameters.
  
  properties
    % Minimum allowable width (in pixels) for each UIControl element
    MinCtrlWidth = 40
    % Maximum allowable width (in pixels) for each UIControl element
    MaxCtrlWidth = 140
    % Space (in pixels) between parent container and parameter fields
    Margin = 4
    % Space (in pixels) between each parameter field row
    RowSpacing = 1
    % Space (in pixels) between each parameter field column
    ColSpacing = 3
    % Handle to parent UI container
    UIPanel
    % Handles to context menu option for making a parameter conditional
    ContextMenu
  end
  
  properties (Access = ?eui.ParamEditor)
    % Handle to EUI.PARAMEDITOR object
    ParamEditor
    % Minimum height (in pixels) of each field row.  See ONRESIZE
    MinRowHeight
    % Listener handle for when parent container is resized
    Listener
    % Array of UIControl labels
    Labels
    % Array of UIControl elements.  Either 'edit' or 'checkbox' controls
    Controls
    % Array widths, one for each label in Labels.  See ONRESIZE
    LabelWidths
  end
  
  methods
    function obj = FieldPanel(f, ParamEditor)
      % FIELDPANEL Panel UI for Global parameters 
      %  Input f may be a figure or other UI container object
      %  ParamEditor is a handle to an eui.ParamEditor object.
      % 
      % See also EUI.PARAMEDITOR, EUI.CONDITIONPANEL
      obj.ParamEditor = ParamEditor;
      p = uix.Panel('Parent', f, 'BorderType', 'none');
      obj.UIPanel = uipanel('Parent', p, 'BorderType', 'none',...
        'Position', [0 0 0.5 1]);
      obj.Listener = event.listener(obj.UIPanel, 'SizeChanged', @obj.onResize);
    end

    function [label, ctrl] = addField(obj, name, type)
      % ADDFIELD Adds a new field label and input control
      %  Adds a label and control element for representing Global
      %  parameters.  The input name should be identical to a parameter
      %  fieldname.  Type is an optional input specifying the style of
      %  uicontrol (default 'edit').  From this the label string title is
      %  derived using exp.Parameters/title.  Callbacks are added for the
      %  context menu and for edits
      %
      % See also ONEDIT, EXP.PARAMETERS/TITLE, EUI.PARAMEDITOR/BUILDUI
      if nargin < 3; type = 'edit'; end
      if isempty(obj.ContextMenu)
        obj.ContextMenu = uicontextmenu(obj.ParamEditor.Root);
        uimenu(obj.ContextMenu, 'Label', 'Make Conditional', ...
          'MenuSelectedFcn', @(~,~)obj.makeConditional);
      end
      props.TooltipString = obj.ParamEditor.Parameters.description(name);
      props.HorizontalAlignment = 'left';
      props.UIContextMenu = obj.ContextMenu;
      props.Parent = obj.UIPanel;
      props.Tag = name;
      title = obj.ParamEditor.Parameters.title(name);
      label = uicontrol('Style', 'text', 'String', title, props);
      ctrl = uicontrol('Style', type, props);
      callback = @(src,~)onEdit(obj, src, name);
      set(ctrl, 'Callback', callback);
      obj.Labels = [obj.Labels; label];
      obj.Controls = [obj.Controls; ctrl];
    end
    
    function onEdit(obj, src, id)
      % ONEDIT Callback for edits to field controls
      %  Updates the underlying parameter struct, changes the UI
      %  value/string and changes the label colour to red. The src object
      %  should be the edit or checkbox ui control that has been edited,
      %  and id is the unformatted parameter name (stored in the Tag
      %  property of the label and control elements).
      %
      % See also ADDFIELD, EUI.PARAMEDITOR/UPDATE
      switch get(src, 'style')
        case 'checkbox'
          newValue = logical(get(src, 'value'));
          obj.ParamEditor.update(id, newValue);
        case 'edit'
          % if successful update the control with default formatting and
          % modified colour
          newValue = obj.ParamEditor.update(id, get(src, 'string'));
          set(src, 'String', obj.ParamEditor.paramValue2Control(newValue));
      end
      changed = strcmp(src.Tag,{obj.Labels.Tag});
      obj.Labels(changed).ForegroundColor = [1 0 0];
    end
    
    function clear(obj, idx)
      % CLEAR Delete a parameter field
      %  Deletes the label and control elements at index idx.  If no index
      %  given, all controls are deleted.  
      if nargin == 1
        idx = true(size(obj.Labels));
      end
      delete(obj.Labels(idx))
      delete(obj.Controls(idx))
      obj.Labels(idx) = [];
      obj.LabelWidths(idx) = [];
      obj.Controls(idx) = [];
    end
    
    function makeConditional(obj, name)
      % MAKECONDITIONAL Make field parameter into a trial condition
      %  This function removes the selected field from the global UI panel
      %  and calls Condition UI to add a column to the trial condition
      %  table.  It also makes a change to the ParamEditor's Parameters via
      %  the makeTrialSpecific method.
      %
      %  While this function can be called with a parameter name, the
      %  FieldPanel object is normally a protected property of the
      %  ParamEditor class, and the only calls to this function are via the
      %  context menu callback function
      % 
      % See also eui.Parameters/makeTrialSpecific, eui.ConditionPanel/fillConditionTable
      if nargin == 1
        selected = obj.ParamEditor.getSelected();
        if isa(selected, 'matlab.ui.control.UIControl') && ...
            strcmp(selected.Style, 'text')
          name = selected.Tag;
        else % Assume control
          name = obj.Labels([obj.Controls]==selected).Tag;
        end
      end
      idx = strcmp(name,{obj.Labels.Tag});
      assert(~ismember(name, {'randomiseConditions'}), ...
        '%s can not be made a conditional parameter', name)
      
      obj.clear(idx);
      % FIXME The below code could be in a makeConditional method of
      % eui.ParamEditor, thus more clearly separating class functionality:
      % Editing the exp.Parameters object directly should only be done by
      % ParamEditor.  This would also make subclassing these panel classes
      % more straightforward
      obj.ParamEditor.Parameters.makeTrialSpecific(name);
      obj.ParamEditor.ConditionalUI.fillConditionTable();
      notify(obj.ParamEditor, 'Changed');
      obj.onResize;
    end
    
    function delete(obj)
      % DELETE Deletes the UI container
      %   Called when this object or its parent ParamEditor is deleted
      % See also CLEAR
      delete(obj.UIPanel);
    end
       
    function onResize(obj, ~, ~)
      % ONRESIZE Re-position field UI elements after container resize
      %  Calculates the positions all field labels and input controls.
      %  These are organised into rows and columns that maximize use of
      %  space.
      %
      % See also EUI.PARAMEDITOR/ONRESIZE
      if isempty(obj.Controls)
        return
      end
      if isempty(obj.LabelWidths) || numel(obj.LabelWidths) ~= numel(obj.Labels)
        ext = reshape([obj.Labels.Extent], 4, [])';
        obj.LabelWidths = ext(:,3);
        l = uicontrol('Parent', obj.UIPanel, 'Style', 'edit', 'String', 'something');
        obj.MinRowHeight = l.Extent(4);
        delete(l);
      end
            
%       %%% resize condition table
%       w = numel(obj.ConditionTable.ColumnName);
% %       nCols = max(cols);
% %       globalWidth = (fullColWidth * nCols) + borderwidth;
%       if w > 5; w = 0.5; else; w = 0.1 * w; end
%       obj.UI(2).Position = [1-w 0 w 1];
%       obj.UI(1).Position = [0 0 1-w 1];
      
      %%% general coordinates
      pos = getpixelposition(obj.UIPanel);
      borderwidth = obj.Margin;
      bounds = [pos(3) pos(4)] - 2*borderwidth;
      n = numel(obj.Labels);
      vspace = obj.RowSpacing;
      hspace = obj.ColSpacing;
      rowHeight = obj.MinRowHeight + 2*vspace;
      rowsPerCol = floor(bounds(2)/rowHeight);
      cols = ceil((1:n)/rowsPerCol)';
      ncols = cols(end);
      rows = mod(0:n - 1, rowsPerCol)' + 1;
      labelColWidth = max(obj.LabelWidths) + 2*hspace;
      ctrlWidthAvail = bounds(1)/ncols - labelColWidth;
      ctrlColWidth = max(obj.MinCtrlWidth, min(ctrlWidthAvail, obj.MaxCtrlWidth));
      fullColWidth = labelColWidth + ctrlColWidth;
      
      %%% coordinates of labels
      by = bounds(2) - rows*rowHeight + vspace + 1 + borderwidth;
      labelPos = [vspace + (cols - 1)*fullColWidth + 1 + borderwidth...
        by...
        obj.LabelWidths...
        repmat(rowHeight - 2*vspace, n, 1)];
    
      %%% coordinates of edits
      editPos = [labelColWidth + hspace + (cols - 1)*fullColWidth + 1 + borderwidth ...
        by...
        repmat(ctrlColWidth - 2*hspace, n, 1)...
        repmat(rowHeight - 2*vspace, n, 1)];
      set(obj.Labels, {'Position'}, num2cell(labelPos, 2));
      set(obj.Controls, {'Position'}, num2cell(editPos, 2));
      
    end
  end
  
end

