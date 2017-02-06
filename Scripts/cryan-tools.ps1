$Source = Join-Path $PSScriptRoot "..\CSharp\CRyan.Tools.cs" -Resolve
Add-Type -Path $Source

Write-Host "While Loop:" -f cyan -b black
for ($i = 0; $i -lt 10; $i++) {
	[CRyan.Tools.Reverser]::ReverseWhileLoopTimed(66899045)
}

Write-Host "`nRecursive:" -f cyan -b black
for ($i = 0; $i -lt 10; $i++) {
	[CRyan.Tools.Reverser]::ReverseRecursiveTimed(66899045)
}
