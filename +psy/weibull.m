function f = weibull(pars,xx)
%WEIBULL Weibull function from 0 to 1, with lapse rate
%
% f = weibull([alpha,beta,gamma],xx) is
% (1 - gamma) - (1 - 2*gamma) * exp(-(xx/alpha)^beta)
%
% This function goes from -(1-gamma) to (1-gamma). If you need a function
% that goes from 0.5 to (1-gamma), use weibull50
%
% 1999-11 FH wrote it
% 2000-01 MC cleaned it up

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

if length(alpha)~=1 || length(beta)~=1 || length(gamma)~=1
   error('Variables ''alpha'',''beta'' and ''gamma'' must be scalar!');
end

f = (1 - gamma) - (1 - 2*gamma) * exp( -((xx./alpha).^beta));

