namespace Quill.Compiler
using System

class Parser

	const precedence = {
		["="]: 1,
		["or"]: 2,
		["and"]: 3,
		["<"]: 5, [">"]: 5, ["<="]: 5, [">="]: 5, ["~="]: 5, ["=="]: 5,
		["+"]: 10, ["-"]: 10,
		["-(unm)"]: 20, ["*"]: 20, ["/"]: 20,
		["not"]: 30,
		["::"]: 90,
		["."]: 100, [":"]: 100
	}

	new Parser(lexer)
		self.Lexer = lexer
		self.Context = new Context()
		return 0
	end

	function ParseTrueAtom()
		if self.Lexer:IsNext("Number") then
			return {
				Type: "Number",
				TypeInfo: {
					Deterministic: true,
					Type: "number"
				},
				Value: self.Lexer:Next().Value
			}
		elseif self.Lexer:IsNext("Identifier") then
			return {
				Type: "Identifier",
				TypeInfo: { -- TODO: better type inference
					Deterministic: false,
					Type: "any"
				},
				Name: self.Lexer:Next().Value
			}
		elseif self.Lexer:IsNext("Keyword", "self") then
			return {
				Type: "Self",
				TypeInfo: {}
			}
		else
			self.Lexer:Fault("expected expression")
		end
	end

	function ParseAtom()
		return self:MaybeCall(self:ParseTrueAtom)
	end

	function MaybeBinary(atom, precedence)
		atom = if TypeOf(atom) == "function" then atom() else atom
		if self.Lexer:IsNext("Operator") then
			local operator = self.Lexer:Next().Value
			local nextPrecedence = self.precedence[operator]
			if nextPrecedence > precedence then
				local right = self:MaybeBinary(self:ParseAtom, nextPrecedence)
				--if atom.TypeInfo.Type ~= right.TypeInfo.Type then __lua.error("cannot operate on differing types (yet)".__native) end
				return self:MaybeBinary({
					Type: "BinaryOperation",
					TypeInfo: {
						Deterministic: atom.TypeInfo.Deterministic and right.TypeInfo.Deterministic,
						Type: atom.TypeInfo.Type
					},
					Operator: operator,
					Left: atom,
					Right: right
				}, precedence)
			end
		end
		return atom
	end

	function ParseCall(atom, statement)
		self.Lexer:Next()
		local arg = self:ParseExpression()
		self.Lexer:Next("Punctuation", ")")
		local result = {
			Type: if statement then "Statement" else "Call",
			TypeInfo: {
				Deterministic: false,
				Type: "any" -- TODO: better inferencing
			},
			Function: atom,
			Args: {[1]: arg}
		}
		if statement then
			result.Statement = "Call"
		end

		return result
	end

	function MaybeCall(atom)
		atom = if TypeOf(atom) == "function" then atom() else atom
		return if self.Lexer:IsNext("Punctuation", "(") then self:ParseCall(atom) else atom
	end

	function ParseExpression()
		return self:MaybeCall(self:MaybeBinary(self:ParseAtom, 0))
	end

	function ParseStatement()
		if self.Lexer:IsNext("Keyword", "return") then
			self.Lexer:Next()
			return {
				Type: "Statement",
				Statement: "Return",
				Value: self:ParseExpression()
			}
		elseif self.Lexer:IsNext("Identifier") then
			local name = self.Lexer:Next().Value
			if self.Lexer:IsNext("Punctuation", "(") then
				return self:ParseCall({
					Type: "Identifier",
					TypeInfo: { -- TODO: better type inference
						Deterministic: false,
						Type: "any"
					},
					Name: name
				}, true)
			else
				self.Lexer:Next("Operator", "=")
				return {
					Type: "Statement",
					Statement: "Assignment",
					Name: name,
					Value: self:ParseExpression()
				}
			end
		elseif self.Lexer:IsNext("Keyword", "local") then
			self.Lexer:Next()
			local Name = self.Lexer:Next("Identifier").Value
			self.Lexer:Next("Operator", "=")
			local Value = self:ParseExpression()
			return {
				Type: "Statement",
				Statement: "Local",
				Name: Name,
				Value: Value
			}
		else
			self.Lexer:Fault("expected statement")
		end
	end

	function ParseBlock(blockEnd)
		local statements = {}
		blockEnd = blockEnd or "end"
		while not self.Lexer:IsNext("Keyword", blockEnd) and not self.Lexer:EOF() do
			Table:Insert(statements, self:ParseStatement())
			if self.Lexer:IsNext("Punctuation", ";") then
				self.Lexer:Next()
			end
		end
		self.Lexer:Next("Keyword", blockEnd)
		return statements
	end

	function ParseFunction(className)
		self.Context = new Context(self.Context)
		self.Lexer:Next("Keyword", "function")
		local name = self.Lexer:Next("Identifier").Value
		self.Lexer:Next("Punctuation", "(")
		self.Lexer:Next("Punctuation", ")")
		local body = self:ParseBlock()
		self.Context = self.Context.Parent
		return {
			Type: "Function",
			Name: name,
			Class: className,
			Body: body
		}
	end

	function ParseClass()
		self.Context = new Context(self.Context)
		self.Lexer:Next("Keyword", "class")
		local name = self.Lexer:Next("Identifier").Value
		local functions = {}
		while not self.Lexer:EOF() and not self.Lexer:IsNext("Keyword", "end") do
			Table:Insert(functions, self:ParseFunction(name))
		end
		self.Lexer:Next("Keyword", "end")
		self.Context = self.Context.Parent
		return {
			Type: "Class",
			Name: name,
			Functions: functions
		}
	end

	function ParseProgram()
		local classes = {}
		while not self.Lexer:EOF() do
			Table:Insert(classes, self:ParseClass())
		end
		return {
			Type: "Program",
			Classes: classes
		}
	end

end