classdef CustomSeq < fun.Seq
  %FUN.CUSTOMSEQ Map elements using custom function on retrieval
  %  Typically instantiated by applied map method to another sequence type.
  %
  %  Examples:
  %    s = sequence(num2cell(1:5)) % create sequence
  %    mapped = s.map(@(v) v*2) % Map through multiplier
  %    mapped.first % 2
  %    mapped.reverse.first % 10
  %
  % See also SEQUENCE, FUN.SEQ, FUN.KEYEDSEQ
  % 
  % Part of Burgbox
  
  properties (Access = private)
    FirstFun
    RestFun
  end
  
  methods
    function obj = CustomSeq(firstFun, restFun)
      obj.FirstFun = firstFun;
      obj.RestFun = restFun;
    end

    function [varargout] = first(obj)
      [varargout{1:max(1, nargout)}] = obj.FirstFun(obj);
    end

    function s = rest(obj)
      s = obj.RestFun(obj);
    end 
  end
  
end

