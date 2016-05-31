classdef Clock < handle
  %HW.CLOCK An interface for abstracting clock implementation
  %   This class is to help with abstracting code that needs to timestamp
  % events. Subclasses of this implement timestamps using different clocks 
  % (e.g. using MATLAB's 'now', Psychtoolbox's 'GetSecs', or a DAQ
  % timing clock etc). The function 'now' must return the time in *seconds* since 
  % some reference time, as counted by whatever clock the subclass uses. This class 
  % also allows you to "zero" the reference time at some moment. Time is then counted 
  % up from that moment on (and is negative for times before that point). Code 
  % that needs to track time can use this class to remain agnostic about what 
  % timing clock is acutally used. You could even use this e.g. as a neat way to
  % run an experiment at a different speed.
  %
  % Part of Rigbox

  % 2012-10 CB created

  properties (SetAccess = protected)
    ReferenceTime = 0;
  end
  
  methods (Abstract, Access = protected)
    t = absoluteTime(obj)
  end
  
  methods
    function t = fromMatlab(obj, serialDateNum)
      % Converts from a MATLAB serial date number to the same time but
      % expressed in this clocks reference frame
      mnow = now; % use MATLAB's time function
      thisnow = now(obj); % use our time function
      t = thisnow + (serialDateNum - mnow)*24*60*60;
    end

    function t = fromPtb(obj, secs)
      % Converts from Psychtoolboxes GetSecs time to the same time but
      % expressed in this clocks reference frame
      ptbnow = GetSecs; % use psychtoolbox's time function
      thisnow = now(obj); % use our time function
      t = secs + (thisnow - ptbnow);
    end
    
    function t = toPtb(obj, secs)
      % Converts from this clocks reference frame to the same time but
      % expressed Psychtoolboxes GetSecs time
      ptbnow = GetSecs; % use psychtoolbox's time function
      thisnow = now(obj); % use our time function
      t = secs + (ptbnow - thisnow);
    end

    function t = now(obj)
      % t returned is the time now in seconds, either relative to some
      % arbritrary reference or if zero has been called, relative to that
      % moment
      t = absoluteTime(obj) - obj.ReferenceTime;
    end
    
    function zeroTime = zero(obj)
      zeroTime = absoluteTime(obj);
      obj.ReferenceTime = zeroTime;
    end
  end
  
end

