<#
.SYNOPSIS
	Test whether a domain is blacklisted
.DESCRIPTION
	This function will check if the IP address associated with the entered domain is listed in a number of blacklists. The blacklist information is stored in a csv file, containing the name, domain, and description of each blacklist server. If desired, you can enter the IP for the domain directly into the -Domain parameter.
	
	~@Author:	Chris Ryan
	@FeDate:	January 13th, 2016
	@LeDate:	January 14th, 2016
.ROLE
	Public~h_File
#>
Function Test-DomainBlacklisting {
	Param(
		[CmdletBinding()]
		[Parameter(Mandatory=$true,Position=0)]
		[alias("d")]
		[string]
		$Domain,
		
		[Parameter(Position=1)]
		[alias("f")]
		[string]
		$File="C:\Users\Chris Ryan\Google Drive\KeepSynced\PSProjects\forLauncher\FullBLTrimmed.csv"
	)
	$reverseIp = ""
	$ipRegex = "(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})"
	$blDisc = @()		# store any discovered blacklists containing the domain's IP
	
	# Retrieve the list of DNSBL domains (as objects)
	try {
		$blDomains = Import-Csv -Path $File
	}
	catch {
		Write-Error "Unable to import data from DNSBL data file!"
		break
	}
	
	# Retrieve the DNS listing for the entered domain and check for any errors
	if (!($Domain -Match $ipRegex)) {
		Write-Verbose "Looking up IP for $Domain"
		$listing = nslookup $Domain 2>&1		# re-direct error stream
		if ($listing[0].GetType().ToString() -like "*ErrorRecord*") {		#System.Management.Automation.ErrorRecord
			if ($listing[0].Exception.ToString() -like "*Non-exist*") {		#Non-existent domain
				Write-Error -ErrorRecord $listing[0]
				break
			}
			
			$listing = $listing[2..($listing.Length)]		# first 2 items will be error records (2nd is blank)
		}
	
		# Search the domain's listing from your DNS query to extract their IP and reverse it
		for ($i = 0; $i -lt $listing.Length; $i++) {
			if ($listing[$i] -like "*$Domain*") {
				if ($listing[$i + 1] -Match $ipRegex) {
					$reverseIp = $Matches[4] + "." + $Matches[3] + "." + $Matches[2] + "." + $Matches[1]
				}
			}
		}
	}
	else {		# IP was entered as the domain
		$reverseIp = $Matches[4] + "." + $Matches[3] + "." + $Matches[2] + "." + $Matches[1]
	}
	
	# Call nslookup on each blacklist domain, prepending the reversed IP
	$count = 1
	$total = $blDomains.Length
	foreach ($bl in $blDomains) {
		Write-Verbose "Checking blacklist $count of $total"
		$data = nslookup "$reverseIp.$($bl.Zone)" 2>&1		# re-direct error stream
		if ($data[0].GetType().ToString() -like "*ErrorRecord*") {		#System.Management.Automation.ErrorRecord
			if ($data[0].Exception.ToString() -notlike "*can't find*") {		#Non-existent domain && Unspecified error...
				Write-Host $data[0].Exception.ToString()
				$blDisc += $bl
			}
		}
		$count++
	}
	
	return $blDisc |Select-Object -Property 'DNS blacklist','Listing goal' |Format-Table -AutoSize
}