classdef Signals < exp.SignalsExp
  %EXP.SIGNALSEXP Base class for stimuli-delivering experiments
  %   The class defines a framework for event- and state-based experiments.
  %   Visual and auditory stimuli can be controlled by experiment phases.
  %   Phases changes are managed by an event-handling system.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  methods
    
    function updateParams(obj, paramStruct)
      % get global parameters & conditional parameters structs
      fprintf('Updating parameters\n');
      [~, globalStruct, allCondStruct] = toConditionServer(...
        exp.Parameters(paramStruct));
      obj.GlobalPars.post(rmfield(globalStruct, 'defFunction'));
      obj.ConditionalPars.post(allCondStruct);
    end
          
    function post(obj, id, msg)
      com = obj.Communicator;
      if isa(com, 'io.Communicator')
        send(com, id, msg);
      elseif isa(com, 'srv.StimulusControl')
        % Notify listeners of event to simulate remote message received
        switch id
          case 'signals'
            evt = srv.ExpEvent('signals', [], msg);
            notify(com, 'ExpUpdate', evt);
          case 'status'
            type = msg{1};
            switch type
              case 'starting'
                %experiment about to start
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
      end
    end
        
  end
  
  methods (Access = protected)

    function saveData(~)
    % Do nothing
    end
    
  end
  
end