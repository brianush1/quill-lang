namespace Quill.Compiler
using System

class Context

	new Context(parent)
		self.Parent = parent
		self.Data = {}
	end

	function HasField(field)
		return self[field] ~= nil
	end

	--[[self[field]
		local context = self
		local result
		repeat
			result = context.Data[field]
			context = context.Parent
		until result or context == nil
		return result
	end

	self[field] = value
		self.Data[field] = value
	end]]

end