classdef CellSeq < fun.Seq
  %FUN.CELLSEQ Sequence wrapper for cell arrays
  %   Creates an iterable sequence from a column cell array input.  The
  %   array may be filtered and values mapped through functions only on
  %   retrieval. Helpful for delaying costly operations such as loading
  %   files.
  %
  % See also SEQUENCE, FUN.SEQ, FUN.KEYEDSEQ
  % 
  % Part of Burgbox

  properties (Access = private)
    Arr = {}
    Idx = 1
  end
  
  methods
    function v = first(obj)
      v = obj.Arr{obj.Idx};
    end
    
    function b = isempty(obj)
      if numel(obj) == 0
        b = true;
      else
        b = obj.Idx > numel(obj.Arr);
      end
    end
    
    function c = toCell(obj)
      c = obj.Arr(obj.Idx:end);
    end
    
    function s = rest(obj)
      s = fun.CellSeq.create(obj.Arr, obj.Idx + 1);
    end
  end
  
  methods (Static)
    function obj = create(a, firstIdx)
      if nargin < 2
        firstIdx = 1;
      end
      if firstIdx <= numel(a)
        obj = fun.CellSeq;
        obj.Arr = a;
        obj.Idx = firstIdx;
      else
        obj = nil;
      end
    end
  end
  
end

