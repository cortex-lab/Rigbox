function json=savejson(rootname,obj,varargin)
%
% json=savejson(rootname,obj,filename)
%    or
% json=savejson(rootname,obj,opt)
% json=savejson(rootname,obj,'param1',value1,'param2',value2,...)
%
% convert a MATLAB object (cell, struct or array) into a JSON (JavaScript
% Object Notation) string
%
% author: Qianqian Fang (fangq<at> nmr.mgh.harvard.edu)
%            created on 2011/09/09
%
% $Id: savejson.m 394 2012-12-18 17:58:11Z fangq $
%
% input:
%      rootname: name of the root-object, if set to '', will use variable name
%      obj: a MATLAB object (array, cell, cell array, struct, struct array)
%      filename: a string for the file name to save the output JSON data
%      opt: a struct for additional options, use [] if all use default
%        opt can have the following fields (first in [.|.] is the default)
%
%        opt.FileName [''|string]: a file name to save the output JSON data
%        opt.FloatFormat ['%.10g'|string]: format to show each numeric element
%                         of a 1D/2D array;
%        opt.ArrayIndent [1|0]: if 1, output explicit data array with
%                         precedent indentation; if 0, no indentation
%        opt.ArrayToStruct[0|1]: when set to 0, savejson outputs 1D/2D
%                         array in JSON array format; if sets to 1, an
%                         array will be shown as a struct with fields
%                         "_ArrayType_", "_ArraySize_" and "_ArrayData_"; for
%                         sparse arrays, the non-zero elements will be
%                         saved to _ArrayData_ field in triplet-format i.e.
%                         (ix,iy,val) and "_ArrayIsSparse_" will be added
%                         with a value of 1; for a complex array, the 
%                         _ArrayData_ array will include two columns 
%                         (4 for sparse) to record the real and imaginary 
%                         parts, and also "_ArrayIsComplex_":1 is added. 
%        opt.ParseLogical [0|1]: if this is set to 1, logical array elem
%                         will use true/false rather than 1/0.
%        opt.NoRowBracket [1|0]: if this is set to 1, arrays with a single
%                         numerical element will be shown without a square
%                         bracket, unless it is the root object; if 0, square
%                         brackets are forced for any numerical arrays.
%        opt.ForceRootName [0|1]: when set to 1 and rootname is empty, savejson
%                         will use the name of the passed obj variable as the 
%                         root object name; if obj is an expression and 
%                         does not have a name, 'root' will be used; if this 
%                         is set to 0 and rootname is empty, the root level 
%                         will be merged down to the lower level.
%        opt.Inf ['"$1_Inf_"'|string]: a customized regular expression pattern
%                         to represent +/-Inf. The matched pattern is '([-+]*)Inf'
%                         and $1 represents the sign. For those who want to use
%                         1e999 to represent Inf, they can set opt.Inf to '$11e999'
%        opt.NaN ['"_NaN_"'|string]: a customized regular expression pattern
%                         to represent NaN
%        opt.JSONP [''|string]: to generate a JSONP output (JSON with padding),
%                         for example, if opt.JSON='foo', the JSON data is
%                         wrapped inside a function call as 'foo(...);'
%        opt.UnpackHex [1|0]: conver the 0x[hex code] output by loadjson 
%                         back to the string form
%        opt can be replaced by a list of ('param',value) pairs. The param 
%        string is equivallent to a field in opt.
% output:
%      json: a string in the JSON format (see http://json.org)
%
% examples:
%      a=struct('node',[1  9  10; 2 1 1.2], 'elem',[9 1;1 2;2 3],...
%           'face',[9 01 2; 1 2 3; NaN,Inf,-Inf], 'author','FangQ');
%      savejson('mesh',a)
%      savejson('',a,'ArrayIndent',0,'FloatFormat','\t%.5g')
%
% license:
%     BSD or GPL version 3, see LICENSE_{BSD,GPLv3}.txt files for details
%
% -- this function is part of jsonlab toolbox (http://iso2mesh.sf.net/cgi-bin/index.cgi?jsonlab)
%

if(nargin==1)
   varname=inputname(1);
   obj=rootname;
   if(isempty(varname)) 
      varname='root';
   end
   rootname=varname;
else
   varname=inputname(2);
end
if(length(varargin)==1 && ischar(varargin{1}))
   opt=struct('FileName',varargin{1});
else
   opt=varargin2struct(varargin{:});
end
opt.IsOctave=exist('OCTAVE_VERSION', 'builtin');
rootisarray=0;
rootlevel=1;
forceroot=jsonopt('ForceRootName',0,opt);

tab = sprintf('\t');
newline = sprintf('\n');
floatformat=jsonopt('FloatFormat','%.10g',opt);
arrayIndent=jsonopt('ArrayIndent',1,opt)==1;
parseLogical=jsonopt('ParseLogical',0,opt)==1;
noRowBracket=jsonopt('NoRowBracket',1,opt)==1;
arrayToStruct=jsonopt('ArrayToStruct',0,opt);
unpackHex=jsonopt('UnpackHex',1,opt);
jsonp=jsonopt('JSONP','',opt);

% speedup?
maxlevel = 25; % maximum object nesting degree to save padding for
pad = cell(maxlevel+1,1); % idx 1 is zero level padding
for l = 1:maxlevel
  pad{l+1} = [pad{l} tab];
end

if((isnumeric(obj) || islogical(obj) || ischar(obj) || isstruct(obj) || iscell(obj)) && isempty(rootname) && forceroot==0)
    rootisarray=1;
    rootlevel=0;
else
    if(isempty(rootname))
        rootname=varname;
    end
end
if((isstruct(obj) || iscell(obj))&& isempty(rootname) && forceroot)
    rootname='root';
end

json=obj2json(checkname(rootname),obj,rootlevel);
if(rootisarray)
    json=sprintf('%s\n',json);
else
    json=sprintf('{\n%s\n}\n',json);
end
if(~isempty(jsonp))
    json=sprintf('%s(%s);\n',jsonp,json);
end
% save to a file if FileName is set, suggested by Patrick Rapin
if ~isempty(jsonopt('FileName','',opt))
    fid = fopen(opt.FileName, 'wt');
    fwrite(fid,json,'char');
    fclose(fid);
end

    %%-------------------------------------------------------------------------
    function txt=obj2json(name,item,level)

    if(iscell(item))
        txt=cell2json(name,item,level,opt);
    elseif(isstruct(item))
        txt=struct2json(name,item,level);
    elseif(ischar(item))
        txt=str2json(name,item,level,opt);
    else
        txt=mat2json(name,item,level);
    end
    end

    %%-------------------------------------------------------------------------
    function txt=cell2json(name,item,level,varargin)
      %% Warning i need some work, and checking that loadjson mirrors this well
    txt='';
    if(~iscell(item))
            error('input is not a cell');
    end

    len=numel(item); % let's handle 1D cell first
%     padding1=pad{level};%repmat(sprintf('\t'),1,level-1); ???
    padding0=pad{level+1};%repmat(sprintf('\t'),1,level);
    if (~isempty(name))
        txt=sprintf('%s"%s": [',padding0, name); name=''; 
    else
        txt=sprintf('%s[',padding0); 
    end
    if len==0
       txt = [txt ']'];
    else
        for i=1:len
            txt=[txt newline obj2json(name,item{i},level+1)];
            if(i<len) txt=[txt ',']; end
        end
        txt=sprintf('%s\n%s]',txt,padding0);
    end
%     if(len~=0) 
%         if(~isempty(name))
%             txt=sprintf('%s"%s": [\n',padding0, name); name=''; 
%         else
%             txt=sprintf('%s[\n',padding0); 
%         end
%     elseif(len==0)
%         if(~isempty(name))
%             txt=sprintf('%s"%s": null',padding0, name); name=''; 
%         else
%             txt=sprintf('%snull',padding0); 
%         end
%     end
    
    end

    %%-------------------------------------------------------------------------
    function txt=struct2json(name,item,level)
    if ~isstruct(item)
      error('input is not a struct');
    elseif isempty(item)
      txt = '';
      return
    end
    len=numel(item);
    bracelevel = level+(len>1);
    names = fieldnames(item);
    checkedNames = cellfun(@checkname, names, 'uni', false);
    padding0=pad{level+1};       %padding for this level
    padding1=pad{bracelevel+1};  %padding for braces, maybe deeper than this
    values = struct2cell(item);  % all structure values in a table
    elemstxt = cell(size(item)); % array to store each elements object text
    for e=1:len
        elements = cell(1,numel(names));
        for f=1:numel(names)
            elements{f} = obj2json(checkedNames{f},values{f,e},bracelevel+1);
        end
        elementstxt = sprintf('\n%s,', elements{:}); % format all fields together
        elemstxt{e} = elementstxt(1:end-1);
    end
    linepad = [newline padding1];
    intxt = sprintf(['{%s\n' padding1 '},' linepad], elemstxt{:}); % format all elements
    intxt = intxt(1:(end-numel(linepad)-1)); % snip off next element tokens/formatting
    if(len==1)
        if ~isempty(name)
            txt=[padding0 '"' name '": ' intxt];
        else
            txt=intxt;
        end
    else
        txt=[padding0 '"' name '": [' linepad intxt newline padding0 ']'];
    end
    end

    %%-------------------------------------------------------------------------
    function txt=str2json(name,item,level,varargin)
    txt='';
    if(~ischar(item))
            error('input is not a string');
    end
    item=reshape(item, max(size(item),[1 0]));
    len=size(item,1);
    sep=sprintf(',\n');

    padding1=pad{level+1};

    if(~isempty(name)) 
        if(len>1) txt=sprintf('%s"%s": [\n',padding1,name); end
    else
        if(len>1) txt=sprintf('%s[\n',padding1); end
    end
    isoct=jsonopt('IsOctave',0,varargin{:});
    for e=1:len
        if(isoct)
            val=regexprep(item(e,:),'\\','\\');
            val=regexprep(val,'"','\"');
            val=regexprep(val,'^"','\"');
        else
            val=regexprep(item(e,:),'\\','\\\\');
            val=regexprep(val,'"','\\"');
            val=regexprep(val,'^"','\\"');
        end
        if(len==1)
            obj=['"' name '": ' '"',val,'"'];
      if(isempty(name)) obj=['"',val,'"']; end
            txt=sprintf('%s%s%s%s',txt,padding1,obj);
        else
            txt=[txt pad{level+2} '"',val,'"'];
        end
        if(e==len) sep=''; end
        txt=sprintf('%s%s',txt,sep);
    end
    if(len>1) txt=sprintf('%s\n%s%s',txt,padding1,']'); end
    end

    %%-------------------------------------------------------------------------
    function txt=mat2json(name,item,level)
    if(~isnumeric(item) && ~islogical(item))
            error('input is not an array');
    end

    padding1=pad{level+1};%repmat(tab,1,level);
    padding0=pad{level+2};%repmat(tab,1,level+1);

    if(length(size(item))>2 || issparse(item) || ~isreal(item) || ...
       isempty(item) || arrayToStruct)
        if(isempty(name))
          txt=sprintf('%s{\n%s"_ArrayType_": "%s",\n%s"_ArraySize_": %s,\n',...
                  padding1,padding0,class(item),padding0,regexprep(mat2str(size(item)),'\s+',',') );
        else
          txt=sprintf('%s"%s": {\n%s"_ArrayType_": "%s",\n%s"_ArraySize_": %s,\n',...
                  padding1,name,padding0,class(item),padding0,regexprep(mat2str(size(item)),'\s+',',') );
        end
    else
        if(isempty(name))
          %% warning i may have broken this part
          txt=sprintf('%s%s',padding1,matdata2json(item,level+1));
%           txt=sprintf('%s[%s]',padding1,matdata2json(item,level+1));
        else
            txt = [padding1 '"' name '": ' matdata2json(item,level+1)];
%             if(numel(item)==1 && ~noRowBracket)
%                 %numtxt=regexprep(regexprep(numtxt,'^\[',''),']','');
%                 %assume square brackets first + last chars
%                 numtxt = numtxt(2:end-1);
%             end
%             txt=[padding1 '"' name '": ' numtxt];
        end
        return;
    end
    dataformat='%s%s%s%s%s';

    if(issparse(item))
        [ix,iy]=find(item);
        data=full(item(find(item)));
        if(~isreal(item))
           data=[real(data(:)),imag(data(:))];
           if(size(item,1)==1)
               % Kludge to have data's 'transposedness' match item's.
               % (Necessary for complex row vector handling below.)
               data=data';
           end
           txt=sprintf(dataformat,txt,padding0,'"_ArrayIsComplex_": ','1', sprintf(',\n'));
        end
        txt=sprintf(dataformat,txt,padding0,'"_ArrayIsSparse_": ','1', sprintf(',\n'));
        if(size(item,1)==1)
            % Row vector, store only column indices.
            txt=sprintf(dataformat,txt,padding0,'"_ArrayData_": ',...
               matdata2json([iy(:),data'],level+2), sprintf('\n'));
        elseif(size(item,2)==1)
            % Column vector, store only row indices.
            txt=sprintf(dataformat,txt,padding0,'"_ArrayData_": ',...
               matdata2json([ix,data],level+2), sprintf('\n'));
        else
            % General case, store row and column indices.
            txt=sprintf(dataformat,txt,padding0,'"_ArrayData_": ',...
               matdata2json([ix,iy,data],level+2), sprintf('\n'));
        end
    else
        if(isreal(item))
            txt=sprintf(dataformat,txt,padding0,'"_ArrayData_": ',...
                matdata2json(item(:)',level+2), sprintf('\n'));
        else
            txt=sprintf(dataformat,txt,padding0,'"_ArrayIsComplex_": ','1', sprintf(',\n'));
            txt=sprintf(dataformat,txt,padding0,'"_ArrayData_": ',...
                matdata2json([real(item(:)) imag(item(:))],level+2), sprintf('\n'));
        end
    end
    txt=sprintf('%s%s%s',txt,padding1,'}');
    end

    %%-------------------------------------------------------------------------
    function txt=matdata2json(mat,level)
    % handle each case individually for maximum speed
    if numel(mat) == 1
        txt = sprintf(floatformat, mat);
        if ~noRowBracket
            txt = ['[' txt ']'];
        end
    elseif isempty(mat)
        txt = 'null';
    elseif isrow(mat)
        txt = sprintf([floatformat ','], mat);
        txt = ['[' txt(1:end-1) ']'];
    elseif iscolumn(mat)
        txt = sprintf([newline pad{level+1} '[' floatformat '],'], mat);
        txt = ['[' txt(1:end-1) newline pad{level} ']'];
    else % matrix with rows>1 & cols>1
        formatstr=['[' repmat([floatformat ','],1,size(mat,2)-1) floatformat '],' newline];
        if arrayIndent
          formatstr = [pad{level+1} formatstr];
        end
        txt = sprintf(formatstr,mat');
        txt = ['[' newline txt(1:end-2) newline pad{level} ']'];
    end
%     if(size(mat,1)==1)
%         pre='';
%         post='';
%         level=level-1;
%     else
%         pre=sprintf('[\n');
%         post=sprintf('\n%s]',pad{level});
%     end
%     if(isempty(mat))
%         txt='null';
%         return;
%     end
%     
%     formatstr=['[' repmat([floatformat ','],1,size(mat,2)-1) floatformat '],' newline]; 
% 
%     if(nargin>=2 && size(mat,1)>1 && arrayIndent)
%         formatstr=[pad{level+1} formatstr];
%     end
% %     intxt=sprintf(formatstr,mat');
%     txt=sprintf(formatstr,mat');
    if(parseLogical && islogical(mat))
       txt=regexprep(txt,'1','true');
       txt=regexprep(txt,'0','false');
    end
    if(any(isinf(mat(:))))
        txt=regexprep(txt,'([-+]*)Inf',jsonopt('Inf','"$1_Inf_"',opt));
    end
    if(any(isnan(mat(:))))
        txt=regexprep(txt,'NaN',jsonopt('NaN','"_NaN_"',opt));
    end
    end

    %%-------------------------------------------------------------------------
    function name=checkname(name)
    if(isempty(regexp(name,'0x([0-9a-fA-F]+)_','once')))
        return
    elseif unpackHex
        isoct=jsonopt('IsOctave',0,opt);
        if(~isoct)
            name=regexprep(name,'(^x|_){1}0x([0-9a-fA-F]+)_','${native2unicode(hex2dec($2))}');
        else
            pos=regexp(name,'(^x|_){1}0x([0-9a-fA-F]+)_','start');
            pend=regexp(name,'(^x|_){1}0x([0-9a-fA-F]+)_','end');
            if(isempty(pos)) return; end
            str0=name;
            pos0=[0 pend(:)' length(name)];
            name='';
            for i=1:length(pos)
                name=[name str0(pos0(i)+1:pos(i)-1) char(hex2dec(str0(pos(i)+3:pend(i)-1)))];
            end
            if(pos(end)~=length(name))
                name=[name str0(pos0(end-1)+1:pos0(end))];
            end
        end
    end
    end

end

