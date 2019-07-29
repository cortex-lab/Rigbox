function [exitStatus, failures] = runall(ignoreTagged)
% RUNALL gathers and runs all tests in Rigbox (including in the alyx-matlab
% and signals submodules), and returns TestResults for failing tests.
% To be called for code checks and the like.
% 
% Inputs:
%   `ignoreTagged`: if true (default), tests that are tagged as requiring a
%       specific hardware implementation will be ignored
% Outputs:
%   `exitStatus`: a number indicating whether all tests passed (0) or
%       some tests failed (1)
%   `failures`: an array of the failed tests
%
% TODO Method setup in `dat_test` may become global fixture
% TODO Deal with directory changes

if nargin < 1; ignoreTagged = true; end
import matlab.unittest.selectors.HasTag
%% Gather tests
rigbox_tests = testsuite;
signals_tests = testsuite(fullfile('..\signals\tests'));
alyx_tests = testsuite(fullfile('..\alyx-matlab\tests'));

%% Filter & run
% the suite is automatically sorted based on shared fixtures. However, if
% you add, remove, or reorder elements after initial suite creation, call
% the `sortByFixtures` method to sort the suite.
%
% Tagged tests will require a specific hardware implementation
all_tests = [rigbox_tests signals_tests alyx_tests];
tests = iff(ignoreTagged, @()all_tests.selectIf(~HasTag), all_tests);
results = run(tests);

%% Diagnostics
exitStatus = any([results.Failed]);
failures = tests([results.Failed]);