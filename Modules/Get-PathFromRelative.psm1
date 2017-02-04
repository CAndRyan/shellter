function Get-PathFromRelative {
	param(
		[parameter(Mandatory=$true)]
		[String]
		$Relative,
		
		[parameter()]
		[Switch]
		$Imaginary
	)
	
	if ($Imaginary) {
		return [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Relative))
	}
	else {	#will throw an error if the path cannot resolve
		return Join-Path (Get-Location) $Relative -Resolve
	}
}
