classdef Selector < handle
  %BUI.SELECTOR Popup selector between options
  %   Class for a popup menu uicontrol that allows selection between a list
  %   of options. Each element of the Option property is converted to a
  %   string using char(...) (or num2str(...) if it's a numeric element)
  %   and displayed in the popup/dropdown box.
  %
  % Part of Burgbox

  % 2012-12 CB created
  
  properties
    UIControl% handle for underlying selector uicontrol (maybe a child of Handle)
  end
  
  properties (SetAccess = private)
    Handle % handle for root container
  end
  
  properties (Dependent = true)
    Selected
    SelectedIdx
    Option %Array of options to select from
  end
  
  properties (Access = private)
    pOption
  end
  
  events
    SelectionChanged
  end
  
  methods
    function op = get.Option(obj)
      op = obj.pOption;
    end
    
    function sel = get.Selected(obj)
      if ~isempty(obj.Option)
        if iscell(obj.Option)
          sel = obj.Option{get(obj.UIControl, 'Value')};
        else
          sel = obj.Option(get(obj.UIControl, 'Value'));
        end
      else
        sel = [];
      end
    end
    
    function sel = get.SelectedIdx(obj)
      if ~isempty(obj.Option)
        sel = get(obj.UIControl, 'Value');
      else
        sel = [];
      end
    end
    
    function set.SelectedIdx(obj, idx)
      if ~isempty(obj.Option)
        if idx ~= get(obj.UIControl, 'Value')
          set(obj.UIControl, 'Value', idx);
          notify(obj, 'SelectionChanged');
        end
      end
    end
    
    function set.Selected(obj, s)
      if ischar(s)
        idx = find(strcmp(s, obj.Option), 1);
      elseif iscell(obj.Option)
        idx = find(cellfun(@(e) e == s, obj.Option), 1);
      else
        idx = find(obj.Option == s, 1);
      end
      assert(~isempty(idx), 'Passed value is not an option');
      if idx ~= get(obj.UIControl, 'Value')
        set(obj.UIControl, 'Value', idx);
        notify(obj, 'SelectionChanged');
      end
    end
    
    function set.Option(obj, op)
      if ischar(op)
        op = {op};
      end
      sel = obj.Selected; %get currently selected option
%       eqfun = @(a,b) iff(ischar(a) || ischar(b),...
%         @() strcmp(a, b),...
%         @() iff(~isempty(a) && ~isempty(b), @() a == b, false));
      eqfun = @isequal;
      labelfun = @(v) iff(isnumeric(v), @() num2str(v), char(v));
      obj.pOption = op; %change the options
      labels = mapToCell(labelfun, op); %get labels for new options
      
      idx = find(cell2mat(mapToCell(@(a) eqfun(a, sel), obj.pOption)), 1);
      if isempty(idx)
        idx = 1;
        notify(obj, 'SelectionChanged');
      end
      if ~isempty(labels)
        %set control with labels
        set(obj.UIControl, 'String', labels, 'Value', idx, 'enable', 'on'); 
      else
        %set control to inactive since empty options was passed
        set(obj.UIControl, 'String', {'-'}, 'Value', 1, 'enable', 'off'); 
      end
    end

    function obj = Selector(parent, option)
      buildUI(obj, parent);
      obj.Option = option;
%       obj.addlistener('SelectionChanged', @(src, evt) disp(src.Selected));
    end
    
    function delete(obj)
      if ishandle(obj.UIControl)
        delete(obj.UIControl);
      end
    end
  end
  
  methods (Access = protected)
    function uiCallback(obj, ~, ~)
      notify(obj, 'SelectionChanged');
    end

    function buildUI(obj, parent)
      vbox = uiextras.VBox('Parent', parent);
%       obj.Handle = vbox.UIContainer; % No longer present, called uipanel('Parent', gcf(), 'Units', 'Normalized', 'BorderType', 'none')
      obj.Handle = vbox.Parent; % added by MW 2017-02-13
      obj.UIControl = uicontrol('Parent', vbox, 'Style', 'popupmenu',...
        'String', {''}, 'Callback', @obj.uiCallback);
    end
  end
  
end

