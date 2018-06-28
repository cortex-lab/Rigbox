classdef DiscWorld < exp.LIARExperiment
  %EXP.DISCWORLD Choice by rotating a Gabor disc
  %   Detailed explanation goes here
  %
  % Part of Rigbox

  % 2013-01 CB created, inspired by Terry Pratchett
  
  properties
    DiscSigma = 100
    DiscBounds
    CueBounds
    CueTexture
  end
  
  methods
    function obj = DiscWorld()
      obj = obj@exp.LIARExperiment();
    end
    
    function calibrateInputGain(obj)
      % compute gain based on factor to covert input sensor to millimetres
      % and degPerMM
      radPerMM = deg2rad(obj.ConditionServer.param('visWheelGain'));
      obj.InputGain = obj.InputSensor.MillimetresFactor*radPerMM;
    end

    function prepareStim(obj)
      projection = obj.StimViewingModel;
      cs = obj.ConditionServer; % the condition server holds this trial's params
      colour = reshape(param(cs, 'cueColour'), [1 1 3]);
      
      % get stimulus parameters for this trial
      azimuth = deg2rad(param(cs, 'cueAzimuth'));
      elevation = deg2rad(param(cs, 'cueElevation'));
      angleThreshold = deg2rad(param(cs, 'choiceThreshold'));
      if numel(angleThreshold) < 2
        angleThreshold = repmat(angleThreshold, [2 1]);
      end
      obj.InputThreshold = angleThreshold;
      spatialFreq = param(cs, 'cueSpatialFrequency'); % grating, cycles per degree
      % convert visual cue spatial freq to wavelength in radians (visual
      % angle) per (grating period) cycle
      wavelen = deg2rad(1/spatialFreq);
      contrast = param(cs, 'visCueContrast');
      % cue sigma is the grating size [w;h]
      sigma = deg2rad(param(cs, 'cueSigma'));
      % initial orientation of gabor
      ori = deg2rad(param(cs, 'cueOrientation'));
      
      % visual field coords of cue centre
      cenPolar = atan2(elevation, azimuth);
      cenAngle = hypot(elevation, azimuth);
      
      %Graphics coords of cue centre
      [targetCX, targetCY] = pixelAtView(projection, cenPolar, cenAngle);
      
      %Calculate bounds of cue. Note that we assume
      %the visual field horizon is aligned with the monitor's x-axis.
      %cuePxPerRad - is visual pixel density at the centre of the cue
      texSize = 6.5*sigma; % texture size in radians to contain Gabor
      [texBounds, pxPerRad] = approxViewBounds(projection,...
        cenPolar, cenAngle, texSize(1), texSize(2));
      obj.CueBounds = round(texBounds);
      %compute (w,h) sigma of Gabor in pixel units
      [sigmaPxWidth, sigmaPxHeight] = RectSize(approxViewBounds(projection,...
        cenPolar, cenAngle, sigma(1), sigma(2)));
      
      % calibrate the spatial frequency at the graphics centre of
      % the cue. The final parameter for creating the stimuli
      % are wavelengths (per grating cycle) in pixels.
      pxWavelength = wavelen*pxPerRad;
      
      ensureWindowReady(obj); %ensure graphics window is ready for ops
      
      % delete any previous textures
      deleteTextures(obj.StimWindow);
      
      % x and y sample points for the gabor image
      xx = (obj.CueBounds(1):obj.CueBounds(3)) - targetCX;
      yy = (obj.CueBounds(2):obj.CueBounds(4)) - targetCY;
        
      % Gabor gratings, randomised cosine phase
      phase = 2*pi*rand; % randomised gabor phase
      targetImg = contrast*vis.gabor(...
        xx, yy,...
        sigmaPxWidth, sigmaPxHeight, pxWavelength,...
        0, ori, phase);
      % gabor modulates cue colour
      targetImg = round(bsxfun(@times, colour, (1 + targetImg)));
      targetImg = min(max(targetImg, 0), 255);
      obj.CueTexture = makeTexture(obj.StimWindow, round(targetImg));
      log(obj, 'visCuePhase', phase);
    end
  end
  
  methods (Access = protected)
    function drawFrame(obj)
      if inPhase(obj, 'interactive')
        cueAngle = obj.InputGain*(obj.InputSensor.LastPosition - obj.InputOffset);
      elseif inPhase(obj, 'feedback')
        response = obj.Data.trial(obj.TrialNum).responseMadeID;
        cueAngle = obj.InputThreshold(response);
      else
        cueAngle = 0;
      end
      
      if inPhase(obj, 'stimulusCue')
        drawTexture(obj.StimWindow, obj.CueTexture, [], obj.CueBounds, rad2deg(cueAngle));
      end
    end
  end
  
end

