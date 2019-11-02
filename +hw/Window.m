classdef Window < handle
  %Window Some window on a device you can draw to
  %   This is an abstract base class for some device you draw to. All
  %   drawing should be done first to an "off-screen" buffer, and only 
  %   "flipped" onto screen when you request it. i.e. no drawing will be
  %   visible while you call the drawing/painting but will appear at once
  %   when you call the flip function.
  %
  % Part of Rigbox

  % 2012-10 CB created

  properties (Abstract)
    BackgroundColour %background colour to apply to the window
    ForegroundColour %default colour to use for drawing
  end
  
  properties (Abstract, SetAccess = protected)
    White %the value for white (highest)
    Gray %the value for mid-gray
    Black %the value for black (lowest)
    Red %the value for red
    Green %the value for green
    Blue %the value for blue
    ColourRange %the range from lowest to highest
    %Bounding rectangle [left top right bottom] for this window
    Bounds
    Invalid %True or false: anything drawn since last flip?
    TimeInvalidated %Time this window was last invalidated
  end
  
  properties (SetAccess = protected)
    %List of reasons for invalidations that accrue until a flip occurs, at
    %which point the list becomes associated with that screen update (i.e.
    %a list of changes which were made during the update).
    InvalidationUpdates = {}
  end
  
  methods (Abstract)
    % Opens a window into which stimuli can be drawn
     open(obj)
     
     % Closes the window if currently open
     close(obj)
    
     % Flips offscreen buffer to window, "validating" it
     % 
     % [TIME, INVALIDFRAMES, VALIDATIONLAG] = flip(WHEN) performs flip as
     % close to system time, WHEN, as possible. Returns the time the
     % flipped actually occured (TIME), the whole number of frames (rounded 
     % down) since the last invalidation (INVALIDFRAMES), and the time for
     % the last invalidation to completion of this flip (zero if the window
     % was still valid).
     %
     % [TIME, INVALIDFRAMES, VALIDATIONLAG] = flip() as above, but performs 
     % flip as soon as possible
    [time, invalidFrames, validationLag] = flip(obj, when)
    
    % Clears to background colour
    clear(obj)
    
    % Draws a texture
    %
    % drawTexture(TEX, SRCRECT, DESTRECT, ANGLE, GLOBALALPHA)
    drawTexture(obj, tex, srcRect, destRect, angle, globalAlpha)
    
    % Fills rectangular region with a colour
    %
    % fillRect(COLOUR, RECT)
    fillRect(obj, colour, rect)

    % Creates the texture on this device from an image matrix
    tex = makeTexture(obj, image)
    
    % Deletes any textures created on this device
    deleteTextures(obj)
    
    % Changes alpha blending factors
    [oldSrcFactor, oldDestFactor] = setAlphaBlending(obj, srcFactor, destFactor)
    
    % Draws text to the screen
    [nx, ny] = drawText(obj, text, x, y, colour, vSpacing, wrapAt)
  end
  
  methods
    function invalidate(obj, description)
      if nargin >= 2 && ~isempty(description)
        obj.InvalidationUpdates = [obj.InvalidationUpdates, description];
      end
      if ~obj.Invalid
        obj.TimeInvalidated = GetSecs;
        obj.Invalid = true;
      end
    end
  end

end

