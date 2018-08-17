namespace System

class Process

	new Process(file, args)
		local command = file:Replace("/", System.IO::Directory.PathSeparator)
		if args ~= nil then
			command = command + " " + args
		end
		self.ExitCode = __lua.select(3, __lua.os.execute(command.__native))
	end

end