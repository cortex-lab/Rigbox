function im = sigEdgeDisc(xx, yy, radius, border)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

[xx, yy] = meshgrid(xx, yy);

dd = sqrt(xx.^2 + yy.^2);
im = taper(dd) + taper(-dd) - 1;


  function y = taper(x)
    y = -2*(x - radius*(1 - 0.5*border))./(radius*border);
    y = 0.5*(erf(y) + 1);
  end

end

