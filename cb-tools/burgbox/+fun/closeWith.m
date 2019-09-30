function closeWith_fun = closeWith(f, varargin)
%FUN.CLOSEWITH Function closure with specified variables
%   TODO Detailed explanation goes here
%
% Part of Burgbox

% 2013-10 CB created

closeWith_args = varargin;
closeWith_fun = func2str(f);
if ~strcmp(closeWith_fun(1), '@')
  closeWith_fun = ['@' closeWith_fun];
end
clear f varargin;

for closeWith_i = 1:numel(closeWith_args)
  closeWith_name = inputname(closeWith_i + 1);
  if isempty(closeWith_name)
    error('unamed argument');
  end
  eval([ closeWith_name ' = closeWith_args{closeWith_i};']);
  
end

clear closeWith_name closeWith_args closeWith_name closeWith_i;
closeWith_fun = eval(closeWith_fun);

end

