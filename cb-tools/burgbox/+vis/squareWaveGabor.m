function [G, gauss, grate] = squareWaveGabor(xx, yy, sigmaX, sigmaY, lambda, thetaGauss, thetaCos, phi)
%VIS.GABOR Creates a Gabor image
%   -- xx, yy -- coordinates over which to calculate the image
%   -- sigmaX, sigmaY -- size of gaussian aperture along major and minor
%   axes
%   -- lambda -- related to spatial frequency
%   -- thetaGauss -- rotation of gaussian aperture (i.e. if not circular)
%   -- thetaCos -- orientation of grating
%   -- phi -- phase of grating
%
% Part of Burgbox

% 2012-01 CB created vis.gabor
% 2015-01-09 NAS modified one line to change it to square waves

%     x_range = linspace( -x_size/2, x_size/2, x_size );
%     y_range = linspace( -y_size/2, y_size/2, y_size );
    [X, Y] = meshgrid(xx, yy);
    Xe = X.*cos(thetaGauss) + Y.*sin(thetaGauss);
    Ye = Y.*cos(thetaGauss) - X.*sin(thetaGauss);
    Xc = X.*cos(thetaCos - pi/2) + Y.*sin(thetaCos - pi/2);
    gauss = exp( -Xe.^2./(2*sigmaX^2) + -Ye.^2./(2*sigmaY^2) );
    grate = 2*(cos( 2*pi*Xc./lambda + phi )>0)-1; % NAS changed this line to go from sine wave to square wave 2015-10-09
    G = gauss.*grate;
end