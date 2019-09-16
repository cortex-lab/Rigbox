classdef PseudoCircularScreenViewingModel < hw.ViewingModel
  %HW.PSEUDOCIRCULARSCREENVIEWINGMODEL Multiple screens viewed from a point
  % 
  %   Warning: this is probably broken. At least needs tidying up
  %
  %   This model assumes screens as one part of a sphere, does not assume
  %   the screen rims are connected with each other.
  %   CB: is this true? Is it not a cyclinder, where the screens are
  %   connected?
  %
  % Note: For now, the subject's 'straight-ahead'/zero visual angle is
  % assumed to be *along the z-axis* towards the screen.
  % Part of Rigbox

  % 2012-11 - created by Chris Burgess
  % 2013-01 - modefied by Daisuke Shimaoka (spelling Daisuke?)
  % 2013-09 - fixed by Chris Burgess/Bilal Haider
  properties
    %A position vector [y,z] of the subject in metres, with respect to
    %the (centre of the) top left pixel of the screen. y is aligned
    %with the standard graphics axes (i.e. y going down),
    %while z extends out from the screen perpendicular to the plane of the
    %display).
    %animal is assumed to be horizontally placed at the middest of the
    %screens (so there's no 'x' parameter)
    %SubjectPos
    
    %Number of pixels across the screen. Also see the function
    %useGraphicsPixelWidth to deduce this directly from the graphics
    %hardware.
    ScreenWidthPixels
    
    %The physical width of the screen, in metres. Pixels are assumed to
    %have a 1:1 aspect ratio.
    %ScreenHeightMetres
    
    %Visual field range covered by screen [left, right] relative to
    %zero straight ahead
    ScreenFieldDegrees
    
    %Straight ahead pixel y coordinate
    HorizonYPixel
    
    %r in pixels = pixel arc length/angle covered by screen in radians
  end
  
  methods
    function px = pixelRadius(obj)
      px = obj.ScreenWidthPixels/screenFieldWidth(obj);
    end
    
    function rad = screenFieldWidth(obj)
      rad = deg2rad(diff(obj.ScreenFieldDegrees));
    end
    
    function [x, y] = pixelAtSpherical(obj, azi, alt)
      rpx = pixelRadius(obj);
      y = obj.HorizonYPixel - rpx.*tan(alt);
      x = (rad2deg(azi) - obj.ScreenFieldDegrees(1)).*obj.ScreenWidthPixels/diff(obj.ScreenFieldDegrees);
    end
    
    function pxPerRad = visualPixelDensity(obj, x, y)
      % Returns the 'visual' pixel density (px per rad) at a point
      
      pxPerRad = repmat(obj.ScreenWidthPixels/screenFieldWidth(obj), size(x));
      
      %             sz = size(x);
      %
      %             pxPerMetre = obj.ScreenWidthPixels/obj.ScreenWidthMetres;
      %             zPx = pxPerMetre*obj.SubjectPos(2); % view distance in pixels
      %
      %
      %             % Screen distance in pixels, d, as a function of visual angle, t:
      %             % d(t) = zPx*tan(t)
      %             % Derivative w.r.t. t yields pixel density at a given visual angle:
      %             % d'(t) = zPx*sec(t)^2
      %             pxPerRad = zPx*ones(sz);%*sec(t).^2;
    end
    
    function useGraphicsPixelWidth(obj, ptbScreenNum)
      rect = Screen('Rect', ptbScreenNum);
      obj.ScreenWidthPixels = rect(3);
    end
    
    function [x, y] = pixelAtView(obj, polarAngle, visualAngle)
      % central fixation: (polarangle, visualangle) = (0,0)
      % Screen pixel of a visual field locus
      
      vx = visualAngle.*cos(polarAngle);
      vy = visualAngle.*sin(polarAngle);
      
      rpx = pixelRadius(obj);
      y = obj.HorizonYPixel - rpx.*tan(vy);
      x = (rad2deg(vx) - obj.ScreenFieldDegrees(1)).*obj.ScreenWidthPixels/diff(obj.ScreenFieldDegrees);
      
      %             pxPerMetre = obj.ScreenWidthPixels/obj.ScreenWidthMetres;
      %
      %             sy = obj.SubjectPos(1);
      %
      %             % calc screen x & y projections of visual field locus
      %             % NB: polar angle *increases* anticlockwise from horizon->right
      %             d = obj.SubjectPos(2)*tan(visualAngle);
      %             x = pxPerMetre*(d.*cos(polarAngle) + 0.5*obj.ScreenWidthMetres );
      %             y = pxPerMetre*(d.*sin(-polarAngle) + sy);
    end
    
    function [polarAngle, visualAngle] = viewAtPixel(obj, x, y)
      % Visual field coordinates of a specified pixel
      
      rpx = pixelRadius(obj);
      %(hopefully!) inverse of
      %x = (vx - obj.ScreenFieldDegrees(1)).*obj.ScreenWidthPixels/diff(obj.ScreenFieldDegrees);
      vx = deg2rad(x.*diff(obj.ScreenFieldDegrees)./obj.ScreenWidthPixels + obj.ScreenFieldDegrees(1));
      
      %hopefully inverse of
      %y = obj.HorizonYPixel - rpx.*tan(vy);
      vy = atan2(obj.HorizonYPixel - y, rpx);
      
      polarAngle = atan2(vy, vx);
      visualAngle = hypot(vx, vy);
      
      %             % Visual angle from central fixation pixel to specified pixel
      %             [centrePx, centrePy] = pixelAtView(obj, 0, 0);
      %             centrePx = repmat(centrePx, size(x));
      %             centrePy = repmat(centrePy, size(y));
      %             visualAngle = visualAngleBetweenPixels(obj, x, y, centrePx, centrePy);
      %
      %             % Polar angle is just the angle from central fixation pixel to
      %             % specified (and increases anticlockwise from horizon->right).
      %             polarAngle = -atan2(y - centrePy, x - centrePx);
    end
    
    function rad = visualAngleBetweenPixels(obj, x1, y1, x2, y2)
      disp('PLEASE IMPLEMENT ME!!!')
      % Visual angle between two pixel points
      dist_px = sqrt((x1-x2).^2 +(y1-y2).^2);
      dist_metre = obj.ScreenWidthMetres/obj.ScreenWidthPixels * dist_px;
      
      %      rad = 2*asin(dist_metre ./ (2*obj.SubjectPos(2)));
      rad = dist_metre ./ obj.SubjectPos(2);
      
    end
  end
  
end

