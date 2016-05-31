classdef StopServices < exp.Action
  %EXP.STOPSERVICES Stops experiment services
  %   Convenience action for use with an EventHandler. This will stop the
  %   configured experiment services, by calling stop(ref) on each (where
  %   'ref' is the experiment's reference). See also SRV.SERVICE.
  %
  % Part of Rigbox

  % 2013-06 CB created
  
  properties
    Services %service objects to stop
  end
  
  methods
    function obj = StopServices(services)
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

    function perform(obj, eventInfo, dueTime)
      %try to stop all the services
      [ex, exServices] = fun.applyForce(@(s) s.stop(), obj.Services);
      %throw up an error if any failed to stop
      if ~isempty(ex)
          for ei = 1:numel(ex)
              try
              warning('**** Exception %i stopping service ''%s'': ***\n', ei, exServices{ei}{2});
              end
%               disp(ex{ei}.getReport);
          end
%         failList = mkStr(mapToCell(@(e) e{2}.Title, exServices), [], ',', []);
%         error('Not all services stopped (%s)', failList);
      end
    end
  end
  
end

