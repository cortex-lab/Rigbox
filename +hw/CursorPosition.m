classdef CursorPosition < hw.PositionSensor
  %HW.CURSORPOSITION Tracks mouse cursor position along a direction
  %   Returns the current mouse cursor position as projected
  % along ProjectionDir
  %
  % Part of Rigbox

  % 2012-10 CB created
  
  properties
    ProjectionDir = 0 %direction in radians along which position is tracked
    Window = [] %window to find mouse cursor position in
  end

  properties (Access = protected)
    LastAbsPosition = 0
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
%       ptbScreen = max(Screen('Screens'));
%       screenBounds = Screen('Rect', ptbScreen);
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
  end
  
end