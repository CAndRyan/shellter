function Get-GitRepos {
	[CmdletBinding()]
	param(
		[parameter()]
		[String]
		$Directory = "C:\",
		
		[parameter()]
		[Switch]
		$IncludeBare
	)
	
	$sw = $null
	$verbosity = $VerbosePreference
	$sw = [System.Diagnostics.Stopwatch]::StartNew()
	if ($Verbose) {
		$VerbosePreference = "continue"
	}
	
	if ($IncludeBare) {
		Get-ChildItem -Path $Directory -Recurse -Force -ErrorAction silentlycontinue -File -Filter "HEAD" |
			Select-Object -ExpandProperty FullName |
			Foreach-Object  {$_ -replace "(\\\.git)?\\HEAD$", ""} |
			Where-Object {-not ($_ -match ".*\\\.git\\.*")}
	}
	else {
		Get-ChildItem -Path $Directory -Recurse -Force -ErrorAction silentlycontinue -Directory -Filter ".git" |
			Select-Object -ExpandProperty FullName |
			Foreach-Object  {$_ -replace "\\\.git$", ""}
	}
	
	$sw.Stop()
	Write-Verbose "Execution took $($sw.Elapsed.TotalSeconds) seconds"
	$VerbosePreference = $verbosity
}

function Import-GitCommandsXml {
	param(
		[parameter()]
		[String]
		$Path = "$env:USERPROFILE\Documents\git-commands.xml"
	)
	
	$dat = New-Object -TypeName PSObject
	$dat |Add-Member -MemberType NoteProperty -Name NextId -Value 0 -PassThru |
		Add-Member -MemberType NoteProperty -Name Commands -Value (New-Object System.Collections.Generic.List[PSObject])
	
	if (Test-Path -Path $Path) {
		$xml = Import-Clixml -Path $Path
		foreach ($obj in $xml.Commands) {
			$dat.Commands.Add($obj)
		}
		
		$dat.NextId = $xml.NextId
	}
	
	return $dat
}

function Add-GitCommand {
	param(
		[parameter(Mandatory=$true)]
		[String]
		$Name,
		
		[parameter(Mandatory=$true)]
		[String]
		$Command,
		
		[parameter(Mandatory=$true)]
		[String]
		$Description,
		
		[parameter()]
		[String]
		$Resource,
		
		[parameter()]
		[String]
		$Path = "$env:USERPROFILE\Documents\git-commands.xml"
	)
	
	$dat = Import-GitCommandsXml -Path $Path
	
	$new = New-Object -TypeName PSObject
	$new |Add-Member -MemberType NoteProperty -Name Id -Value $dat.NextId -PassThru |
		Add-Member -MemberType NoteProperty -Name Name -Value $Name -PassThru |
		Add-Member -MemberType NoteProperty -Name Command -Value $Command -PassThru |
		Add-Member -MemberType NoteProperty -Name Description -Value $Description -PassThru |
		Add-Member -MemberType NoteProperty -Name Resource -Value $Resource
		
	$dat.Commands.Add($new)
	$dat.NextId = $dat.NextId + 1
	$dat.Commands = $dat.Commands |Sort-Object -Property Name
	
	$dat |Export-Clixml -Path $Path
}

function Get-GitCommands {
	param(
		[parameter()]
		[String]
		$Filter = "",
		
		[parameter()]
		[String]
		$Path = "$env:USERPROFILE\Documents\git-commands.xml"
	)
	
	$dat = Import-GitCommandsXml -Path $Path
	
	if ($Filter -eq "") {
		return $dat.Commands
	}
	else {
		return $dat.Commands |Where-Object {($_.Name -like "*$Filter*") -or ($_.Command -like "*$Filter*")}
	}
}

function Remove-GitCommand {
	param(
		[parameter(Mandatory=$true)]
		[Int]
		$Id,
		
		[parameter()]
		[String]
		$Path = "$env:USERPROFILE\Documents\git-commands.xml"
	)
	
	$dat = Import-GitCommandsXml -Path $Path
	
	$rem = $dat.Commands |Where-Object {$_.Id -eq $Id}
	if ($rem -ne $null) {
		$dat.Commands.Remove($rem) |Out-Null
		$dat |Export-Clixml -Path $Path
	}
}
