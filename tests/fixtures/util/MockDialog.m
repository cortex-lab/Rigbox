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
  %     mockdlg = MockDialog.instance('uin32');
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
    Dialogs = containers.Map('KeyType', 'uint32')
    % 
    UseDefaults logical = true
    % Number of calls to newCall % TODO must be uint
    NumCalls uint32 {mustBeInteger, mustBeNonnegative} = 0
  end
    
  methods (Static)
    
    function obj = instance(keyType)
      if nargin == 0; keyType = 'uint32'; end
      persistent inst
      if isempty(inst)
        inst = MockDialog();
      end
      if inst.Dialogs.Count ~= 0 && ~strcmp(inst.Dialogs.KeyType, keyType)
        warning('MockDialog:Instance:SetKeyType', ...
          'KeyType change from to %s. Resetting object', keyType)
        inst.reset();
        inst.Dialogs = containers.Map('KeyType', keyType);
      end
        
      obj = inst;
    end
    
%     function reset()
%       delete(inst)
%       clear('inst')
%       obj = [];
%       clear('MockDialog')
%     end

  end
  
  methods
    
    function reset(obj)
      keySet = obj.Dialogs.keys;
      remove(obj.Dialogs,keySet)
      obj.NumCalls = 0;
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
        warning('MockDialog:newCall:InTestFalse', ...
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
          elseif length(varargin(3:end)) == length(unique(varargin(3:end))
            def = varargin(3); % Custom button one is default
          else
            def = varargin(end); % Assume last input default
          end
          if strcmp(obj.Dialog.KeyType, 'char')
            key = varargin{1}; % Key is prompt
          else
            key = obj.NumCalls;
            if key > obj.Dialog.Count
              key = key - obj.Dialog.Count*floor(key/obj.Dialog.Count);
              key = typecast(key, obj.Dialog.KeyType);
            end
          end
        case 'inputdlg'
          % Find key
          if ~strcmp(obj.Dialog.KeyType, 'char')
            key = obj.NumCalls;
            if key > obj.Dialog.Count
              key = key - obj.Dialog.Count*floor(key/obj.Dialog.Count);
              key = typecast(key, obj.Dialog.KeyType);
            end
          elseif isempty(varargin)
            key = 'Input';
          elseif length(varargin) == 1 % Use prompt string
            key = varargin{1};
          else % Use dialog title
            key = varargin{2};
          end
          % Set default answer as default returned value
          def = iff(length(varargin) > 3, @()varargin(4), {});
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
      end
      obj.NumCalls = obj.NumCalls + 1; % Iterate number of calls
    end
      
  end
    
end