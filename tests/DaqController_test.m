classdef DaqController_test < matlab.unittest.TestCase
  
  properties
  end

  methods (Test)
    function test_dependant_properties(testCase)
      c = hw.DaqController;
      testCase.verifyEmpty(c.AnalogueChannelsIdx)
      testCase.verifyEqual(c.NumChannels, 0)
      
      c.DaqChannelIds = {'ao0', 'ctr1', 'ao1', 'AO2'};
      expected = [true, false, true, true];
      testCase.verifyEqual(c.AnalogueChannelsIdx, expected)
      testCase.verifyEqual(c.NumChannels, 4)
    end
  end
  
end
