A scratchpad for C# (.NET core) to test code snippets. There is significant room for improvements, but serves as a simple way to execute code and optionally measure the execution time(s).

>Commands (with their methods and args):
	>--martini: will run the Martini.cs ScratchPad which prints a martini glass of a given size (height) to the console
		>Syntax: --martini [-method<int>] size<int>
		>Examples:
			>dotnet run --martini -1 5 --measure100000
		>The available methods are an enum with domain [0,4] and will default to 0 if not provided
			>0: Performant method (runs the Slick method)
			>1: Slick method which uses a single StringBuilder and builds from the middle out in a single loop
			>2: Modified method which uses two StringBuilders (top and bottom of glass) in a single loop
			>3: Original method which uses a single loop, printing the top direct-to-console while bulding the bottom in a StringBuilder
			>4: Basic method which uses two loops to print the top then bottom (direct-to-console)
	>Sample results from 100,000 loops with size 5:
		>NAME		TICKS	MS
		>Slick:		553		<0.5
		>Modified:	640		<0.5
		>Original:	1155	<0.5
		>Basic:		1425	<0.5
	>Sample results from 100,000 loops with size 50:
		>NAME		TICKS	MS
		>Slick:		8123	2
		>Modified:	10677	3
		>Original:	13140	4
		>Basic:		16015	6
	
>Arguments (to be improved):
	>These are case-insensitive
	>The first arg must be --command where "command" is one of the available command targets of the program
	>The last arg can be a flag with an optional int value attached. This will measure the execution time(s) and loop as many times as the appended int value specifies
		>Examples:
			> --measured 
				>default is always 1 execution loop
			> --measured2
			> --measured100000
		>This flag must come last
		>The execution time (in ms and clock ticks) will be printed after each loop
		>After looping, the average time (in ms and clock ticks) will be output
		>If an exception is raised, the details will be printed and the loops will end with no average time calculated
		>An initial execution will happen before looping (if this flag is present)
			>This is done to account for the JIT compiler optimizing Console print (and maybe others?)
			>Since the ScratchPad is intended for Console printing, the first execution will always be slower
			>This is meant to remove this initial outlier from the execution times
			>This execution at least has an impact when running through "dotnet run", but not necessarily after compiling to win10-x64

>Syntax: ScratchPad.exe --command<string> [commandMethodAndArgs] [--measured[loopCount<int>]]

>Build --- uses the dotnet CLI:
	>Execute this following after pulling the code or after adding dependencies:
		>dotnet restore
	>Quick Tips:
		>dotnet --help
		>dotnet publish -c release 
			>Debug is used by default
		>dotnet build
		>dotnet run [args]
			>where args are passed to the built application
	>For any .NET core target (portable dll output)
		>dotnet run [args] (will compile, run, and pass in all args)
	>For win10-x64 target (exe output):
		>dotnet publish -c release -r win10-x64
		>dotnet build -r win10-x64
		
>Adding commands (see Martini.cs for an example):
	>Create a new file
	>Place everything within the ScratchPad namespace AND within "partial class Program"
	>Make the new class implement IDriver, which requires a method "void Main(string[] args)"
		>This method will be passed all remaining arguments not used by the program's Main method (those reserved args are removed from the array)
	>Update the switch statement within the Program.cs file's Main method to include the new IDriver
