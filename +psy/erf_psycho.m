function f = erf_psycho(pars,xx)
%ERF_PSYCHO erf function from 0 to 1, with lapse rate
%
% f = erf_psycho([threshold slope gamma],xx)
%
% computes:
% f = gamma + (1-2*gamma)* (erf( (xx-threshold)/slope ) + 1)/2
%
% MC 2000

threshold	= pars(1);
slope 		= pars(2);
gamma       = pars(3);

f = gamma + (1-2*gamma)* (erf( (xx-threshold)/slope ) + 1)/2;
