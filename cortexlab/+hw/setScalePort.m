function scale = setScalePort(port, rigname)
% CHANGESCALEPORT Set the port of the scale in the hardware object
%  Sets the COM port of the scale and saves it into the hardware file.
%  
%  Inputs:
%    port (char|numerical) : which port to set the hardware scale to
%    rigname (char) : the host name of the rig whose scale port to change
%  
%  Output:
%    scale (hw.WeighingScale) : the edited scale object
%
%  Examples:
%    scale = setScalePort('COM3')
%    setScalePort(3, 'ZREDONE')
% 
% See also HW.DEVICES
if nargin < 2
  rigname = upper(hostname);
end

hwPath = fullfile(getOr(dat.paths,'globalConfig'),rigname,'hardware.mat');
load(hwPath, 'scale')
scale.ComPort = iff(upper(port(1)) == 'C', upper(port), ['COM',num2str(port)]);
save(hwPath, 'scale', '-append')