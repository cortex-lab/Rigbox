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
    end
  end
  
end

