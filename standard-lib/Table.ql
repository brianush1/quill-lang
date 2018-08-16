namespace System

class Table

	const function Contains(array, value)
		for i, v in array do
			if v == value then
				return true
			end
		end
		return false
	end

	const function Insert(array, value)
		array.Length = array.Length + 1
		array[array.Length] = value
	end

end