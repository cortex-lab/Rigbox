classdef Bars < exp.Experiment
  %UNTITLED Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    StimTexture
    StimBounds
  end
  
  methods
    function prepareStim(obj)
      screenBounds = obj.StimWindow.Bounds;
      view = obj.StimViewingModel;
      cond = obj.ConditionServer;
      
      pos = deg2rad(param(cond, 'position')); % xpos or ypos, degrees
      colour = param(cond, 'colour');
      sz = deg2rad(param(cond, 'size')); % visual angle - 1 cycle = 10 degrees
      ori = param(cond, 'orientation'); % visual angle - 1 cycle = 10 degrees
      % [left top right bottom]
      
      switch ori
        case {'vertical' 'ver' 'v'}
          xBounds = pixelAtSpherical(view, [pos pos] + sz*[-0.5 0.5], [0 0]);
          bounds = [xBounds(1) screenBounds(2) xBounds(2) screenBounds(4)];
        case {'horizontal' 'hor' 'h'}
          [~, yBounds] = pixelAtSpherical(view, [0 0], [pos pos] + sz*[0.5 -0.5]);
          bounds = [screenBounds(1) yBounds(1) screenBounds(3) yBounds(2)];
        otherwise
          error('Unknown orientation category "%s"', ori)
      end
      
      obj.StimBounds = bounds;
      ensureWindowReady(obj); %ensure graphics window is ready for ops
      % delete any previous textures
      deleteTextures(obj.StimWindow);
      
      obj.StimTexture = makeTexture(obj.StimWindow, reshape(colour, 1, 1, []));
    end
  end
  
  methods (Access = protected)
    function init(obj)
      init@exp.Experiment(obj); % do superclass init
    end
    
    function drawFrame(obj)
      if inPhase(obj, 'stimulus')
        bounds = obj.StimBounds;
        drawTexture(obj.StimWindow, obj.StimTexture, [], bounds);
      end
      if ~isfield(obj.Data.trial, 'stimFrame')
        n = 1;
      else
        n = length(obj.Data.trial(obj.TrialNum).stimFrame) + 1;
      end
      obj.Data.stimFrame(n).time = obj.Clock.now;
      obj.Data.stimFrame(n).stimBounds = round(obj.StimBounds);
    end
  end
  
end


