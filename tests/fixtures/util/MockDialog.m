classdef MockDialog < handle
  % MOCKDIALOG A class for mocking MATLAB dialog windows
  %  Examples:
  %
  %     mockdlg = MockDialog.instance('char');
  %     mockdlg.Dialogs('Set tolerence') = sequence({50, 5, 0.05});
  %
  %     mockdlg = MockDialog.instance('char');
  %     mockdlg.Dialogs('1st dlg title') = 12;
  %     mockdlg.Dialogs('2nd dlg title') = false;
  %
  %     mockdlg = MockDialog.instance('uint32');
  %     mockdlg.Dialogs(0) = 12;
  %     mockdlg.Dialogs(1) = {12, 'second input ans', true};
  %
  %     mockdlg = MockDialog.instance();
  %     mockdlg.UseDefaults = true;
  %
  % See also QUESTDLG, INPUTDLG
  
  properties
    % Flag to ensure that we're in a test enviroment.  Should be set to
    % true explicitly by a test script upon setup
    InTest logical = false
    % Containers map of user input, whose keys are either dialog titles or
    % function call number
    Dialogs = containers.Map('KeyType', 'uint32', 'ValueType', 'any')
    % When true use default values for all dialogs (equivalent to user
    % pressing return key)
    UseDefaults logical = true
    % Number of calls to newCall
    NumCalls uint32 {mustBeInteger, mustBeNonnegative} = 0
  end
    
  methods (Static)
    
    function obj = instance(keyType)
      persistent inst
      if isempty(inst)
        inst = MockDialog();
      end
      if nargin > 0 && ~strcmp(inst.Dialogs.KeyType, keyType)
        warning('MockDialog:Instance:SetKeyType', ...
          'KeyType change to %s. Resetting object', keyType)
        inst.reset();
        inst.Dialogs = containers.Map('KeyType', keyType, 'ValueType', 'any');
      end
        
      obj = inst;
    end
    
  end
  
  methods
    
    function reset(obj)
      keySet = obj.Dialogs.keys;
      remove(obj.Dialogs,keySet);
      obj.NumCalls = 0;
      obj.InTest = false;
      obj.UseDefaults = true;
    end
    
    function answer = newCall(obj, type, varargin)
      % NEWCALL Called by shadowed dialog functions during tests
      %  The origin of the calls may be identified in two ways:
      %    1. Its sequence in the calls to this method.  If the KeyType of
      %    the obj.Dialog container is uint32 then the answers returned or
      %    defaults set are based on its order in the sequence of calls.
      %    2. The dialog title or prompt string.  If the obj.Dialog keys
      %    are 'char' (default), then the dialog title strings are used as
      %    keys.  If the dialog has no title then the prompt string is
      %    used.  NB: for inputdlg boxes the default is 'Input'.  If your
      %    function has multiple calls to inputdlg() with no inputs, better
      %    set KeyType to unit32.
      %
      %  Using the call sequence is useful when the title/prompt strings
      %  are variable, unknown or none-unique.  Use title strings as keys
      %  if you wish to run multiple tests in parallel.  
      %
      %  If the object's UseDefaults property is true, return the dialog's
      %  default answer for each call.
      %
      %  Inputs:
      %    type ('char') - function name that was called by function under
      %      test.  Currently implemented options are 'inputdlg' and
      %      'questdlg'.  Anything else causes method to return % FIXME
      %    All other inputs must be those that would be passed to the
      %    function designated by 'type'.
      % 
      % See also
      
      % Check we're in test mode, throw warning if not
      if ~obj.InTest
        warning('Rigbox:MockDialog:newCall:notInTest', ...
          ['MockDialog method called whilst InTest flag set to false. ' ...
          'Check paths or set flag to true to avoid this message'])
      end
      
      % Check which dialog function was called and get answer keys and
      % default answers
      switch type
        case 'questdlg'
          % ignore options struct; we don't care about them
          if isstruct(varargin{end}); varargin(end) = []; end
          if length(varargin) < 3
            def = 'Yes'; % Default is 'Yes'
          elseif length(varargin(3:end)) == length(unique(varargin(3:end)))
            def = varargin(3); % Custom button one is default
          else
            def = varargin(end); % Assume last input default
          end
          if strcmp(obj.Dialogs.KeyType, 'char')
            key = varargin{1}; % Key is prompt
          else
            key = obj.fromCount;
          end
        case {'inputdlg', 'newid'}
          % Find key
          if ~strcmp(obj.Dialogs.KeyType, 'char') && ~obj.UseDefaults
            key = obj.fromCount;
          elseif isempty(varargin)
            key = 'Input';
          elseif length(varargin) == 1 % Use prompt string
            key = varargin{1};
          else % Use dialog title
            key = varargin{2};
          end
          % Set default answer as default returned value
          def = iff(length(varargin) > 3, @()varargin{4}, {});
        otherwise
          % pass
          return
      end
    
      % Set the answer to be either the dialog's default of whatever's set
      % in the Dialogs containers.Map object
      answer = iff(obj.UseDefaults, def, @()obj.Dialogs(key));
      % If the answer is a Sequence object, return the first in the
      % sequence and iterate
      if isa(answer, 'fun.CellSeq')
        answer = answer.first;
        obj.Dialogs(key) = obj.Dialogs(key).rest;
      elseif isa(answer, 'fun.EmptySeq')
        warning('Rigbox:MockDialog:newCall:EmptySeq', ...
          'End of input sequence, using default input instead')
        answer = def;
      end
      
      % inputdlg always returns a cell
      if ismember(type, {'inputdlg','newid'})
        answer = ensureCell(answer);
      end
      obj.NumCalls = obj.NumCalls + 1; % Iterate number of calls
    end
      
  end
  
  methods (Access = private)
    
    function key = fromCount(obj)
      if strcmp(obj.Dialogs.KeyType, 'char')
        key = [];
        return
      elseif ~obj.UseDefaults
        assert(obj.Dialogs.Count > 0, ...
          'Rigbox:MockDialog:newCall:behaviourNotSet', ...
          'No values saved in Dialogs property')
      end
      key = obj.NumCalls;
      if key > obj.Dialogs.Count
        key = key - obj.Dialogs.Count*floor(key/uint32(obj.Dialogs.Count));
        key = typecast(key, obj.Dialogs.KeyType);
      end
    end
    
  end
    
end