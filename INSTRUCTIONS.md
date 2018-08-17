# Instructions
## Hello, World!

	namespace Thing
	
	class Program
	
		function Main()
			return 0
		end
	
	end

## How to compile your program
Right now, the compiler is a big mess.
The basics are that you put your project in a folder, and you add a `.project` file to it.
In the `.project` file, you put some information about your project:

	{
		Files: {
			"Program.ql"
		},
		Dependencies: {"standard-lib"}, -- Any dependencies must be in the folder that your project folder is in
		Entrypoint: "Thing::Program:Main"
	}

To compile to Lua 5.3.3, use the following format:

	lua ./bootstrap/qcc.lua -p=projectpath [-e]
	
	projectpath    The path to your project folder (NOT the `.project` file)
	-e             Tells the compiler to execute your code, anything after this will be sent as parameters to the program

	This must run on Lua 5.3, otherwise it might not work

## Documentation
Can be found in the wiki. Work in progress.

## Things to note
Namespaces can contain dots (`.`), but they are not indexed.
So if you have a `using System` at the top of your file, you can't type `IO::File`, you must type `System.IO::File`
This may change in the future.