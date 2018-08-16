namespace System

@summary Standard output stream
class Output

	@summary Writes a string to the output
	const function Write(value: string)
		if __lua.type(value) == "table".__native then
			__lua.io.write(value.__native)
		else
			__lua.io.write(__lua.tostring(value))
		end
	end

	@summary Writes a string to the output, followed by a newline
	const function WriteLine(value: string)
		self:Write(value)
		self:Write("\n")
	end

	@summary Writes a formatted string to the output
	const function WriteF(value, ...args)
		for i, v in args do
			if __lua.type(v) == "table".__native then
				v = v.__native
			end
		end
		self:Write(__lua.string.format(value.__native, ...args))
	end

	@summary Writes multiple strings to the output, separated by a space and followed by a newline
	const function Log(...values: string[])
		for i, v in values do
			if i > 1 then
				self:Write(" ")
			end
			self:Write(v)
		end
		self:Write("\n")
	end

end