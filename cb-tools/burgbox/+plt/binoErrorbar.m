function [h, p, n] = binoErrorbar(axh, x, trialsByX, varargin)
%PLT.BINOERRORBAR Plot parametric binomial data with 95% CI errorbars
%   H = PLT.BINOERRORBAR(axh, x, trialsByX, varargin)
%
% Part of Burgbox

% 2013-10 CB created

[phat, pci] = mapToCell(@(t) binofit(sum(t(:)), numel(t)), trialsByX);
% convert to percentages
phat = 100*cell2mat(phat');
pci = 100*cell2mat(pci');
if nargout > 2
  n = cellfun(@numel, trialsByX(:));
end
p = phat/100;
if numel(x) > 0
  h = plt.errorbar(axh, x, phat, pci(:,1), pci(:,2), varargin{:});
else
  h = [];
end

end

