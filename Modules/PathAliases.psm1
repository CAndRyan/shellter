$global:PathMap = @{
	"pf" = "C:\Program Files";
	"pfx" = "C:\Program Files (x86)";
	"scripts" = "$env:USERPROFILE\Documents\PowerShell\Scripts";
	"npp" = "C:\Program Files (x86)\notepad++\plugins";
	"dl" = "$env:USERPROFILE\Downloads";
}

function Get-FromPathMap {
	param(
		[parameter(Mandatory=$true)]
		[String]
		$Alias
	)
	
	return $PathMap[$Alias]
}

function Update-PathMap {
	foreach ($key in $PathMap.Keys) {
		New-Variable -Name "4$key" -Value (Get-FromPathMap $key) -Scope global
	}
}

#$global:4pf = Get-FromPathMap pf
#$global:4pfx = Get-FromPathMap pfx
#$global:4scripts = Get-FromPathMap scripts
#$global:4npp = Get-FromPathMap npp
#$global:4dl = Get-FromPathMap dl
