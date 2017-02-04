<#
.SYNOPSIS
	Retrieve the data from a table on a webpage
.DESCRIPTION
	This function requires a string for the webpage URL and a string for the file location to output the resulting table data as a CSV. If the file path includes a ':' the function will treat it as a full name. Otherwise the function will treat the input as a partial file path, starting from the current working directory. The function uses PowerShell's Invoke-WebRequest without the -UseBasicParsing parameter so it generates a COM object through Internet Explorer.
	
	~@Author:	Chris Ryan
	@FeDate:	January 12th, 2016
	@LeDate:	January 12th, 2016
.ROLE
	Public
#>
Function Get-TableFromWeb {
	Param(
		[CmdletBinding()]
		[Parameter(Mandatory=$true,Position=0)]
		[alias("u")]
		[string]
		$Url,
		
		[Parameter(Mandatory=$true,Position=1)]
		[alias("f")]
		[string]
		$File
	)
	# Invoke web request and retrieve the html content
	#$Url = "https://en.wikipedia.org/wiki/Comparison_of_DNS_blacklists"
	$website = Invoke-WebRequest -Uri $Url
	$data = ($website.ParsedHtml.getElementsByTagName("table") |Select-Object -First 1).rows
	$table = @()
	$total = $data.Length
	$count = 1		# to keep track of where we are for verbose output
	$numColumns = 0
	$reference
	
	# Parse the results and build each row of our table
	foreach($item in $data) {
		Write-Verbose "Working on item $count of $total"
		if ($item.tagName -eq "tr"){
			$row = @()
			$cells = $item.children
			$valid = $true
			
			# Extract the <td> and <th> elements to build each row
			foreach ($cell in $cells) {
				if ($cell.tagName -imatch "t[dh]") {
					$row += $cell.innerText
				}
			}
			
			# Determine the number of columns from the first element, ideally the header...		*should search for rowspan="x"*
			if ($count -eq 1) {
				$numColumns = $row.Count
			}
			<# elseif ($row.Count -lt $numColumns) {		# Add the first elements of the $header array to this row
				if ($row.Count -eq ($numColumns + 1)) {
					Write-Verbose "Adding extra columns on row $count"
					$tempRow = @()
					$tempRow += $reference[0]
					foreach ($str in $row) {
						$tempRow += $str
					}
					$row = $tempRow
				}
				else {		# Temporarily locking down other options
					Write-Verbose "Merging extra columns on row $count"
					$valid = $false
				}
			}
			elseif ($row.Count -gt $numColumns) {		# Take the first extra elements of this row and merge them
				$valid = $false
			}
			else {
				$reference = $row
			} #>
			
			# Add the row to the table if it is valid
			if ($valid) {
				$table += "`'" + $($row -join "`',`'") + "`'"		#join each element in the row by ',' for the csv output
			}
		}
		$count++
	}
	
	# Determine whether or not the provided file already has the proper file extension
	if ($File -notlike "*.csv") {
		$File = $File + ".csv"
	}
	
	# Determine whether or not the provided file is a full or partial path
	if ($File -like "*:*") {
		#
	}
	else {
		$File = $(Get-Location).Path + $File
	}
	
	$table |Out-File -FilePath $File -Encoding ascii
}