function f = weibull50(pars,xx)
%WEIBULL50 Weibull function from 0.5 to 1, with lapse rate
%
% f = weibull50([alpha,beta,gamma],xx) is
% (1 - gamma) - (1/2 - gamma) * exp(-(xx/alpha)^beta)
%
% alpha is the threshold
% beta is the slope
% gamma is the % of errors users make anyhow
%
% See also: Weibull
%
% 2000-04 MC 

xx = xx(:)';

if nargin~=2
   error('Error in function Weibull: Wrong number of input arguments');
end
if size(xx,1)~=1
   error('Error in function Weibull: variable xx must be a vector');
end
if size(pars)~=[1,3]
   error('Error in function Weibull: Wrong number of input arguments in pars!')
end

alpha	= pars(1);
beta	= pars(2);
gamma	= pars(3);

if alpha<0
   error('alpha must be positive');
end

if length(alpha)~=1 || length(beta)~=1 || length(gamma)~=1
   error('Variables ''alpha'',''beta'' and ''gamma'' must be scalar!');
end

f = (1 - gamma) - (0.5 - gamma) * exp( -((xx./alpha).^beta));

