classdef SignalsTest < exp.SignalsExp
  
  properties
    Debugging = true
  end
    
  methods
    function useRig(obj,~)
      disp('using defaults')
      % Devices
      obj.Wheel = MockSensor();
      obj.Wheel.addprop('EncoderResolution');
      obj.Wheel.EncoderResolution = 1024;
      obj.Wheel.MillimetresFactor = 31*2*pi/400;
%       obj.LickDetector = MockSensor();
      % Window
      % TODO Move to class
      oldShieldingLevel = Screen('Preference', 'WindowShieldingLevel', 1249);
      oldVBLTimestampingMode = Screen('Preference', 'VBLTimestampingMode', -1);
      oldSkipSyncTests = Screen('Preference', 'SkipSyncTests', 2);
      screenNum = max(Screen('Screens'));
      obj.NextSyncIdx = 1;
      obj.StimWindowPtr = Screen('OpenWindow', screenNum, 0, [0,0,1280,600]);
      Screen('FillRect', obj.StimWindowPtr, 255/2);
      Screen('Flip', obj.StimWindowPtr);
      obj.Occ = vis.init(obj.StimWindowPtr);
      % Set output listeners
      % TODO
    end
    
    function delete(~)
      Screen('CloseAll')
    end
  end
  
  methods (Access = protected)
    function saveData(~)
      % Do nothing; not called when expRef empty
    end
  end
end