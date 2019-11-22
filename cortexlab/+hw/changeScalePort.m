function scale = changeScalePort(port, rigname)
if nargin < 2
  rigname = upper(hostname);
end

hwPath = fullfile(getOr(dat.paths,'globalConfig'),rigname,'hardware.mat');
load(hwPath, 'scale')
scale.ComPort = iff(upper(port(1)) == 'C', upper(port), ['COM',num2str(port)]);
save(hwPath, 'scale', '-append')