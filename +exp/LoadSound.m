classdef LoadSound < exp.Action
  %EXP.LOADSOUND Loads specified samples ready for playing
  %   Convenience action for use with an EventHandler. This will load the
  %   audio samples from the specified parameter onto the Experiment audio
  %   device ready for playback. Samples will be multipled by the contents
  %   of the specified amplitude parameter before loading (used to
  %   modulate amplitude). See also EXP.PLAYSOUND.
  %
  % Part of Rigbox

  % 2013-06 CB created
  
  properties
    SamplesParam %name of parameter for the sound's samples
    AmpParam %name of parameter for the amplitude modulation
  end
  
  methods
    function obj = LoadSound(samplesParam, ampParam)
      obj.SamplesParam = samplesParam;
      obj.AmpParam = ampParam;
    end

    function perform(obj, eventInfo, dueTime)
      amp = param(eventInfo, obj.AmpParam);
      samples = param(eventInfo, obj.SamplesParam);
      %samples are assumed to be wrapped in a cell array
      samples = samples{1};
      loadSound(eventInfo.Experiment, amp.*samples);
    end
  end
  
end

