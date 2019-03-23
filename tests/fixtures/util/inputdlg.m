function choice = inputdlg(varargin)
mock = MockDialog.instance;

choice = mock.newCall('inputdlg', varargin{:});
end