-- badly written

-- it's a bootstrap compiler, don't judge
-- but mostly cuz I never planned on making this open source
local compiler = require("./bootstrap/quill-compiler")
local source
local input
local output
local execute = false
local project = false

local execArgs = {}
for i = 1, #arg do
	local a = arg[i]
	if execute then
		execArgs[#execArgs + 1] = a
	elseif a:sub(1, 3) == "-o=" then
		output = a:sub(4)
	elseif a:sub(1, 3) == "-p=" then
		input = a:sub(4)
		project = true
	elseif a == "-i" or a == "-e" then
		execute = true
	else
		input = a
	end
end

if input == nil then
	print("error: no input file")
	os.exit()
end

if output == nil then
	local l = -1
	while true do
		local nl = input:find(".", l + 1, true)
		if nl ~= nil then
			l = nl
		else
			break
		end
	end
	output = (project and input:sub(1, input:find(".", 1, true) - 1) .. "out" or input:sub(1, l == -1 and #input or (l - 1))) .. ".lua"
end

function readfile(file)
	local file = io.open(file, "r")
	if file == nil then
		print("error: specified input file doesn't exist")
		os.exit()
	end
	local result = file:read("*a")
	io.close(file)
	return result
end

if project then
	local src = readfile(input .. "/.project")
	source = compiler.compileProject(input, src)
else
	local src = readfile(input)
	source = compiler.compile(src)
end

local dst = io.open(output, "w+")
dst:write(source)
dst:flush()

if execute then
	print("Done compiling")
	local s,e=(load or loadstring)("local args=(...);" .. source)
	if not s then error(e, 0) end
	print("Executing program...")
	s(execArgs)
end
--[[
local function exec(...)
	print(...)
	os.execute(...)
end

exec("nasm -f win32 " .. output:sub(1, -5) .. ".asm")
exec("GoLink.exe /console /entry _entry " .. output .. " kernel32.dll msvcrt.dll")]]