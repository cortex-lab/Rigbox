classdef DeliverReward < exp.Action
  %EXP.DELIVERREWARD Delivers reward in an experiment
  %   Convenience action for use with an EventHandler. This will deliver
  %   reward using the Experiment RewardController, with a size according
  %   to the parameter named in SizeParam. See also EXP.EVENTHANDLER,
  %   HW.REWARDCONTROLLER.
  %
  % Part of Rigbox

  % 2013-06 CB created  
  
  properties
    SizeParam
  end
  
  methods
    function obj = DeliverReward(sizeParam)
      obj.SizeParam = sizeParam;
    end

    function perform(obj, eventInfo, dueTime)
      e = eventInfo.Experiment;
      sz = param(eventInfo, obj.SizeParam); %reward size
      deliverReward(e, sz(:)');
    end
  end
  
end

