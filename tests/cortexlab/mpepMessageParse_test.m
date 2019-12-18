% mpepMessageParse test
% preconditions
subject = 'M20140123_CB';
series = num2str(randi(10000));
seq = randi(100);
ref = dat.constructExpRef(subject, series, seq);

block = '5';
stim = '1';
duration = '36000';
msg = @(cmd) sprintf('%s %s %s %d %s %s %s', ...
  cmd, subject, series, seq, block, stim, duration);

%% Test 1: infosave
cmd = sprintf('infosave %s_%s_%d', subject, series, seq);
info = dat.mpepMessageParse(cmd);

assert(strcmp(info.instruction, 'infosave'))
assert(strcmp(info.subject, subject))
assert(strcmp(info.series, series))
assert(strcmp(info.exp, num2str(seq)))
assert(strcmp(info.expRef, ref))

%% Test 2: hello
info = dat.mpepMessageParse(msg('hello'));
assert(strcmp(info.instruction, 'hello'))
assert(isempty(info.expRef))

%% Test 3: full mpep instruction
info = dat.mpepMessageParse(msg('expstart'));

assert(strcmp(info.instruction, 'expstart'))
assert(strcmp(info.subject, subject))
assert(strcmp(info.series, series))
assert(strcmp(info.exp, num2str(seq)))
assert(strcmp(info.expRef, ref))
assert(strcmp(info.block, block))
assert(strcmp(info.stim, stim))
assert(strcmp(info.duration, duration))

%% Test 4: series to datestr
series = datestr(now, 'yyyymmdd');
cmd = sprintf('expinterrupt %s %s %d', subject, series, seq);
info = dat.mpepMessageParse(cmd);

assert(strcmp(info.series, datestr(now, 'yyyy-mm-dd')))
assert(strcmp(info.expRef, dat.constructExpRef(subject, now, seq)))

%% Test 5: empty sequence
cmd = sprintf('expend %s %s', subject, series);
ex.message = '';
try
  dat.mpepMessageParse(cmd);
catch ex
end
assert(contains(ex.message, 'not valid'))

%% Test 6: Alyx serialization
% Test compatibility with parseAlyxInstance

token = char(randsample([48:57 65:89 97:122], 36, true)); % Generate token
ai = Alyx.parseAlyxInstance(ref, Alyx('user', token)); % Stringify instance
cmd = sprintf('alyx %s %s %d %s', subject, series, seq, ai); % Make message

info = dat.mpepMessageParse(cmd);

assert(strcmp(info.instruction, 'alyx'))
assert(strcmp(info.subject, subject))
assert(strcmp(info.series, series))
assert(strcmp(info.exp, num2str(seq)))

