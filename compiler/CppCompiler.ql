namespace Quill.Compiler
using System

class CppCompiler

	new CppCompiler(lexer)
		self.Lexer = lexer
		return 0
	end

	--[[
		integers and numbers will only be internal, external will be just number
		conversion between the two will be seamless
		integers will be guaranteed integers (no 12.0, 5.0, etc., 3.75 * 3.2 = 12(int))
		numbers will be guaranteed doubles (12 / 3 = 4(int), 12 / 5 = 2.4(double))
		
		nevermind above, issue is that conversion and checking for conversion will lead to slower execution

		Quill types (so far): nil (65535), number (0)
		Lua types (reference): nil, number, boolean, string, table, function, thread, userdata

		Values are stored in rax
		Types are stored in rbx
	]]

	function FixName(...names)
		local name = "l"
		for i, v in names do
			name = name + "_" + v:Replace("_", "u_")
		end
		return name
	end

	function CompileBlock(block)
		local result = ""
		for i, v in block do
			result = result + self:Compile(v)
		end
		return result
	end

	function Compile(item)
		if item.Type == "Statement" then
			if item.Statement == "Return" then
				return "\n\treturn " + self:Compile(item.Value) + ";"
			elseif item.Statement == "Local" then
				return "\n\tstruct qlvalue " + self:FixName("variable", item.Name) + " = " + self:Compile(item.Value) + ";"
			elseif item.Statement == "Assignment" then
				return "\n\t" + self:FixName("variable", item.Name) + " = " + self:Compile(item.Value) + ";"
			elseif item.Statement == "Call" then
				return "\n\t" + self:Compile(item.Function) + "(" + self:Compile(item.Args[1]) + ");"
			end
		elseif item.Type == "Number" then
			return "qlnumber((double)" + item.Value + ")"
		elseif item.Type == "Identifier" then
			return self:FixName("variable", item.Name)
		elseif item.Type == "BinaryOperation" then
			if item.Operator == "+" then
				return "qladd(" + self:Compile(item.Left) + ", " + self:Compile(item.Right) + ")"
			elseif item.Operator == "*" then
				return "qlmul(" + self:Compile(item.Left) + ", " + self:Compile(item.Right) + ")"
			end
		elseif item.Type == "Program" then
			return self:Compile(item.Classes[1])
		elseif item.Type == "Function" then
			return "struct qlvalue " + self:FixName("method", item.Class, item.Name) + "() {" + self:CompileBlock(item.Body) + "\n}\n\n"
		elseif item.Type == "Class" then
			local result = "struct " + self:FixName("class", item.Name) + " {\n"
			for i, v in item.Functions do
				result = result + "\tstruct qlvalue " + self:FixName("variable", v.Name) + ";\n"
			end

			result = result + "};\n\n"

			for i, v in item.Functions do
				result = result + self:Compile(v)
			end

			return result
		elseif item.Type == "Call" then
			return self:Compile(item.Function) + "(" + self:Compile(item.Args[1]) + ")"
		end
		__lua.error(("oops " + item.Type).__native) -- TODO
	end

	function CompileProgram(ast)
		return "#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <setjmp.h>
#include <stdnoreturn.h>
#include <math.h>

/*
 * Used functions:
 *
 * malloc
 * free
 * 
 */

struct qlstring {
	char* data;
	uint32_t length;
};

union qldata {
	double number;
	struct qlstring string;
};

struct qlvalue {
	uint16_t type;
	union qldata data;
};

inline struct qlvalue qlnumber(double data) {
	struct qlvalue result;
	result.type = 0;
	result.data.number = data;
	return result;
}

inline struct qlvalue qlstring(const char* data, uint32_t length) {
	struct qlvalue result;
	result.type = 1;
	result.data.string.data = (char*)data;
	result.data.string.length = length;
	return result;
}

void error() {

}

struct qlvalue qladd(struct qlvalue a, struct qlvalue b) {
	if (a.type != b.type) error();

	struct qlvalue result;
	if (a.type == 0) {
		result.type = 0;
		result.data.number = a.data.number + b.data.number;
	} else if (a.type == 1) {
		result.type = 1;
		// TODO result.data.string.data = 
	}

	return result;
}

struct qlvalue qlmul(struct qlvalue a, struct qlvalue b) {
	if (a.type != b.type) error();

	struct qlvalue result;
	if (a.type == 0) {
		result.type = 0;
		result.data.number = a.data.number * b.data.number;
	} else if (a.type == 1) {
		result.type = 1;
		// TODO result.data.string.data = 
	}

	return result;
}

struct qlvalue qlnil;

// TODO: temporary, remove
struct qlvalue l_variable_print(struct qlvalue thing) {
	if (thing.type == 0) {
		printf(\"%.14g\\n\", thing.data.number);
	}

	return qlnil;
}

" + self:Compile(ast) + "int main() {
	qlnil.type = 65535;
	double result = l_method_Program_Main().data.number;
	int status = (int)result;
	if ((double)status != result) {
		error();
	}
	return status;
}"
	end

end