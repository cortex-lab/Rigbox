classdef ViewingModel < handle
  %HW.VIEWINGMODEL Conversions between graphics and visual field parameters
  %   This is an abstract class defining an interface for converting
  %   between graphics and visual field parameters/coordinates etc, using
  %   some model of the graphics display and view of it by the subject.
  %
  % Part of Rigbox
  
  % 2012-11 CB created

  methods (Abstract)
    % Returns the 'visual' pixel density (px per rad) at a point
    %
    % This may be useful e.g. for choosing spatial frequency of stimuli at
    % a certain point on the screen.
    %
    % PXPERRAD = visualPixelDensity(X, Y) returns the number of pixels per
    % radian (PXPERRAD) of visual angle at the pixel with coordinates (X,Y).
    pxPerRad = visualPixelDensity(obj, x, y)

    % Visual angle between two pixel points
    %
    % This is useful if you want to measure graphics dimensions in visual
    % angles.
    %
    % RAD = visualAngleBetweenPixels(X1, Y1, X2, Y2) returns the visual
    % angle for the subject in radians (RAD) between two pixels on the 
    % screen.
    rad = visualAngleBetweenPixels(obj, x1, y1, x2, y2)
    
    % Screen pixel of a visual field locus
    %
    % This may be useful e.g. for placing stimuli at a certain point in the
    % subjects visual field. Also, the presumed 'straight-ahead' view pixel
    % should map to the centre of the visual field (zero polar and visual
    % angles).
    %
    % [X, Y] = pixelAtView(POLARANGLE, VISUALANGLE) returns the pixel 
    % coordinates of some point on the screen corresponding to a viewing
    % locus specified in polar visual field coordinates (by POLARANGLE and
    % VISUALANGLE).
    [x, y] = pixelAtView(obj, polarAngle, visualAngle)

    % Visual field coordinates of a specified pixel
    %
    % [POLARANGLE ,VISUALANGLE] = viewAtPixel(X, Y) returns the polar
    % visual field coordinates (by POLARANGLE and VISUALANGLE) of the 
    % pixel on the screen (specified by X,Y) as viewed by the subject.
    [polarAngle, visualAngle] = viewAtPixel(obj, x, y)
  end
  
  methods
    function [pixRect, pxPerRad] = approxViewBounds(obj, centrePolar, centreAngle, w, h)
      % Approximate screen pixel bounds of specified view region
      %
      % [PIXRECT] = viewAtPixel(CENTREPOLAR, CENTREANGLE, W, H) returns the
      % the approximate bounding rectangle on the graphics device, PIXRECT, 
      % of the visual field region with specified centre, of width and height
      % (W and H; visual field angle in radians).
      % 
      % TODO: generalise this so that it works if the monitor's x-axis is
      % not aligned with the visual horizon
      [cx, cy] = pixelAtView(obj, centrePolar, centreAngle);
      pxPerRad = visualPixelDensity(obj, cx, cy);
      pxW = pxPerRad.*w;
      pxH = pxPerRad.*h;
      pixRect = [cx - 0.5*pxW, cy - 0.5*pxH, cx + 0.5*pxW, cy + 0.5*pxH];
    end
  end
  
end

