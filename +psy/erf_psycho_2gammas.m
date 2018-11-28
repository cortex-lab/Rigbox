function f = erf_psycho_2gammas(pars,xx)
%ERF_PSYCHO_2GAMMAS erf function from 0 to 1, wiht two lapse rates
%
% f = erf_psycho_2gammas([threshold slope gamma1 gamma2],xx)
%
% Example:
% xx = -50:50;
% ff = erf_psycho_2gammas([-10 10 0.2 0.0],xx);
% figure; plot(xx, ff); set(gca,'ylim',[0 1]);
%
% MC 2000
% 2013-06 MC and MD

threshold	= pars(1);
slope 		= pars(2);
gamma1      = pars(3);
gamma2      = pars(4);


f = nan(size(xx));

% ii = (xx<threshold);
% f( ii) = gamma1 + (1-2*gamma1)* (erf( (xx( ii)-threshold)/slope ) + 1)/2;
% f(~ii) = gamma2 + (1-2*gamma2)* (erf( (xx(~ii)-threshold)/slope ) + 1)/2;

f = gamma1 + (1-gamma1-gamma2)* (erf( (xx-threshold)/slope ) + 1)/2;



