namespace System

@summary Class containing helpful math operations
class Math

	@summary The mathematical constant pi
	const PI = 3.14159265358979323846

	@summary The mathematical constant e
	const E = 2.7182818284590452354

	@summary Rounds the given value towards negative infinity
	const function Floor(value: number)
		return __lua.math.floor(value)
	end

	@summary Rounds the given value towards positive infinity
	const function Ceil(value: number)
		return __lua.math.ceil(value)
	end

	@summary Returns the first value raised to the power of the second value
	const function Pow(x: number, y: number)
		return __lua.math.pow(x, y)
	end

	@summary Returns the logarithm base E of the given value
	const function LogE(value: number)
		return __lua.math.log(value)
	end

	@summary Returns the logarithm base 10 of the given value
	const function Log10(value: number)
		return __lua.math.log10(value)
	end

	@summary Returns the logarithm base 2 of the given value
	const function Log2(value: number)
		return __lua.math.log(value) / 0.6931471805599453
	end

end