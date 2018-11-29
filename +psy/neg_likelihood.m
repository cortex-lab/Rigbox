function l = neg_likelihood(pars, data, P_model, parmin, parmax)
% NEG_LIKELIHOOD Negative likelihood of a psychometric function
%
% L = neg_likelihood(pars, [xx,nn,pp], P_model) is 
% - sum(nn.*(pp.*log10(P_model)+(1-pp).*log10(1-P_model)))
%
% P_model defaults to 'weibull'
% 
% L = neg_likelihood(pars, [xx,nn,pp], P_model, parmin, parmax) lets you
% choose the boundaries for the parameters.
%
% parameters are pars = [threshold, slope, gamma]
%
% 1999-11 FH wrote it
% 2000-01 MC cleaned it up
% 2000-07 MC made it indep of Weibull and added parmin and parmax

if nargin<3
   P_model= 'weibull';
end

if nargin<4
   parmin = [0.005 0 0];
end

if nargin<5
   parmax = [0.5 10 0.25];
end

xx = data(1,:);
nn = data(2,:);
pp = data(3,:);

% here is where you effectively put the constraints.
if any(pars<parmin) || any(pars>parmax)
   l = 10000000;
   return
end

probs = eval(['psy.', P_model,'(pars,xx)']);

if max(probs)>1 || min(probs)<0
    error('At least one of the probabilities is not between 0 and 1');
end

probs(probs==0)=eps;
probs(probs==1)=1-eps;

l = - sum(nn.*(pp.*log(probs)+(1-pp).*log(1-probs)));
% this equation comes from the appendix of Watson, A.B. (1979). Probability
% summation over time. Vision Res 19, 515-522.

