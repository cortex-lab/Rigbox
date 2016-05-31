classdef TriggerLaser < exp.Action
  %EXP.TRIGGERLASER Triggers laser pulse in an experiment
  %   Convenience action for use with an EventHandler. This will trigger
  %   a laser using the Experiment DaqLaser, See also EXP.EVENTHANDLER,
  %   HW.DAQLASER.
  %
  % Part of Rigbox

  % 2014-05 CB created  
  
  properties
    Device % device to trigger
    Probability % probability of triggering laser on each activation
%     SizeParam
  end
  
  methods
    function obj = TriggerLaser(dev, p)
      obj.Device = dev;
      obj.Probability = p;
%       obj.SizeParam = sizeParam;
    end

    function perform(obj, eventInfo, dueTime)
      e = eventInfo.Experiment;
%       sz = param(eventInfo, obj.SizeParam); %reward size
      if rand < obj.Probability
        log(e, 'laserTriggeredTime', e.Clock.now);
        deliverBackground(obj.Device, 0);
%         post(e, 'status',...
%           {'update', e.Data.expRef, 'rewardDelivered', sz, dueTime});
      end
    end
  end
  
end

