classdef Monotonic < matlab.unittest.constraints.Constraint
  %QC.MONOTONIC TODO Document
  %   TODO Support for chars

    
  properties (SetAccess = immutable)
    Strict logical = false
    Direction {mustBeMember(Direction, {'increasing', 'decreasing', 'either'})} = 'either'
  end
    
  methods
    function obj = Monotonic(varargin)
      p = inputParser;
      p.addParameter('Strict', false, @islogical)
      options = {'increasing', 'decreasing', 'either'};
      p.addParameter('Direction', 'either', @(x) ismember(lower(x), options))
      p.parse(varargin{:});
      obj.Strict = p.Results.Strict;
      obj.Direction = lower(p.Results.Direction);
    end
    
    function bool = satisfiedBy(constraint, actual)
      switch constraint.Direction
        case 'increasing'
          bool = constraint.allIncreasing(actual);
        case 'decreasing'
          bool = constraint.allDecreasing(actual);
        otherwise
          bool = ...
            (constraint.allIncreasing(actual) || constraint.allDecreasing(actual));
      end
    end
    
    function diag = getDiagnosticFor(constraint, actual)
      import matlab.unittest.diagnostics.StringDiagnostic
      if constraint.satisfiedBy(actual)
        diag = StringDiagnostic('FieldSet passed.');
      else
        % Diagnose failure
        isStrict = constraint.isStrict(actual);
        if isStrict
          % Strictly increasing or decreasing, so direction must be wrong
          assert(~strcmp(constraint.Direction, 'either'))
          diagMsg = ['array values not monotonically ' constraint.Direction];
        elseif ~isStrict && any(diff(actual) < 0)
          diagMsg = 'array values not strictly monotonically increasing';
        else
          diagMsg = 'array values not strictly monotonically decreasing';
        end
        diag = StringDiagnostic(['FieldSet failed.\n' diagMsg]);
      end
    end
    
  end
  
  methods (Sealed)
    
    function bool = allIncreasing(constraint, actual)
      if constraint.Strict
        bool = all(diff(actual) > 0);
      else
        bool = all(diff(actual) >= 0);
      end
    end
    
    function bool = allDecreasing(constraint, actual)
      if constraint.Strict
        bool = all(diff(actual) < 0);
      else
        bool = all(diff(actual) <= 0);
      end
    end
        
  end
  
  methods (Static)
    
    function bool = isStrict(A)
      bool = numel(unique(diff(A))) == 1;
    end
    
  end
      
end