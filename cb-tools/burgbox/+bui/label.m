function h = label(text, parent, varargin)
%BUI.LABEL Succinctly creates a text uicontrol
%   h = BUI.LABEL(text, parent, ...) wraps a call to MATLAB's uicontrol 
%   to create a text control, with the string 'text', and the parent
%   control 'parent', and the HorizontalAlignment alignment property set to
%   'left'. Any additional args are directly passed to uicontrol.
%
% Part of Burgbox

% 2013-03 CB created

h = uicontrol('Style', 'text', 'HorizontalAlignment', 'left', 'String', text,...
  'Parent', parent, varargin{:});

end

