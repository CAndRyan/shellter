# 

function Get-LocalUsersAndGroups {
	param(
		[parameter()]
		[alias("cn")]
		[string]
		$ComputerName = $env:COMPUTERNAME
	)

	$adsi = [ADSI]"WinNT://$ComputerName"

	$adsi.Children |Where-Object {$_.SchemaClassName -eq "user"} |
		ForEach-Object {
			$groups = $_.Groups() |ForEach-Object {$_.GetType().InvokeMember("Name", "GetProperty", $null, $_, $null)}
			$_ |Select-Object @{n="UserName";e={$_.Name}},@{n="Groups";e={$groups -join ";"}}
		}
}
	