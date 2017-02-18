function frame = translateFrame(fftframe, dx, dy)


[h, w] = size(fftframe);

% fy changes along first dimension
fy = reshape(ifftshift((-fix(h/2):ceil(h/2) - 1)/h), [], 1);
% fx changes along second dimension
fx = reshape(ifftshift((-fix(w/2):ceil(w/2) - 1)/w), 1, []);
%translation in space domain is rotation in frequency domain
% i.e. need to rotate each coefficient by translation times component's freq
% bsxfun expands singleton dimensions as neccessary to match sizes of its
% array arguments. Same outcome as repmat along those dimension without the
% additional memory requirements (in theory)

% compute complex fourier coeff then rotate
frame = abs(ifft2(... % fourier inverse
  fftframe.*exp(-1j*2*pi*(bsxfun(@plus, dy*fy, dx*fx)))));
  

end

