function using(packages)
%USE TODO

cbToolsPath = fileparts(mfilename('fullpath'));

switch lower(packages)
  case 'superwebsocket'
    asmPath = fullfile(cbToolsPath, 'SuperWebSocket');
    NET.addAssembly(fullfile(asmPath, 'SuperWebSocket.dll'));
  case 'websocket4net'
    asmPath = fullfile(cbToolsPath, 'SuperWebSocket');
    NET.addAssembly(fullfile(asmPath, 'WebSocket4Net.dll'));
end

end

