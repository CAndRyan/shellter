Set-Location "$env:USERPROFILE\Documents\PowerShell\Scripts"
$warnings = New-Object System.Collections.Generic.List[String]

#*** IMPORT MODULES ***
$global:MapModules = @{}
$modules = (	# load with some exclusions (in .txt file)
	"..\Modules"
)
foreach ($path in $modules) {
	$exclude = (Get-Content -Path (Join-Path $path "exclude.txt") -EA silentlycontinue) -join ", "
	$count = 0
	foreach ($module in (Get-ChildItem -Path $path -Filter *.psm1 -Exclude $exclude -Recurse)) {
		try {
			Import-Module -Name $module -EA stop
			$MapModules.Add($count, ($module.Name -replace ".psm1$", ""))
			$count++
		}
		catch {
			$warnings.Add("Failed to load '$($module.FullName)'")
			#Out-Default -InputObject $_.Exception.ToString()
		}
	}
}
#*** IMPORT MODULES ***

#*** CUSTOM FUNCTIONS ***
function Get-FromMapModulesCommands {
	param([parameter(Mandatory=$true)][Int]$Index)
	Get-Command -Module $MapModules[$Index]
}
function Get-MapModules {
	$MapModules |Format-Table -AutoSize
}
function Get-WorkToHome {
	#
}
#function Start-NotepadPP {
#	Start-AndMapProcess -Path "C:\Program Files (x86)\notepad++\notepad++.exe"
#}
#*** CUSTOM FUNCTIONS ***

#*** DEFINE ALIASES ***
#Set-Alias -Name "np" -Value Start-NotepadPP
Set-Alias -Name "np" -Value "C:\Program Files (x86)\notepad++\notepad++.exe"
Set-Alias -Name "getd" -Value Get-FromMapPath
Set-Alias -Name "getm" -Value Get-MapModules
Set-Alias -Name "getc" -Value Get-FromMapModulesCommands
Set-Alias -Name "pow" -Value powershell.exe
#*** DEFINE ALIASES ***

#*** EXECUTE FUNCTIONS ***
Update-MapPath
Set-ShellWindow -Title "CRyan" -Home
#*** EXECUTE FUNCTIONS ***

#*** DISPLAY WARNINGS ***
$verbosity = $VerbosePreference
$VerbosePreference = "continue"
foreach ($warning in $warnings) {
	Write-Verbose -Message $warning
}
$VerbosePreference = $verbosity
#*** DISPLAY WARNINGS ***
