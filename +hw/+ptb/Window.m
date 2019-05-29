classdef Window < hw.Window
  %HW.PTB.WINDOW A Psychtoolbox Screen implementation of Window
  %   Detailed explanation goes here
  %
  % Part of Rigbox

  % 2012-10 CB created
  
  properties (Dependent)
    BackgroundColour
    DaqVendor
    DaqDev
    DaqSyncEchoPort
    IsOpen
  end
  
  properties
    ForegroundColour
    ScreenNum; %Psychtoolbox screen number
    PxDepth = 32 %the pixel colour depth (bits)
    OpenBounds %default screen region to open window onscreen - empty for full
    SyncBounds %position bounding rectangle of sync region
    %sync region [r g b], or luminance for each consecutive flip (row-wise).
    %Wil repeat in a cycle. Default is white->black->....
    SyncColourCycle = [0; 255]
    MonitorId %an identifier for the monitor
    Calibration %Struct containing calibration data
    PtbVerbosity = 2
    PtbSyncTests
  end

  properties (SetAccess = protected)
    White
    Gray
    Black
    Red
    Green
    Blue
    ColourRange
    Bounds
  end
  
  properties (SetAccess = protected, Transient)
    PtbHandle = -1 %a handle to the PTB screen window
    RefreshInterval %refresh interval for updating the device
    NextSyncIdx %index into SyncColourCycle for next sync colour
    Invalid = false
    TimeInvalidated  = -1
    AsyncFlipping = false
    AsyncFlipTimeInvalidated = -1
    DaqData %for storing during DAQ acquisition, eg for calibration
  end
  
  properties (Access = protected)
    TexList %list of textures currently on the graphics device
    pBackgroundColour
    OldPtbVerbosity
    OldPtbSyncTests
    DaqSession
    pDaqVendor = 'ni'
    pDaqDev = 'Dev1'
    pDaqSyncEchoPort % e.g. 'port0/line0'. empty for don't use the DAQ
  end
  
  methods
    % Window constructor
    function obj = Window()
      obj.ScreenNum = max(Screen('Screens'));
    end
    
    function positionSyncRegion(obj, refCorner, width, height, xOffset, yOffset)
      if nargin < 5
        xOffset = 0;
      end
      if nargin < 6
        yOffset = 0;
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
      Screen('Preference', 'SuppressAllWarnings', true);
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
        % if the lag to validate the Window was two fullrefreshes or more,
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
      Screen('FillRect', obj.PtbHandle, obj.BackgroundColour);
    end

    function drawTexture(obj, tex, srcRect, destRect, angle, globalAlpha)
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
      if nargin < 3
        rect = [];
      end
      Screen('FillRect', obj.PtbHandle, colour, rect);
    end

    function tex = makeTexture(obj, image)
      tex = Screen('MakeTexture', obj.PtbHandle, image);
      obj.TexList = [obj.TexList tex];
      Screen('PreloadTextures', obj.PtbHandle, tex);
    end

    function [nx, ny] = drawText(obj, text, x, y, colour, vSpacing, wrapAt)
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
    
    function c = calibration(obj, dev, lightIn, clockIn, clockOut)
      % Creates a calibration file automatically using the light meter
      
      %first load a default gamma table
      stdGammaTable = repmat(linspace(0, 1 - 1/256, 256)',[1 3]);
      disp('Loading standard gamma table');
      Screen('LoadNormalizedGammaTable', obj.PtbHandle, stdGammaTable);
      
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
%       figure; plot(lags,xc)
      [~,imax] = max(xc);
      ishift = lags(imax);
      delay = 1000*ishift/acqRate; % in ms
      fprintf('Digital is ahead of screen by %2.2f ms\n',delay);
      
      % correct the data
      clock = circshift(clock,[ishift,0]);
      
      %% plot the data
      
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
      title(sprintf('In this plot. digital has been delayed by %2.2f ms', delay));
      
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
      % assumption. The value is the hardware.mat file is not used by PTB
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