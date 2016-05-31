function t = eventTimes(trials, event)
%blockEventTimes Returns a vector of times of the named event

t = [trials.([event 'Time'])];

end

