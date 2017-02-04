<#
.SYNOPSIS
	Retrieve the available wireless networks
.DESCRIPTION
	This function will return the list of all networks visible to the wireless network interface card. The network currently connected to will display an asterisk before the SSID (name). The property, "AccessPoint", displays all the access points visible for this network and includes information on their signal strength and radio type. Each network is accessible from the list by using their Id to index into the list.
   
	~@Author:	Chris Ryan
	@FeDate:	December 29th, 2015
	@LeDate:	December 30th, 2015
.EXAMPLE
	Get-NetworkList
	
	This command produces a list containing all the networks available to the wireless network interface card.
.ROLE
	Public~s_Sort -Property Strength -Descending |Select -Property * -ExcludeProperty Id, AccessPoint |Format-Table -AutoSize
#>
function Get-NetworkList {
	# Retrieve text dump of network information
	$dump = netsh wlan show all
	$current = netsh wlan show interfaces

	# Trim excess info from the text dump (after "SHOW NETWORKS MODE")
	for ($i = 1; $i -lt $dump.Length; $i++) {		# could probably start later in the text dump
		if ($dump[$i].StartsWith("=")) {
			$i++
			if ($dump[$i] -match "SHOW NET") {
				$dump = $dump[($i + 7)..($dump.Length)]		# 7 lines before the first network
				break
			}
		}
	}
	
	# Determine the current network in use if connected to one
	$currentSsid = $null
	if ($current.Length -gt 20) {
		if ($current[19].Trim() -match "^Profile\s+:\s(.*)$") {
			$currentSsid = $Matches[1].Trim()
		}
	}
	Remove-Variable Matches

	# Begin parsing and building objects
	$network = New-Object System.Collections.Generic.List[PSCustomObject]
	for ($i = 0; $i -lt $dump.Length; $i++) {
		# Extract general network info for a network object
		if ($dump[$i] -match "^SSID (\d+) : (.*)$") {
			# Modify the Id for this network so it matches the index in the network list
			$nId = [int]$Matches[1] - 1
			
			# Check if the current connection matches the extracted SSID from the text dump
			$ssid = $Matches[2].Trim()
			if ($ssid -eq $currentSsid) {
				$ssid = "*$ssid"
			}
		
			# Generate a network object and start populating properties
			$item = New-Object -TypeName PSObject
			$item |Add-Member -MemberType NoteProperty -Name Id -Value $nId -PassThru |
				Add-Member -MemberType NoteProperty -Name SSID -Value $ssid -PassThru |
				Add-Member -MemberType NoteProperty -Name NetworkType -Value $dump[$i + 1].Substring(($dump[$i + 1].IndexOf(':') + 2)) -PassThru |
				Add-Member -MemberType NoteProperty -Name Authentication -Value $dump[$i + 2].Substring(($dump[$i + 2].IndexOf(':') + 2)) -PassThru |
				Add-Member -MemberType NoteProperty -Name Encryption -Value $dump[$i + 3].Substring(($dump[$i + 3].IndexOf(':') + 2))
			$i = $i + 4
			Remove-Variable Matches

			# Extract the info from each access point on the network
			$access = New-Object System.Collections.Generic.List[PSCustomObject]
			while ($dump[$i].Trim().StartsWith("B")) {
				if ($dump[$i].Trim() -match "^BSSID (\d+)\s+: (.*)$") {
					$bId = $($Matches[1])
					$bssid = $Matches[2]
					$signal = ""
					if ($dump[$i + 1].Length -gt ($dump[$i + 1].IndexOf(':') + 2)) {
						$signal = $dump[$i + 1].Substring(($dump[$i + 1].IndexOf(':') + 2))
					}
					$radio = ""
					if ($dump[$i + 2].Length -gt ($dump[$i + 2].IndexOf(':') + 2)) {
						$radio = $dump[$i + 2].Substring(($dump[$i + 2].IndexOf(':') + 2))
					}
					$channel = ""
					if ($dump[$i + 3].Length -gt ($dump[$i + 3].IndexOf(':') + 2)) {
						$channel = $($dump[$i + 3].Substring(($dump[$i + 3].IndexOf(':') + 2)))
					}
					$bRates = ""
					if ($dump[$i + 4].Length -gt ($dump[$i + 4].IndexOf(':') + 2)) {
						$bRates = $dump[$i + 4].Substring(($dump[$i + 4].IndexOf(':') + 2))
					}
					$oRates = ""
					if ($dump[$i + 5].Length -gt ($dump[$i + 5].IndexOf(':') + 2)) {
						$oRates = $dump[$i + 5].Substring(($dump[$i + 5].IndexOf(':') + 2))
					}
				
					# Generate an access point object
					$object = New-Object -TypeName PSObject
					$object |Add-Member -MemberType NoteProperty -Name Id -Value $bId -PassThru |
						Add-Member -MemberType NoteProperty -Name BSSID -Value $bssid -PassThru |
						Add-Member -MemberType NoteProperty -Name Signal -Value $signal -PassThru |
						Add-Member -MemberType NoteProperty -Name RadioType -Value $radio -PassThru |
						Add-Member -MemberType NoteProperty -Name Channel -Value $channel -PassThru |
						Add-Member -MemberType NoteProperty -Name BasicRates -Value $bRates -PassThru |
						Add-Member -MemberType NoteProperty -Name OtherRates -Value $oRates
					$access.Add($object)
					$i = $i + 6
					Remove-Variable Matches
				}
			}
			
			# Determine the highest signal strength from all access points
			$strength = 0
			foreach ($point in $access) {
				if ($point -match "(\d+)%") {
					if ([int]$Matches[1] -gt $strength) {
						$strength = [int]$Matches[1]
					}
				}
			}
			$strength = "$strength%"
			
			# Finish building the network object and add to list
			$item |Add-Member -MemberType NoteProperty -Name Strength -Value $strength -PassThru |
				Add-Member -MemberType NoteProperty -Name AccessPoint -Value $access
			$network.Add($item)
		}
	}
	
	return $network
}