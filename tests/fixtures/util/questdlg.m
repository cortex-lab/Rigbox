function choice = questdlg(varargin)
mock = MockDialog.instance;

choice = mock.newCall('questdlg', varargin{:});
end