classdef PlaySound < exp.Action
  %EXP.PLAYSOUND Plays the currently loaded sound
  %   Convenience action for use with an EventHandler. This will play the
  %   sound that was last loaded in the experiment.
  %   See also EXP.LOADSOUND.
  %
  % Part of Rigbox

  % 2013-06 CB created
  
  properties
    Name %name of the sound, used for naming/recording the event
    Delay
  end
  
  methods
    function obj = PlaySound(name, delay)
      obj.Name = name;
      obj.Delay = delay;
    end
    
    function obj = set.Delay(obj, value)
      if (islogical(value) && value == false)
        % Delay is false means sound plays immediately & action will block
        % until playback commences
        obj.Delay = false;
      else
        obj.Delay = exp.TimeSampler.using(value);
      end
    end

    function perform(obj, eventInfo, dueTime)
      delay = obj.Delay;
      if (islogical(delay) && delay == false)
        % play ASAP and wait to start so an accurate start time is obtained
        playSound(eventInfo.Experiment, obj.Name, 1, [], true);
      else
        % play at dueTime + specified delay, and do not wait to start
        playTime = dueTime + delay.secs;
        playSound(eventInfo.Experiment, obj.Name, 1, playTime, false);
      end
    end
  end
  
end

