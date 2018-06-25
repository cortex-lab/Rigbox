function elem = checkerLeft(t)
%vis.checker A grid of rectangles
%   Detailed explanation goes here

elem = t.Node.Net.subscriptableOrigin('checker');

%% make initial layers to be used as templates
maskTemplate = vis.emptyLayer();
maskTemplate.isPeriodic = false;
maskTemplate.interpolation = 'nearest';
maskTemplate.show = true;
maskTemplate.colourMask = [false false false true];

maskTemplate.textureId = 'checkerMaskPixel';
[maskTemplate.rgba, maskTemplate.rgbaSize] = vis.rgba(0, 0);
maskTemplate.blending = '1-source'; % allows us to lay down our zero alpha value

stencilTemplate = maskTemplate;
stencilTemplate.textureId = 'checkerStencilPixel';
[stencilTemplate.rgba, stencilTemplate.rgbaSize] = vis.rgba(1, 1);
stencilTemplate.blending = 'none';

% pattern layer uses the alpha values laid down by mask layers
patternLayer = vis.emptyLayer();
patternLayer.textureId = sprintf('~checker%i', randi(2^32));
patternLayer.isPeriodic = false;
patternLayer.interpolation = 'nearest';
patternLayer.blending = 'destination'; % use the alpha mask gets laid down before this

%% construct signals used to assemble layers
% N rows by cols signal is derived from the size of the pattern array but
% we skip repeats so that pattern changes don't update the mask layers
% unless the size has acutally changed
nRowsByCols = elem.pattern.flatten().map(@size).skipRepeats();
aziRange = elem.azimuthRange.flatten();
altRange = elem.altitudeRange.flatten();
sizeFrac = elem.rectSizeFrac.flatten();
% signal containing the masking layers
gridMaskLayers = mapn(nRowsByCols, aziRange, altRange, sizeFrac, ...
  maskTemplate, stencilTemplate, @gridMask);
% signal contain the checker layer
checkerLayer = scan(elem.pattern.flatten(), @updatePattern,...
                   elem.colour.flatten(), @updateColour,...
                   elem.azimuthRange.flatten(), @updateAzi,...
                   elem.altitudeRange.flatten(), @updateAlt,...
                   elem.show.flatten(), @updateShow,...
                   patternLayer); % initial value
%% set default attribute values
elem.layers = [gridMaskLayers checkerLayer];
elem.azimuthRange =  [-135 0];
elem.altitudeRange = [-37.5 37.5];
elem.rectSizeFrac = [1 1]; % horizontal and vertical size of each rectangle
elem.pattern = [
   1 -1  1 -1
  -1  0  0  0 
   1  0  0  0
  -1  1 -1  1];
 elem.show = true;
end

%% helper functions
function layer = updatePattern(layer, pattern)
% map pattern from -1 -> 1 range to 0->255, cast to 8 bit integers, then
% convert to RGBA texture format.
[layer.rgba, layer.rgbaSize] = vis.rgbaFromUint8(uint8(127.5*(1 + pattern)), 1);
end

function layer = updateColour(layer, colour)
layer.maxColour = [colour 1];
end

function layer = updateAzi(layer, aziRange)
layer.size(1) = abs(diff(aziRange));
layer.texOffset(1) = mean(aziRange);
end

function layer = updateAlt(layer, altRange)
layer.size(2) = abs(diff(altRange));
layer.texOffset(2) = mean(altRange);
end

function layer = updateShow(layer, show)
layer.show = show;
end

function layers = gridMask(nRowsByCols, aziRange, altRange, sizeFrac, mask, stencil)
gridDims = [abs(diff(aziRange)) abs(diff(altRange))];
cellSize = gridDims./flip(nRowsByCols);
nCols = nRowsByCols(2) + 1;
nRows = nRowsByCols(1) + 1;
midAzi = mean(aziRange);
midAlt = mean(altRange);
%% base layer to imprint area the checker can draw on (by applying an alpha mask)
stencil.texOffset = [midAzi midAlt];
stencil.size = gridDims;
if any(sizeFrac < 1)
  %% layers for lines making up mask grid - masks out margins around each square
  % make layers for vertical lines
  if nCols > 1
    azi = linspace(aziRange(1), aziRange(2), nCols);
  else
    azi = midAzi;
  end
  collayers = repmat(mask, 1, nCols);
  for vi = 1:nCols
    collayers(vi).texOffset = [azi(vi) midAlt];
  end
  [collayers.size] = deal([(1 - sizeFrac(1))*cellSize(1) gridDims(2)]);
  % make layers for horizontal lines
  if nRows > 1
    alt = linspace(altRange(1), altRange(2), nRows);
  else
    alt = midAlt;
  end
  rowlayers = repmat(mask, 1, nRows);
  for hi = 1:nRows
    rowlayers(hi).texOffset = [midAzi alt(hi)];
  end
  [rowlayers.size] = deal([gridDims(1) (1 - sizeFrac(2))*cellSize(2)]);
  %% combine the layers and return
  layers = [stencil collayers rowlayers];
else % no mask grid needed as each cell is full size
  layers = stencil;
end

end