___class = {}
unpack = table.unpack or unpack
function ___class:__call(...)
	local object = setmetatable({}, self)
	local init = self.__init
	if init then
		init(object, ...)
	end
	return object
end
function ___class:__newindex(key, value)
	rawset(self, key, value)
	if string.sub(key, 1, 2) ~= "__" then
		self.__index[key] = value
	end
end
function ___class.new(base)
	return setmetatable({__index = setmetatable({}, base)}, ___class)
end
function concat(a,b) return a..b end
function __tfx(t)
	t.Length = #t
	return t
end
function __spread(t)
	return unpack(t, 1, t.Length)
end
function __spr(...)
	local t = (...)
	local Length, tbl = select("#", ...) + t.Length, {select(2, ...)}
	local ftbl = {}
	local j = 0
	for i = 1, t.Length do
		ftbl[j] = t[i]
		j = j + 1
	end
	for i = 1, #tbl do
		ftbl[j] = tbl[i]
		j = j + 1
	end
	return unpack(ftbl, 0, Length - 2)
end
function getlen(thing)
	return #thing
end
local ns = {}
function strn(t)
	for i = 1, #t do
		t[i] = ns.System.String(t[i])
	end
	return unpack(t)
end
local consts = {}
function __regconst(o,c,v)
	consts[#consts+1] = {o, c, v}
end
function __makeconsts()
	for i,v in ipairs(consts) do
		v[1][v[2]] = v[3]()
	end
end
function __tablify(t)
	return setmetatable(t, {__index = function(self, key)
		if key == "ins" then return self end
		if type(key) == "table" and key.__native then
			for k,v in pairs(self) do
				if type(k) == "table" and k.__native == key.__native then
					return v
				end
			end
		end
	end})
end
do
local __ns = ns['Quill.Compiler'] or {}
local included = {'Quill.Compiler', 'System'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['Quill.Compiler'] = __ns
do local __class = ___class.new() __ns.Program = __class
function __class:Main(...)
local args = __tfx{...};
local input;
local output;
local optimize = (false);
local _ = args
for i = 1, _.Length do
local v = _[i]
if (v:Substring(1, 3) == (ns.System.String "-o=")) then
output = v:Substring(4);
elseif (v == (ns.System.String "-O")) then
optimize = (true);
else
input = v;
end
;
end;
local outputFile = ns['System.IO'].File:Open((output + (ns.System.String ".c")), (ns.System.String "w+"));
local lexer = ins.Lexer(ns['System.IO'].File:Open(input, (ns.System.String "r")));
local parser = ins.Parser(lexer);
local ast = parser:ParseProgram();
if optimize then
ins.Optimizer:Optimize(ast);
end
;
local compiler = ins.CppCompiler();
outputFile:Write(compiler:CompileProgram(ast));
outputFile:Flush();
ins.__lua.os.execute((((ns.System.String "gcc ") + output) + (ns.System.String ".c -o compilertest.exe -O3")).__native);
ins.Output:Log((ns.System.String "Status code:"), ins.__lua.select(3, ins.__lua.os.execute((ns.System.String "compilertest.exe").__native)));
return 0;
end
end
end
do
local __ns = ns['Quill.Compiler'] or {}
local included = {'Quill.Compiler', 'System'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['Quill.Compiler'] = __ns
do local __class = ___class.new() __ns.Lexer = __class
__regconst(__ns.Lexer, 'Keywords', function() return __tablify {Length=25; (ns.System.String "function"),(ns.System.String "return"),(ns.System.String "end"),(ns.System.String "local"),(ns.System.String "class"),(ns.System.String "new"),(ns.System.String "namespace"),(ns.System.String "self"),(ns.System.String "using"),(ns.System.String "const"),(ns.System.String "for"),(ns.System.String "in"),(ns.System.String "do"),(ns.System.String "if"),(ns.System.String "else"),(ns.System.String "elseif"),(ns.System.String "then"),(ns.System.String "enum"),(ns.System.String "nil"),(ns.System.String "while"),(ns.System.String "break"),(ns.System.String "false"),(ns.System.String "true"),(ns.System.String "repeat"),(ns.System.String "until"),} end);
function __class:__init(file)
self.File = file;
self.Line = 1;
self.LineContents = (ns.System.String "");
self.LineIndex = 1;
end
function __class:ReadChar()
local result = (self.PeekedChar or self.File:ReadChar());
if (result == (ns.System.String "\n")) then
self.Line = (self.Line + 1);
self.LineContents = (ns.System.String "");
self.LineIndex = 1;
elseif (result ~= (nil)) then
self.LineContents = (self.LineContents + ((function() if (result == (ns.System.String "\t")) then return (ns.System.String "    ") else return result end end)()));
self.LineIndex = (self.LineIndex + ((function() if (result == (ns.System.String "\t")) then return 4 else return 1 end end)()));
end
;
self.PeekedChar = (nil);
return result;
end
function __class:PeekChar()
if self.PeekedChar then
return self.PeekedChar;
end
;
self.PeekedChar = self.File:ReadChar();
return self.PeekedChar;
end
function __class:CharEOF()
return (self:PeekChar() == (nil));
end
function __class:Fault(msg, index, size)
size = (size or 1);
index = (index or (self.LineIndex - 1));
while ((self:PeekChar() ~= (ns.System.String "\n")) and ( not self:CharEOF()))do
self:ReadChar();
end;
while (self.LineContents:Substring(1, 1) == (ns.System.String " "))do
self.LineContents = self.LineContents:Substring(2);
index = (index - 1);
end;
ins.Output:Log((((((((((ns.System.String "error: ") + msg) + (ns.System.String " at line ")) + ins.String:ToString(self.Line)) + (ns.System.String " (file .)\n\nsource: ")) + self.LineContents) + (ns.System.String "\n       ")) + (ns.System.String " "):Repeat(index)) + (ns.System.String "~"):Repeat(size)));
ins.__lua.os.exit(1);
end
function __class:IsWhitespace(char)
return (ns.System.String " \t\r\n"):Contains(char);
end
function __class:IsIdentifier(char)
return (ns.System.String "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"):Contains(char);
end
function __class:IsDigit(char)
return (ns.System.String ".0123456789"):Contains(char);
end
function __class:IsOperator(char)
return (ns.System.String "~:+-*/^&|!=<>%#"):Contains(char);
end
function __class:IsPunctuation(char)
return (ns.System.String ".;,({[]})"):Contains(char);
end
function __class:ReadWhile(predicate)
local result = (ns.System.String "");
while (( not self:CharEOF()) and predicate(self:PeekChar()))do
result = (result + self:ReadChar());
end;
return result;
end
function __class:ParseNumber()
local result = (ns.System.String "");
local hasDecimal = (false);
while (( not self:CharEOF()) and self:IsDigit(self:PeekChar()))do
if (self:PeekChar() == (ns.System.String ".")) then
if hasDecimal then
break;
else
hasDecimal = (true);
end
;
end
;
result = (result + self:ReadChar());
end;
return result;
end
function __class:ReadToken()
self:ReadWhile(function(...) return self:IsWhitespace(...) end);
local tokenStart = self.LineIndex;
if self:CharEOF() then
return (nil);
end
;
local char = self:PeekChar();
if self:IsDigit(char) then
return __tablify {Length=0; [("Type")] = (ns.System.String "Number");[("Value")] = self:ParseNumber();[("TokenStart")] = tokenStart;};
elseif self:IsOperator(char) then
return __tablify {Length=0; [("Type")] = (ns.System.String "Operator");[("Value")] = self:ReadWhile(function(...) return self:IsOperator(...) end);[("TokenStart")] = tokenStart;};
elseif self:IsPunctuation(char) then
return __tablify {Length=0; [("Type")] = (ns.System.String "Punctuation");[("Value")] = self:ReadChar();[("TokenStart")] = tokenStart;};
elseif self:IsIdentifier(char) then
local value = self:ReadWhile(function(...) return self:IsIdentifier(...) end);
return __tablify {Length=0; [("Type")] = ((function() if ins.Table:Contains(self.Keywords, value) then return (ns.System.String "Keyword") else return (ns.System.String "Identifier") end end)());[("Value")] = value;[("TokenStart")] = tokenStart;};
end
;
end
function __class:Read()
if self.Peeked then
local result = self.Peeked;
self.Peeked = (nil);
return result;
end
;
return self:ReadToken();
end
function __class:Peek()
if self.Peeked then
return self.Peeked;
end
;
self.Peeked = self:ReadToken();
return self.Peeked;
end
function __class:IsNext(type, value)
if self:EOF() then
return (false);
end
;
local peek = self:Peek();
return ((peek.Type == type) and ((function() if (value == (nil)) then return (true) else return (peek.Value == value) end end)()));
end
function __class:Next(type, value)
if self:EOF() then
return (nil);
end
;
if (type == (nil)) then
return self:Read();
end
;
if ( not self:IsNext(type, value)) then
local token = self:Peek();
self:Fault(((((((ns.System.String "expected '") + value) + (ns.System.String "'")) + (ns.System.String ", got '")) + token.Value) + (ns.System.String "'")), token.TokenStart, token.Value.Length);
end
;
return self:Read();
end
function __class:EOF()
return (self:Peek() == (nil));
end
function __class:LogTokens()
while ( not self:EOF())do
local token = self:Read();
ins.Output:Log(token.Type, (ns.System.String ":"), token.Value);
end;
end
end
end
do
local __ns = ns['Quill.Compiler'] or {}
local included = {'Quill.Compiler', 'System'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['Quill.Compiler'] = __ns
do local __class = ___class.new() __ns.Parser = __class
__regconst(__ns.Parser, 'precedence', function() return __tablify {Length=0; [(ns.System.String "=")] = 1;[(ns.System.String "or")] = 2;[(ns.System.String "and")] = 3;[(ns.System.String "<")] = 5;[(ns.System.String ">")] = 5;[(ns.System.String "<=")] = 5;[(ns.System.String ">=")] = 5;[(ns.System.String "~=")] = 5;[(ns.System.String "==")] = 5;[(ns.System.String "+")] = 10;[(ns.System.String "-")] = 10;[(ns.System.String "-(unm)")] = 20;[(ns.System.String "*")] = 20;[(ns.System.String "/")] = 20;[(ns.System.String "not")] = 30;[(ns.System.String "::")] = 90;[(ns.System.String ".")] = 100;[(ns.System.String ":")] = 100;} end);
function __class:__init(lexer)
self.Lexer = lexer;
self.Context = ins.Context();
return 0;
end
function __class:ParseTrueAtom()
if self.Lexer:IsNext((ns.System.String "Number")) then
return __tablify {Length=0; [("Type")] = (ns.System.String "Number");[("TypeInfo")] = __tablify {Length=0; [("Deterministic")] = (true);[("Type")] = (ns.System.String "number");};[("Value")] = self.Lexer:Next().Value;};
elseif self.Lexer:IsNext((ns.System.String "Identifier")) then
return __tablify {Length=0; [("Type")] = (ns.System.String "Identifier");[("TypeInfo")] = __tablify {Length=0; [("Deterministic")] = (false);[("Type")] = (ns.System.String "any");};[("Name")] = self.Lexer:Next().Value;};
elseif self.Lexer:IsNext((ns.System.String "Keyword"), (ns.System.String "self")) then
return __tablify {Length=0; [("Type")] = (ns.System.String "Self");[("TypeInfo")] = __tablify {Length=0; };};
else
self.Lexer:Fault((ns.System.String "expected expression"));
end
;
end
function __class:ParseAtom()
return self:MaybeCall(function(...) return self:ParseTrueAtom(...) end);
end
function __class:MaybeBinary(atom, precedence)
atom = ((function() if (ins.TypeOf(atom) == (ns.System.String "function")) then return atom() else return atom end end)());
if self.Lexer:IsNext((ns.System.String "Operator")) then
local operator = self.Lexer:Next().Value;
local nextPrecedence = self.precedence[operator];
if (nextPrecedence > precedence) then
local right = self:MaybeBinary(function(...) return self:ParseAtom(...) end, nextPrecedence);
return self:MaybeBinary(__tablify {Length=0; [("Type")] = (ns.System.String "BinaryOperation");[("TypeInfo")] = __tablify {Length=0; [("Deterministic")] = (atom.TypeInfo.Deterministic and right.TypeInfo.Deterministic);[("Type")] = atom.TypeInfo.Type;};[("Operator")] = operator;[("Left")] = atom;[("Right")] = right;}, precedence);
end
;
end
;
return atom;
end
function __class:ParseCall(atom, statement)
self.Lexer:Next();
local arg = self:ParseExpression();
self.Lexer:Next((ns.System.String "Punctuation"), (ns.System.String ")"));
local result = __tablify {Length=0; [("Type")] = ((function() if statement then return (ns.System.String "Statement") else return (ns.System.String "Call") end end)());[("TypeInfo")] = __tablify {Length=0; [("Deterministic")] = (false);[("Type")] = (ns.System.String "any");};[("Function")] = atom;[("Args")] = __tablify {Length=0; [1] = arg;};};
if statement then
result.Statement = (ns.System.String "Call");
end
;
return result;
end
function __class:MaybeCall(atom)
atom = ((function() if (ins.TypeOf(atom) == (ns.System.String "function")) then return atom() else return atom end end)());
return ((function() if self.Lexer:IsNext((ns.System.String "Punctuation"), (ns.System.String "(")) then return self:ParseCall(atom) else return atom end end)());
end
function __class:ParseExpression()
return self:MaybeCall(self:MaybeBinary(function(...) return self:ParseAtom(...) end, 0));
end
function __class:ParseStatement()
if self.Lexer:IsNext((ns.System.String "Keyword"), (ns.System.String "return")) then
self.Lexer:Next();
return __tablify {Length=0; [("Type")] = (ns.System.String "Statement");[("Statement")] = (ns.System.String "Return");[("Value")] = self:ParseExpression();};
elseif self.Lexer:IsNext((ns.System.String "Identifier")) then
local name = self.Lexer:Next().Value;
if self.Lexer:IsNext((ns.System.String "Punctuation"), (ns.System.String "(")) then
return self:ParseCall(__tablify {Length=0; [("Type")] = (ns.System.String "Identifier");[("TypeInfo")] = __tablify {Length=0; [("Deterministic")] = (false);[("Type")] = (ns.System.String "any");};[("Name")] = name;}, (true));
else
self.Lexer:Next((ns.System.String "Operator"), (ns.System.String "="));
return __tablify {Length=0; [("Type")] = (ns.System.String "Statement");[("Statement")] = (ns.System.String "Assignment");[("Name")] = name;[("Value")] = self:ParseExpression();};
end
;
elseif self.Lexer:IsNext((ns.System.String "Keyword"), (ns.System.String "local")) then
self.Lexer:Next();
local Name = self.Lexer:Next((ns.System.String "Identifier")).Value;
self.Lexer:Next((ns.System.String "Operator"), (ns.System.String "="));
local Value = self:ParseExpression();
return __tablify {Length=0; [("Type")] = (ns.System.String "Statement");[("Statement")] = (ns.System.String "Local");[("Name")] = Name;[("Value")] = Value;};
else
self.Lexer:Fault((ns.System.String "expected statement"));
end
;
end
function __class:ParseBlock(blockEnd)
local statements = __tablify {Length=0; };
blockEnd = (blockEnd or (ns.System.String "end"));
while (( not self.Lexer:IsNext((ns.System.String "Keyword"), blockEnd)) and ( not self.Lexer:EOF()))do
ins.Table:Insert(statements, self:ParseStatement());
if self.Lexer:IsNext((ns.System.String "Punctuation"), (ns.System.String ";")) then
self.Lexer:Next();
end
;
end;
self.Lexer:Next((ns.System.String "Keyword"), blockEnd);
return statements;
end
function __class:ParseFunction(className)
self.Context = ins.Context(self.Context);
self.Lexer:Next((ns.System.String "Keyword"), (ns.System.String "function"));
local name = self.Lexer:Next((ns.System.String "Identifier")).Value;
self.Lexer:Next((ns.System.String "Punctuation"), (ns.System.String "("));
self.Lexer:Next((ns.System.String "Punctuation"), (ns.System.String ")"));
local body = self:ParseBlock();
self.Context = self.Context.Parent;
return __tablify {Length=0; [("Type")] = (ns.System.String "Function");[("Name")] = name;[("Class")] = className;[("Body")] = body;};
end
function __class:ParseClass()
self.Context = ins.Context(self.Context);
self.Lexer:Next((ns.System.String "Keyword"), (ns.System.String "class"));
local name = self.Lexer:Next((ns.System.String "Identifier")).Value;
local functions = __tablify {Length=0; };
while (( not self.Lexer:EOF()) and ( not self.Lexer:IsNext((ns.System.String "Keyword"), (ns.System.String "end"))))do
ins.Table:Insert(functions, self:ParseFunction(name));
end;
self.Lexer:Next((ns.System.String "Keyword"), (ns.System.String "end"));
self.Context = self.Context.Parent;
return __tablify {Length=0; [("Type")] = (ns.System.String "Class");[("Name")] = name;[("Functions")] = functions;};
end
function __class:ParseProgram()
local classes = __tablify {Length=0; };
while ( not self.Lexer:EOF())do
ins.Table:Insert(classes, self:ParseClass());
end;
return __tablify {Length=0; [("Type")] = (ns.System.String "Program");[("Classes")] = classes;};
end
end
end
do
local __ns = ns['Quill.Compiler'] or {}
local included = {'Quill.Compiler', 'System'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['Quill.Compiler'] = __ns
do local __class = ___class.new() __ns.CppCompiler = __class
function __class:__init(lexer)
self.Lexer = lexer;
return 0;
end
function __class:FixName(...)
local names = __tfx{...};
local name = (ns.System.String "l");
local _ = names
for i = 1, _.Length do
local v = _[i]
name = ((name + (ns.System.String "_")) + v:Replace((ns.System.String "_"), (ns.System.String "u_")));
end;
return name;
end
function __class:CompileBlock(block)
local result = (ns.System.String "");
local _ = block
for i = 1, _.Length do
local v = _[i]
result = (result + self:Compile(v));
end;
return result;
end
function __class:Compile(item)
if (item.Type == (ns.System.String "Statement")) then
if (item.Statement == (ns.System.String "Return")) then
return (((ns.System.String "\n\treturn ") + self:Compile(item.Value)) + (ns.System.String ";"));
elseif (item.Statement == (ns.System.String "Local")) then
return (((((ns.System.String "\n\tstruct qlvalue ") + self:FixName((ns.System.String "variable"), item.Name)) + (ns.System.String " = ")) + self:Compile(item.Value)) + (ns.System.String ";"));
elseif (item.Statement == (ns.System.String "Assignment")) then
return (((((ns.System.String "\n\t") + self:FixName((ns.System.String "variable"), item.Name)) + (ns.System.String " = ")) + self:Compile(item.Value)) + (ns.System.String ";"));
elseif (item.Statement == (ns.System.String "Call")) then
return (((((ns.System.String "\n\t") + self:Compile(item.Function)) + (ns.System.String "(")) + self:Compile(item.ins.Args[1])) + (ns.System.String ");"));
end
;
elseif (item.Type == (ns.System.String "Number")) then
return (((ns.System.String "qlnumber((double)") + item.Value) + (ns.System.String ")"));
elseif (item.Type == (ns.System.String "Identifier")) then
return self:FixName((ns.System.String "variable"), item.Name);
elseif (item.Type == (ns.System.String "BinaryOperation")) then
if (item.Operator == (ns.System.String "+")) then
return (((((ns.System.String "qladd(") + self:Compile(item.Left)) + (ns.System.String ", ")) + self:Compile(item.Right)) + (ns.System.String ")"));
elseif (item.Operator == (ns.System.String "*")) then
return (((((ns.System.String "qlmul(") + self:Compile(item.Left)) + (ns.System.String ", ")) + self:Compile(item.Right)) + (ns.System.String ")"));
end
;
elseif (item.Type == (ns.System.String "Program")) then
return self:Compile(item.ins.Classes[1]);
elseif (item.Type == (ns.System.String "Function")) then
return (((((ns.System.String "struct qlvalue ") + self:FixName((ns.System.String "method"), item.Class, item.Name)) + (ns.System.String "() {")) + self:CompileBlock(item.Body)) + (ns.System.String "\n}\n\n"));
elseif (item.Type == (ns.System.String "Class")) then
local result = (((ns.System.String "struct ") + self:FixName((ns.System.String "class"), item.Name)) + (ns.System.String " {\n"));
local _ = item.Functions
for i = 1, _.Length do
local v = _[i]
result = (((result + (ns.System.String "\tstruct qlvalue ")) + self:FixName((ns.System.String "variable"), v.Name)) + (ns.System.String ";\n"));
end;
result = (result + (ns.System.String "};\n\n"));
local _ = item.Functions
for i = 1, _.Length do
local v = _[i]
result = (result + self:Compile(v));
end;
return result;
elseif (item.Type == (ns.System.String "Call")) then
return (((self:Compile(item.Function) + (ns.System.String "(")) + self:Compile(item.ins.Args[1])) + (ns.System.String ")"));
end
;
ins.__lua.error(((ns.System.String "oops ") + item.Type).__native);
end
function __class:CompileProgram(ast)
return (((ns.System.String "#include <stdio.h>\n#include <stdarg.h>\n#include <stdint.h>\n#include <stdlib.h>\n#include <stdbool.h>\n#include <string.h>\n#include <setjmp.h>\n#include <stdnoreturn.h>\n#include <math.h>\n\n/*\n * Used functions:\n *\n * malloc\n * free\n * \n */\n\nstruct qlstring {\n	char* data;\n	uint32_t length;\n};\n\nunion qldata {\n	double number;\n	struct qlstring string;\n};\n\nstruct qlvalue {\n	uint16_t type;\n	union qldata data;\n};\n\ninline struct qlvalue qlnumber(double data) {\n	struct qlvalue result;\n	result.type = 0;\n	result.data.number = data;\n	return result;\n}\n\ninline struct qlvalue qlstring(const char* data, uint32_t length) {\n	struct qlvalue result;\n	result.type = 1;\n	result.data.string.data = (char*)data;\n	result.data.string.length = length;\n	return result;\n}\n\nvoid error() {\n\n}\n\nstruct qlvalue qladd(struct qlvalue a, struct qlvalue b) {\n	if (a.type != b.type) error();\n\n	struct qlvalue result;\n	if (a.type == 0) {\n		result.type = 0;\n		result.data.number = a.data.number + b.data.number;\n	} else if (a.type == 1) {\n		result.type = 1;\n		// TODO result.data.string.data = \n	}\n\n	return result;\n}\n\nstruct qlvalue qlmul(struct qlvalue a, struct qlvalue b) {\n	if (a.type != b.type) error();\n\n	struct qlvalue result;\n	if (a.type == 0) {\n		result.type = 0;\n		result.data.number = a.data.number * b.data.number;\n	} else if (a.type == 1) {\n		result.type = 1;\n		// TODO result.data.string.data = \n	}\n\n	return result;\n}\n\nstruct qlvalue qlnil;\n\n// TODO: temporary, remove\nstruct qlvalue l_variable_print(struct qlvalue thing) {\n	if (thing.type == 0) {\n		printf(\"%.14g\\n\", thing.data.number);\n	}\n\n	return qlnil;\n}\n\n") + self:Compile(ast)) + (ns.System.String "int main() {\n	qlnil.type = 65535;\n	double result = l_method_Program_Main().data.number;\n	int status = (int)result;\n	if ((double)status != result) {\n		error();\n	}\n	return status;\n}"));
end
end
end
do
local __ns = ns['Quill.Compiler'] or {}
local included = {'Quill.Compiler', 'System'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['Quill.Compiler'] = __ns
do local __class = ___class.new() __ns.Context = __class
function __class:__init(parent)
self.Parent = parent;
self.Data = __tablify {Length=0; };
end
function __class:HasField(field)
return (self[field] ~= (nil));
end
end
end
do
local __ns = ns['System'] or {}
local included = {'System'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['System'] = __ns
do local __class = ___class.new() __ns.Object = __class
function __class:ToString()
return;
end
end
end
do
local __ns = ns['System'] or {}
local included = {'System'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['System'] = __ns
do local __class = ___class.new() __ns.Output = __class
function __ns.Output:Write(value)
if (ins.__lua.type(value) == (ns.System.String "table").__native) then
ins.__lua.io.write(value.__native);
else
ins.__lua.io.write(ins.__lua.tostring(value));
end
;
end
function __ns.Output:WriteLine(value)
self:Write(value);
self:Write((ns.System.String "\n"));
end
function __ns.Output:WriteF(value, ...)
local args = __tfx{...};
local _ = args
for i = 1, _.Length do
local v = _[i]
if (ins.__lua.type(v) == (ns.System.String "table").__native) then
v = v.__native;
end
;
end;
self:Write(ins.__lua.string.format(value.__native, __spr(args)));
end
function __ns.Output:Log(...)
local values = __tfx{...};
local _ = values
for i = 1, _.Length do
local v = _[i]
if (i > 1) then
self:Write((ns.System.String " "));
end
;
self:Write(v);
end;
self:Write((ns.System.String "\n"));
end
end
end
do
local __ns = ns['System'] or {}
local included = {'System'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['System'] = __ns
do local __class = ___class.new() __ns.Math = __class
__regconst(__ns.Math, 'PI', function() return 3.14159265358979323846 end);
__regconst(__ns.Math, 'E', function() return 2.7182818284590452354 end);
function __ns.Math:Floor(value)
return ins.__lua.math.floor(value);
end
function __ns.Math:Ceil(value)
return ins.__lua.math.ceil(value);
end
function __ns.Math:Pow(x, y)
return ins.__lua.math.pow(x, y);
end
function __ns.Math:LogE(value)
return ins.__lua.math.log(value);
end
function __ns.Math:Log10(value)
return ins.__lua.math.log10(value);
end
function __ns.Math:Log2(value)
return (ins.__lua.math.log(value) / 0.6931471805599453);
end
end
end
do
local __ns = ns['System'] or {}
local included = {'System'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['System'] = __ns
do local __class = ___class.new() __ns.String = __class
function __class:__init(native)
self.__native = native;
self.Length = ins.__lua.getlen(self.__native);
end
function __ns.String:ToString(thing)
return ins.String(ins.__lua.tostring(thing));
end
function __class:ToNumber()
return ins.__lua.tonumber(self.__native);
end
function __class:Replace(string, nstring)
return ins.String(self.__native:gsub(string.__native, nstring.__native));
end
function __class:Substring(start, finish)
return ins.String(self.__native:sub(start, finish));
end
function __class:Repeat(times)
return ins.String(self.__native:rep(times));
end
function __class:ToUppercase()
return ins.String(self.__native:upper());
end
function __class:ToLowercase()
return ins.String(self.__native:lower());
end
function __ns.String:Char(value)
return ins.String(ins.__lua.string.char(value));
end
function __class:Reverse()
return ins.String(self.__native:reverse());
end
function __class:Byte()
return self.__native:byte();
end
function __class:Contains(str)
return self.__native:find(str.__native, 1, (true));
end
function __class:__eq(two)
return ((self.__native == two) or (self.__native == two.__native));
end
function __class:__add(two)
return ins.String(ins.__lua.concat(self.__native, two.__native));
end
end
end
do
local __ns = ns['System'] or {}
local included = {'System'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['System'] = __ns
do local __class = ___class.new() __ns.Table = __class
function __ns.Table:Contains(array, value)
local _ = array
for i = 1, _.Length do
local v = _[i]
if (v == value) then
return (true);
end
;
end;
return (false);
end
function __ns.Table:Insert(array, value)
array.Length = (array.Length + 1);
array[array.Length] = value;
end
end
end
do
local __ns = ns['System.IO'] or {}
local included = {'System.IO'}
local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
	for i, v in next, included do
		if ns[v][k] then
			return ns[v][k]
		end
	end
end})
ns['System.IO'] = __ns
do local __class = ___class.new() __ns.File = __class
function __ns.File:Open(path, mode)
local file = ins.File();
file.__file = ins.__lua.io.open(path.__native, mode.__native);
return file;
end
function __class:Exists(path)
end
function __class:Dispose()
ins.__lua.io.close(self.__file);
end
function __class:ReadAll()
return ns['System'].String(self.__file:read((ns.System.String "*a").__native));
end
function __class:ReadLine()
return ns['System'].String(self.__file:read());
end
function __class:ReadChar()
if self:EOF() then
return (nil);
end
;
return ns['System'].String(self.__file:read(1));
end
function __class:EOF()
return (self.__file:read(0) == (nil));
end
function __class:Write(str)
self.__file:write(str.__native);
end
function __class:WriteLine()
self.__file:write(ins.str.__native);
self.__file:write((ns.System.String "\n").__native);
end
function __class:Flush()
self.__file:flush();
end
end
end
__makeconsts()os.exit(ns['Quill.Compiler'].Program():Main(strn(args)))