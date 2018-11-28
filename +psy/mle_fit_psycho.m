function [ pars, L ] = mle_fit_psycho(data,P_model,parstart,parmin,parmax,nfits)
% MLE_FIT_PSYCHO Maximumum likelihood fit of psychometric function
%
% pars = mle_fit_psycho([xx,nn,pp]) fits a Weibull function to the data, where 
% xx is a vector of stim levels
% nn is a vector of number of trials for each stim level
% pp is a vector of percentage correct
%
% pars = mle_fit_psycho([xx;nn;pp], P_model) lets you specify the psychometric
% function (default = 'weibull'). Possibilities include 'weibull'
% (DEFAULT), 'weibull50' and 'erf_psycho'
% 
% pars = mle_fit_psycho([xx;nn;pp], P_model,parstart,parmin,parmax) ...
%
% pars = mle_fit_psycho([xx;nn;pp], P_model,parstart,parmin,parmax,nfits)
%	- default 5
%   - choose this number of random starting values to try to avoid local
%   minima. Recommended to use a value >1.
%
% If the data go from 50% to 100%, you better use an appropriate P_model...
% For example: weibull50
% 
% [pars L ] = ... returns the likelihood
%
% EXAMPLE (with data from 0 to 1)
% cc = [-8 -6 -4 -2  0  2  4  6  8 ]; % contrasts
% nn = [10 10 10 10 10 10 10 10 10 ]; % number of trials at each contrast
% pp = [ 5  8 20 41 54 59 79 92 96 ]/100; % proportion "rightward"
% 
% pars = mle_fit_psycho([cc;nn;pp], 'erf_psycho');
% 
% figure; clf
% plot(cc, pp, 'bo', 'markerfacec','b'); hold on
% plot(-8:0.1:8, erf_psycho(pars,-8:0.1:8), 'b');

% 1999-11 FH wrote it
% 2000-01 MC cleaned it up
% 2000-04 MC took care of the 50% case
% 2009-12 MC replaced fmins with fminsearch
% 2010-02 MC, AZ added nfits
% 2013-02 MC+MD fixed bug with dealing with NaNs

if nargin < 6
    nfits = 5;
end

if size(data,1)~=3
   error('Error in mle_fit_psycho: Size of ''data'' must be [3,x]!');
end

% find the good values in pp (conditions that were effectively run)
ii = isfinite(data(3,:));

if nargin < 2   
   P_model = 'weibull';
end

if nargin < 3
    xx = data(1,ii);
    parstart = [ mean(xx), 3, 0.05 ];
    parmin = [min(xx) 0 0];
    parmax = [max(xx) 10 0.40];
end

likelihoods = zeros(nfits,1);
pars = cell(nfits,1);

for ifit = 1:nfits

    pars{ifit} = fminsearch(...
        @(pars) psy.neg_likelihood(pars, data(:,ii), P_model, parmin, parmax),...
        parstart , optimset('Display','off') ); %AZ2010-03-31: suppress msgs

    parstart = parmin + rand(size(parmin)).* (parmax-parmin);
    
    likelihoods(ifit) = - psy.neg_likelihood(pars{ifit}, data(:,ii), P_model, parmin, parmax);
    
end

% the values to be output
[L,iBestFit] = max(likelihoods);
pars = pars{iBestFit};


