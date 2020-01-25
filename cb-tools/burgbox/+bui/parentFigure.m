function h = parentFigure(h)
%BUI.PARENTFIGURE Parent figure of graphics object
%   f = BUI.PARENTFIGURE(h) Returns the parent figure, if any, of the
%   graphics object with handle 'h'.  NB: For most purposes `ancestor` will
%   suffice.
%
% Part of Burgbox

% 2012-12 CB created

while ~isempty(h) && ~strcmp(get(h, 'Type'), 'figure')
  h = get(h, 'Parent');
end

end

