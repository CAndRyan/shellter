$Source = Join-Path $PSScriptRoot "..\CSharp\CRyan.Tools.cs" -Resolve

#Add-Type -TypeDefinition $Source -Language CSharp
Add-Type -Path $Source

for ($i = 0; $i -lt 10; $i++) {
	[CRyan.Tools.Reverser]::ReverseWhileLoopTimed(66899045)
	[CRyan.Tools.Reverser]::ReverseRecursiveTimed(66899045)
}
