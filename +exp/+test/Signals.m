classdef Signals < exp.SignalsExp
  %EXP.TEST.SIGNALSEXP Subclass for playing with Signals Experiments
  %   This class overloads a couple of superclass methods for running an
  %   experiment definition in a test enviroment.
  %
  % See also EUI.SIGNALSTEST
  %
  % Part of Rigbox
  
  % 2012-11 CB created
  
  methods
    
    function updateParams(obj, paramStruct)
      % UPDATEPARAMS Updates parameters after initialization
      %  Updates the parameter signals with a new parameter set.
      %
      %  Input:
      %    paramStruct : A parameter structure
      %
      
      % get global parameters & conditional parameters structs
      fprintf('Updating parameters\n');
      [~, globalStruct, allCondStruct] = toConditionServer(...
        exp.Parameters(paramStruct));
      if isfield(globalStruct, 'defFunction')
        globalStruct = rmfield(globalStruct, 'defFunction');
      end
      obj.GlobalPars.post(globalStruct);
      obj.ConditionalPars.post(allCondStruct);
    end
    
    function post(obj, id, msg)
      % POST Directly trigger remote rig events, simulating Web Sockets
      %  If the Communicator is a srv.StimulusControl object, its events
      %  are notified as if the events have been received from a Web
      %  socket.
      %
      % See also SRV.STIMULUSCONTROL
      com = obj.Communicator;
      if isa(com, 'srv.StimulusControl')
        % Notify listeners of event to simulate remote message received
        switch id
          case 'signals'
            evt = srv.ExpEvent('signals', [], msg);
            notify(com, 'ExpUpdate', evt);
          case 'status'
            type = msg{1};
            switch type
              case 'starting'
                % experiment about to start
                ref = msg{2};
                notify(com, 'ExpStarting', srv.ExpEvent('starting', ref));
              case 'update'
                ref = msg{2}; args = msg(3:end);
                if strcmp(args{1}, 'event') && strcmp(args{2}, 'experimentInit')
                  notify(com, 'ExpStarted', srv.ExpEvent('started', ref));
                elseif strcmp(args{1}, 'event') && strcmp(args{2}, 'experimentEnded')
                  % message usually sent by expServer
                  notify(com, 'ExpStopped', srv.ExpEvent('completed', ref));
                end
                notify(com, 'ExpUpdate', srv.ExpEvent('update', ref, args));
            end
          otherwise
            % Do nothing upon Alyx request
        end
      else
        post@exp.SignalsExp(obj, id, msg)
      end
    end
    
  end
  
  methods (Access = protected)
    
    function saveData(~)
      % Do nothing
    end
    
  end
  
end