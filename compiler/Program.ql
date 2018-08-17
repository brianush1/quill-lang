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
		new Process("gcc.exe", output + ".c -o " + output + ".exe -O3")
		--new Process("nasm -f win64 " + output + ".asm")
		--new Process("GoLink.exe /console /entry _start " + output + ".obj msvcrt.dll")

		local process = new Process(output + ".exe")
		Output:Log("Exit code:", process.ExitCode)

		return 0
	end

end