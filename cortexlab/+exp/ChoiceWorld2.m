classdef ChoiceWorld2 < exp.LIARExperiment
  %EXP.CHOICEWORLD Experiment with dragging stimuli on left or right
  %   See also EXP.LIAREXPERIMENT.
  %
  % Part of Burgbox

  % 2012-10 CB created

  properties (Access = protected)
    InitialTargetBounds
    BlankTargetTexture = []
    TargetTexture = []
    ResponsePos
  end
  
  methods
    function obj = ChoiceWorld()
      disp('test choice world')
      obj = obj@exp.LIARExperiment();
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
      view = obj.StimViewingModel;
      cs = obj.ConditionServer; % the condition server holds this trial's params
      targetColour = reshape(param(cs, 'targetColour'), [1 1 3]);

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
      cueSigma = deg2rad(param(cs, 'cueSigma'))';
      % orientation of gabor
      targetOri = deg2rad(param(cs, 'targetOrientation'));
      
      % visual field coords of target centres'
      alt = targetAltitude*[1; 1];
      azi = 0.5*angleBetweenTargets*[-1; 1];
      
      %Graphics coords of straight ahead & target centres
      [aheadCX, aheadCY] = pixelAtView(view, 0, 0);
      [targetCX, targetCY] = pixelAtSpherical(view, azi, alt);
      
      %Calculate bounds of targets. Note that we assume 
      %the visual field horizon is aligned with the monitor's x-axis.
      %targetPxPerRad - is visual pixel density at the centre of each target
      %
      targetPxPerRad = visualPixelDensity(view, targetCX, targetCY);
      % work from cx to meridian for sigma width conversion
      % work from cy downwards for sigma height conversion
%       if numel(
      [sigpxw, sigpxh] = pixelSizeAtXPosYPos(view, azi, alt, cueSigma(1), cueSigma(2));
      
      sw = RectWidth(screenBounds);
      sh = RectHeight(screenBounds);
      obj.InitialTargetBounds = screenBounds + [-sw -sh sw sh];
      %compute (w,h) sigma of Gabor in pixel units
%       sigma1 = pixelAtSpherical(view);
%       sigmaBounds = approxViewBounds(view,...
%         centrePolar, centreAngle, repmat(cueSigma(1), 2, 1), repmat(cueSigma(2), 2, 1));
%       sigmaSize = [...
%         (sigmaBounds(:,3) - sigmaBounds(:,1)),... %widths
%         (sigmaBounds(:,4) - sigmaBounds(:,2))]; %heights

      % 'InputThreshold' are the x pixel position offsets in the world
      % required to reach a response threshold for each target. Note that
      % bringing a left target to the ahead position requires moving it to
      % the right, and vice versa.
      thresh = aheadCX - targetCX;
      obj.InputThreshold = thresh;
      
      % we calibrate the spatial frequency at spots which are at the
      % intersection of the visual field horizon and the graphics centre of
      % each target column. The final parameter for creating the stimuli
      % are wavelengths (per grating cycle) in pixels.
      cuePxWavelengths = cueWavelength*targetPxPerRad;
      
      % delete any previous textures
      deleteTextures(obj.StimWindow);
      
      %generate both target textures
      obj.BlankTargetTexture = zeros(1, 2);
      obj.TargetTexture = zeros(1, 2);
      phase = zeros(1, 2);
      colxx = obj.InitialTargetBounds(1):obj.InitialTargetBounds(3);
      colyy = obj.InitialTargetBounds(2):obj.InitialTargetBounds(4);
      gaborImgs = zeros(numel(colyy), numel(colxx), 2); %y,x,col,ti
      for i = 1:2
        % Gabor gratings, randomised cosine phase
        phase(i) = 2*pi*rand; % randomised gabor phase
        gaborImgs(:,:,i) = targetCons(i)*vis.gabor(...
          colxx - targetCX(i), colyy - targetCY(i),...
          sigpxw(i), sigpxh(i), cuePxWavelengths(i),...
          0, targetOri, phase(i));
%         blankImg = repmat(targetColour, [size(targetImg), 1]);
%         targetImg = repmat(targetImg, [1 1 3]); % replicate three colour channels
%         targetImg = round(blankImg.*(1 + targetImg));
%         targetImg = min(max(targetImg, 0), 255);
        
%         gaborImgs(:,:,:,i) = targetImg;
      end
      finalImg = bsxfun(@times, 1 + sum(gaborImgs, 3), targetColour);
      finalImg = max(min(round(finalImg), 255), 0);
      obj.BlankTargetTexture = makeTexture(obj.StimWindow, targetColour);
      obj.TargetTexture = makeTexture(obj.StimWindow, finalImg);
      imagesc(finalImg/255);
      log(obj, 'visCuePhase', phase);
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
      
      stimTextures = [];
      if inPhase(obj, 'stimulusCue')
        stimTextures = obj.TargetTexture;
      elseif inPhase(obj, 'stimulusBackground')
        stimTextures = obj.BlankTargetTexture;
      end
      if ~isempty(stimTextures)
        bounds = OffsetRect(obj.InitialTargetBounds, pos, 0)';
        drawTexture(obj.StimWindow, stimTextures, [], bounds);
%         if ~isfield(obj.Data.trial, 'stimFrame')
%           n = 1;
%         else
%           n = length(obj.Data.trial(obj.TrialNum).stimFrame) + 1;
%         end
%         obj.Data.trial(obj.TrialNum).stimFrame(n).time = obj.Clock.now;
%         obj.Data.trial(obj.TrialNum).stimFrame(n).targetBounds = round(bounds);
      end
    end    
  end
  
end

