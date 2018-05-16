function s = obj2json(rig)
% OBJ2JSON Converts input into JSON
s = obj2struct(rig);
if verLessThan('matlab','9.1')
  s = savejson('', s);
elseif verLessThan('matlab','9.3')
  s = jsonencode(s);
else
  s = jsonencode(s, 'ConvertInfAndNaN', true);
end
end