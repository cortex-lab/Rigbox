classdef ChoiceWorld < exp.LIARExperiment
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
      viewModel = obj.StimViewingModel;
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
      cueSigma = deg2rad(param(cs, 'cueSigma'));
      % orientation of gabor
      targetOri = deg2rad(param(cs, 'targetOrientation'));
      if numel(targetOri) == 1
        targetOri = repmat(targetOri, 2, 1);
      end
      
      % visual field coords of target centres'
      alt = targetAltitude*[1; 1];
      azi = 0.5*angleBetweenTargets*[-1; 1];
      centrePolar = atan2(alt, azi);
      centreAngle = hypot(alt, azi);
      
      %Graphics coords of straight ahead & target centres
      [aheadCX, ~] = pixelAtView(viewModel, 0, 0);
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
      cuePxWavelengths = cueWavelength*targetPxPerRad;
      
      ensureWindowReady(obj); %ensure graphics window is ready for ops
      
      % delete any previous textures
      deleteTextures(obj.StimWindow);
      
      %generate both target textures
      obj.BlankTargetTexture = zeros(1, 2);
      obj.TargetTexture = zeros(1, 2);
      phase = zeros(1, 2);
      for i = 1:2
        colxx = obj.InitialTargetBounds(i,1):obj.InitialTargetBounds(i,3);
        colyy = obj.InitialTargetBounds(i,2):obj.InitialTargetBounds(i,4);
        % Gabor gratings, randomised cosine phase
        phase(i) = 2*pi*rand; % randomised gabor phase
        targetImg = targetCons(i)*vis.gabor(...
          colxx - targetCX(i), colyy - targetCY(i),...
          sigmaSize(i,1), sigmaSize(i,2), cuePxWavelengths(i),...
          0, targetOri(i), phase(i));
        blankImg = repmat(targetColour, [size(targetImg), 1]);
        targetImg = repmat(targetImg, [1 1 3]); % replicate three colour channels
        targetImg = round(blankImg.*(1 + targetImg));
        targetImg = min(max(targetImg, 0), 255);
        
        obj.BlankTargetTexture(i) = makeTexture(obj.StimWindow, round(blankImg));
        obj.TargetTexture(i) = makeTexture(obj.StimWindow, round(targetImg));
      end
      log(obj, 'visCuePhase', phase);
    end
  end

  methods (Access = protected)
    function drawFrame(obj)
      if inPhase(obj, 'interactive')
        posGain = param(obj.ConditionServer, 'stimPositionGain');
        pos = posGain(1)*obj.InputGain*(obj.InputSensor.LastPosition - obj.InputOffset);
      elseif inPhase(obj, 'feedback')
        posGain = param(obj.ConditionServer, 'stimPositionGain');
        pos = posGain(end)*obj.ResponsePos;
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
    
    function saveData(obj)
      saveData@exp.Experiment(obj);
      
      % If Alyx URL not set or default subject, simply return
      subject = dat.parseExpRef(obj.Data.expRef);
      if isempty(getOr(dat.paths, 'databaseURL')) || strcmp(subject, 'default')
        return
      end
      
      if ~obj.AlyxInstance.IsLoggedIn
        warning('Rigbox:exp:SignalsExp:noTokenSet', 'No Alyx token set');
        try
          % Register saved files
          savepaths = dat.expFilePath(obj.Data.expRef, 'block');
          obj.AlyxInstance.registerFile(savepaths{end});
          
          % Save the session end time
          if ~isempty(obj.AlyxInstance.SessionURL)
            % Infer from date session and retrieve using expFilePath
            url = getOr(obj.AlyxInstance.getSessions(obj.Data.expRef), 'url');
            assert(~isempty(url), 'Failed to determine session url')
            obj.AlyxInstance.SessionURL = url;
          end
          numTrials = obj.Data.numCompletedTrials;
          if isfield(obj.Data, 'trial') && isfield(obj.Data.trial, 'feedbackType')
            numCorrect = sum([obj.Data.trial.feedbackType] == 1);
          else
            numCorrect = 0;
          end
          sessionData = struct('end_time', obj.AlyxInstance.datestr(now), ...
            'n_trials', numTrials, 'n_correct_trials', numCorrect);
          obj.AlyxInstance.postData(obj.AlyxInstance.SessionURL, sessionData, 'patch');
        catch ex
          warning(ex.identifier, 'Failed to register files to Alyx: %s', ex.message);
        end
        try
          if ~isfield(obj.Data,'rewardDeliveredSizes') || ...
              strcmp(obj.Data.endStatus, 'aborted')
            return % No completed trials
          end
          amount = sum(obj.Data.rewardDeliveredSizes(:,1)); % Take first element (second being laser)
          if ~any(amount); return; end % Return if no water was given
          controller = obj.RewardController.SignalGenerators(strcmp(obj.RewardController.ChannelNames,'rewardValve'));
          type = iff(isprop(controller, 'WaterType'), controller.WaterType, 'Water');
          obj.AlyxInstance.postWater(subject, amount*0.001, now, type, obj.AlyxInstance.SessionURL);
        catch ex
          warning(ex.identifier, 'Failed to post water to Alyx: %s', ex.message);
        end
      end
    end
    
  end
  
end

