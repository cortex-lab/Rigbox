classdef calibrate_test < matlab.unittest.TestCase & matlab.mock.TestCase & matlab.mixin.SetGet
  % CALIBRATE_TEST Tests for hw.calibrate
  
  properties % Mocks
    scale
    generator
    controller
    scaleBehaviour
    generatorBehaviour
    controllerBehaviour
  end
  
  properties
    tMin = 20e-3
    tMax = 150e-3
    interval = 0.1
    delivPerSample = 300
    nPerT = 3
    nVolumes = 5
    volumeRange = [0.06, 3.5]
    noise = 0.05; % s.d.
  end
  
  properties (Access = protected)
    LastGrams
    measurements
  end
  
  methods (TestClassSetup)
    function setupMocks(testCase)
      % Create mocks.  Note that using the metaclass is intended for
      % abstract classes.
      [testCase.scale, testCase.scaleBehaviour] = ...
        createMock(testCase, ...
        'AddedProperties', properties(hw.WeighingScale)', ...
        'AddedMethods', methods(hw.WeighingScale)');
      
      [testCase.generator, testCase.generatorBehaviour] = ...
        createMock(testCase, ...
        'AddedProperties', properties(hw.RewardValveControl)', ...
        'AddedMethods', methods(hw.RewardValveControl)');
      
      [testCase.controller, testCase.controllerBehaviour] = ...
        createMock(testCase, ...
        'AddedProperties', properties(hw.DaqController)', ...
        'AddedMethods', methods(hw.DaqController)');
    end
    
  end
  
  methods (TestMethodSetup)
    
    function mockMeasurements(testCase)
      rng = testCase.volumeRange; % grams
      vols = linspace(rng(1), rng(2), testCase.nVolumes)*testCase.delivPerSample;
      %       err = repmat((vols/100)*10, testCase.nPerT, 1);
      r = normrnd(repmat(vols, testCase.nPerT, 1), testCase.noise) / 1000;
      testCase.measurements = cumsum([0; 3; r(:)]);
    end
    
    function setup(testCase)
      
      import matlab.mock.actions.Invoke
      import matlab.mock.actions.AssignOutputs
      import matlab.mock.actions.StoreValue
      import matlab.mock.actions.ReturnStoredValue
      
      testCase.assignOutputsWhen(... % ComPort
        get(testCase.scaleBehaviour.Port), serial('port'))
      % Define tare behaviour
      when(testCase.scaleBehaviour.tare.withExactInputs, ...
        Invoke(@(~) set(testCase, 'LastGrams', 0)));
      % When zero scale during init
      when(testCase.scaleBehaviour.init.withExactInputs, ...
        Invoke(@(~) testCase.scale.tare()));
      
      % Define behaviours for controller
      names = {'rewardValve', 'digitalChannel'};
      testCase.assignOutputsWhen(... % ChannelNames
        get(testCase.controllerBehaviour.ChannelNames), names)
      
      generators = repmat(testCase.generator, size(names));
      testCase.assignOutputsWhen(... % SignalGenerators
        get(testCase.controllerBehaviour.SignalGenerators), generators)
      
      % Define behaviours for generator
      when(set(testCase.generatorBehaviour.ParamsFun), StoreValue)
      when(get(testCase.generatorBehaviour.ParamsFun), ReturnStoredValue)
    end
  end
  
  methods (Test)
    
    function test_calibration(tc)
      import matlab.mock.actions.AssignOutputs
      action = AssignOutputs(0);
      for i = 1:length(tc.measurements)
        action = action.then(AssignOutputs(tc.measurements(i)));
      end
      when(tc.scaleBehaviour.readGrams.withExactInputs, action)
      
      % Set something to check ParamsFun is replaced on errors
      rnd = rand;
      tc.generator.ParamsFun = @()rnd;
      
      hw.calibrate('rewardValve', tc.controller, tc.scale, tc.tMin, tc.tMax, ...
        'settleWait', 0, ...
        'nPert', tc.nPerT, ...
        'nVolumes', tc.nVolumes, ...
        'interval', tc.interval, ...
        'delivPerSample', tc.delivPerSample);
      
      % Retrieve mock history
      history = tc.getMockHistory(tc.generator);
      % Create sequence and find calibration values
      f = @(a)endsWith(class(a), 'Modification') && strcmp(a.Name, 'Calibrations');
      seq = sequence(mapToCell(@identity, history));
      actual = seq.reverse.filter(f).first.Value;
      
      tc.assertTrue(~isNil(actual), 'Failed to record calibration')
      
      tolerance = 1/(24*60); % 1 Minute
      tc.verifyEqual(actual.dateTime, now, 'AbsTol', tolerance, ...
        'Unexpected date time recorded for calibration')
      
      minMax = [actual.measuredDeliveries([1 end]).durationSecs];
      tc.verifyEqual(minMax, [tc.tMin, tc.tMax], 'Unexpected measured time range')
      
      rng = tc.volumeRange;
      vols = linspace(rng(1), rng(2), tc.nVolumes);
      tc.verifyEqual(vols, [actual.measuredDeliveries.volumeMicroLitres], 'AbsTol', 0.3);
      
      tc.verifyEqual(tc.generator.ParamsFun(), rnd, ...
        'Failed to reset ParamsFun property in signal generator')
      
      % Retrieve mock history
      history = tc.getMockHistory(tc.controller);
      % find calls to command
      f = @(a) strcmp(a.Name, 'command');
      in = cell2mat(fun.map(@(a)a.Inputs{2}, fun.filter(f, history)))';
      
      expected = (tc.nPerT * tc.nVolumes) + 1; % +1 for scale test
      tc.verifyEqual(expected, size(in,1), ...
        'Unexpected number of called to DAQ command method')
      tc.verifyTrue(all(in(2:end,3) == tc.delivPerSample), ...
        'Unexpected number of called to DAQ command method')
      tc.verifyTrue(all(in(2:end,2) == tc.interval), ...
        'Unexpected number of called to DAQ command method')
    end
    
    function test_scale_fails(tc)
      import matlab.mock.actions.Invoke
      import matlab.mock.actions.AssignOutputs
      import matlab.mock.actions.ThrowException
      
      % Define readGrams behaviour
      when(tc.scaleBehaviour.readGrams.withExactInputs, ...
        Invoke(@(~) tc.LastGrams));
      % Set something to check ParamsFun is replaced on errors
      rnd = rand;
      tc.generator.ParamsFun = @()rnd;
      
      % Test errors on uninitiated scale:
      fn = @()hw.calibrate('rewardValve', tc.controller, ...
        hw.WeighingScale, tc.tMin, tc.tMax, 'settleWait', 0);
      tc.verifyError(fn, 'Rigbox:hw:calibrate:noscales')
      % Test input errors:
      fn = @()hw.calibrate('rewardValve', tc.controller, ...
        hw.WeighingScale, tc.tMin, tc.tMax, 'partial');
      tc.verifyError(fn, 'Rigbox:hw:calibrate:partialPVpair')
      % Test unresponsive scale
      tc.scale.init;
      fn = @()hw.calibrate('rewardValve', tc.controller, ...
        tc.scale, tc.tMin, tc.tMax, 'settleWait', 0);
      tc.verifyError(fn, 'Rigbox:hw:calibrate:deadscale')
      tc.verifyEqual(tc.generator.ParamsFun(), rnd, ...
        'Failed to reset ParamsFun property in signal generator')
      
      action = AssignOutputs(0);
      for i = 1:length([0;3;3])
        action = action.then(AssignOutputs(tc.measurements(i)));
      end
      action = action.then(ThrowException(MException('test:unexpected','')));
      when(tc.scaleBehaviour.readGrams.withExactInputs, action)
      fn = @()hw.calibrate('rewardValve', tc.controller, ...
        tc.scale, tc.tMin, tc.tMax, 'settleWait', 0);
      tc.verifyError(fn, 'test:unexpected')
      tc.verifyEqual(tc.generator.ParamsFun(), rnd, ...
        'Failed to reset ParamsFun property in signal generator')
    end
  end
  
end