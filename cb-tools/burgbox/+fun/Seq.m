classdef Seq
  %FUN.SEQ Interface for iterating sequences
  %   Abstract class for creating iterable sequences.  Currently supports
  %   cell arrays only.  Sequences may be created using the SEQUENCE
  %   function or by instantiating one of the subclasses directly.  
  %
  %   Sequence objects may be reversed, mapped and filtered.  Subsequences
  %   may be created from them also.
  %
  % See also SEQUENCE, FUN.CELLSEQ, FUN.KEYEDSEQ, FUN.CUSTOMSEQ
  %
  % Part of Burgbox
  
  % 2013-09 CB created
  
  methods (Abstract)
    v = first(obj) %get first element in sequence
    s = rest(obj) %get Sequence of all elements except first
  end
  
  methods
    function c = toCell(seq)
      %conversion to cell array
      %subclasses can potentially make more efficient
      c = cell(1);
      i = 1;
      while ~isNil(first(seq))
        if i > numel(c)
          c = [c; cell(size(c))];
        end
        c{i} = first(seq);
        i = i + 1;
        seq = rest(seq);
      end
      c(i:end) = [];
    end
    
    function s = map(seq, f)
      % New sequence of results from applying a function to each element
      %
      % s = MAP(f) returns a new sequence of the results of applying
      % function 'f' to each element in this sequence.
      if isempty(seq)
        s = nil;
      else
        s = fun.CustomSeq(@mapFirst, @mapRest);
      end
      
      function s = mapRest(~)
        s = map(rest(seq), f);
      end
      
      function [varargout] = mapFirst(~)
        [varargout{1:nargout}] = f(first(seq));
      end
    end
    
    function s = filter(seq, pred)
      % Sub-sequence of elements which pass predicate
      %
      % s = FILTER(pred) returns a sub-sequence containing the elements, e
      % from this sequence for which pred(e) returns true.
      
      narginchk(2,2)
      if isempty(seq)
        s = nil;
      else
        s = fun.CustomSeq(@filterFirst, @filterRest);
        seeked = false;
      end
      
      function s = filterRest(~)
        if ~seeked
          seek();
        end
        s = filter(rest(seq), pred);
      end
      
      function [varargout] = filterFirst(~)
        if ~seeked
          seek();
        end
        [varargout{1:max(1, nargout)}] = first(seq);
      end
      
      function seek()
        while ~isNil(first(seq)) && ~pred(first(seq))
          seq = rest(seq);
        end
        seeked = true;
      end
    end
    
    function s = take(seq, n)
      % Sub-sequence of first _n_ elements
      %
      % s = TAKE(n) returns a sub-sequence of the first 'n' elements from
      % this sequence (or all elements if there are less than 'n').
      
      narginchk(2,2)
      s = fun.CustomSeq(@takeFirst, @takeRest);
      
      function s = takeRest(~)
        if n > 1
          s = take(rest(seq), n - 1);
        else
          s = nil;
        end
      end
      
      function [varargout] = takeFirst(~)
        if n > 0
          [varargout{1:max(1, nargout)}] = first(seq);
        else
          [varargout{1:max(1, nargout)}] = deal(nil);
        end
      end
    end
    
    function s = reverse(seq)
      % Sequence with elements in reverse order
      %
      % s = REVERSE() returns a sequence containing the elements, e
      % from this sequence but in reverse order.

      s = sequence(flipud(toCell(seq)));
    end
  end
  
end

