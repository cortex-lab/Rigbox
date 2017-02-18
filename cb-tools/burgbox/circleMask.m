function m = circleMask(r)%, cx, cy, w, h)
disp('**using circleMask**');
[x, y] = meshgrid(-r:r, -r:r);
m = x.^2 + y.^2 < r.^2;
end

