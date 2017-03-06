classdef (Sealed) EmptySeq < fun.Seq
  %FUN.EMPTYSEQ Summary of this class goes here
  %   Detailed explanation goes here
  
  enumeration
    Nil % singleton object 
  end
  
  methods
    function [varargout] = first(obj)
      [varargout{1:max(1, nargout)}] = deal(nil);
    end

    function n = numel(obj)
      n = 0; % no elements in empty sequence
    end

    function b = isempty(obj)
      b = true; % is empty
    end

    function s = rest(obj)
      s = fun.EmptySeq.Nil;
    end

    function c = toCell(obj)
      %conversion to cell array
      c = cell(0,1);
    end
  end
  
end

