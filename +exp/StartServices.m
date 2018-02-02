classdef StartServices < exp.Action
  %EXP.STARTSERVICES Starts experiment services
  %   Convenience action for use with an EventHandler. This will start the
  %   associated services, by calling start(ref) on them, where 'ref' is
  %   taken from the Experiment's reference and the current instance of
  %   Alyx (if any). See also SRV.SERVICE, EXP.STOPSERVICES
  %
  % Part of Rigbox

  % 2013-06 CB created  
  
  properties
    Services %service objects to start
  end
  
  methods
    function obj = StartServices(services)
      obj.Services = services;
    end
    
    function obj = set.Services(obj, value)
      if ~iscell(value)
        value = {value};
      end
      assert(all(cellfun(@(e) isa(e, 'srv.Service'), value)),...
        'Services must be an srv.Service object, or an array thereof');
      obj.Services = value;
    end

    function perform(obj, eventInfo, ~)
      %PERFORM Starts each service sequentially
      % perform(obj, eventInfo, dueTime)
      %
      expRef = eventInfo.Experiment.Data.expRef;
      ai = eventInfo.Experiment.AlyxInstance;
      n = numel(obj.Services);
      for i = 1:n
        try
          obj.Services{i}.start(expRef, ai);
          fprintf('Started ''%s''\n', obj.Services{i}.Title);
        catch ex
          %stop services that were started up till now
          fun.applyForce(@(s) s.stop(), obj.Services(1:(i- 1)));
          rethrow(ex); % now rethrow the exception
        end
      end
    end
  end
  
end

