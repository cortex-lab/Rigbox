classdef ClearTestCache < matlab.unittest.fixtures.Fixture
  %CLEARTESTCACHE Clears all test functions that store variables
  %   Clears all global and persistent test function variables.  NB: As
  %   this calls a function itself clears these functions, the teardown
  %   order may be important, i.e. if a fixture path changes the variables
  %   for these functions may not be cleared.  On the other hand, the act
  %   itself of unsetting a path may clear the cache anyway.  Further
  %   testing required.
    
  methods
    function setup(fixture)
      fixture.addTeardown(@fixture.clearFunctionCache)
    end
  end
  
  methods (Static)
    function clearFunctionCache()
      % Clear functions used in tests
      %  cb-tools cache cleared by the ReposFixture teardown
      clear system pnet MockDialog KbQueueCheck modDate ...
        devices configureDummyExperiment Screen funSpy
    end
  end
end