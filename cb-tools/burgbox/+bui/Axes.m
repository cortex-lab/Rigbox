classdef Axes < handle
  %BUI.AXES Axes control
  %   Detailed explanation goes here
  %
  % Part of Burgbox
  
  % 2012-12 CB created
    
  properties
    
  end

  properties (SetAccess = private, Hidden)
    Handle % matlab axes handle for this component
  end
  
  properties (SetAccess = private, GetAccess = protected)
    MousePressed = false
    MouseDragging = false
    MouseOver = false    
    Figure
  end % read-only protected properties
  
  properties (Dependent = true)
    Position
    XLim
    YLim
    CLim
    XTickLabel
    YTickLabel
    NextPlot
    DataAspectRatio
    ActivePositionProperty
    Title
  end
  
  properties (Dependent = true, SetAccess = private)
    FigurePixelPosition
    PixelPosition
  end
  
  properties (Access = private)
    Listeners
    pTitle
  end
  
  events
    MouseDragged
    MouseDragEnded
    MouseButtonDown
    MouseButtonUp
    MouseMoved
    MouseEntered
    MouseLeft
  end

  methods
    function obj = Axes(args)
      % args is either a handle to the parent, or to an already created
      % axes handle which will become the axes we wrap
      if nargin < 1
        args = gcf;
      end
      obj.Figure = bui.parentFigure(args);
      figureEvents = bui.events(obj.Figure);
      obj.Listeners = [...
        event.listener(figureEvents, 'MouseMotion', @obj.processMouseMovement)
        event.listener(figureEvents, 'MouseButtonUp', @obj.processMouseButtonUp)
        event.listener(figureEvents, 'MouseButtonDown', @obj.processMouseButtonDown)];
      if ishandle(args) && strcmp(get(args, 'type'), 'axes')
         obj.Handle = args;
      else
        obj.Handle = axes('Parent', args);
      end
    end
    
    function delete(obj)
      disp('deleting axes figure listeners, and axes handle');
      delete(obj.Listeners);
      if ishandle(obj.Handle)
        delete(obj.Handle);
      end
    end
    
    function [varargout] = line(obj, varargin)
      h = line(varargin{:}, 'Parent', obj.Handle);
      if nargout > 0
        varargout{1} = h;
      end
    end
    
    function [varargout] = imagesc(obj, varargin)
      h = imagesc(varargin{:}, 'Parent', obj.Handle);
      if nargout > 0
        varargout{1} = h;
      end
    end
    
    function [varargout] = plot(obj, varargin)
      h = plot(obj.Handle, varargin{:});
      if nargout > 0
        varargout{1} = h;
      end
    end
    
    function [varargout] = plot3(obj, varargin)
      h = plot3(obj.Handle, varargin{:});
      if nargout > 0
        varargout{1} = h;
      end
    end
    
    function [varargout] = surf(obj, varargin)
      h = surf(obj.Handle, varargin{:});
      if nargout > 0
        varargout{1} = h;
      end
    end
    
    function clear(obj, varargin)
      cla(obj.Handle, varargin{:});
    end
    
    function [varargout] = scatter(obj, varargin)
      h = scatter(obj.Handle, varargin{:});
      if nargout > 0
        varargout{1} = h;
      end
    end
    
    function h = yLabel(obj, str)
      h = ylabel(obj.Handle, str);
    end
    
    function h = xLabel(obj, str)
      h = xlabel(obj.Handle, str);
    end
    
    function h = zLabel(obj, str)
      h = zlabel(obj.Handle, str);
    end
    
    function value = get.NextPlot(obj)
      value = get(obj.Handle, 'NextPlot');
    end
    
    function set.NextPlot(obj, value)
       set(obj.Handle, 'NextPlot', value);
    end
    
    function value = get.Title(obj)
      value = obj.pTitle;
    end
    
    function set.Title(obj, value)
      title(obj.Handle, value);
      obj.pTitle = value;
    end
    
    function value = get.Position(obj)
      value = get(obj.Handle, 'Position');
    end
    
    function value = get.DataAspectRatio(obj)
      value = get(obj.Handle, 'DataAspectRatio');
    end
    
    function set.DataAspectRatio(obj, value)
      set(obj.Handle, 'DataAspectRatio', value);
    end
    
    function value = get.XLim(obj)
      value = get(obj.Handle, 'XLim');
    end
    
    function set.XLim(obj, value)
      set(obj.Handle, 'XLim', sort(value));
    end
    
    function value = get.CLim(obj)
      value = get(obj.Handle, 'CLim');
    end
    
    function set.CLim(obj, value)
      set(obj.Handle, 'CLim', sort(value));
    end
    
    function value = get.XTickLabel(obj)
      value = get(obj.Handle, 'XTickLabel');
    end
    
    function set.XTickLabel(obj, value)
      set(obj.Handle, 'XTickLabel', value);
    end
    
    function value = get.YTickLabel(obj)
      value = get(obj.Handle, 'YTickLabel');
    end
    
    function set.YTickLabel(obj, value)
      set(obj.Handle, 'YTickLabel', value);
    end
    
    function value = get.YLim(obj)
      value = get(obj.Handle, 'YLim');
    end
    
    function set.YLim(obj, value)
      set(obj.Handle, 'YLim', sort(value));
    end
    
    function value = get.ActivePositionProperty(obj)
      value = get(obj.Handle, 'ActivePositionProperty');
    end
    
    function set.ActivePositionProperty(obj, value)
      set(obj.Handle, 'ActivePositionProperty', value);
    end
    
    function value = get.PixelPosition(obj)
      value = getpixelposition(obj.Handle);
    end
    
    function value = get.FigurePixelPosition(obj)
      value = getpixelposition(obj.Handle, true);
    end
    
    function set.Position(obj, pos)
      set(obj.Handle, 'Position', pos);
    end
    
    function h = text(obj, varargin)
      h = text(varargin{:}, 'Parent', obj.Handle);
    end
  end
  
  methods (Access = private)
    function r = axisBounds(obj)
      xlim = obj.XLim;
      ylim = obj.YLim;
      r = [xlim(1) ylim(1) diff(xlim) diff(ylim)];
    end
    
    function processMouseButtonDown(obj, src, evt)
      if obj.MouseOver
        obj.MousePressed = true; % mouse pressed over the axes
        notify(obj, 'MouseButtonDown', bui.MouseEvent(obj.Handle));
      end
    end
    
    function processMouseButtonUp(obj, src, evt)
      obj.MousePressed = false;
      if obj.MouseOver
        notify(obj, 'MouseButtonUp');
      end
      if obj.MouseDragging
        obj.MouseDragging = false;
        notify(obj, 'MouseDragEnded');
      end
    end

    function processMouseMovement(obj, src, evt)
      oldMouseOver = obj.MouseOver;
%       withinBounds = bui.bounded(evt.CurrentPos, obj.FigurePixelPosition);
      p = get(obj.Handle, 'CurrentPoint')';
      obj.MouseOver = bui.bounded(p(1:2), axisBounds(obj));
      
      if obj.MouseOver && ~oldMouseOver
        notify(obj, 'MouseEntered', bui.MouseEvent(obj.Handle));
      elseif ~obj.MouseOver && oldMouseOver
        notify(obj, 'MouseLeft');
      end
      if obj.MouseOver
        notify(obj, 'MouseMoved', bui.MouseEvent(obj.Handle));
      end
      % if the mouse button was pressed without release over axes then
       % this is a dragging event
      if obj.MousePressed
        obj.MouseDragging = true;
        notify(obj, 'MouseDragged', bui.MouseEvent(obj.Handle));
      end
    end
  end
    
end

