classdef Log < handle
  %EUI.LOG UI control for viewing experiment log entries
  %   TODO
  %
  % Part of Rigbox

  % 2013-06 CB created

  properties
    Table % handle for the entries table
  end
  
  properties (SetAccess = private)
    Entry
    SelectedEntry
  end
  
  properties (Dependent = true)

  end
  
  properties (Access = private)
  end
  
  events
  end
  
  methods
    function obj = Log(parent)
      buildUI(obj, parent);
    end
    
    function setSubject(obj, subjectRef)
      obj.Entry = fliplr(dat.logEntries(subjectRef));
      fillTable(obj);
    end
    
    function refresh(obj)
      set(obj.Table, 'Data', obj.data);
    end
    
    function e = entriesByType(obj, type)
      e = obj.Entry(strcmp({obj.Entry.type}, type));
    end
    
    function delete(obj)
      if ishandle(obj.Table)
        delete(obj.Table);
      end
    end
  end
  
  methods (Access = protected)
    function fillTable(obj)
      set(obj.Table, 'ColumnName', obj.columnNames, 'Data', obj.data);
    end
    
    function d = data(obj)
      rows = mapToCell(@obj.formatRow, obj.Entry);
      d = reshape(cellflat(rows), [], numel(rows))';
    end
    
    function w = columnWidths(obj)
      %{date type value comments}
      w = {90 80 120 400};
    end
    
    function n = columnNames(obj)
      n = {'Date', 'Type', 'Value', 'Comments'};
    end
    
    function row = formatRow(obj, entry)
      date = datestr(entry.date, 'ddd dd/mm/yy');
      type = entry.type;
      value = entry.value;
      comments = entry.comments;
      switch entry.type
        case 'weight-grams'
          type = 'weight';
          value = sprintf('%.2fg', value);
        case 'experiment-ref'
          type = 'experiment';
        case 'experiment-info'
          type = 'experiment';
          value = value.ref;
        case 'watersupp-info'
          type = 'water supplement';
          value = sprintf('%.1f%s', value.volume, value.volumeUnits);
      end
      if isstruct(value)
        value = '[...]';
      end
      if size(comments, 1) > 1
        comments = mat2DStrTo1D(comments);
      end
      row = {date, type, value, comments};
    end
    
    function cellSelected(obj, ~, evt)
      obj.SelectedEntry = obj.Entry(evt.Indices(:,1));
    end

    function buildUI(obj, parent)
      vbox = uiextras.HBox('Parent', parent);
      
%       topbox = uiextras.HBox('Parent', vbox, 'Padding', 1);
      obj.Table = uitable('Parent', vbox,...
        'FontName', 'Consolas',...
        'ColumnName', obj.columnNames,...
        'RowName', [],...
        'ColumnWidth', obj.columnWidths,...
        'CellSelectionCallback', @obj.cellSelected);
      
%       obj.Table = uitable('Style', 'popupmenu', 'Enable', 'on',...
%         'String', {''},...
%         'Callback', @(src, evt) obj.showStack(get(src, 'Value')),...
%         'Parent', vbox);
%       
%       % set up the axes for displaying current frame image
%       obj.Axes = bui.Axes(vbox);
%       obj.Axes.ActivePositionProperty = 'Position';
%       obj.Image = imagesc(0, 'Parent', obj.Axes.Handle);
%       obj.Axes.XTickLabel = [];
%       obj.Axes.YTickLabel = [];
%       obj.Axes.DataAspectRatio = [1 1 1];
% 
%       % configure handling mouse events over axes to update selector cursor
%       obj.Axes.addlistener('MouseLeft',...
%         @(src, evt) handleMouseLeft(obj));
%       obj.Axes.addlistener('MouseMoved', @(src, evt) handleMouseMovement(obj, evt));
%       obj.Axes.addlistener('MouseButtonDown', @(src, evt) handleMouseDown(obj, evt));
%       obj.Axes.addlistener('MouseDragged', @(src, evt) handleMouseDragged(obj, evt));
% 
%       bottombox = uiextras.HBox('Parent', vbox, 'Padding', 1);
%       
%       obj.PlayButton = uicontrol('String', '|>',...
%         'Callback', @(src, evt) obj.playStack(),...
%         'Parent', topbox);
%       obj.StopButton = uicontrol('String', '||',...
%         'Callback', @(src, evt) obj.stopStack(),...
%         'Enable', 'off',...
%         'Parent', topbox);
%       obj.SpeedMenu = uicontrol('Style', 'popupmenu', 'Enable', 'on',...
%         'String', {'', '', '', '', ''},...
%         'Value', find(obj.PlaySpeed == 1, 1),...
%         'Parent', topbox,...
%         'Callback', @(s,e) obj.updatePlayStep());
%       
%       obj.FrameSlider = uicontrol('Style', 'slider', 'Enable', 'off',...
%         'Parent', bottombox,...
%         'Callback', @(src, ~) obj.showFrame(get(src, 'Value')));
%       obj.StatusText = uicontrol('Style', 'edit', 'String', '', ...,
%         'Enable', 'inactive', 'Parent', bottombox);
%       set(vbox, 'Sizes', [24 -1 24]);
%       set(topbox, 'Sizes', [-1 24 24 58]);
%       set(bottombox, 'Sizes', [-1 160]);
    end
  end
  
end

