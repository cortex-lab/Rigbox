function s = sequence(varargin)
%SEQUENCE Creates a sequence from an array
%   s = SEQUENCE(coll) creates a sequence from the array 'coll'
%
%   s = SEQUENCE(keys, retrieveFun) creates a sequence where each element
%   is that returned from retrieveFun passed each key in turn from the
%   array keys. e.g:
%
%     s = SEQUENCE({'huge1.mat' 'huge2.mat' 'huge3.mat'}, @load)
%
%   will return a sequence in which each element is data returned from
%   loading the mat files huge1.mat, huge2.mat, .... However, each actual
%   load will *only* occur as each element is retrieved (see first(...),
%   and rest(...) functions). This 'lazy' sequencing can thus be useful for
%   delaying costly operations until they're actually needed, or avoiding 
%   altogether (e.g. if searching for something, you can stop loading more
%   data when you find it), whilst still using the same algorithms as
%   on normal sequences. Note: Currently matrix arrays are not supported.
%
% See also FUN.SEQ, FIRST, REST
%
% Part of Burgbox

% 2013-09 CB created

if nargin == 1
  coll = varargin{1}(:);
  if isempty(coll)
    s = nil;
  elseif iscell(coll)
    s = fun.CellSeq.create(coll);
  else
    error('Cannot make a sequence from a ''%s''', class(coll));
  end
elseif isa(varargin{2}, 'function_handle')
  [keys, retrieveFun] = varargin{:};
  s = fun.KeyedSeq.create(keys, retrieveFun);
else
  error('Unrecognised type to create sequence of');
end

end

