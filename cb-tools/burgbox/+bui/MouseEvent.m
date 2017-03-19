classdef MouseEvent < event.EventData
  %MouseEvent Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (SetAccess = protected)
    CurrentPos % cursor position at time of event
  end

  methods
    function obj = MouseEvent(graphicsHandle)
      switch get(graphicsHandle, 'type')
        case 'figure'
          obj.CurrentPos = get(graphicsHandle, 'CurrentPoint');
        case 'axes'
          p = get(graphicsHandle, 'CurrentPoint')';
          obj.CurrentPos = p(1:2);
      end
    end
  end
  
end

