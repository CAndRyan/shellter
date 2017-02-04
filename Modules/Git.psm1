function Get-GitRepos {
	param(
		[parameter()]
		[String]
		$Directory = "C:\"
	)
	
	$verboseOn = ($PSBoundParameters['Verbose'] -eq $true)
	
	Get-ChildItem -Path $Directory -Recurse -Force -ErrorAction silentlycontinue -Filter ".git" |
		Select-Object -ExpandProperty FullName |
		Foreach-Object  {$_ -replace "\\.git$", ""}
}
