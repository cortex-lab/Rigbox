function onNextEvent(source, eventName, fun)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

done = false;
eventName = ensureCell(eventName);
listeners = event.listener.empty;
for ii = 1:numel(eventName)
  listeners(ii) = addlistener(source, eventName{ii}, @doit);
end

  function doit(src, evtData)
    if ~done
      done = true;
      fun(src, evtData);
    end
    delete(listeners(isvalid(listeners)));
  end
end

