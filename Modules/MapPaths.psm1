$global:MapPath = @{
	"pf" = "C:\Program Files";
	"pfx" = "C:\Program Files (x86)";
	"scripts" = "$env:USERPROFILE\Documents\PowerShell\Scripts";
	"npp" = "C:\Program Files (x86)\notepad++\plugins";
	"dl" = "$env:USERPROFILE\Downloads";
}

function Get-FromMapPath {
	param(
		[parameter(Mandatory=$true)]
		[String]
		$Alias
	)
	
	return $MapPath[$Alias]
}

function Update-MapPath {
	foreach ($key in $MapPath.Keys) {
		New-Variable -Name "4$key" -Value (Get-FromMapPath $key) -Scope global
	}
}

#$global:4pf = Get-FromMapPath pf
#$global:4pfx = Get-FromMapPath pfx
#$global:4scripts = Get-FromMapPath scripts
#$global:4npp = Get-FromMapPath npp
#$global:4dl = Get-FromMapPath dl
