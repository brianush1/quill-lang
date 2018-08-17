namespace Quill.Compiler
using System

class Lexer

	const Keywords = {
		"function", "return", "end", "local", "class",
		"new", "namespace", "self", "using", "const",
		"for", "in", "do", "if", "else", "elseif",
		"then", "enum", "nil", "while", "break", "false",
		"true", "repeat", "until"}

	new Lexer(file)
		self.File = file
		self.Line = 1
		self.LineContents = ""
		self.LineIndex = 1
	end

	function ReadChar()
		local result = self.PeekedChar or self.File:ReadChar()

		if result == "\n" then
			self.Line = self.Line + 1
			self.LineContents = ""
			self.LineIndex = 1
		elseif result ~= nil then
			self.LineContents = self.LineContents + if result == "\t" then "    " else result
			self.LineIndex = self.LineIndex + if result == "\t" then 4 else 1
		end
		self.PeekedChar = nil
		return result
	end

	function PeekChar()
		if self.PeekedChar then
			return self.PeekedChar
		end

		self.PeekedChar = self.File:ReadChar()
		return self.PeekedChar
	end

	function CharEOF()
		return self:PeekChar() == nil
	end

	function Fault(msg, index, size)
		size = size or 1
		index = index or self.LineIndex - 1
		while self:PeekChar() ~= "\n" and not self:CharEOF() do
			self:ReadChar()
		end
		while self.LineContents:Substring(1, 1) == " " do
			self.LineContents = self.LineContents:Substring(2)
			index = index - 1
		end
		Output:Log("error: " + msg + " at line " + String:ToString(self.Line)
			+ " (file .)\n\nsource: " + self.LineContents + "\n       " + " ":Repeat(index) + "~":Repeat(size))
		__lua.os.exit(1)
	end

	function IsWhitespace(char)
		return " \t\r\n":Contains(char)
	end

	function IsIdentifier(char)
		return "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_":Contains(char)
	end

	function IsDigit(char)
		return ".0123456789":Contains(char)
	end
	
	function IsOperator(char)
		return "~:+-*/^&|!=<>%#":Contains(char)
	end

	function IsPunctuation(char)
		return ".;,({[]})":Contains(char)
	end

	function ReadWhile(predicate)
		local result = ""
		while not self:CharEOF() and predicate(self:PeekChar()) do
			result = result + self:ReadChar()
		end
		return result
	end

	function ParseNumber()
		local result = ""
		local hasDecimal = false
		while not self:CharEOF() and self:IsDigit(self:PeekChar()) do
			if self:PeekChar() == "." then
				if hasDecimal then
					break
				else
					hasDecimal = true
				end
			end
			result = result + self:ReadChar()
		end
		return result
	end

	function ReadToken()
		self:ReadWhile(self:IsWhitespace)

		local tokenStart = self.LineIndex

		if self:CharEOF() then
			return nil
		end

		local char = self:PeekChar()

		if self:IsDigit(char) then
			return {
				Type: "Number",
				Value: self:ParseNumber(),
				TokenStart: tokenStart
			}
		elseif self:IsOperator(char) then
			return {
				Type: "Operator",
				Value: self:ReadWhile(self:IsOperator),
				TokenStart: tokenStart
			}
		elseif self:IsPunctuation(char) then
			return {
				Type: "Punctuation",
				Value: self:ReadChar(),
				TokenStart: tokenStart
			}
		elseif self:IsIdentifier(char) then
			local value = self:ReadWhile(self:IsIdentifier)
			return {
				Type: if Table:Contains(self.Keywords, value) then "Keyword" else "Identifier",
				Value: value,
				TokenStart: tokenStart
			}
		end
	end

	function Read()
		if self.Peeked then
			local result = self.Peeked
			self.Peeked = nil
			return result
		end
		
		return self:ReadToken()
	end

	function Peek()
		if self.Peeked then
			return self.Peeked
		end

		self.Peeked = self:ReadToken()
		return self.Peeked
	end

	function IsNext(type, value)
		if self:EOF() then return false end
		local peek = self:Peek()
		return peek.Type == type and if value == nil then true else peek.Value == value
	end

	function Next(type, value)
		if self:EOF() then return nil end
		if type == nil then return self:Read() end
		if not self:IsNext(type, value) then
			local token = self:Peek()
			self:Fault("expected '" + value + "'" + ", got '" + token.Value + "'", token.TokenStart, token.Value.Length) -- TODO
		end
		return self:Read()
	end

	function EOF()
		return self:Peek() == nil
	end

	function LogTokens()
		while not self:EOF() do
			local token = self:Read()
			Output:Log(token.Type, ":", token.Value)
		end
	end

end