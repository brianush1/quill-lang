namespace Quill.Compiler
using System

class Program

	@summary The main entry point of the application
	function Main(...args)
		local input
		local output
		local optimize = false
		for i, v in args do
			if v:Substring(1, 3) == "-o=" then
				output = v:Substring(4)
			elseif v == "-O" then
				optimize = true
			else
				input = v
			end
		end

		local outputFile = System.IO::File:Open(output + ".c", "w+")
		local lexer = new Lexer(System.IO::File:Open(input, "r"))
		local parser = new Parser(lexer)
		local ast = parser:ParseProgram()

		if optimize then
			Optimizer:Optimize(ast)
		end

		local compiler = new CppCompiler()
		outputFile:Write(compiler:CompileProgram(ast))
		outputFile:Flush()
		__lua.os.execute(("gcc " + output + ".c -o compilertest.exe -O3").__native)
		--__lua.os.execute(("nasm -f win64 " + output + ".asm").__native)
		--__lua.os.execute(("GoLink.exe /console /entry _start " + output + ".obj msvcrt.dll").__native)

		Output:Log("Status code:", __lua.select(3, __lua.os.execute("compilertest.exe".__native)))

		return 0
	end

end