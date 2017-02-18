classdef MessageReceived < event.EventData
  %IO.MESSAGERECEIVED TODO
  %   Detailed explanation goes here
  
  properties
    Id %Id string of the message
    Data %Abritrary data in the message
    Sender %The sender of the message
  end
  
  methods
    function obj = MessageReceived(id, data, sender)
      obj.Id = id;
      obj.Data = data;
      obj.Sender = sender;
    end
  end
  
end

