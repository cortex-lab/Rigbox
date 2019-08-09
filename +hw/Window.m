classdef (Abstract) Window < handle
%HW.WINDOW A window on a computer screen to draw to
%
%  All drawing should initially occur on an off-screen buffer, and only 
%  be flipped onto the window when requested (i.e. drawings will only
%  appear on-screen after calling a method to create the drawing AND
%  calling a separate method to flip the drawing onto the window). This
%  class relies on Psychtoolbox (PTB) for some functionality.
%
% *Note, whenever "time" is mentioned in this file, assume it is given in
% seconds by PTB's `GetSecs` unless otherwise specified.
%
% Part of Rigbox
%
% 2012-10 CB created

  properties (Abstract)
    % A numeric array [R G B] of the background colour of the window
    BackgroundColour
    % A numeric array [R G B] of the default colour to use for drawing
    ForegroundColour 
  end
  
  properties (Abstract, SetAccess = protected)
    % The value for white (highest)
    White 
    % The value for mid-gray
    Gray 
    % The value for black (lowest)
    Black 
    % The value for red
    Red 
    % The value for green
    Green 
    % The value for blue
    Blue 
    % The colour range from lowest to highest
    ColourRange 
    % A numeric array [left top right bottom] in pixels for the bounding
    % rectangle of the window on-screen
    Bounds 
    % A boolean flag set to true if anything has been drawn since the last
    % screen flip, and false otherwise
    Invalid 
    % A numeric of the time the window was last invalidated (i.e. the time
    % the off-screen buffer was last drawn to)
    TimeInvalidated
  end
  
  properties (SetAccess = protected)
    % A cell string list of reasons for invalidations that accrue until a 
    % flip occurs, at which point the list becomes associated with that 
    % screen flip (i.e. a list of changes which were made during the flip).
    InvalidationUpdates = {}
  end
  
  methods (Abstract)
    % Flips drawing from off-screen buffer to window, validating window
    %
    % Inputs:
    %   `when`: an optional input numeric of the time to perform the screen flip. 
    %   If not included, `flip` performs the flip as soon as possible.
    %
    % Outputs:
    %   `time`: The time the flip occurs.
    %   `invalidFrames`: The number of frames since the flip occurred.
    %   `validationLag`: The time from the last invalidation to the flip
    %   (i.e. the time from completing the drawing on the off-screen
    %   buffer to flipping to the window).
    [time, invalidFrames, validationLag] = flip(obj, when)
    
    % Clears to background colour
    clear(obj)
    
    % Draws a texture to off-screen buffer
    %
    % Inputs:
    %   `tex`: 
    %   `srcRect`:
    %   `destRect`:
    %   `angle`: 
    %   `globalAlpha`: 
    drawTexture(obj, tex, srcRect, destRect, angle, globalAlpha)
    
    % Fills off-screen buffer's rectangular bounds with a colour
    %
    % Inputs:
    %   `colour`:
    %   `rect`: 
    fillRect(obj, colour, rect)

    % Creates a texture on off-screen buffer from an image matrix
    %
    % Inputs:
    %   `image`: a matrix...
    tex = makeTexture(obj, image)
    
    % Deletes all textures from off-screen buffer
    deleteTextures(obj)
    
    % Changes alpha blending factors
    %
    % Inputs:
    %   `srcFactor`:
    %   `destFactor`:
    [oldSrcFactor, oldDestFactor] = ...
      setAlphaBlending(obj, srcFactor, destFactor)
    
    % Draws text to off-screen buffer
    %
    % Inputs:
    %   `txt`: a char array of the text to draw
    %   `x`: 
    %   `y`:
    %   `colour`:
    %   `vSpacing`:
    %   `wrapAt`:
    [nx, ny] = drawText(obj, text, x, y, colour, vSpacing, wrapAt)  
  end
  
  
  methods
    function invalidate(obj, description)
    % Invalidates the window.
    %
    % `invalidate` is most often called when the off-screen buffer is drawn
    % to.
    %
    % Inputs:
    %   `description`: an optional char array that specifies the reason for
    %   the invalidation
      
    if nargin >= 2 && ~isempty(description)
      % add new invalidation message
      obj.InvalidationUpdates = [obj.InvalidationUpdates, description];
    end
    if ~obj.Invalid
      % invalidate window
      obj.TimeInvalidated = GetSecs;
      obj.Invalid = true;
    end
  end
  end
  
end

