function like = lapseNormalLikelihood(c, gam, mu, sig)
%PSY.LAPSENORMALLIKELIHOOD Gaussian discrimination model with lapsing
%   l = PSY.LAPSENORMALLIKELIHOOD(x, gam, mu, sig) returns the likelihood
%   of a positive discrimination (or hit) with the parameters, 'c', 'gam',
%   'mu' and 'sig', modelling some measurement contaminated by Gaussian
%   noise and with a lapse rate.
%
%   The model is that some measurement of an environmental variable, c is
%   made, which is contaminated by Gaussian noise. For example this could
%   be the difference between contrasts to the left and right, i.e. c = c_r
%   - c_l. This value is thresholded with 'mu', such that if the measured
%   variable is less that 'mu', it is a miss, and if greater, it is a hit.
%   'x' would be the overall rate of hits. The lapse rate 'gam' specifies
%   the chance a hit or miss occurs on a discrimination-independet path.
%   Note that on something like the left or right discrimation above, hit
%   could e.g. mean right, and miss left.
%
% Part of Rigbox

% 2013-06 CB created

like = gam + (1 - 2*gam)*(1 - normcdf(mu, c, sig));

end