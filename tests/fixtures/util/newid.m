function choice = newid(varargin)
mock = MockDialog.instance;

choice = mock.newCall('newid', varargin{:});
end