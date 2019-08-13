classdef cellstr2double_perftest < matlab.perftest.TestCase
%   C = num2cellstr((1:n)+rand(1,n));
%   testCase.startMeasuring
%   X1 = cellstr2double(C);
%   testCase.stopMeasuring
%   X2 = str2double(C);
%   t(2) = toc;
%   fprintf('cellstr2double %.1f times faster than str2double\n', t(2)/t(1));
%   
%   testCase.assertTrue(all(X1 == X2))

  properties (TestParameter)
    n = {1, 100, 1000, 10000}; % Create large cell array %10,000,000
  end
  
  methods (Test)
    function test_cellstr2double(testCase, n)
      C = num2cellstr((1:n)+rand(1,n));
      while(testCase.keepMeasuring)
        X1 = cellstr2double(C);
      end
      X2 = str2double(C);
      %       fprintf('cellstr2double %.1f times faster than str2double\n', t(2)/t(1));
      
      testCase.assertTrue(all(X1 == X2))
    end
    
    function test_str2double(testCase, n)
      C = num2cellstr((1:n)+rand(1,n));
      testCase.startMeasuring
      X = str2double(C);
      testCase.stopMeasuring
      testCase.assertEqual(size(C), size(X))
      testCase.assertTrue(isnumeric(X))
    end
  end
end