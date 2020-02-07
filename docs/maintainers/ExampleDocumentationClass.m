classdef ExampleDocumentationClass < handle
% EXAMPLEDOCUMENTATIONCLASS A well-documented class.
% Long Description (should typically be longer than a function's "Long
% Description" and explain in general terms how the class's innards
% work). Code and files should be referenced within single backticks (` `).
%
% Examples:
%   - Instantiate an object and run `method1`:
%     >> exampleClass = ExampleDocumentationClass();
%     >> exampleClass.method1();
%
% Warnings/Exceptions:
%   noConstructorInput
%     Given if there is no input arg to the constructor method on object
%     instantiation.
%
% (Optional - Additional notes):
%   No additional notes for this class.
%
% Additional notes:
%   No additional notes for this class, but this section could contain
%   history, license, authorship, and/or reference info.
%
% @todo: document all classes in this format

properties (Access=private)
  % Property1 is a short string describing the instantiated object. It's
  % private because it should only be set during object construction.
  Property1
end

methods
  function obj = ExampleDocumentationClass(str)
    % ExampleDocumentationClass constructor method.
    % This function sets the object's `Property1` to `str`, if given.
    %
    % Inputs:
    %   str : string
    %     A short string description of the instantiated object.
    %
    % Examples:
    %   Create an object that mentions how well-documented this class is:
    %     e = ExampleDocumentationClass(["Look at my documentation!"])
    if nargin < 1
        warning('Rigbox:docs:exampleDocumentationClass:noConstructorInput',...
                'No input to the constructor was given.');
        return
    end
    obj.Property1 = str;
    obj.dispProperty1();
  end
end

methods (Access=protected)
  function dispProperty1(obj)
    % dispProperty1 displays `Property1` only upon object instantiation.
    %
    % Examples:
    %   Instantiate an object, which will call this method:
    %     e = ExampleDocumentationClass(["Look at my documentation!"])
    disp(obj.Property1);
  end
end

end