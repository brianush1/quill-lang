local tab_size = 4
local keywords = ([[
 function return end local class new
 namespace self using const for in do
 if else elseif then enum nil while break false true

 repeat until
 ]]):gsub("[\r\n]", "")

local precedence = {
	["="] = 1,
	["or"] = 2,
	["and"] = 3,
	["<"] = 5, [">"] = 5, ["<="] = 5, [">="] = 5, ["~="] = 5, ["=="] = 5,
	["+"] = 10, ["-"] = 10,
	["-(unm)"] = 20, ["*"] = 20, ["/"] = 20,
	["not"] = 30,
	["::"] = 90,
	["."] = 100, [":"] = 100
}

local op_types = {
	["="] = "assign",
	["+"] = "add", ["-"] = "sub",
	["*"] = "mul", ["/"] = "div",
	["::"] = "namespace",
	["."] = "dotIndex", [":"] = "dotIndex"
}

function InputStream(input, file)
	local pos, col, line = 1, 0, 1
	local current_line_index = 1
	local Length = #input
	local res
	res = {
		get_position = function(_)
			return pos
		end,
		input = input,
		next = function(_, skip)
			local char = input:sub(pos, pos + (skip or 0))
			if skip then
				for i = 1, #char do
					local c = char:sub(i, i)
					col = col + (c == "\t" and tab_size or 1)
					pos = pos + 1
					if c == "\n" then
						current_line_index = pos
						line = line + 1
						col = 0
					end
				end
			else
				col = col + (char == "\t" and tab_size or 1)
				pos = pos + 1
				if char == "\n" then
					current_line_index = pos
					line = line + 1
					col = 0
				end
			end
			return char
		end,
		peek = function(_, skip)
			if skip then
				return input:sub(pos, pos + skip)
			end
			return input:sub(pos, pos)
		end,
		eof = function()
			return pos > Length
		end,
		saveState = function()
			return {
				current_line_index = current_line_index,
				pos = pos,
				col = col,
				line = line
			}
		end,
		loadState = function(_, state)
			current_line_index = state.current_line_index
			pos = state.pos
			col = state.col
			line = state.line
		end,
		saveFault = function()
			return {
				line_index = current_line_index,
				column = col,
				error_line = line,
				stream = res
			}
		end,
		fault = function(_, msg, tokenLength, data)
			local column = col
			local line_index = current_line_index
			local error_line = line
			if data then
				line_index = data.line_index
				column = data.column
				error_line = data.error_line
			end
			print("error: " .. msg .. " at line " .. error_line .. " (file " .. file .. ")")

			local line = input:sub(line_index, (input:find("\n", line_index, true) or #input + 1) - 1):gsub("\t", (" "):rep(tab_size))
			local c = column + 8

			while line:sub(1, 1) == " " do
				line = line:sub(2)
				c = c - 1
			end

			print("\nsource: " .. line)
			print((" "):rep(c) .. (tokenLength and ("~"):rep(tokenLength) or "~"))

			os.exit()
		end
	}
	return res
end

function Tokenizer(input)
	local function is_hex_digit(ch)
		return ("0123456789abcdefABCDEF"):find(ch, 1, true)
	end

	local function is_digit(ch)
		return ("0123456789"):find(ch, 1, true)
	end

	local function is_identifier(ch)
		return ("abcdefghijklmnopqrstuvwxyz0123456789_$"):find(ch:lower(), 1, true)
	end

	local function is_punctuation(ch)
		return (".;,({[]})"):find(ch, 1, true)
	end

	local function is_op_char(ch)
		return ("~:+-*/^&|!=<>%#"):find(ch, 1, true)
	end

	local function read_while(predicate)
		local result = ""
		while not input:eof() and predicate(input:peek()) do
			result = result .. input:next()
		end
		return result
	end

	local function skip_comment()
		read_while(function(ch)
			return ch ~= "\n"
		end)
	end

	local function skip_block_comment()
		read_while(function()
			return input:peek(1) ~= "]]"
		end)
		input:next()
		input:next()
	end

	local function is_whitespace(ch)
		return (" \t\r\n"):find(ch, 1, true)
	end

	local function read_number()
		local fault_data = input:saveFault()
		local number
		local is_float = false
		if input:peek(1) == "0x" then
			number = input:next(1) .. read_while(is_hex_digit)
		else
			number = read_while(function(ch)
				if ch == "." then
					if is_float then return false end
					is_float = true
					return true
				end
				return is_digit(ch)
			end)
		end
		return {
			type = "number",
			value = number,
			is_float = is_float,
			fault_data = fault_data
		}
	end

	local function read_identifier()
		local fault_data = input:saveFault()
		local value = read_while(is_identifier)
		return {
			type = keywords:find(" " .. value .. " ", 1, true) and "keyword" or (precedence[value] and "operator" or "identifier"),
			value = value,
			fault_data = fault_data
		}
	end

	local function read_string()
		local fault_data = input:saveFault()
		local str = ""
		local escape = false
		input:next()
		while not input:eof() do
			local ch = input:next()
			if escape then
				str = str .. "\\" .. ch
				escape = false
			elseif ch == "\\" then
				escape = true
			elseif ch == "\"" then
				break
			else
				str = str .. ch
			end
		end
		return {
			type = "string",
			value = str,
			fault_data = fault_data
		}
	end

	local function read_next()
		read_while(is_whitespace)

		if input:eof() then return nil end

		local ch = input:peek()

		local fault_data = input:saveFault()

		if input:peek(3) == "--[[" then
			skip_block_comment()
			return read_next()
		elseif input:peek(1) == "--" then
			skip_comment()
			return read_next()
		elseif input:peek() == "@" then
			skip_comment()
			return read_next()
		end

		if is_digit(ch) then return read_number() end
		if is_identifier(ch) then return read_identifier() end
		if ch == "\"" then return read_string() end
		
		if is_punctuation(ch) then return {
			type = "punctuation",
			value = input:next(),
			fault_data = fault_data
		} end

		if is_op_char(ch) then return {
			type = "operator",
			value = read_while(is_op_char),
			fault_data = fault_data
		} end
		
		input:fault("unknown character '" .. ch ..  "'")
	end

	local current = nil

	local function checkToken(token, type, value, return_value)
		if type then
			local gotType = token == nil and "<eof>" or token.type
			local gotValue = token ~= nil and token.value or nil

			if gotType ~= type or (value ~= nil and gotValue ~= value) then
				if return_value then return false end
				local expectation = type .. (value and " '" .. value .. "'" or "")
				local actual = gotType .. (gotValue and " '" .. gotValue .. "'" or "")
	
				if gotType == "<eof>" then
					input:fault("expected " .. expectation .. ", got <eof>")
				else
					input:fault("expected " .. expectation .. ", got " .. actual, #token.value, token.fault_data)
				end
			end

			if return_value then return true end
		end
	end

	local function next(_, type, value)
		local result = current or read_next()
		current = nil

		checkToken(result, type, value)

		return result
	end

	local function peek(_, type, value)
		if not current then current = read_next() end

		checkToken(current, type, value)

		return current
	end

	local function is_next(_, type, value)
		if not current then current = read_next() end
		return checkToken(current, type, value, true)
	end

	local function eof()
		return peek() == nil
	end

	return {
		next = next,
		peek = peek,
		is_next = is_next,
		eof = eof,
		input = input,
		saveState = input.saveState,
		loadState = input.loadState,
		fault = function(_, msg, token)
			input:fault(msg, #token.value, token.fault_data)
		end
	}
end

--@ deprecated
local function compileAsm(expr, stackframe)
	local q = {}
	if expr.type == "program" then
		
		q[1] = ([[
		global _start
		NULL equ 0

		extern printf, ExitProcess

		section .data
		%%data%%

		section .bss
			dummy resd 1

		section .text

		_start:
			call %%entrypoint%%
			push eax
			call ExitProcess
		]]):gsub("%%%%entrypoint%%%%", "ql_Main")
		local data = {}
		for _, func in ipairs(expr.functions) do
			q[#q+1] = "\n" .. func.qlname .. ":\n"
			q[#q+1] = "\tpush ebp\n"
			q[#q+1] = "\tmov ebp, esp\n"
			local index = #q + 1
			local stackframeInitializer = {}
			q[index] = ""
			local stackframe = {0, stackframeInitializer, data}
			for _, expr in ipairs(func.body) do
				q[#q+1] = compileAsm(expr, stackframe)
			end
			q[index] = table.concat(stackframeInitializer)
			q[#q+1] = "\tpop ebp\n"
			q[#q+1] = "\tret\n"
		end

		q[1] = q[1]:gsub("%%%%data%%%%", table.concat(data))
	elseif expr.type == "return" then
		q[#q+1] = compileAsm(expr.value, stackframe)
	elseif expr.type == "string" then
		--q[#q+1] = "\n;\t" .. expr.type .. "\n"
		local data = stackframe[3]
		local l = #data
		data[l + 1] = "\t__str" .. l .. " db \"" .. expr.value .. "\", 0\n"
		q[#q+1] = "\tmov eax, __str" .. l .. "\n"
	elseif expr.type == "number" then
		--q[#q+1] = "\n;\t" .. expr.type .. "\n"
		q[#q+1] = "\tmov eax, " .. expr.value .. "\n"
	elseif expr.type == "add" then
		q[#q+1] = compileAsm(expr.left, stackframe)
		q[#q+1] = "\tpush eax\n"
		q[#q+1] = compileAsm(expr.right, stackframe)
		q[#q+1] = "\tpop ecx\n"
		--q[#q+1] = "\n;\t" .. expr.type .. "\n"
		q[#q+1] = "\tadd eax, ecx\n"
	elseif expr.type == "sub" then
		q[#q+1] = compileAsm(expr.left, stackframe)
		q[#q+1] = "\tpush eax\n"
		q[#q+1] = compileAsm(expr.right, stackframe)
		q[#q+1] = "\tpop ecx\n"
		--q[#q+1] = "\n;\t" .. expr.type .. "\n"
		q[#q+1] = "\tsub ecx, eax\n"
		q[#q+1] = "\tmov eax, ecx\n"
	elseif expr.type == "mul" then
		q[#q+1] = compileAsm(expr.left, stackframe)
		q[#q+1] = "\tpush eax\n"
		q[#q+1] = compileAsm(expr.right, stackframe)
		q[#q+1] = "\tpop ecx\n"
		--q[#q+1] = "\n;\t" .. expr.type .. "\n"
		q[#q+1] = "\timul eax, ecx\n"
	elseif expr.type == "div" then
		q[#q+1] = compileAsm(expr.left, stackframe)
		q[#q+1] = "\tpush eax\n"
		q[#q+1] = compileAsm(expr.right, stackframe)
		q[#q+1] = "\tmov ecx, eax\n"
		q[#q+1] = "\tpop eax\n"
		q[#q+1] = "\tmov edx, 0\n"
		--q[#q+1] = "\n;\t" .. expr.type .. "\n"
		q[#q+1] = "\tdiv ecx\n"
	elseif expr.type == "local" then
		stackframe[1] = stackframe[1] - 1
		stackframe[expr.name] = {}
		stackframe[expr.name].id = tostring(stackframe[expr.name]):sub(8)
		q[#q+1] = compileAsm(expr.value, stackframe)
		q[#q+1] = "\tmov DWORD [__lv" .. stackframe[expr.name].id .. "], eax\n"
		table.insert(stackframe[3], "\t__lv" .. stackframe[expr.name].id .. " db 0, 0, 0, 0\n")
	elseif expr.type == "assign" then
		q[#q+1] = compileAsm(expr.right, stackframe)
		q[#q+1] = "\tmov DWORD [__lv" .. stackframe[expr.left.value].id .. "], eax\n"
		--table.insert(stackframe[2], "\tpush eax\n")
	elseif expr.type == "identifier" then
		--q[#q+1] = compileAsm(expr.value, stackframe)
		q[#q+1] = "\tmov eax, DWORD [__lv" .. stackframe[expr.value].id .. "]\n"
	else
		error("oops")
	end
	return table.concat(q)
end

local function makeScope(parent)
	return setmetatable({}, {__index = function(_, k)
		return parent and parent[k] or false
	end})
end

function compile(scope, expr, data)
	local q = {}
	if expr.type == "program" then
		q[1] = ([=[do
		local __ns = ns['$ns'] or {}
		local included = {$i}
		local ins = setmetatable({TypeOf = function(x) return ns.System.String(type(x)) end, __lua = _ENV or getfenv()}, {__index = function(_,k)
			for i, v in next, included do
				if ns[v][k] then
					return ns[v][k]
				end
			end
		end})
		ns['$ns'] = __ns
		]=]):gsub("\n\t\t", "\n"):gsub("%$ns", expr.namespace):gsub("%$i", expr.usings)
		for _, enum in ipairs(expr.enums) do
			q[#q+1] = compile(makeScope(), enum)
		end
		for _, class in ipairs(expr.classes) do
			q[#q+1] = compile(makeScope(), class)
		end
		q[#q+1] = "end\n"
	elseif expr.type == "class" then
		q[#q+1] = "do local __class = ___class.new() __ns."
		q[#q+1] = expr.name .. " = __class\n"
		for _, const in ipairs(expr.consts) do
			q[#q+1] = "__regconst(__ns." .. expr.name .. ", '" .. const.name .. "', function() return " .. compile(scope, const.value) .. " end);\n"
		end
		for _, func in ipairs(expr.functions) do
			q[#q+1] = compile(scope, func, "__ns." .. expr.name)
		end
		q[#q+1] = "end\n"
	elseif expr.type == "enum" then
		q[#q+1] = "__ns."
		q[#q+1] = expr.name .. " = {\n"
		for k, v in pairs(expr.values) do
			q[#q+1] = "['" .. k .. "'] = " .. v .. ";\n"
		end
		q[#q+1] = "}\n"
	elseif expr.type == "function" then
		local args = ""
		local ellipsisArg = nil
		local newScope = makeScope(scope)
		for i, arg in ipairs(expr.args) do
			if arg.ellipsis then ellipsisArg = arg.name end
			args = args .. (i > 1 and ", " or "") .. (arg.ellipsis and "..." or arg.name)
			newScope[arg.name] = true
		end
		q[#q+1] = "function " .. (expr.const and data or "__class") .. ":" .. expr.name .. "(" .. args .. ")\n"
		if ellipsisArg then
			q[#q+1] = "local " .. ellipsisArg .. " = __tfx{...};\n"
		end
		for _, stat in ipairs(expr.body) do
			q[#q+1] = compile(newScope, stat) .. ";\n"
		end
		q[#q+1] = "end\n"
	elseif expr.type == "return" then
		return expr.value and ("return " .. compile(scope, expr.value)) or "return"
	elseif expr.type == "nativestring" then
		return "(\"" .. expr.value:gsub("\n", "\\n") .. "\")"
	elseif expr.type == "string" then
		return "(ns.System.String \"" .. expr.value:gsub("\n", "\\n") .. "\")"
	elseif expr.type == "number" then
		return expr.value
	elseif expr.type == "nothing" then
		return ""
	elseif expr.type == "add" or
			expr.type == "sub" or
			expr.type == "mul" or
			expr.type == "div" or
			expr.type == "binOp" then
		return "(" .. compile(scope, expr.left) .. " " .. expr.operator .. " " .. compile(scope, expr.right) .. ")"
	elseif expr.type == "local" then
		scope[expr.name] = true
		return "local " .. expr.name .. (expr.value ~= nil and " = " .. compile(scope, expr.value) or "")
	elseif expr.type == "assign" then
		return compile(scope, expr.left) .. " = " .. compile(scope, expr.right)
	elseif expr.type == "raw" then
		return "(" .. expr.value .. ")"
	elseif expr.type == "identifier" then
		if expr.alone then
			return scope[expr.value] and expr.value or "ins." .. expr.value
		else
			return expr.value
		end
	elseif expr.type == "self" then
		return "self"
	elseif expr.type == "call" then
		local args = ""
		for i, arg in ipairs(expr.args) do
			args = args .. (i > 1 and ", " or "") .. compile(scope, arg)
		end
		return compile(scope, expr.callee) .. "(" .. args .. (")"):rep(expr.spreads) .. ")"
	elseif expr.type == "squareIndex" then
		return compile(scope, expr.expr) .. "[" .. compile(scope, expr.key) .. "]"
	elseif expr.type == "spread" then
		return "__spr(" .. compile(scope, expr.value)
	elseif expr.type == "dotIndex" then
		local colon = expr.operator == ":"
		local nocallColon = expr.right.type ~= "call" and expr.operator == ":"
		return (nocallColon and "function(...) return " or "") .. compile(scope, expr.left) .. (colon and ":" or ".") .. compile(scope, expr.right) .. (nocallColon and "(...) end" or "")
	elseif expr.type == "namespace" then
		return "ns['" .. compile(scope, expr.left) .. "']." .. compile(scope, expr.right)
	elseif expr.type == "foreach" then
		local newScope = makeScope(scope)
		newScope[expr.i] = true
		newScope[expr.v] = true
		q[#q+1] = "local _ = " .. compile(scope, expr.array)
		q[#q+1] = "\nfor " .. expr.i .. " = 1, _.Length do\nlocal "
		q[#q+1] = expr.v .. " = _[" .. expr.i .. "]\n"
		for _, stat in ipairs(expr.block) do
			q[#q+1] = compile(newScope, stat) .. ";\n"
		end
		q[#q+1] = "end"
	elseif expr.type == "for" then
		local newScope = makeScope(scope)
		newScope[expr.i] = true
		q[#q+1] = "for " .. expr.i .. " = " .. compile(scope, expr.start) .. ", ".. compile(scope, expr.End) .. ", " .. compile(scope, expr.step) .. " do\n"
		for _, stat in ipairs(expr.block) do
			q[#q+1] = compile(newScope, stat) .. ";\n"
		end
		q[#q+1] = "end"
	elseif expr.type == "repeat" then
		local newScope = makeScope(scope)
		q[#q+1] = "repeat\n"
		for _, stat in ipairs(expr.block) do
			q[#q+1] = compile(newScope, stat) .. ";\n"
		end
		q[#q+1] = "until " .. compile(scope, expr.Until)
	elseif expr.type == "while" then
		local newScope = makeScope(scope)
		q[#q+1] = "while "
		q[#q+1] = compile(scope, expr.cond)
		q[#q+1] = "do\n"
		for _, stat in ipairs(expr.block) do
			q[#q+1] = compile(newScope, stat) .. ";\n"
		end
		q[#q+1] = "end"
	elseif expr.type == "break" then
		return "break"
	elseif expr.type == "ifExpr" then
		return "((function() if " .. compile(scope, expr.cond) .. " then return " .. compile(scope, expr.value) .. " else return " .. compile(scope, expr.elseValue) .. " end end)())"
	elseif expr.type == "if" then
		for i,v in ipairs(expr.blocks) do
			if expr.conds[i] then
				q[#q+1] = (i > 1 and "elseif " or "if ") .. compile(scope, expr.conds[i]) .. " then\n"
			else
				q[#q+1] = "else\n"
			end
			local newScope = makeScope(scope)
			for _, stat in ipairs(v) do
				q[#q+1] = compile(newScope, stat) .. ";\n"
			end
		end
		q[#q+1] = "end\n"
	elseif expr.type == "table" then
		q[#q+1] = "__tablify {Length=" .. expr.arrayLength .. "; "
		for i = 1, expr.arrayLength do
			q[#q+1] = compile(scope, expr.array[i]) .. ","
		end
		for i, v in ipairs(expr.recordk) do
			q[#q+1] = "[" .. compile(scope, v) .. "] = " .. compile(scope, expr.recordv[i]) .. ";"
		end
		q[#q+1] = "}"
	else
		for k,v in pairs(expr)do print(k,v)end
		os.exit(1)
		--error("oops " .. expr.type, 0)
	end
	return table.concat(q)
end

local header = [=[___class = {}
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
]=]
local compiler;compiler = {
	--@ deprecated
	compileAsm = compileAsm,
	compile = function(src)
		for _, pass in ipairs(compiler.passes) do
			src = pass(src)
		end
		return header .. compile(nil, src) .. "__makeconsts()os.exit(__ns.Program():Main(strn(args)))"
	end,
	compileProject = function(file, src)
		local function readProjectFile(src)
			for _, pass in ipairs(compiler.passes) do
				src = pass(src, "Project File", true)
			end
			local result = (load or loadstring)("function __tablify(...)return...end local ns={System={String=function(...)return...end}}" .. compile(makeScope(), src))()
			local dependencies = result.Dependencies
			for i = 1, dependencies.Length do
				local filehandle = io.open(file .. "/../" .. dependencies[i] .. "/.project", "r")
				if filehandle == nil then
					print("error: specified dependency doesn't exist")
					os.exit()
				end
				local contents = filehandle:read("*a")
				io.close(filehandle)
				local prj = readProjectFile(contents)
				for j = 1, prj.Files.Length do
					result.Files[#result.Files + 1] = "../" .. dependencies[i] .. "/" .. prj.Files[j]
				end
			end
			return result
		end
		local project = readProjectFile(src)
		local result = header
		for _, v in ipairs(project.Files) do
			print("Compiling " .. file .. "/" .. v)
			local src = readfile(file .. "/" .. v)
			for _, pass in ipairs(compiler.passes) do
				src = pass(src, v)
			end
			result = result .. compile(nil, src)
		end
		return result .. "__makeconsts()os.exit(ns['" .. project.EntryNamespace .. "'].Program():Main(strn(args)))"
	end,
	passes = {
		function(code, file, singleExpr)
			local input = Tokenizer(InputStream(code, file))
			local ParseAtom, ParseExpression, ParseBlock

			local function ParseCall(expr)
				input:next("punctuation", "(")
				local args = {}
				local spreads = 0
				while not input:is_next("punctuation", ")") do
					local spread = false
					if input:is_next("punctuation", ".") then
						input:next("punctuation", ".")
						input:next("punctuation", ".")
						input:next("punctuation", ".")
						spread = true
						spreads = spreads + 1
						args[#args + 1] = {
							type = "spread",
							value = ParseExpression()
						}
					else
						args[#args + 1] = ParseExpression()
					end
					if input:is_next("punctuation", ",") then
						input:next()
					else
						break
					end
				end
				input:next("punctuation", ")")
				return {
					type = "call",
					callee = expr,
					args = args,
					spreads = spreads
				}
			end

			local function ParseIndex(expr)
				input:next("punctuation", "[")
				local key = ParseExpression()
				input:next("punctuation", "]")
				return {
					type = "squareIndex",
					expr = expr,
					key = key
				}
			end

			local function MaybeBinary(left, prec)
				local isDot = input:is_next("punctuation", ".") or input:is_next("punctuation", ":")
				local isDColon = input:is_next("operator", "::")
				if input:is_next("operator") or isDot or isDColon then
					local op_token = input:peek()
					local next_prec = precedence[op_token.value]
					if next_prec == nil then
						error("invalid operator " .. op_token.value) -- TODO
					end
					if next_prec > prec then
						input:next()
						local right = MaybeBinary(ParseAtom(), next_prec)
						if op_token.value == "="
							and left.type ~= "identifier"
							and left.type ~= "dotIndex"
							and left.type ~= "squareIndex" then
							error("cannot assign to non-identifier") -- TODO
						end
						if op_token.value == "." or op_token.value == ":" then
							right.alone = false
							if right.type == "call" then
								right.callee.alone = false
							end
						elseif op_token.value == "::" then
							left.alone = false
							if left.type == "dotIndex" then
								left.left.alone = false
							end
							if right.type == "dotIndex" then
								right.left.alone = false
							elseif right.type == "call" then
								right.callee.alone = false
								if right.callee.type == "dotIndex" then
									right.callee.left.alone = false
								end
							end
							right.alone = false
						end
						return MaybeBinary({
							type = op_types[op_token.value] or "binOp",
							operator = op_token.value,
							left = left,
							right = right
						}, prec)
					end
				end
				return left
			end

			local function MaybeCall(expr)
				expr = expr()
				if input:is_next("punctuation", "(") then
					return ParseCall(expr)
				elseif input:is_next("punctuation", "[") then
					return ParseIndex(expr)
				else
					return expr
				end
			end

			function ParseAtom()
				return MaybeCall(function()
					if input:is_next("punctuation", "(") then
						input:next()
						local result = ParseExpression()
						input:next("punctuation", ")")
						return result
					elseif input:is_next("punctuation", "{") then
						input:next()
						local array = {}
						local arrayLength = 0
						local recordk = {}
						local recordv = {}
						while not input:eof() and not input:is_next("punctuation", "}") do
							local state = input:saveState()
							local continue = true
							if input:is_next("identifier") then
								local n = input:next()
								if input:is_next("operator", ":") or input:is_next("operator", "=") then
									input:next()
									continue = false
									table.insert(recordk, {type = "nativestring", value = n.value})
									table.insert(recordv, ParseExpression())
								end
							elseif input:is_next("punctuation", "[") then
								input:next()
								continue = false
								table.insert(recordk, ParseExpression())
								input:next("punctuation", "]")
								if input:is_next("operator", ":") then
									input:next()
								else
									input:next("operator", "=")
								end
								table.insert(recordv, ParseExpression())
							end
							if continue then
								input:loadState(state)
								arrayLength = arrayLength + 1
								array[arrayLength] = ParseExpression()
							end
							if input:is_next("punctuation", ",") or input:is_next("punctuation", ";") then
								input:next()
							else
								break
							end
						end
						input:next("punctuation", "}")
						return {
							type = "table",
							array = array,
							arrayLength = arrayLength,
							recordk = recordk,
							recordv = recordv
						}
					elseif input:is_next("keyword", "if") then
						input:next()
						local cond = ParseExpression()
						input:next("keyword", "then")
						local value = ParseExpression()
						input:next("keyword", "else")
						local elseValue = ParseExpression()
						return {
							type = "ifExpr",
							cond = cond,
							value = value,
							elseValue = elseValue
						}
					elseif input:is_next("number") then
						local num = input:next()
						return {
							type = "number",
							value = num.value
						}
					elseif input:is_next("identifier") then
						local num = input:next()
						return {
							type = "identifier",
							alone = true,
							value = num.value
						}
					elseif input:is_next("keyword", "nil") or input:is_next("keyword", "true") or input:is_next("keyword", "false") then
						return {
							type = "raw",
							value = input:next().value
						}
					elseif input:is_next("keyword", "self") then
						input:next()
						return {
							type = "self"
						}
					elseif input:is_next("string") then
						local str = input:next()
						return {
							type = "string",
							value = str.value
						}
					elseif input:is_next("operator", "-") then
						input:next()
						return MaybeBinary({
							type = "sub",
							operator = "-",
							left = {
								type = "number",
								value = "0"
							},
							right = MaybeBinary(ParseAtom(), precedence["-(unm)"])
						}, 0)
					elseif input:is_next("operator", "not") then
						input:next()
						return MaybeBinary({
							type = "binOp",
							operator = "not",
							left = {
								type = "nothing"
							},
							right = MaybeBinary(ParseAtom(), precedence["not"])
						}, 0)
					elseif input:is_next("keyword", "new") then
						input:next()
						return ParseExpression()
					else
						input:fault("expected expression", input:next())
					end
				end)
			end

			function ParseExpression(optional)
				return MaybeCall(function()
					return MaybeBinary(ParseAtom(optional), 0)
				end)
			end

			local function ParseType(optional)
				optional = true
				if optional and not input:is_next("operator", ":") then return end
				input:next("operator", ":")
				local value = input:is_next("keyword") and input:next("keyword").value or input:next("identifier").value
				while input:is_next("punctuation", ".") do
					input:next()
					value = value .. "." .. input:next("identifier").value
				end
				if input:is_next("operator", "::") then
					input:next()
					value = value .. "::" .. input:next("identifier").value
				end
				while input:is_next("punctuation", ".") do
					input:next()
					value = value .. "." .. input:next("identifier").value
				end
				if input:is_next("punctuation", "[") then
					value = value .. "[]"
					input:next("punctuation", "[")
					input:next("punctuation", "]")
				end
				return {
					type = "type",
					value = value
				}
			end

			local function ParseStatement()
				if input:is_next("keyword", "return") then
					input:next()
					local next_token = input:is_next("keyword", "end") or input:is_next("punctuation", ";")
					local value = (not next_token) and ParseExpression() or nil
					return {
						type = "return",
						value = value
					}
				elseif input:is_next("keyword", "local") then
					input:next()
					local name = input:next("identifier").value
					local value
					if input:is_next("operator", "=") then
						input:next("operator", "=")
						value = ParseExpression()
					end
					return {
						type = "local",
						name = name,
						value = value
					}
				elseif input:is_next("keyword", "break") then
					input:next()
					return {
						type = "break"
					}
				elseif input:is_next("keyword", "if") then
					local conds = {}
					local blocks = {}
					local function recurse(isElse)
						input:next()
						local condition
						if not isElse then
							condition = ParseExpression()
							input:next("keyword", "then")
						end
						local body = {}
						while not (input:is_next("keyword", "end") or input:is_next("keyword", "elseif") or input:is_next("keyword", "else") or input:eof()) do
							local stat = ParseStatement()
							body[#body + 1] = stat
							if input:is_next("punctuation", ";") then input:next() end
							if stat.type == "return" then
								break
							end
						end
						blocks[#blocks + 1] = body
						conds[#conds + 1] = condition
						if input:is_next("keyword", "end") then
							input:next("keyword", "end")
						elseif input:is_next("keyword", "elseif") then
							recurse()
						elseif input:is_next("keyword", "else") then
							recurse(true)
						end
					end
					recurse()
					return {
						type = "if",
						conds = conds,
						blocks = blocks
					}
				elseif input:is_next("keyword", "while") then
					input:next()
					local cond = ParseExpression()
					input:next("keyword", "do")
					return {
						type = "while",
						cond = cond,
						block = ParseBlock()
					}
				elseif input:is_next("keyword", "repeat") then
					input:next()
					local block = ParseBlock("until")
					local Until = ParseExpression()
					return {
						type = "repeat",
						block = block,
						Until = Until
					}
				elseif input:is_next("keyword", "for") then
					input:next()
					local i = input:next("identifier").value
					if input:is_next("punctuation", ",") then
						input:next()
						local v = input:next("identifier").value
						input:next("keyword", "in")
						local array = ParseExpression()
						input:next("keyword", "do")
						return {
							type = "foreach",
							i = i,
							v = v,
							array = array,
							block = ParseBlock()
						}
					else
						input:next("operator", "=")
						local start = ParseExpression()
						input:next("punctuation", ",")
						local End = ParseExpression()
						local step = {
							type = "number",
							value = "1"
						}
						if input:is_next("punctuation", ",") then
							input:next("punctuation", ",")
							step = ParseExpression()
						end
						input:next("keyword", "do")
						return {
							type = "for",
							i = i,
							start = start,
							End = End,
							step = step,
							block = ParseBlock()
						}
					end
				else
					local token = input:peek()
					local expr = ParseExpression()
					--if expr.type == "assign" or expr.type == "call" then
						return expr
					--[[else
						input:fault("expected statement", token)
					end]]
				end
			end

			function ParseBlock(endingKeyword)
				endingKeyword = endingKeyword or "end"
				local body = {}
				while not (input:is_next("keyword", endingKeyword) or input:eof()) do
					local stat = ParseStatement()
					body[#body + 1] = stat
					if input:is_next("punctuation", ";") then input:next() end
					if stat.type == "return" then
						break
					end
				end
				input:next("keyword", endingKeyword)
				return body
			end

			local function ParseFunction(className, isConst)
				local name
				if input:is_next("keyword", "new") then
					input:next()
					input:next("identifier", className)
					name = "__init"
				elseif input:is_next("keyword", "self") then
					input:next()
					input:next("punctuation", "[")
					name = input:next("identifier").value
					input:next("punctuation", "]")
					name = "__init"
				else
					input:next("keyword", "function")
					name = input:next("identifier").value
				end
				input:next("punctuation", "(")
				local args = {}
				while not input:is_next("punctuation", ")") and not input:eof() do
					local ellipsis = false
					if input:is_next("punctuation", ".") then
						input:next("punctuation", ".")
						input:next("punctuation", ".")
						input:next("punctuation", ".")
						ellipsis = true
					end
					args[#args + 1] = {name = input:next("identifier").value, ellipsis = ellipsis, type = ParseType(false)}
					if input:is_next("punctuation", ",") then
						input:next()
					else
						break
					end
				end
				input:next("punctuation", ")")
				return {
					type = "function",
					name = name,
					args = args,
					body = ParseBlock(),
					const = isConst
				}
			end

			local function ParseConst()
				local name = input:next("identifier").value
				local type = ParseType(true)
				input:next("operator", "=")
				local value = ParseExpression()
				return {
					type = "const",
					name = name,
					type = type,
					value = value
				}
			end

			local function ParseClass()
				local functions = {}
				input:next("keyword", "class")
				local consts = {}
				local vars = {}
				local name = input:next("identifier").value
				while not (input:is_next("keyword", "end") or input:eof()) do
					if input:is_next("keyword", "const") then
						input:next()
						if input:is_next("keyword", "function") then
							functions[#functions + 1] = ParseFunction(name, true)
						else
							consts[#consts + 1] = ParseConst()
						end
					else
						functions[#functions + 1] = ParseFunction(name)
					end
				end
				input:next("keyword", "end")
				return {
					type = "class",
					name = name,
					consts = consts,
					functions = functions
				}
			end

			local function ParseEnum()
				local values = {}
				input:next("keyword", "enum")
				local name = input:next("identifier").value
				local vs = {}
				while not (input:is_next("keyword", "end") or input:eof()) do
					local k = input:next("identifier").value
					local v
					if input:is_next("operator", "=") then
						input:next()
						v = input:next("number").value
					else
						local V = 1
						if #vs == 1 then
							V = vs[1] + 1
						elseif #vs == 2 then
							if vs[1] == "1" and vs[2] == "2" then
								V = 4
							else
								V = 2 * vs[#vs] - vs[#vs - 1]
							end
						elseif #vs >= 3 then
							if (vs[3] / vs[2]) == (vs[2] / vs[1]) then
								V = vs[#vs] * (vs[3] / vs[2])
							elseif (vs[3] - vs[2]) == (vs[2] - vs[1]) then
								V = vs[#vs] + (vs[3] - vs[2])
							else
								V = vs[#vs] + 1
							end
						end
						v = tostring(V)
					end
					vs[#vs + 1] = v
					values[k] = v
					if input:is_next("punctuation", ",") then
						input:next()
					else
						break
					end
				end
				input:next("keyword", "end")
				return {
					type = "enum",
					name = name,
					values = values
				}
			end

			local function ParseProgram()
				local namespace = "global"
				local usings = ""
				if input:is_next("keyword", "namespace") then
					input:next()
					namespace = input:next("identifier").value
					while input:is_next("punctuation", ".") do
						namespace = namespace .. input:next().value .. input:next("identifier").value
					end
					usings = usings .. "'" .. namespace .. "'"
				end
				if input:is_next("keyword", "using") then
					input:next()
					local namespace = input:next("identifier").value
					while input:is_next("punctuation", ".") do
						namespace = namespace .. input:next().value .. input:next("identifier").value
					end
					usings = usings .. ", '" .. namespace .. "'"
				end
				local classes = {}
				local enums = {}
				while not input:eof() do
					if input:is_next("keyword", "enum") then
						enums[#enums + 1] = ParseEnum()
					else
						classes[#classes + 1] = ParseClass()
					end
				end
				return {
					type = "program",
					namespace = namespace,
					usings = usings,
					enums = enums,
					classes = classes
				}
			end

			return singleExpr and {type = "return", value = ParseExpression()} or ParseProgram()
		end
	}
}

return compiler