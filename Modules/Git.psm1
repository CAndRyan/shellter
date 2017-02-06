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
