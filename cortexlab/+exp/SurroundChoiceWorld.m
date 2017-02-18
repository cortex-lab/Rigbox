classdef SurroundChoiceWorld < exp.ChoiceWorld
  %EXP.SURROUNDCHOICEWORLD Experiment with dragging stimuli on left or right
  %   See also EXP.CHOICEWORLD & EXP.LIAREXPERIMENT.
  %
  % Part of Burgbox

  % 2012-10 CB created

  properties (Access = protected)
    BgTexture
    BgBounds
%     InitialTargetBounds
%     BlankTargetTexture = []
%     TargetTexture = []
%     ResponsePos
  end
  
  methods
    function obj = SurroundChoiceWorld()
      obj = obj@exp.ChoiceWorld();
    end
    
    function registerResponse(obj, id, time)
      registerResponse@exp.LIARExperiment(obj, id, time);
      if id == param(obj.ConditionServer, 'responseForNoGo')
        obj.ResponsePos = obj.InputGain* ...
          (obj.InputSensor.LastPosition - obj.InputOffset);
      else
        thresh = param(obj.ConditionServer, 'responseForThreshold') == id;
        obj.ResponsePos = obj.InputThreshold(thresh);
      end
    end
    
    function calibrateInputGain(obj)
      % calibrate input sensor gain
      visWheelGain = obj.ConditionServer.param('visWheelGain');
      % calibrate to translation at centre/ahead screen location
      [cx, cy] = obj.StimViewingModel.pixelAtView(0, 0);
      % pixels per visual radian at the straight ahead screen position
      pxPerRad = obj.StimViewingModel.visualPixelDensity(cx, cy);
      
      % units conversion for gain factor:
      % visual:        deg -> px
      %          ------------------------
      % wheel:   mm  -> discrete 'clicks'
      warning('double check this calibration code')
      visPxPerWheelPos = deg2rad(visWheelGain)*pxPerRad*obj.InputSensor.MillimetresFactor;
      obj.InputGain = visPxPerWheelPos;
    end
    
    function prepareStim(obj)     
      screenBounds = obj.StimWindow.Bounds;
      viewModel = obj.StimViewingModel;
      
      stimRad = max(RectWidth(screenBounds), RectHeight(screenBounds));
      obj.BgBounds = CenterRect(SetRect(0, 0, 2*stimRad, 2*stimRad), screenBounds);
      
      cs = obj.ConditionServer; % the condition server holds this trial's params
      
      if paramExists(cs, 'surroundContrast')
        surroundContrast = param(cs, 'surroundContrast');
      else
        surroundContrast = 0.0;
      end
      
      targetColour = reshape(param(cs, 'targetColour'), [1 1 3]);
      bgColour = reshape(param(cs, 'bgColour'), [1 1 3]);

      % get stimulus parameters for this trial
      angleBetweenTargets = deg2rad(param(cs, 'distBetweenTargets'));
      targetAltitude = deg2rad(param(cs, 'targetAltitude'));
      targetWidthAngle = deg2rad(param(cs, 'targetWidth'));
      targetThresholdAngle = repmat(deg2rad(param(cs, 'targetThreshold')), [2 1]);
      cueSpatialFreq = param(cs, 'cueSpatialFrequency'); % grating, cycles per degree
      % convert visual cue spatial freq to wavelength in radians (visual
      % angle) per (grating period) cycle
      cueWavelength = deg2rad(1/cueSpatialFreq);
      targetCons = param(cs, 'visCueContrast');
      % cue sigma is the grating size [w;h]
      cueSigma = deg2rad(param(cs, 'cueSigma'));
      % orientation of gabor
      targetOri = deg2rad(param(cs, 'targetOrientation'));
      
      % visual field coords of target centres'
      alt = targetAltitude*[1; 1];
      azi = 0.5*angleBetweenTargets*[-1; 1];
      centrePolar = atan2(alt, azi);
      centreAngle = hypot(alt, azi);
      
      %Graphics coords of straight ahead & target centres
      [aheadCX, aheadCY] = pixelAtView(viewModel, 0, 0);
      [targetCX, targetCY] = pixelAtView(viewModel, centrePolar, centreAngle);
      
      %Calculate bounds of targets. Note that we assume 
      %the visual field horizon is aligned with the monitor's x-axis.
      %targetPxPerRad - is visual pixel density at the centre of each target
      %
      %Target columns span the top to bottom of the stim window, with
      %width of customisable visual field angle
      [columnBounds, targetPxPerRad] = approxViewBounds(viewModel,...
        centrePolar, centreAngle, targetWidthAngle, 0);
      columnBounds = [...
        columnBounds(:,1),...
        [0; 0],... %top of screen
        columnBounds(:,3),...
        repmat(screenBounds(4), 2, 1)]; %bottom of screen
      obj.InitialTargetBounds = round(columnBounds);
      obj.InitialTargetBounds = repmat(obj.BgBounds, 2, 1);
      %compute (w,h) sigma of Gabor in pixel units
      sigmaBounds = approxViewBounds(viewModel,...
        centrePolar, centreAngle, repmat(cueSigma(1), 2, 1), repmat(cueSigma(2), 2, 1));
      sigmaSize = [...
        (sigmaBounds(:,3) - sigmaBounds(:,1)),... %widths
        (sigmaBounds(:,4) - sigmaBounds(:,2))]; %heights

      % 'InputThreshold' are the x pixel position offsets in the world
      % required to reach a response threshold for each target. Note that
      % bringing a left target to the ahead position requires moving it to
      % the right, and vice versa.
      obj.InputThreshold = aheadCX - pixelAtView(viewModel, centrePolar, targetThresholdAngle);
      
      % we calibrate the spatial frequency at spots which are at the
      % intersection of the visual field horizon and the graphics centre of
      % each target column. The final parameter for creating the stimuli
      % are wavelengths (per grating cycle) in pixels.
      pxWavelength = mean(cueWavelength*targetPxPerRad);
      texRes = 500;
      
      surrPhase = 2*pi*rand;
      
      grating = surroundContrast*cos(2*pi*linspace(-stimRad/pxWavelength, stimRad/pxWavelength, texRes) + surrPhase);
      
      ensureWindowReady(obj); %ensure graphics window is ready for ops
      
      % delete any previous textures
      deleteTextures(obj.StimWindow);
      
      % background/surround texture
      obj.BgTexture = makeTexture(obj.StimWindow, bsxfun(@times, 0.5*(grating + 1), 2*(bgColour + 1) - 1));
      
      %generate both target textures
      obj.BlankTargetTexture = zeros(1, 2);
      obj.TargetTexture = zeros(1, 2);
      phase = zeros(1, 2);
      
      for i = 1:2
        colxx = stimRad*linspace(-1, 1, texRes);%obj.InitialTargetBounds(i,1):obj.InitialTargetBounds(i,3);
%         colyy = linspace(, texRes);%obj.InitialTargetBounds(i,2):obj.InitialTargetBounds(i,4);
        % Gabor gratings, randomised cosine phase
        phase(i) = 2*pi*rand; % randomised gabor phase
        [targetImg, gaussImg] = vis.gabor(...
          colxx - targetCX(i) + aheadCX, colxx - targetCY(i) + aheadCY,... 
          sigmaSize(i,1), sigmaSize(i,2), pxWavelength,...
          0, targetOri, phase(i));
        mask = 20*gaussImg;
        mask(mask > 1) = 1;
        blankImg = repmat(targetColour, [size(targetImg), 1]);
        targetImg = repmat(targetCons(i)*targetImg, [1 1 3]); % replicate three colour channels
        targetImg = round(blankImg.*(1 + targetImg));
        targetImg = cat(3, targetImg, round(255*mask));
        targetImg = min(max(targetImg, 0), 255);
        
%         obj.BlankTargetTexture(i) = makeTexture(obj.StimWindow, round(blankImg));
        obj.TargetTexture(i) = makeTexture(obj.StimWindow, round(targetImg));
      end
      log(obj, 'visCuePhase', phase);
      log(obj, 'surroundPhase', surrPhase);
      log(obj, 'surroundContrast', surroundContrast);
    end
  end

  methods (Access = protected)
    function drawFrame(obj)
      if inPhase(obj, 'interactive')
        pos = obj.InputGain*(obj.InputSensor.LastPosition - obj.InputOffset);
      elseif inPhase(obj, 'feedback')
        pos = obj.ResponsePos;
      else
        pos = 0;
      end
      
      if inPhase(obj, 'stimulusBackground')
        surroundOri = param(obj.ConditionServer, 'surroundOrientation');
        bounds = OffsetRect(obj.BgBounds, pos, 0);
        drawTexture(obj.StimWindow, obj.BgTexture, [], bounds, -surroundOri);
      end
      if inPhase(obj, 'stimulusCue')
        stimTextures = obj.TargetTexture;
        bounds = OffsetRect(obj.InitialTargetBounds, pos, 0)';
        setAlphaBlending(obj.StimWindow, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        drawTexture(obj.StimWindow, stimTextures, [], bounds);
        setAlphaBlending(obj.StimWindow, GL_ONE, GL_ZERO);
      end
%       if ~isempty(stimTextures)
%         bounds = OffsetRect(obj.InitialTargetBounds, pos, 0)';
%         drawTexture(obj.StimWindow, stimTextures, [], bounds);
% %         if ~isfield(obj.Data.trial, 'stimFrame')
% %           n = 1;
% %         else
% %           n = length(obj.Data.trial(obj.TrialNum).stimFrame) + 1;
% %         end
% %         obj.Data.trial(obj.TrialNum).stimFrame(n).time = obj.Clock.now;
% %         obj.Data.trial(obj.TrialNum).stimFrame(n).targetBounds = round(bounds);
%       end
    end    
  end
  
end

