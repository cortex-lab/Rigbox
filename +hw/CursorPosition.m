classdef CursorPosition < hw.PositionSensor
  %HW.CURSORPOSITION Tracks mouse cursor position along a direction
  %   Returns the current mouse cursor position as projected
  %   along ProjectionDir
  %
  % Part of Rigbox

  % 2012-10 CB created
  
  properties
    % Direction in radians along which position is tracked
    ProjectionDir = 0
    % Window to find mouse cursor position in
    Window hw.Window = hw.ptb.Window.empty
    % 
    FixedPosition matlab.lang.OnOffSwitchState = 'on'
    % 
    GetMouseFcn = @GetMouse
  end

  properties (Access = protected)
    LastAbsPosition = 0
    LastInBounds = 0
  end
  
  methods %(Access = protected)
    function [x, time] = readAbsolutePosition(obj)
      % read the current cursor position
      [mx, my] = GetMouse();
      time = obj.Clock.now;
      
%       % calc the centre pos of the screen
%       if ~isempty(obj.Window)
%         ptbScreen = obj.Window.PtbHandle;
%         screenBounds = obj.Window.Bounds;
%       else
%         ptbScreen = max(Screen('Screens'));
%         screenBounds = Screen('Rect', ptbScreen);
%       end
%       [centreX, centreY] = RectCenter(screenBounds);
      
      % cursor reset/offset position - somewhere to leave enough space for
      % movements of the cursor before it is set back there
      offsetX = 300;
      offsetY = 300;
      
      % set cursor to offset position
      SetMouse(offsetX, offsetY);
      
      % work out centre-offset coords
      dx = mx - offsetX;
      dy = my - offsetY;

      % work out projection
      dx = dx*cos(obj.ProjectionDir) + dy*sin(obj.ProjectionDir);

      % the new absolute position is the old one plus the new offset
      x = obj.LastAbsPosition + dx;
      obj.LastAbsPosition = x;
    end
    
    function [x, time] = getMouse(obj)
      % GETMOUSE Return mouse x co-ordinate over stimulus window only
      %  TODO Make into hw class
      
      % read the current cursor position
      [mx, my] = GetMouse();
      time = obj.Clock.now;
      
      if ~isempty(obj.Window)
        bounds = obj.Window.OpenBounds;
        withinBounds = ...
          mx >= bounds(1) && ...
          mx <= bounds(1) + bounds(3) && ...
          my >= bounds(2) && ...
          my <= bounds(2) + bounds(4);
        [offsetX, offsetY] = RectCenter(bounds);
      else
        withinBounds = true;
        % cursor reset/offset position - somewhere to leave enough space for
        % movements of the cursor before it is set back there
        [offsetX, offsetY] = deal(300);
      end
      
      % set cursor to offset position
      if obj.FixedPosition, SetMouse(offsetX, offsetY); end
      
      % work out projection
      x = mx*cos(obj.ProjectionDir) + my*sin(obj.ProjectionDir);
      dx = (x - obj.LastAbsPosition);
      obj.LastAbsPosition = x;
      if withinBounds
        x = obj.LastInBounds + dx;
        obj.LastInBounds = x;
      else
        x = obj.LastInBounds;
      end
    end
  end
  
end