classdef LickExperiment < exp.LIARExperiment
  % LickExperiment
  %   The properties and methods of this object determine what will
  %   happen in the experiment.
  
  properties
    TargetRect %graphics coord rectangle for current target
    TargetTexture %texture for gabor grating target
    BarTextures %textures for each possible bar colour
    BarAzimuths %visual field azimuths of each possible bar's centre
    BarPxRects %graphics bounds for each possible flashed bar
    BarRectSeq %sequence of indices for selecting bar rectangle
    BarColourSeq %sequence of indices for selecting bar colour
    Grating
    BarIdx = 0     %which bar to flash
    RewardKey = KbName('space') %space bar
  end
  
  methods
    function useRig(obj, rig)
      useRig@exp.LIARExperiment(obj, rig); % let superclass do its stuff
      % read rig devices
      obj.RewardController = rig.daqController;
      obj.InputSensor = rig.lickDetector;
%       obj.LickDetector = rig.lickDetector;
    end
    
    function deliverReward(obj, sz)
      % TODO make a reward event or something?
      t = obj.Clock.now;
      if nargin < 2
        n = numel(param(obj.ConditionServer, 'rewardVolume'));
        sz = [obj.RewardController.SignalGenerators(1:n).DefaultCommand];
      end
      contrast = obj.Data.trial(obj.TrialNum).condition.trialContrast;
      if abs(contrast) > 0
        command(obj.RewardController, sz);
        obj.Data.rewardDeliveredSizes(end + 1,:) = sz;
        obj.Data.rewardDeliveryTimes(end + 1) = t;
        post(obj, 'status',...
          {'update', obj.Data.expRef, 'rewardDelivered', sz, t});
      end
    end

    function prepareTargetTexture(obj)
      %compute target texture positions in graphics coordinates
      elev = param(obj.ConditionServer, 'targetElevation');
      azi = param(obj.ConditionServer, 'targetAzimuth');
      sig = param(obj.ConditionServer, 'targetSigma');
      ori = param(obj.ConditionServer, 'targetOrientation');
      con = param(obj.ConditionServer, 'targetContrast');
      sf = param(obj.ConditionServer, 'targetSpatialFrequency');
      %convert to graphics coords
      model = obj.StimViewingModel;
      %centre of gabor on screen:
      %[x, y] = model.pixelAtView(polarAngle, visualAngle)
      [cx, cy] = model.pixelAtView(atan2(elev, azi), deg2rad(hypot(azi, elev)));
      %get pixel density at centre to adjust gabor wavelength
      %pxPerRad = model.visualPixelDensity(x, y)
      pxPerRad = model.visualPixelDensity(cx, cy);
      pxSigma = deg2rad(sig)*pxPerRad;
      pxWavelength = deg2rad(1/sf)*pxPerRad;
      
      
      sz = 6*pxSigma;
      %set bounding rectange for target texture to be drawn to
      obj.TargetRect = CenterRectOnPoint(SetRect(0, 0, sz(1), sz(2)), cx, cy);
      xx = -sz/2:sz/2;
      
      phase = 2*pi*rand; % randomised phase
      img = vis.gabor(...
        xx, xx,... %x & y points of gabor to plot
        pxSigma(1), pxSigma(2), pxWavelength,... %xsigma,ysigma,wavelength
        0, deg2rad(ori), phase); %gabor ori, cosine ori, cosine phase
      
      con = con(randi(numel(con)));
      obj.Data.trial(obj.TrialNum).condition.trialContrast = con;
      
      img = 255*0.5*(con*img + 1);
      ensureWindowReady(obj); %ensure graphics window is ready for ops
      %create texture for target
      obj.TargetTexture = makeTexture(obj.StimWindow, img);
    end
  end
  
  methods (Access = protected)
    function init(obj)
      %Called by the experiment when it's first run, before entering the
      %main loop. By this stage, the stimulus window will be open.
      %When init is finished, an 'experimentInit' event is fired.
      
      %let superclass (exp.Experiment) do its initalisation first
      init@exp.LIARExperiment(obj);
      
      white = obj.StimWindow.White;
      %make 1-pixel textures (will be rescaled as appropriate) of each
      %possible bar colour
      barCol = param(obj.ConditionServer, 'barColours');
      obj.BarTextures = arrayfun(@(c) obj.StimWindow.makeTexture(c),...
        white*barCol);
      %initialise the experiment's data for storing bar info
      obj.Data.barAzimuth = [];
      obj.Data.barColour = [];
      %NOTE: times are when the bar should change and the screen was
      %invalidated. the bar will actually be drawn to screen ASAP after
      %this
      obj.Data.barChangeTime = [];
    end
    
    function updateState(obj)
      %Called during the main experiment loop to update state prior to
      %any stimulus drawing, potentially to invalidate the screen
      timenow = obj.Clock.now;
      flashDuration = param(obj.ConditionServer, 'barFlashDuration');
      flashDelay = param(obj.ConditionServer, 'barFlashISI');
      flashCycle = flashDuration + flashDelay;
      seqLength = numel(obj.BarRectSeq);
      barIdx = mod(floor(timenow/flashCycle), seqLength) + 1;
      if mod(timenow, flashCycle) > flashDuration
        barIdx = -1;
      end
      if barIdx ~= obj.BarIdx
        obj.StimWindow.invalidate; %make sure the new bar gets draw ASAP
        if barIdx > 0
          obj.BarIdx = barIdx;
          %store the new bar's details in experiment data
          barAzi = obj.BarAzimuths(obj.BarRectSeq(barIdx));
          obj.Data.barAzimuth = [obj.Data.barAzimuth; barAzi];
          obj.Data.barColour = [obj.Data.barColour; obj.BarColourSeq(obj.BarIdx)];
          obj.Data.barChangeTime = [obj.Data.barChangeTime; timenow];
        end
      end
      
      % check lick trace for contingent licking
      %if appropriate start a new phase
      %obj.startPhase('positiveFeedback', obj.Clock.now)
      % else if inappropriate
      %obj.startPhase('negativeFeedback', obj.Clock.now)
    end
    
    function drawFrame(obj)
      %Called during the main experiment loop to draw the current
      %stimulus when the screen has been invalidated
      
      %% Draw grating if in grating phase
      if inPhase(obj, 'grating')
        drawTexture(obj.StimWindow, obj.TargetTexture, [], obj.TargetRect);
      end
      
      %% Select the properties for the current bar
      if obj.BarIdx > 0
        %retrieve relevant parameters
        rects = obj.BarPxRects;
        rectSeq = obj.BarRectSeq;
        colourSeq = obj.BarColourSeq;
        %pick out the stuff for the current bar
        barRect = rects(rectSeq(obj.BarIdx),:); %bounding rect for the bar to draw
        barTex = obj.BarTextures(colourSeq(obj.BarIdx)); %texture for bar to draw
        %draw the bar
        %[] parameter is the source rectangle, which means use the default
        %behaviour drawing the whole texture
        drawTexture(obj.StimWindow, barTex, [], barRect);
      end
    end
    
    function handleKeyboardInput(obj, keysPressed, keysReleased)
      %Called during main experiment loop to handle keys pressed
      
      %let superclass handle inputs it's interested in (e.g. esc for quit)
      handleKeyboardInput@exp.LIARExperiment(obj, keysPressed, keysReleased);
      
      if any(keysPressed(obj.RewardKey))
        % handle the quit key being pressed
        disp('Reward key pressed');
      else
      end
    end
  end
  
end

