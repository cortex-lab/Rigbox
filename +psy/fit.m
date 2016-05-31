function varargout = fit(varargin)
%PSY.FIT Fit a psychometric curve
%   TODO
%
% Part of Rigbox

% 2013-06 CB created

if nargin == 1
  %assume single argument is a block
  [pR, n, c] = psy.responseByCondition(varargin{1});
else
  %assume three arguments are pR, n and c
  [pR, n, c] = varargin{:};
end

  function ll = loglike(param)
    gam = param(1);% the lapse rate (i.e. proportion of trials with 
    % random/stimulus-indepent response)
    mu = param(2); % the contrast mean for the cumulative gaussian
    sig = param(3);% the contrast variance for the cumulative gaussian
    
    if gam < 0 || gam > 0.5
      ll = -Inf;
      return
    end
    
    like = psy.lapseNormalLikelihood(c, gam, mu, sig);
    % log likelihood is summed log of each data points likelihood
    ll = sum(n.*(pR.*log(like) + (1 - pR).*log(1 - like)));
  end
    

paramstart = [0, 0, 0.25];

pars = fminsearch(@(param) -loglike(param),...
        paramstart, optimset('Display','off','TolX',1e-7) );
varargout = [num2cell(pars), n, c, pR];


      
end

