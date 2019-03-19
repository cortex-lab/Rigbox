function choice = inputdlg(varargin)
mock = MockDialog.instance;

choice = mock.newCall('inputdlg', varargin{:});
end

% function answer = inputdlg(varargin)
% if nargin == 5
%   if ischar(varargin{5})
%     opts.Resize = varargin{5};
%   else
%     opts = varargin{5};
%   end
%   opts.WindowStyle = 'normal';
% else
%   opts.WindowStyle = 'normal';
% end
% all_f = which('-all', 'inputdlg');
% all_f = all_f(cell2mat(strfind (all_f, matlabroot)));
% f = fileFunction(all_f{:});
% answer = feval(f, varargin{:}, opts);
