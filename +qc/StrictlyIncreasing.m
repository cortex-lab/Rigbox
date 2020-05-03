classdef (Sealed) StrictlyIncreasing < qc.Monotonic
    
  methods
    
    function obj = StrictlyIncreasing
      obj = obj@qc.Monotonic('Direction', 'increasing', 'Strict', true);
    end
    
  end
  
end