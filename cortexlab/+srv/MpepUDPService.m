classdef MpepUDPService < srv.Service
  %SRV.MPEPUDPSERVICE Start/stop Mpep data hosts for an experiment
  %   TODO
  %   See also IO.MPEPUDPDATAHOSTS, SRV.SERVICE.
  %
  % Part of Rigbox

  % 2014-02 CB created  
  
  properties (Dependent, SetAccess = protected)
    Status
  end
  
  properties (SetAccess = protected)
    DataHosts
  end
  
  methods
    function obj = MpepUDPService(dataHosts)
      obj.DataHosts = dataHosts;
      obj.Title = 'mpep UDP data hosts';
      obj.Id = 'mpepdatahosts';
    end

    function value = get.Status(obj)
      value = 'idle';
%       if all(obj.DataHosts.Connected)
%         if isempty(obj.ExpRef)
%           value = 'idle';
%         else
%           value = 'running';
%         end
%       else
%         value = 'unavailable';
%       end
    end

    function start(obj, expRef)
      fprintf('start stub ''%s''\n', expRef);
    end
    
    function stop(obj)
      fprintf('stop stub ''%s''\n', expRef);
    end
  end
  
end

