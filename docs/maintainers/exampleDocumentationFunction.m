function exampleOutput = exampleDocumentationFunction(varargin)
% exampleDocumentationFunction creates an example output.
% This function takes in at least one, and optionally a second input
% argument. If there is just one input argument, the input argument is
% returned unchanged. If there are two input arguments, the concatenation
% of the two is returned.
%
% Inputs:
%   exampleInput : string 
%     An example input.
%   optionalInput (optional) : string
%     An optional input.
%
% Outputs:
%   exampleOutput : string
%     An example output.
%
% Examples: 
%   Create an example output with a single input arg:
%     exampleOutput = exampleDocumentationFunction('Hi');
%   Create an example output with a two input args:
%     exampleOutput = exampleDocumentationFunction('Hi', 'Dave');
%
% See also: `ExampleDocumentationClass`.
%
% Warnings/Exceptions:
%   incorrectInputs
%     Raised if the number or type of inputs aren't correct.
%
% Additional notes:
%   No additional notes for this function, but this section could contain
%   history, license, authorship, and/or reference info.
%
% @todo: document all functions in this format

% Check that we have exactly one or two inputs, and they're strings.
if len(varargin) ~= 1 && len(varargin) ~= 2 ...
&& ~all(cellfun(@isstring, varargin))  % throw error
  error('Rigbox:docs:exampleDocumentationFunction:incorrectInputs', ...
        'There must be exactly 1 or 2 inputs, and they must be strings');
end

if len(varargin) == 1  % return input
  exampleOutput = varargin{1};
else  % return concatenated inputs
  exampleOutput = varargin{1} + ", " + varargin{2};
end

end