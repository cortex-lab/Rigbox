classdef CustomSeq < fun.Seq
  %FUN.CUSTOMSEQ Summary of this class goes here
  %   Detailed explanation goes here
  
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

