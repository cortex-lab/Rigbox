classdef Window < hw.Window
  %HW.PTB.WINDOW A Psychtoolbox Screen implementation of Window
  %   Detailed explanation goes here
  %
  % Part of Rigbox

  % 2012-10 CB created
  
  properties (Dependent)
    % Background colour of the stimulus window.  Can be a scalar luminance
    % value or an RGB vector.
    BackgroundColour
    % Name of DAQ vendor of device used for the sync pulse echo.  E.g. 'ni'
    DaqVendor
    % The device ID of device to output sync echo pulse on
    DaqDev
    % Channel to output sync echo on e.g. 'port0/line0'. Leave empty for
    % don't use the DAQ
    DaqSyncEchoPort
    % Flag indicating whether PsychToolbox window is open.  See 'Screen
    % OpenWindow?'
    IsOpen
  end
  
  properties
    ForegroundColour
    % Screen number to open window in. Screen 0 is always the full Windows
    % desktop.  Screens 1 to n are corresponding to windows display monitors
    % 1 to n.  See 'Screen Screens?'
    ScreenNum
    % The pixel colour depth (bits) - also known as bpp or bits per pixel,
    % not to spatial size of the pixel.  See 'Screen PixelSize?'
    PxDepth = 32
    % Default screen region to open window onscreen - empty for full.
    % [topLeftX topLeftY bottomRightX bottomRightY]
    OpenBounds
    % Position bounding rectangle of sync region - empty for none;
    % [topLeftX topLeftY bottomRightX bottomRightY]. See positionSyncRegion
    SyncBounds
    % Sync region [r g b], or luminance for each consecutive flip
    % (row-wise). Will repeat in a cycle. Default is white->black->....
    SyncColourCycle = [0; 255]
    % An identifier for the monitor
    MonitorId
    % Struct containing calibration data.  See calibration
    Calibration
    % Set the verbosity level.  0-5 where 5 is most verbose.
    PtbVerbosity = 2
    % When true test synchronization to retrace upon open. Defaults to
    % global preference (usually true).  See 'Screen SkipSyncTests?'
    PtbSyncTests
  end

  properties (SetAccess = protected)
    % Intensity value to produce white at the current screen depth
    White
    % Gray level based values set in White and Black
    Gray
    % Intensity value to produce black at the current screen depth
    Black
    % Red level based values set in White and Black
    Red
    % Green level based values set in White and Black
    Green
    % Blue level based values set in White and Black
    Blue
    % Colour range based on current pixel depth
    ColourRange
    % Actual bounds of the stimulus window, if open
    Bounds
  end
  
  properties (SetAccess = protected, Transient)
    % A handle to the PTB screen window.  -1 when closed.
    PtbHandle = -1
    % Refresh interval for updating the device.  See 'Screen
    % GetFlipInterval?'
    RefreshInterval
    % Index into SyncColourCycle for next sync colour
    NextSyncIdx
    % When true stimulus frame should be re-drawn at next opportunity
    Invalid = false
    TimeInvalidated  = -1
    AsyncFlipping = false
    AsyncFlipTimeInvalidated = -1
    % For storing during DAQ acquisition, e.g. for calibration
    DaqData
  end
  
  properties (Access = protected)
    % List of textures currently on the graphics device
    TexList
    pBackgroundColour
    OldPtbVerbosity
    OldPtbSyncTests
    DaqSession
    pDaqVendor = 'ni'
    pDaqDev = 'Dev1'
    pDaqSyncEchoPort
  end
  
  methods
    % Window constructor
    function obj = Window()
      obj.ScreenNum = max(Screen('Screens'));
    end
    
    function positionSyncRegion(obj, refCorner, width, height, xOffset, yOffset)
      % POSITIONSYNCREGION Set position of the photodiode sync square
      %  Set the SyncBounds property with respect to any corner of the
      %  stimulus window.  If the Bounds property isn't set, they are
      %  determined from the OpenBounds property and current resolution.
      %
      %  Inputs:
      %    refCorner (char) - Compass coordinates of the of the sync
      %      square, e.g. northeast(/ne), southwest(/sw), etc.
      %    width (double) - Width of the sync square in pixels
      %    height (double) - Height of the sync square in pixels
      %    xOffset (double) - X-offset in pixels of sync square reletive to
      %      refCorner (default 0)
      %    yOffset (double) - Y-offset in pixels of sync square reletive to
      %      refCorner (default 0)
      %
      %  Example:
      %    % Set a 100 px sync square in the top left of the screen 
      %    obj.positionSyncRegion('NorthEast', 100, 100)
      %
      % See also FLIP
      
      narginchk(2,6)
      if nargin < 5; xOffset = 0; end
      if nargin < 6; yOffset = 0; end
      
      % If the bounds aren't set, infer them
      if isempty(obj.Bounds)
        win = iff(obj.IsOpen, obj.PtbHandle, obj.ScreenNum);
        obj.Bounds = getOr(obj, 'OpenBounds', Screen('Rect',win));
      end

      switch lower(refCorner)
        case {'northeast' 'ne'}
          refx = obj.Bounds(3);
          refy = obj.Bounds(2);
          bounds = SetRect(refx - width, refy, refx, refy + height);
        case {'southeast' 'se'}
          refx = obj.Bounds(3);
          refy = obj.Bounds(4);
          bounds = SetRect(refx - width, refy - height, refx, refy);
        case {'southwest' 'sw'}
          refx = obj.Bounds(1);
          refy = obj.Bounds(4);
          bounds = SetRect(refx, refy - height, refx + width, refy);
        case {'northwest' 'nw'}
          refx = obj.Bounds(1);
          refy = obj.Bounds(2);
          bounds = SetRect(refx, refy, refx + width, refy + height);
        otherwise
          error('"%s" is not a valid corner reference (use compass terms)', refCorner);
      end
      % do the requested offset
      obj.SyncBounds = OffsetRect(bounds, xOffset, yOffset);
    end
    
    function value = get.IsOpen(obj)
      openWins = Screen('Windows');
      if any(openWins == obj.PtbHandle)
        value = true;
      else
        value = false;
      end
    end
    
    function value = get.DaqVendor(obj)
      value = obj.pDaqVendor;
    end
    
    function set.DaqVendor(obj, value)
       obj.pDaqVendor = value;
       if ~isempty(obj.DaqSession)
         % update the existing session
         obj.DaqSession.outputSingleScan(false);
         % remove previous device, configure new one
         obj.DaqSession.release();
         obj.DaqSession = daq.createSession(value);
         obj.DaqSession.addDigitalChannel(obj.DaqDev, obj.DaqSyncEchoPort, 'OutputOnly');
       end
    end
    
    function value = get.DaqDev(obj)
      value = obj.pDaqDev;
    end
    
    function set.DaqDev(obj, value)
       obj.pDaqDev = value;
       if ~isempty(obj.DaqSession)
         % update the existing session
         obj.DaqSession.outputSingleScan(false);
         % remove channels associated with previous device and open on new
         % one
         obj.DaqSession.removeChannel(1:numel(obj.DaqSession.Channels));
         obj.DaqSession.addDigitalChannel(value, obj.DaqSyncEchoPort, 'OutputOnly');
       end
    end
    
    function value = get.DaqSyncEchoPort(obj)
      value = obj.pDaqSyncEchoPort;
    end
    
    function set.DaqSyncEchoPort(obj, value)
       obj.pDaqSyncEchoPort = value;
       if ~isempty(obj.DaqSession)
         % update the existing session
         obj.DaqSession.outputSingleScan(false);
         if ~isempty(value)
           % remove channels associated with previous port and open on new
           % port
          obj.DaqSession.removeChannel(1:numel(obj.DaqSession.Channels));
          obj.DaqSession.addDigitalChannel(obj.DaqDev, value, 'OutputOnly');
         else
           % an empty port value means don't use the daq, so release the
           % previous session
           obj.DaqSession.release();
           obj.DaqSession = [];
         end
       end
    end
    
    function value = get.BackgroundColour(obj)
      value = obj.pBackgroundColour;
    end
    
    function set.BackgroundColour(obj, colour)
      obj.pBackgroundColour = colour;
      if obj.PtbHandle > -1
        % performing a ptb FillRect will set the new background colour
        Screen('FillRect', obj.PtbHandle, colour);
      end
    end

    function [oldSrcFactor, oldDestFactor] = setAlphaBlending(obj, srcFactor, destFactor)
      [oldSrcFactor, oldDestFactor] = Screen('BlendFunction', obj.PtbHandle,...
        srcFactor, destFactor);
    end

    function open(obj)
      % OPEN Open the PsychToolbox window
      %  Calls Screen('OpenWindow') to open a new window using the obj
      %  properties.  Also initializes the a DAQ Session if the
      %  DaqSyncEchoPort property is set.
      %
      % See also CLOSE, FLIP
      
      % close a previously open screen window if any
      close(obj);
      % configure a DAQ session if required
      if ~isempty(obj.DaqSyncEchoPort)
        obj.DaqSession = daq.createSession(obj.DaqVendor);
        obj.DaqSession.addDigitalChannel(obj.DaqDev, obj.DaqSyncEchoPort, 'OutputOnly');
        obj.DaqSession.outputSingleScan(false);
      end
      if ~isempty(obj.PtbVerbosity)
        obj.OldPtbVerbosity = Screen('Preference', 'Verbosity', obj.PtbVerbosity);
      end
      if ~isempty(obj.PtbSyncTests)
        obj.OldPtbSyncTests = Screen('Preference', 'SkipSyncTests', double(~obj.PtbSyncTests));
      end
      Screen('Preference', 'SuppressAllWarnings', true); % @fixme Warnings supressed despite verbosity
      % @body The entry here suggests that this flag is equivalent to
      % setting verbosity to 0: 
      % https://github.com/Psychtoolbox-3/Psychtoolbox-3/wiki/FAQ:-Control-Verbosity-and-Debugging
      % Perhaps this shouldn't be set after setting 'Verbosity'?
      
      % setup screen window
      obj.PtbHandle = Screen('OpenWindow', obj.ScreenNum, obj.BackgroundColour,...
        obj.OpenBounds, obj.PxDepth);
      obj.PxDepth = Screen('PixelSize', obj.PtbHandle);
      obj.Bounds = Screen('Rect', obj.PtbHandle);

      %first flip will be first sync colour in cycle
      obj.NextSyncIdx = 1;
      obj.RefreshInterval = Screen('GetFlipInterval', obj.PtbHandle);
      obj.White = WhiteIndex(obj.PtbHandle);
      obj.Black = BlackIndex(obj.PtbHandle);
      
      %apply calibration, if any
      if ~isempty(obj.Calibration)
        obj.applyCalibration(obj.Calibration);
      else
        fprintf('\nWarning: No gamma calibration available\n');
      end

      % setup colour numbers used for drawing
      obj.ColourRange = obj.White - obj.Black;
      obj.Red = [obj.White obj.Black obj.Black];
      obj.Green = [obj.Black obj.White obj.Black];
      obj.Blue = [obj.Black obj.Black obj.White];
      obj.Gray = 0.5*(obj.Black + obj.White);
      if isempty(obj.BackgroundColour)
        obj.BackgroundColour = obj.Black;
      end
      if isempty(obj.ForegroundColour)
        obj.ForegroundColour = obj.White;
      end
    end

    function close(obj)
      % CLOSE Close any window and release DAQ session
      % close screen resources
      openWins = Screen('Windows');
      if any(openWins == obj.PtbHandle)
        deleteTextures(obj);
        Screen('Close', obj.PtbHandle);
      end
      if ~isempty(obj.OldPtbVerbosity)
        Screen('Preference', 'Verbosity', obj.OldPtbVerbosity);
      end
      if ~isempty(obj.OldPtbSyncTests)
        Screen('Preference', 'SkipSyncTests', obj.OldPtbSyncTests);
      end
      obj.OldPtbVerbosity = [];
      obj.OldPtbSyncTests = [];
      obj.PtbHandle = -1;
      if ~isempty(obj.DaqSession)
        obj.DaqSession.outputSingleScan(false);
        obj.DaqSession.release();
        obj.DaqSession = [];
      end
    end

    % PTBWindow destructor: clear PTB Screen resources
    function delete(obj)
      close(obj);
    end
    
    function asyncFlipBegin(obj)
      % begin the actual 'flip' of the frame onto the screen
      obj.AsyncFlipping = true;
      if ~isempty(obj.SyncBounds)
        % render sync region with next colour in cycle
        col = obj.SyncColourCycle(obj.NextSyncIdx,:);
        % render rectangle in the sync region bounds in the required colour
        Screen('FillRect', obj.PtbHandle, col, obj.SyncBounds);
        % cyclically increment the next sync idx
        obj.NextSyncIdx = mod(obj.NextSyncIdx, size(obj.SyncColourCycle, 1)) + 1;
      else
        col = 0;
      end
      if ~isempty(obj.DaqSession)
        % update sync echo
        outputSingleScan(obj.DaqSession, mean(col) > 0);
      end
%       disp('AsyncFlipBegin');
      if obj.Invalid
        obj.Invalid = false;
        % save the time the window was invalidated for later comparison to
        % when the update was complete
        obj.AsyncFlipTimeInvalidated = obj.TimeInvalidated;
      else
        obj.AsyncFlipTimeInvalidated = nan;
      end
      Screen('AsyncFlipBegin', obj.PtbHandle);
    end
    
    function [time, invalidFrames, validationLag] = asyncFlipEnd(obj)
      obj.AsyncFlipping = false;
%       disp('AsyncFlipEnd');
      vbl = Screen('AsyncFlipEnd', obj.PtbHandle);
      time = vbl;

      if isfinite(obj.AsyncFlipTimeInvalidated)
        validationLag = time - obj.AsyncFlipTimeInvalidated;
        % if the lag to validate the Window was two full refreshes or more,
        % we have missed one or more frames:
        % This is because we can potentially invalidate at the start of one
        % frame, then need another full frame to refresh again.
        invalidFrames = floor(validationLag/obj.RefreshInterval);
        if invalidFrames >= 2
          fprintf('*** (ASYNC) %i FRAME(S) LATE, UPDATE LAG was %gms ***\n',...
            invalidFrames - 1, 1000*validationLag);
        end
%         fprintf('*** %i FRAME(S), REFRESH LAG was %gms ***\n',...
%           invalidFrames, 1000*validationLag);
      else
        % if the Window was still valid, just return a lag of zero
        validationLag = 0;
      end
      obj.InvalidationUpdates = {}; % clear invalidation updates list
    end

    function [time, invalidFrames, validationLag] = flip(obj, when)
      if nargin < 2
        when = 0;
      end
      % do the actual 'flip' of the frame onto the screen
      if ~isempty(obj.SyncBounds)
        % render sync region with next colour in cycle
        col = obj.SyncColourCycle(obj.NextSyncIdx,:);
        % render rectangle in the sync region bounds in the required colour
        Screen('FillRect', obj.PtbHandle, col, obj.SyncBounds);
        % cyclically increment the next sync idx
        obj.NextSyncIdx = mod(obj.NextSyncIdx, size(obj.SyncColourCycle, 1)) + 1;
      else
        col = 0;
      end
      if ~isempty(obj.DaqSession)
        % update sync echo
        outputSingleScan(obj.DaqSession, mean(col) > 0);
      end
      vbl = Screen('Flip', obj.PtbHandle, when);
      time = vbl;
      
      if obj.Invalid 
        validationLag = time - obj.TimeInvalidated;
        obj.Invalid = false;
        % if the lag to validate the Window was more than one refresh, we
        % have missed one or more frames
        invalidFrames = max(round((validationLag/obj.RefreshInterval) - 1), 0);
        if invalidFrames > 0
          fprintf('*** %i FRAME(S) LATE, UPDATE LAG was %gms ***\n', invalidFrames, ...
            1000*validationLag);
        end
      else
        % if the Window was still valid, just return a lag of zero
        validationLag = 0;
      end
      obj.InvalidationUpdates = {}; % clear invalidation updates list
    end

    function clear(obj)
      % CLEAR Clear any textures on screen
      %  Redraw background over any textures
      Screen('FillRect', obj.PtbHandle, obj.BackgroundColour);
    end

    function drawTexture(obj, tex, srcRect, destRect, angle, globalAlpha)
      % DRAWTEXTURE Draw one or more textures to the screen
      %  drawTexture(obj, tex, [srcRect, destRect, angle, globalAlpha])
      %  Draw one or more OpenGL textures to the screen.  
      %
      %  Inputs:
      %    tex - A texture specified via MAKETEXTURE method
      %    srcRect - Specifies a rectangular subpart of the texture to be 
      %      drawn in px (Defaults to full texture).  A 4-element numerical
      %      array
      %    destRect - A 4-element numerical array defining the rectangular
      %      subpart of the window in px where the texture should be drawn.
      %      This defaults to centered on the screen
      %    angle - Specifies a rotation angle in degree for rotated drawing
      %      of the texture (Defaults to 0 deg. = upright)
      %    globalAlpha - A global alpha transparency value to apply to the
      %      whole texture for blending. Range is 0 = fully transparent
      %      to 1 = fully opaque, defaults to one. If both, an
      %      alpha-channel and globalAlpha are provided, then the final
      %      alpha is the product of both values
      %
      %  Example:
      %    % Draw an image to the screen
      %    obj.open()
      %    tex = obj.makeTexture(imread('cell.tif'));
      %    obj.drawTexture(tex)
      %    obj.flip()
      %
      % See also MAKETEXTURE, SCREEN DRAWTEXTURE?
      %
      if nargin < 6
        globalAlpha = [];
      end
      if nargin < 5
        angle = [];
      end
      if nargin < 4
        destRect = [];
      end
      if nargin < 3
        srcRect = [];
      end
      Screen('DrawTextures', obj.PtbHandle, tex, srcRect, destRect, angle, [], globalAlpha);
    end

    function fillRect(obj, colour, rect)
      % FILLRECT Draw rectangle(s) with a given colour
      %  Fill one or more rectangles with a given colour.  
      %  Inputs:
      %    colour - a CLUT index for rect.  May be a scalar luminance
      %      value, RGB or RGBA vector.  To specify a different colour for
      %      each rectangle, pass in a matrix.  Each column specifies a
      %      colour for a given rectangle.  colour and rect should have the
      %      same number of columns.
      %    rect - an 4xn matrix of pixel coordinates where n is the number
      %      of rectangles to draw.  [topLeftX topLeftY bottomRightX
      %      bottomRightY].  If left empty, whole screen is filled with
      %      colour
      %
      %  Example:
      %    % Draw two rectangles, one green, one red:
      %    obj.open()
      %    colour = [[0; 255; 0], [255; 0; 0]];
      %    rect = [[0; 0; 100; 100], [100; 100; 200; 200]];
      %    obj.fillRect(colour, rect)
      %    obj.flip()
      %
      % See also FLIP, POSITIONSYNCREGION, SCREEN FILLRECT?
      if nargin < 3
        rect = [];
      end
      Screen('FillRect', obj.PtbHandle, colour, rect);
    end

    function tex = makeTexture(obj, image)
      % MAKETEXTURE Make OpenGL texture
      %  Convert a 2D or 3D matrix into an OpenGL texture and return an
      %  index which may be passed to DRAWTEXTURE to specify the texture.
      %  The texture is preloaded into graphics memory.
      %
      %  Input:
      %    image - May be a single monochrome plane or 3D matrix where the
      %      3rd dimention consists of RGB or RGBA values.  Values should
      %      typically be between 0-255.
      %
      %  Output: 
      %    tex - An OpenGL texture pointer.
      %
      %  Example:
      %    % Draw an image to the screen
      %    obj.open()
      %    tex = obj.makeTexture(imread('cell.tif'));
      %    obj.drawTexture(tex)
      %    obj.flip()
      %
      % See also FLIP, DRAWTEXTURE, SCREEN MAKETEXTURE?, PRELOADTEXTURE?

      tex = Screen('MakeTexture', obj.PtbHandle, image);
      obj.TexList = [obj.TexList tex];
      Screen('PreloadTextures', obj.PtbHandle, tex);
    end

    function [nx, ny] = drawText(obj, text, x, y, colour, vSpacing, wrapAt)
      % DRAWTEXT Draw some text to the screen
      %  The outputs may be used as the new start positions to draw further
      %  text to the screen.
      %  
      %  Inputs:
      %    text (char) - The text to be written to screen.  May contain
      %      newline characters '\n'.
      %    x (numerical|char) - The top-left x coordinate of the text in
      %      px.  If empty the left-most area part of the screen is used.
      %      May also be one of the following string options: 'center',
      %      'right', 'wrapat', 'justifytomax', 'centerblock'.
      %    y (numerical|char) - The baseline (first line) coordinate of the
      %      text in px.  Defaults to roughly the top of the screen.  If
      %      'center', the text is roughly vertically centered.
      %    color - The CLUT index for the text (scalar, RGB or RGBA vector)
      %      If color is left out, the current text color from previous
      %      text drawing commands is used.
      %    vSpacing - The spacing between the lines in px. Defaults to 1.
      %    wrapAt (char) - automatically break text longer than this string 
      %      into newline separated strings of roughly the same length
      %
      %  Outputs:
      %    nx - The approximate x-coordinate of the 'cursor position' in px
      %    ny - The approximate y-coordinate of the 'cursor position' in px
      %
      %  Example:
      %    % Draw 'Hello world' in red to screen
      %    obj.open()
      %    obj.drawText('Hello World', 'center', 'center', obj.Red);
      %    obj.flip()
      %
      % See also DRAWFORMATTEDTEXT, DRAWTEXTURE, WRAPSTRING
      if nargin < 7
        wrapAt = [];
      end
      if nargin < 6
        vSpacing = [];
      end
      if nargin < 5
        colour = [];
      end
      if nargin < 4
        y = [];
      end
      if nargin < 3
        x = [];
      end
      [nx, ny] = DrawFormattedText(obj.PtbHandle, text, x, y, colour, wrapAt, [], [],...
        vSpacing);
%       Screen('DrawText', obj.PtbHandle, text, x, y, colour, [], real(yPosIsBaseline));
    end

    function deleteTextures(obj)
      if ~isempty(obj.TexList)
        Screen('Close', obj.TexList);
        obj.TexList = [];
      end
    end
    
    function applyCalibration(obj, cal)      
      if strcmp(obj.MonitorId, cal.monitorId) && ...
          abs((1/obj.RefreshInterval) - cal.refreshRate)<0.1
        fprintf('\nApplying monitor calibration performed on %s\n',cal.dateTimeStr);
      else
        warning(...
          'Latest calibration was done on %s\n for a %s monitor running at %3.1fHz\nRERUN Calibration.Make and Calibration.Check', ...
          cal.dateTimeStr, cal.monitorId, cal.refreshRate); %#ok<WNTAG>
      end
      
      if any(isnan(cal.monitorGamInv))
        error('Ouch! There are NaNs in inverse gamma function!')
      end
      
      gammaTable = 1/255 * cal.monitorGamInv;	% corrected to have linear luminance
      Screen('LoadNormalizedGammaTable', obj.PtbHandle, gammaTable);
    end
    
    function c = calibration(obj, dev, lightIn, clockIn, clockOut, makePlot)
      % CALIBRATION Performs a gamma calibration for the screen
      %  Requires the user to hold a photodiode, connected to a NI-DAQ,
      %  against the screen in order to perform gamma calibration, and
      %  returns the results as a struct.
      %  
      %  Inputs:
      %    dev (int) : NI DAQ device ID to which the photodiode is
      %      connected
      %    lightIn (char) : analogue input channel name to which the
      %      photodiode is connected
      %    clockIn (char) : analogue input channel name for clocking pulse
      %    clockOut (char) : digital output channel name for clocking pulse
      %    makePlot (bool) : flag for making photodiode signal plot
      % 
      %  Output:
      %    c (struct) : calibration struct containing refresh rate and
      %      gamma tables
      %
      % See also calibrationStruct, applyCalibration
      
      %first load a default gamma table
      stdGammaTable = repmat(linspace(0, 1 - 1/256, 256)',[1 3]);
      disp('Loading standard gamma table');
      Screen('LoadNormalizedGammaTable', obj.PtbHandle, stdGammaTable);
      
      if nargin < 6
        makePlot = true;
      end
      if nargin < 5
        clockOut = 'port1/line0';
      end
      if nargin < 4
        clockIn = 'ai1';
      end
      if nargin < 3
        lightIn = 'ai0';
      end
      
      steps = round(linspace(0,255,17)); % 17 steps
      nsteps = length(steps);
      colours = zeros(nsteps*3,3);
      iStim = 0;
      for igun = 1:3 % 1,2,3 for r,g,b
        for istep = 1:nsteps
          iStim = iStim+1;
          colours(iStim,:) = [0 0 0];
          colours(iStim,igun) = steps(istep);
        end
      end
      
      [light, clock, acqRate] = obj.measuredStim(colours, dev, lightIn, clockIn, clockOut);
      
      %% assess the delay between digital and analog
      
      [xc, lags ] = xcorr(light, clock, 1000, 'coeff');
      [~,imax] = max(xc);
      ishift = lags(imax);
      delay = 1000*ishift/acqRate; % in ms
      delayMsg = sprintf('Digital is ahead of screen by %2.2f ms\n', delay);
      fprintf(delayMsg);

      % correct the data
      clock = circshift(clock,[ishift,0]);
      
      %% plot the data
      if makePlot
        ns = length(light);
        tt = (1:ns)/acqRate;
        
        figure; plot(tt,clock);
        ylabel('clock signal'); title('Clock');
        
        upCrossings = find(diff( clock > 1 ) ==  1);
        dnCrossings = find(diff( clock > 1 ) == -1);
        
        figure; clf
        for iC = 1:length(upCrossings)
          plot(tt(upCrossings(iC))*[1 1],[0 5],'-', ...
            'color', 0.8*[1 1 1] ); hold on
        end
        plot( tt, light ); hold on
        xlabel('Time (s)');
        ylabel('Photodiode Signal (Volts)');
        set(gca,'ylim',[0 1.1*max(light)]);
        title(delayMsg);
      end
      %% interpret the results
      
      nsteps = length(steps); % length(UpCrossings)/3;
      
      vv = zeros(3,nsteps);
      istim = 0;
      for igun = 1:3 % 1,2,3 for r,g,b
        for istep = 1:nsteps
          istim = istim+1;
          vv(igun,istep) = ...
            mean( light(upCrossings(istim):dnCrossings(istim)) );
        end
      end
      
      %% put all this into a Calibration file and compute inverse gamma table
      c = calibrationStruct(obj, steps, vv, delay);      
    end
  end
  
  methods (Access = protected)
    function c = calibrationStruct(obj, xx, yyy, delay)
      c.monitorId = obj.MonitorId;
      
      %  choose step value (something that goes into 256 evenly)
      %  stepsize = 32; % usually 16; %32;
      %  xx = [0, stepsize-1:stepsize:255];
      %  yyy = repmat(xx,[3,1]);
      
      c.dateTime        = now;
      c.dateTimeStr = datestr(c.dateTime);
      
      c.xx          = xx;
      c.yyy         = yyy;
      c.latency   = delay;
      c.refreshRate   = 1/obj.RefreshInterval;
      
      %% interpolate to obtain monitorGam  
      rr = yyy(1,:);
      gg = yyy(2,:);
      bb = yyy(3,:);
      
      % Normalize to the max and min for r g and b
      rr = (rr - min(rr)) / (max(rr) - min(rr));
      gg = (gg - min(gg)) / (max(gg) - min(gg));
      bb = (bb - min(bb)) / (max(bb) - min(bb));
      
      c.monitorGam=zeros(256,3);
      c.monitorGam(:,1)=interp1(xx,rr,0:255)';
      c.monitorGam(:,2)=interp1(xx,gg,0:255)';
      c.monitorGam(:,3)=interp1(xx,bb,0:255)';
      
      %% calculate inverse gamma table
      
      % Replaced by MW and NS on 2017-02-07 because sometimes obj.PxDepth
      % is 24 (excluding alpha channel) which makes this all not work.
      % However it's been assumed already in the lines right above this
      % that pixel depth is 8 bits, so here we carry on with that
      % assumption. The value in the hardware.mat file is not used by PTB
      % anyway (see line 202).
%       pxDepthPerChannel = obj.PxDepth/4;
      pxDepthPerChannel = 8; 
      
      nguns = size(c.monitorGam,2);
      numEntries = 2^pxDepthPerChannel;
      
      c.monitorGamInv = zeros(numEntries,nguns);
      %  Check for monotonicity, and fix if not monotone
      %
      for igun=1:nguns
        
        thisTable = c.monitorGam(:,igun);
        
        % Find the locations where this table is not monotonic
        %
        list = find(diff(thisTable) <= 0, 1);
        
        if ~isempty(list)
          fprintf('Gamma table %d NOT MONOTONIC.  We are adjusting.',igun);
          
          % We assume that the non-monotonic points only differ due to noise
          % and so we can resort them without any consequences
          %
          thisTable = sort(thisTable);
          
          % Find the sorted locations that are actually increasing.
          % In a sequence of [ 1 1 2 ] the diff operation returns the location 2
          %
          % posLocs is positions of values with positive derivative
          posLocs = find(diff(thisTable) > 0);
          
          % We now shift these up and add in the first location
          %
          posLocs = [1; (posLocs + 1)];
          % monTable is values in original vector with positive derivatives
          monTable = thisTable(posLocs,:);
          
        else
          
          % If we were monotonic, then yea!
          monTable = thisTable;
          posLocs = 1:size(thisTable,1);
        end
        
        % nrow = size(monTable,1);
        
        % Interpolate the monotone table out to the proper size
        % 092697 jbd added a ' before the ;
        c.monitorGamInv(:,igun) = ...
          interp1(monTable,posLocs-1,(0:(numEntries-1))/(numEntries-1))';
        
      end
      if any(isnan(c.monitorGamInv))
        msgbox('Warning: NaNs in inverse gamma table -- may need to recalibrate.');
      end
    end
    
    function storeDaqData(obj, ~, event)
      n = length(event.TimeStamps);
      ii = obj.DaqData.nSamples+(1:n);
      obj.DaqData.timeStamps(ii) = event.TimeStamps;
      obj.DaqData.data(ii,:) = event.Data;
      obj.DaqData.nSamples = obj.DaqData.nSamples + n;
    end
    
    function [l, c, sr] = measuredStim(obj, colours, dev, lightIn, clockIn, clockOut)
      acqRate = 5000; % Hz
      winPtr = obj.PtbHandle;
      
      inSess = daq.createSession('ni');
      fprintf('opening light meter on %s:%s\n', dev, lightIn);
      c = inSess.addAnalogInputChannel(dev, lightIn, 'Voltage');
      c.InputType = 'Differential';
      c = inSess.addAnalogInputChannel(dev, clockIn, 'Voltage');
      c.InputType = 'SingleEnded';
      inSess.Rate = acqRate;
      inSess.IsContinuous = true;
      inSess.NotifyWhenDataAvailableExceeds = ceil(acqRate/10); % call it every 100 ms
      
      obj.DaqData = struct;
      obj.DaqData.timeStamps = zeros( acqRate*120, 1 );
      obj.DaqData.data       = zeros( acqRate*120, 2);
      obj.DaqData.nSamples = 0;
      
      listener = inSess.addlistener('DataAvailable', @obj.storeDaqData);
      
      outSess = daq.createSession('ni'); % must be a different session!
      outSess.addDigitalChannel(dev, clockOut, 'OutputOnly');
      outSess.outputSingleScan(0);
      
      %% Measure Gamma
      Screen('FillRect', winPtr, [0 0 0]);
      Screen('Flip', winPtr);
      
      inSess.startBackground();
      
      nStim = size(colours,1);
      for iStim = 1:nStim
        
% % %         Screen('FillRect', winPtr, [0 0 0]);
% % %         Screen('Flip', winPtr);
        Screen('FillRect', winPtr, colours(iStim,:));
        for iframe = 1:25
          Screen('Flip', winPtr);
          if iframe == 1
            outSess.outputSingleScan(1);
          end
        end
        Screen('FillRect', winPtr, [0 0 0]);
% % %         Screen('Flip', winPtr);
        for iframe = 1:25
          Screen('Flip', winPtr);
          if iframe == 1
            outSess.outputSingleScan(0);
          end
        end
        
        drawnow;
      end
      
      Screen('FillRect', winPtr, [128 128 128]);
      Screen('Flip', winPtr);
      
      inSess.stop();
      
      delete(listener);
      
      %% prepare the data for output
      if obj.DaqData.nSamples ~= inSess.ScansAcquired
        fprintf('Acquired %d samples instead of %d\n', inSess.ScansAcquired, obj.DaqData.nSamples);
      end
      
      ii = 1:obj.DaqData.nSamples;
      l = obj.DaqData.data(ii,1);
      c  = obj.DaqData.data(ii,2);
      sr = acqRate;
      
      release(inSess); %makre sure we tidy up
      release(outSess); %makre sure we tidy up
    end
  end
  
end