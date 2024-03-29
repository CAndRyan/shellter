#Set-Location "$env:USERPROFILE\Documents\PowerShell"
$warnings = New-Object System.Collections.Generic.List[String]

#*** IMPORT MODULES ***
$global:MapModules = @{}
$modules = (	# load with some exclusions (in .txt file)
	"$env:USERPROFILE\Documents\PowerShell\Modules"
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
function Start-DockerShell {
	param(
		[parameter(Mandatory=$true)][string]$ImageName,
		[parameter(Mandatory=$false)][string]$Command
	)
	if ($null -eq $Command -or $command -eq "") {
		& docker exec -it $ImageName /bin/sh
	} else {
		& docker exec -it $ImageName /bin/sh -c "$Command"
	}
}		
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
function Open-WallpapersWin10 {
	& control /name Microsoft.Personalization /page pageWallpaper
}
function Get-PiHoleStats {
	$json = Invoke-RestMethod -Method GET -Uri http://pi.hole/admin/api.php
	return $json
}
function Start-SandboxProgram {
	param([parameter(Mandatory=$true)][String]$Path)
	& "C:\Program Files\Sandboxie\Start.exe" $Path
}
function Set-CurrentShellToMinimized {
	Get-Process -Id $PID |Set-WindowStyle -Style MINIMIZE
}
function Start-GulpBuild {
	param(
		[parameter(Mandatory=$true,HelpMessage="Enter a command like: build-debug")][string]$Command,
		[parameter()][ValidateScript({Test-Path $_ -PathType Container})][string]$Path,
		[parameter()][switch]$NoWait,
		[parameter()][switch]$CloseAfter
	)
	if ($Path) {
		$workingDirectory = $(Resolve-Path $Path).Path;
	}
	else {
		$workingDirectory = $(Get-ChildItem -Path $(Get-Location).Path -Filter gulpfile.js -Recurse -EA SilentlyContinue |
			Select-Object -First 1).Directory.FullName
		if (-not $workingDirectory) {
			throw "No gulpfile found in the current directory"
		}
	}
	$cmd = "`$host.ui.RawUI.WindowTitle = '$workingDirectory'; Write-Host 'Working Directory: '$workingDirectory''; gulp $Command;"
	if (-not $CloseAfter) { $cmd += " Write-Host `"Press ENTER to exit...`"; Read-Host;" }
	Start-Process powershell.exe -ArgumentList "-NoProfile -Command &{ $cmd }" -WorkingDirectory $workingDirectory -Wait:$(-not $NoWait)
}
function Start-MSBuild {
	param(
		[parameter(Mandatory=$true)][string]$ProjectFilePath,
		[parameter()][string]$ExePath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe",
		[parameter()][string]$Configuration = "Debug",
		[parameter()][string]$Target = "Rebuild"
	)
	& $ExePath "$ProjectFilePath" /t:$Target /p:Configuration=$Configuration
}
function Reset-Filebeat {
    Stop-Service "filebeat"
    Get-ChildItem  "$($env:PROGRAMDATA)\filebeat" |
		Where-Object { $_.Name -Match "registry*" } |
		Remove-Item -Force
    Start-Service "filebeat"
}
function Test-ShellIsAdmin {
	return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}
function Stop-PrivelegedProcess {
	param(
		[parameter(Mandatory=$true)][string]$Name
	)
	If (-NOT $(Test-ShellIsAdmin)) { throw "Requires PowerShell to be running as an Administrator" }
	Get-Process -Name $Name -EA SilentlyContinue |Stop-Process -Force
}
function Get-GitGraph {
	$command = "git log --pretty=oneline --graph --decorate --all"
	Invoke-Expression $command
}
function Get-SpongebobCase {
	param(
		[parameter(Mandatory=$true)][string]$InputString
	)
	$output = ""
	for ($i = 0; $i -lt $InputString.Length; $i++) {
		$currentChar = $InputString[$i].ToString()
		if ($i % 2 -eq 1) {
			$output += $currentChar.ToUpper()
		} else {
			$output += $currentChar.ToLower()
		}
	}
	return $output
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
Set-Alias -Name "sand" -Value Start-SandboxProgram
Set-Alias -name "vsc" -Value "code-insiders.cmd"
Set-Alias -Name "min" -Value Set-CurrentShellToMinimized
Set-Alias -Name "ggulp" -Value Start-GulpBuild
Set-Alias -Name "ithrow" -Value Invoke-ThrowCommand
#*** DEFINE ALIASES ***

#*** EXECUTE FUNCTIONS ***
Update-MapPath
Set-ShellWindow -Title "Shellter" -Home
#*** EXECUTE FUNCTIONS ***

#*** DISPLAY WARNINGS ***
$verbosity = $VerbosePreference
$VerbosePreference = "continue"
foreach ($warning in $warnings) {
	Write-Verbose -Message $warning
}
$VerbosePreference = $verbosity
#*** DISPLAY WARNINGS ***
