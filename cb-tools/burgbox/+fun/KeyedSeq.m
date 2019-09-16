classdef KeyedSeq < fun.Seq
  %FUN.KEYEDSEQ Creates a sequence whose values are mapped on retrieval
  %   Typically instantiated via the function SEQUENCE.  
  %   
  %   Examples:
  %    s = SEQUENCE({'huge1.mat' 'huge2.mat' 'huge3.mat'}, @load)
  %    s.first(s.filter(@file.exists)) % load first in sequence that exists
  %
  % See also SEQUENCE, FUN.SEQ, FUN.CUSTOMSEQ
  % 
  % Part of Burgbox
  
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

