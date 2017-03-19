classdef KeyedSeq < fun.Seq
  %FUN.KEYEDSEQ Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Access = private)
    Keys = {}
    RetrieveFun
    Idx = 1
  end
  
  methods
    function [v, k] = first(seq)
      k = seq.Keys{seq.Idx};
      v = seq.RetrieveFun(k);
    end

    function b = isempty(seq)
      if numel(seq) == 0
        b = true;
      else
        b = seq.Idx > numel(seq.Keys);
      end
    end

    function s = rest(seq)
      s = fun.KeyedSeq.create(seq.Keys, seq.RetrieveFun, seq.Idx + 1);
    end
  end

  methods (Static)
    function obj = create(keys, retrieveFun, firstIdx)
      if nargin < 3
        firstIdx = 1;
      end
      if firstIdx <= numel(keys)
        obj = fun.KeyedSeq;
        obj.Keys = keys;
        obj.RetrieveFun = retrieveFun;
        obj.Idx = firstIdx;
      else
        obj = nil;
      end
    end
  end
  
end

