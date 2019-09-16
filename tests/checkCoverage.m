function results = checkCoverage(testFile, funLoc)
% CHECKCOVERAGE Check the coverage of a given test
%  Runs the tests for testFile with the coverage plugin.  Useful for seeing
%  whether your test hits all lines of code.
%
%  Inputs:
%    testFile (char) - file name of test
%    funLoc (char) - folder location of function(s) being tested (optional)
%
%  Output:
%    results (array) - array of test result objects
%
%  Examples:
%    checkCoverage('cellflat') % Folder can be inferred 
%    checkCoverage('fun_package', fileparts(which('fun.run')))
%

narginchk(1,2)
if nargin == 1
  % Try to divine test function location
  funLoc = fileparts(which(strrep(testFile,'_test','')));
end
import matlab.unittest.TestRunner
import matlab.unittest.plugins.CodeCoveragePlugin
runner = TestRunner.withTextOutput;
plugin = CodeCoveragePlugin.forFolder(funLoc);
runner.addPlugin(plugin)
tests = testsuite(testFile);
results = runner.run(tests);