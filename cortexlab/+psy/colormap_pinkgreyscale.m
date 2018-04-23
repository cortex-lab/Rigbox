function map = colormap_pinkgreyscale()
% pink for one extreme, greyscale for the other half. 

map = zeros(100,3);
map(50:-1:1,:) = repmat([(1:50)/50]',1,3);
map(100,:) = [1 0 1];

map = map(end:-1:1,:);

