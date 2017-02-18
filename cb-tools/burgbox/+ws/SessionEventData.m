classdef SessionEventData < event.EventData
  %UNTITLED Summary of this class goes here
  %   Detailed explanation goes here
  
  properties
    Session
    Message
  end
  
  methods
    function obj = SessionEventData(session, message)
      obj.Session = session;
      if nargin > 1
        obj.Message = message;
      end
    end
  end
  
end

