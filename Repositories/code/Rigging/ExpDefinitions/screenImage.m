function [x,y,im] = screenImage(pars)

c = getOr(pars, 'stimulusContrast', nan(1,2)); 
cL = c(1); 
cR = c(2); 

sf = getOr(pars, 'spatialFreq', 1/15);
ori = getOr(pars, 'stimulusOrientation', 0);
% al = pars.stimulusAltitude;
parnames = fieldnames(pars);
idx = contains(parnames, 'azimuth', 'IgnoreCase',true);
az = iff(any(idx), pars.(parnames{idx}), 35);

sigma = getOr(pars, 'sigma', 7);
sigma = sigma(1);

pixPerDeg = 3;

bgc = 127;

xExtent = 540;
im = ones(70*pixPerDeg,xExtent*pixPerDeg)*bgc;
x = linspace(-xExtent/2, xExtent/2, size(im,2));
y = linspace(-35, 35, size(im,1));

gratSize = sigma*7*pixPerDeg;
gw = (gausswin(gratSize, 1/(sigma*pixPerDeg/gratSize*2))*gausswin(gratSize, 1/(sigma*pixPerDeg/gratSize*2))');
gw = gw./max(gw(:));

% sine wave
gratL = imrotate(repmat(sin([1:gratSize]/gratSize*2*pi*gratSize/pixPerDeg*sf),gratSize,1).*gw*cL,ori,'bilinear','crop');
gratR = imrotate(repmat(sin([1:gratSize]/gratSize*2*pi*gratSize/pixPerDeg*sf),gratSize,1).*gw*cR,ori,'bilinear','crop');

gratL = gratL*127+bgc;
gratR = gratR*127+bgc;

sy = round(size(im,1)/2);
insertIndsY = (1:gratSize)+sy-round(gratSize/2);

sx = round((-az+xExtent/2)*pixPerDeg);
insertInds = (1:gratSize)+sx-round(gratSize/2);
incl = insertInds>0&insertInds<size(im,2);
im(insertIndsY, insertInds(incl)) = gratL(:,incl);

sx = round((az+xExtent/2)*pixPerDeg);
insertInds = (1:gratSize)+sx-round(gratSize/2);
incl = insertInds>0&insertInds<size(im,2);
im(insertIndsY, insertInds(incl)) = gratR(:,incl);

