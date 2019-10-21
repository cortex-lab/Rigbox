classdef DummyExperiment < exp.Experiment
  %EXP.DUMMYEXPERIMENT Just lists the current phases on screen
  %   This is an example experiment implementation that just displays the
  %   current phases. 
  %
  % It can just be created and run without any triggers, in which case it
  % will just run until you press the quit key (escape by default). It will
  % need a stimulus window though, e.g. using a pyschtoolbox window:
  % 
  % e = exp.DummyExperiment;
  % e.StimWindow = hw.debugWindow;     % opens an onscreen stimulus window
  % e.ConditionServer = exp.PresetConditionServer([],[]);
  % e.Clock.zero();                    % zero the experiment clock
  % e.run([]);                         % will run until you press <escape>
  % e.StimWindow.close();              % close the stimulus window
  %
  % You can also try this with some triggers that cause it to cycle through
  % trials and phase changes. e.g. before running, try:
  %
  % TODO
  %
  % Part of Rigbox
  
  % 2012-11 CB created
  
  properties
  end
  
  methods
    function obj = DummyExperiment()
      obj.DisplayDebugInfo = true;
    end
  end

  methods (Access = protected)
    function drawFrame(obj)
      if inPhase(obj, 'stimulus')
        % draw texture during stimulus phase
        drawTexture(obj.StimWindow, obj.StimTexture);
      end
    end
  end
  
end

