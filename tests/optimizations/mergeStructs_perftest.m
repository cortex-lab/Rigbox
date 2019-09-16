classdef mergeStructs_perftest < matlab.perftest.TestCase
% Test performance of mergeStruct and mergeStructs
%  Both functions do the same thing: combine two non-scalar structs into
%  one.  mergeStruct appears to have been written with performance
%  optimization.  Let's test this.
%
%   results = runperf('mergeStructs_perftest'); % Run in R2018b
%   names = extractAfter({results.Name},'perftest');
%   averages = arrayfun(@(r)mean([r.Samples.MeasuredTime]), results);
%   for i = 1:length(results)
%     fprintf('%s: mean = %.3g\n', names{i}, averages(i));
%   end
% 
%   [n=value1]/test_mergeStruct: mean = 0.000103
%   [n=value1]/test_mergeStructs: mean = 0.000583 (4.6e+02% diff)
%   [n=value2]/test_mergeStruct: mean = 0.00073
%   [n=value2]/test_mergeStructs: mean = 0.000911 (25% diff)
%   [n=value3]/test_mergeStruct: mean = 0.0035
%   [n=value3]/test_mergeStructs: mean = 0.00377 (7.5% diff)
%   [n=value4]/test_mergeStruct: mean = 0.0354
%   [n=value4]/test_mergeStructs: mean = 0.0353 (-0.24% diff)
%   [n=value5]/test_mergeStruct: mean = 0.342
%   [n=value5]/test_mergeStructs: mean = 0.335 (-2% diff)
%   [n=value6]/test_mergeStruct: mean = 4
%   [n=value6]/test_mergeStructs: mean = 3.96 (-0.89% diff)
% 
% Performance appears to only be improved for 'small' structures.

  properties (ClassSetupParameter)
    n = {1, 100, 1000, 10000, 100000, 1000000}; % Create large struct %10,000,000
  end
  
  properties
    dst struct
    src struct
  end
  
  methods (TestClassSetup)
    function setup(testCase, n)
      % dst corresponds to global pars in SignalExp.  Note we're keeping
      % this structure a fixed size.
      n_global = 100;
      vals = mapToCell(@(~)rand(10,1),1:n_global);
      fnGlobal = strcat('fn', num2cellstr(1:n_global));
      testCase.dst = cell2struct(vals(:), fnGlobal(:));
      % src corresponds to conditional pars in SignalExp
      I = n_global:n+n_global;
      vals = mapToCell(@(~) rand(10,1), I);
      fnConds = strcat('fn', num2cellstr(I));
      testCase.src = cell2struct(vals(:), fnConds(:));
    end
  end
  
  methods (Test)
    function test_mergeStruct(testCase)
      % MERGESTRUCT is part of signals
      while(testCase.keepMeasuring)
        mergeStruct(testCase.dst, testCase.src);
      end
    end
    
    function test_mergeStructs(testCase)
      % MERGESTRUCTS is part of burgbox
      while(testCase.keepMeasuring)
        mergeStructs(testCase.dst, testCase.src);
      end
    end
  end
end