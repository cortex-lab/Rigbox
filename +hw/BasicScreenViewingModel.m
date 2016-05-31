classdef BasicScreenViewingModel < hw.ViewingModel
  %HW.BASICSCREENVIEWINGMODEL Flat screen viewed from a point
  %   A view model for a flat screen viewed from a point with viewing
  %   coordinates (in metres) specified along their screen x and y axes,
  %   and a z-axis emanating from the screen perpendicular to its surface
  %   plane. 
  %
  % Note: For now, the subject's 'straight-ahead'/zero visual angle is
  % assumed to be *along the z-axis* towards the screen.
  %
  % Part of Rigbox
  
  % 2012-11 CB created
  
  properties
    %A position vector [x,y,z] of the subject in metres, with respect to
    %the (centre of the) top left pixel of the screen. x and y are aligned
    %with the standard graphics axes (i.e. x to the right, y going down),
    %while z extends out from the screen perpendicular to the plane of the
    %display).
    SubjectPos

    %Number of pixels across the screen. Also see the function 
    %useGraphicsPixelWidth to deduce this directly from the graphics 
    %hardware.
    ScreenWidthPixels

    %The physical width of the screen, in metres. Pixels are assumed to
    %have a 1:1 aspect ratio.
    ScreenWidthMetres
  end
  
  methods
    
    function pxPerRad = visualPixelDensity(obj, x, y)
      % Returns the 'visual' pixel density (px per rad) at a point
      
      % get the visual angle, t, of the specified pixel
      [polarAngle, t] = viewAtPixel(obj, x, y);
      
      pxPerMetre = obj.ScreenWidthPixels/obj.ScreenWidthMetres;
      zPx = pxPerMetre*obj.SubjectPos(3); % view distance in pixels
      
      % Screen distance in pixels, d, as a function of visual angle, t:
      % d(t) = zPx*tan(t)
      % Derivative w.r.t. t yields pixel density at a given visual angle:
      % d'(t) = zPx*sec(t)^2
      pxPerRad = zPx*sec(t).^2;
    end

    function useGraphicsPixelWidth(obj, ptbScreenNum)
      rect = Screen('Rect', ptbScreenNum);
      obj.ScreenWidthPixels = rect(3);
    end

    function [x, y] = pixelAtView(obj, polarAngle, visualAngle)
      % Screen pixel of a visual field locus

      pxPerMetre = obj.ScreenWidthPixels/obj.ScreenWidthMetres;
      
      s = obj.SubjectPos(1:2);
      if isrow(s)
        s = s';
      end
      
      % calc screen x & y projections of visual field locus
      % NB: polar angle *increases* anticlockwise from horizon->right
      d = obj.SubjectPos(3)*tan(visualAngle);
      x = pxPerMetre*(d.*cos(polarAngle) + s(1));
      y = pxPerMetre*(d.*sin(-polarAngle) + s(2));  
    end

    function [polarAngle, visualAngle] = viewAtPixel(obj, x, y)
      % Visual field coordinates of a specified pixel
      
      % Visual angle from central fixation pixel to specified pixel
      [centrePx, centrePy] = pixelAtView(obj, 0, 0);
      centrePx = repmat(centrePx, size(x));
      centrePy = repmat(centrePy, size(y));
      visualAngle = visualAngleBetweenPixels(obj, x, y, centrePx, centrePy);
      
      % Polar angle is just the angle from central fixation pixel to
      % specified (and increases anticlockwise from horizon->right).
      polarAngle = -atan2(y - centrePy, x - centrePx);
    end

    function rad = visualAngleBetweenPixels(obj, x1, y1, x2, y2)
      % Visual angle between two pixel points
      
      % convert everything to a row vector
      sz = size(x1); % assume everything has the same size
      nElems = prod(sz);
      x1 = reshape(x1, 1, nElems);
      y1 = reshape(y1, 1, nElems);
      x2 = reshape(x2, 1, nElems);
      y2 = reshape(y2, 1, nElems);

      % convert the points to 3D vectors (units of metres) in the plane
      % of the screen
      metresPerPx = obj.ScreenWidthMetres/obj.ScreenWidthPixels;
      p1 = metresPerPx*[x1 ; y1 ; zeros(1, nElems)];
      p2 = metresPerPx*[x2 ; y2 ; zeros(1, nElems)];

      s = obj.SubjectPos;
      if isrow(s)
        s = s';
      end
      s = repmat(s, 1, nElems);
      
      % calculate the angle between the vectors from the subject's pov to
      % the points being viewed (dot product divided by magnitude product)
      viewP1 = p1 - s;
      viewP2 = p2 - s;
      rad = acos(dot(viewP1, viewP2)./sqrt(sum(viewP1.^2).*sum(viewP2.^2)));
      
      % reshape back to input dimensions
      rad = reshape(rad, sz);
    end
  end
  
end

