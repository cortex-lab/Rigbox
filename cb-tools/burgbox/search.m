function [lower_index,upper_index] = search(x, lowerBound, upperBound)
% fast O(log2(N)) computation of the range of indices of x that satify the
% upper and lower bound values using the fact that the x vector is sorted
% from low to high values. Computation is done via a binary search.
%
% Input:
%
% x-            A vector of sorted values from low to high.
%
% LowerBound-   Lower boundary on the values of x in the search
%
% UpperBound-   Upper boundary on the values of x in the search
%
% Output:
%
% lower_index-  The smallest index such that
%               LowerBound<=x(index)<=UpperBound
%
% upper_index-  The largest index such that
%               LowerBound<=x(index)<=UpperBound

if nargin < 3
  upperBound = lowerBound;
end

if lowerBound>x(end) || upperBound<x(1) || upperBound<lowerBound
  % no indices satify bounding conditions
  lower_index = [];
  upper_index = [];
  return;
end

lower_index_a=1;
lower_index_b=length(x); % x(lower_index_b) will always satisfy lowerbound
upper_index_a=1;         % x(upper_index_a) will always satisfy upperbound
upper_index_b=length(x);

%
% The following loop increases _a and decreases _b until they differ
% by at most 1. Because one of these index variables always satisfies the
% appropriate bound, this means the loop will terminate with either
% lower_index_a or lower_index_b having the minimum possible index that
% satifies the lower bound, and either upper_index_a or upper_index_b
% having the largest possible index that satisfies the upper bound.
%
while (lower_index_a+1<lower_index_b) || (upper_index_a+1<upper_index_b)
  
  lw=floor((lower_index_a+lower_index_b)/2); % split the upper index
  
  if x(lw) >= lowerBound
    lower_index_b=lw; % decrease lower_index_b (whose x value remains \geq to lower bound)
  else
    lower_index_a=lw; % increase lower_index_a (whose x value remains less than lower bound)
    if (lw>upper_index_a) && (lw<upper_index_b)
      upper_index_a=lw;% increase upper_index_a (whose x value remains less than lower bound and thus upper bound)
    end
  end
  
  up=ceil((upper_index_a+upper_index_b)/2);% split the lower index
  if x(up) <= upperBound
    upper_index_a=up; % increase upper_index_a (whose x value remains \leq to upper bound)
  else
    upper_index_b=up; % decrease upper_index_b
    if (up<lower_index_b) && (up>lower_index_a)
      lower_index_b=up;%decrease lower_index_b (whose x value remains greater than upper bound and thus lower bound)
    end
  end
end

if x(lower_index_a)>=lowerBound
  lower_index = lower_index_a;
else
  lower_index = lower_index_b;
end
if x(upper_index_b)<=upperBound
  upper_index = upper_index_b;
else
  upper_index = upper_index_a;
end
end