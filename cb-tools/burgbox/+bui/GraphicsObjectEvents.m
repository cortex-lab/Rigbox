classdef GraphicsObjectEvents < handle
  %BUI.GRAPHICSOBJECTEVENTS Generator of events on a graphics object
  %   This object contains subscribable events relating to a particular
  %   grpahics object
  %
  % Part of Burgbox

  % 2013-01 - CB created
  
  properties
  end
  
  properties (SetAccess = private)
    Handle %Handle to the graphics object
  end

  events
    MouseMotion
    MouseButtonUp
    MouseButtonDown
  end
  
  methods
    function obj = GraphicsObjectEvents(graphicsHandle)
      setappdata(graphicsHandle, 'Events', obj);
      set(graphicsHandle, 'WindowButtonMotionFcn', @obj.callMotionListeners);
      set(graphicsHandle, 'WindowButtonDownFcn', @obj.callMouseButtonDownListeners);
      set(graphicsHandle, 'WindowButtonUpFcn', @obj.callMouseButtonUpListeners);
      obj.Handle = graphicsHandle;
    end
  end
  
  methods (Access = private)
    function callMouseButtonDownListeners(obj, src, evt)
      notify(obj, 'MouseButtonDown', bui.MouseEvent(src));
    end

    function callMouseButtonUpListeners(obj, src, evt)
      notify(obj, 'MouseButtonUp', bui.MouseEvent(src));
    end

    function callMotionListeners(obj, src, evt)
      notify(obj, 'MouseMotion', bui.MouseEvent(src));
    end
  end
  
end
