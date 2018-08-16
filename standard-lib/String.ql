namespace System

@summary A class representing a piece of text
class String

	new String(native: string)
		self.__native = native
		self.Length = __lua.getlen(self.__native)
	end

	const function ToString(thing: any)
		return new String(__lua.tostring(thing))
	end

	function ToNumber()
		return __lua.tonumber(self.__native)
	end

	function Replace(string: string, nstring: string)
		return new String(self.__native:gsub(string.__native, nstring.__native))
	end

	@summary Returns a substring of the original string
	function Substring(start: number, finish: number)
		return new String(self.__native:sub(start, finish))
	end

	@summary Repeats the string a number of times
	function Repeat(times: number)
		return new String(self.__native:rep(times))
	end

	@summary Turns all the characters in the string to uppercase
	function ToUppercase()
		return new String(self.__native:upper())
	end

	@summary Turns all the characters in the string to lowercase
	function ToLowercase()
		return new String(self.__native:lower())
	end

	@summary Returns the character represented by the given ASCII value
	const function Char(value: number)
		return new String(__lua.string.char(value))
	end

	@summary Reverses the string
	function Reverse()
		return new String(self.__native:reverse())
	end

	@summary Returns the ASCII value of the first character
	function Byte()
		return self.__native:byte()
	end

	function Contains(str: string)
		return self.__native:find(str.__native, 1, true)
	end

	function __eq(two: String) -- TODO
		return self.__native == two or self.__native == two.__native
	end

	function __add(two: String)
		return new String(__lua.concat(self.__native, two.__native))
	end

end