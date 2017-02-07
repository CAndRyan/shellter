function Import-StandupXml {
	param(
		[parameter()]
		[String]
		$Path = "$env:USERPROFILE\Documents\standup.xml"
	)
	
	$dat = New-Object -TypeName PSObject
	$dat |Add-Member -MemberType NoteProperty -Name NextId -Value 0 -PassThru |
		Add-Member -MemberType NoteProperty -Name Days -Value (New-Object System.Collections.Generic.List[PSObject])
	
	if (Test-Path -Path $Path) {
		$xml = Import-Clixml -Path $Path
		foreach ($obj in $xml.Days) {
			$dat.Days.Add($obj)
			
			foreach ($item in $obj.Notes) {
				$count++
			}
		}
		
		$dat.NextId = $xml.NextId
	}
	
	return $dat
}

function Add-StandupNote {
	param(
		[parameter()]
		[String]
		$Note,
		
		[parameter()]
		[String]
		$Path = "$env:USERPROFILE\Documents\standup.xml",
		
		[parameter()]	#Default to the current date
		[String]
		$DateString = ""
	)
	
	$date = $null
	if ($DateString -ne "") {
		$date = ([DateTime]$DateString)
	}
	else {
		$date = Get-Date
	}
	
	$dat = Import-StandupXml -Path $Path
	
	$curr = New-Object -TypeName PSObject
	$curr |Add-Member -MemberType NoteProperty -Name Date -Value $date -PassThru |
		Add-Member -MemberType NoteProperty -Name Notes -Value (New-Object System.Collections.Generic.List[PSObject])
	
	$selected = $dat.Days |Where-Object {$_.Date.ToString("d") -eq $date.ToString("d")}
	if ($selected -ne $null) {
		foreach ($obj in $selected.Notes) {
			$curr.Notes.Add($obj)
		}
		
		$dat.Days.Remove($selected) |Out-Null
	}
	
	$new = New-Object -TypeName PSObject
	$new |Add-Member -MemberType NoteProperty -Name Id -Value $dat.NextId -PassThru |
		Add-Member -MemberType NoteProperty -Name Note -Value $Note
	$curr.Notes.Add($new)
	$dat.Days.Add($curr)
	$dat.NextId = $dat.NextId + 1
	$dat.Days = $dat.Days |Sort-Object -Property Date
	
	$dat |Export-Clixml -Path $Path
}

function Get-StandupNotes {
	param(
		[parameter()]	#Default to the current date
		[String]
		$DateString = "",
		
		[parameter()]
		[String]
		$Path = "$env:USERPROFILE\Documents\standup.xml",
		
		[parameter()]
		[Switch]
		$Yesterday,
		
		[parameter()]	#Only necessary if using the -Yesterday flag on a Monday and looking to get Sunday - default is Friday...
		[Switch]
		$IncludeWeekend,
		
		[parameter()]
		[Switch]
		$All,
		
		[parameter()]	#Used with -All switch to preserve the data structure
		[Switch]
		$NoFormat
	)
	
	$date = $null
	if ($Yesterday) {
		$today = Get-Date
		if (($today.DayOfWeek -eq "Monday") -and (-not $IncludeWeekend)) {
			$date = $today.AddDays(-3)
		}
		else {
			$date = $today.AddDays(-1)
		}
	}
	elseif ($DateString -ne "") {
		$date = ([DateTime]$DateString)
	}
	else {
		$date = Get-Date
	}
	
	$dat = Import-StandupXml -Path $Path
	
	if ($All) {
		$modded = $dat.Days |
			ForEach-Object {$tmp = $_.Date; $_.Notes |
				Foreach-Object {$_ |
					Add-Member -MemberType NoteProperty -Name Date -Value $tmp -PassThru}} |
			Select-Object -Property Id, Date, Note
			
		if ($NoFormat) {
			return $modded
		}
		else {
			return $modded |Format-Table -GroupBy Date -Property Id, Note
		}
	}
	else {
		$curr = New-Object -TypeName PSObject
		$curr |Add-Member -MemberType NoteProperty -Name Date -Value $date -PassThru |
			Add-Member -MemberType NoteProperty -Name Notes -Value (New-Object System.Collections.Generic.List[PSObject])
		
		$selected = $dat.Days |Where-Object {$_.Date.ToString("d") -eq $date.ToString("d")}
		if ($selected -ne $null) {
			foreach ($obj in $selected.Notes) {
				$curr.Notes.Add($obj)
			}
		}
		
		return $curr.Notes
	}
}

function Remove-StandupNote {
	param(
		[parameter(Mandatory=$true)]
		[Int]
		$Id,
	
		[parameter()]	#Default to the current date
		[String]
		$DateString = "",
		
		[parameter()]
		[String]
		$Path = "$env:USERPROFILE\Documents\standup.xml"
	)
	
	$date = $null
	if ($DateString -ne "") {
		$date = ([DateTime]$DateString)
	}
	else {
		$date = Get-Date
	}
	
	$dat = Import-StandupXml -Path $Path
	
	$curr = New-Object -TypeName PSObject
	$curr |Add-Member -MemberType NoteProperty -Name Date -Value $date -PassThru |
		Add-Member -MemberType NoteProperty -Name Notes -Value (New-Object System.Collections.Generic.List[PSObject])
	
	$selected = $dat.Days |Where-Object {$_.Date.ToString("d") -eq $date.ToString("d")}
	if ($selected -ne $null) {
		foreach ($obj in $selected.Notes) {
			$curr.Notes.Add($obj)
		}
		
		$dat.Days.Remove($selected) |Out-Null
	}
	
	$rem = $curr.Notes |Where-Object {$_.Id -eq $Id}
	if ($rem -ne $null) {
		$curr.Notes.Remove($rem) |Out-Null
		
		$dat.Days.Add($curr)
		$dat.Days = $dat.Days |Sort-Object -Property Date
		$dat |Export-Clixml -Path $Path
	}
}
