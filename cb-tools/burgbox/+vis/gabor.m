function [G, gauss, grate] = gabor(xx, yy, sigmaX, sigmaY, lambda, thetaGauss, thetaCos, phi)
%VIS.GABOR Creates a Gabor image
%   TODO
%
% Part of Burgbox

% 2012-01 CB created

%     x_range = linspace( -x_size/2, x_size/2, x_size );
%     y_range = linspace( -y_size/2, y_size/2, y_size );
    [X, Y] = meshgrid(xx, yy);
    Xe = X.*cos(thetaGauss) + Y.*sin(thetaGauss);
    Ye = Y.*cos(thetaGauss) - X.*sin(thetaGauss);
    Xc = X.*cos(thetaCos - pi/2) + Y.*sin(thetaCos - pi/2);
    gauss = exp( -Xe.^2./(2*sigmaX^2) + -Ye.^2./(2*sigmaY^2) );
    grate = cos( 2*pi*Xc./lambda + phi );
    G = gauss.*grate;
end