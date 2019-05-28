%% Test obj2struct with given data
data = struct;
data.A = struct(... % Scalar struct
  'field1', zeros(10), ...
  'field2', true(10), ...
  'field3', pi, ...
  'field4', single(10), ...
  'field5', '10');
data.B = hw.DaqController(); % Obj containing empty obj
v = daq.getVendors();
if v(strcmp({v.ID},'ni')).IsOperational
  data.B.createDaqChannels(); % Add daq.ni obj
end
data.C = struct; % Non-scalar struct
data.C(1,1).a = 1;
data.C(2,1).a = 2;
data.C(1,2).a = 3;
data.C(2,2).a = 4;
data.D = @(a,b,c)zeros(c,b,a); % Function handle

json = obj2json(data);
out = '{"A":{"field1":[[0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0,0]],"field2":[[true,true,true,true,true,true,true,true,true,true],[true,true,true,true,true,true,true,true,true,true],[true,true,true,true,true,true,true,true,true,true],[true,true,true,true,true,true,true,true,true,true],[true,true,true,true,true,true,true,true,true,true],[true,true,true,true,true,true,true,true,true,true],[true,true,true,true,true,true,true,true,true,true],[true,true,true,true,true,true,true,true,true,true],[true,true,true,true,true,true,true,true,true,true],[true,true,true,true,true,true,true,true,true,true]],"field3":3.1415926535897931,"field4":10,"field5":"10"},"B":{"ClassContructor":"hw.DaqController","ChannelNames":[],"SignalGenerators":{"ClassContructor":"hw.PulseSwitcher","OpenValue":[],"ClosedValue":[],"ParamsFun":[],"DefaultCommand":[],"DefaultValue":[]},"DaqIds":"Dev1","DaqChannelIds":[],"SampleRate":1000,"DaqSession":[],"DigitalDaqSession":[],"Value":[],"NumChannels":0,"AnalogueChannelsIdx":[]},"C":[[{"a":1},{"a":3}],[{"a":2},{"a":4}]],"D":"@(a,b,c)zeros(c,b,a)"}';
assert(strcmp(json,out), 'Test failed')