namespace System.IO

class File
	
	const function Open(path: string, mode: string)
		local file = new File()
		file.__file = __lua.io.open(path.__native, mode.__native)
		return file
	end

	function Exists(path: string)
		-- TODO
	end

	function Dispose()
		__lua.io.close(self.__file)
	end

	function ReadAll()
		return new System::String(self.__file:read("*a".__native))
	end

	function ReadLine()
		return new System::String(self.__file:read())
	end

	function ReadChar()
		if self:EOF() then return nil end
		return new System::String(self.__file:read(1))
	end

	function EOF()
		return self.__file:read(0) == nil
	end

	function Write(str)
		self.__file:write(str.__native)
	end

	function WriteLine()
		self.__file:write(str.__native)
		self.__file:write("\n".__native)
	end

	function Flush()
		self.__file:flush()
	end
	
end