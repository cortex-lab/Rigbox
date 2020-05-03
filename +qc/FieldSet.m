classdef FieldSet < matlab.unittest.constraints.Constraint
  
  properties(SetAccess = immutable)
    FieldName
  end
  
  methods
    function constraint = FieldSet(field)
      constraint.FieldName = field;
    end
    
    function bool = satisfiedBy(constraint, actual)
      bool = constraint.fieldSet(actual);
    end
    
    function diag = getDiagnosticFor(constraint, actual)
      import matlab.unittest.diagnostics.StringDiagnostic
      if constraint.fieldSet(actual)
        diag = StringDiagnostic('FieldSet passed.');
      else
        % Diagnose failure
        try 
          fields = fieldnames(actual);
          if ~ismember(constraint.FieldName, fields)
            diagMsg = sprintf(...
              'FieldSet failed.\ninput has no ''%s'' field', constraint.FieldName);
          else % Must be empty
            diagMsg = sprintf(...
              'FieldSet failed.\n''%s'' field value is empty', constraint.FieldName);
          end
        catch ex
          if ~strcmp(ex.identifier, 'MATLAB:fieldnames:InvalidInput')
            rethrow(ex)
          end
          diagMsg = sprintf(...
            'FieldSet failed.\nclasses of type ''%s'' do not support fields',...
            class(actual));
        end
        diag = StringDiagnostic(diagMsg);
      end
    end
    
  end
  
  methods(Access = private)
    function bool = fieldSet(constraint, actual)
      bool = ...
        isfield(actual, constraint.FieldName) && ...
        ~isempty(actual.(constraint.FieldName));
    end
  end
end