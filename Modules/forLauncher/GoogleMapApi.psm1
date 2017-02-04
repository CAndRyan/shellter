<#
.SYNOPSIS
	Retrieve the directions from one location to another from the Google Maps HTTP web api.
.DESCRIPTION
	This function requires a string for the origin and another string for your destination. There is also a parameter for the mode of travel which accepts 'driving', 'bicycling', 'walking', or 'transit'. If no mode of travel is specified, it will default to 'driving'. By default, the function will use imperial units for the distances (miles, feet) but there is a switch parameter, 'inMetric', you can include to change to metric.
	  
	~@Author:	Chris Ryan
	@FeDate:	November 16th, 2015
	@LeDate:	November 21st, 2015
.EXAMPLE
	Get-TravelDirection -origin "Chicago, IL" -destination "Ames, IA" -mode transit -inMetric
	
	Instruction                                 Duration        TravelMode Distance
	-----------                                 --------        ---------- --------
	Leave: Chicago, IL, USA - To: Ames, IA, USA 7 hours 52 mins transit    682 km 1 m
	Train towards Emeryville Amtrak             6 hours 9 mins  transit    543 km
	Walk to Osceola, IA                         1 min           walking    1 m
	Bus towards Des Moines                      45 mins         transit    77.4 km
	Bus towards Minneapolis GH Depot            35 mins         transit    59.4 km
	Walk to State Gym                           7 mins          walking    0.4 km
	Bus towards Mall via Ames High School       9 mins          transit    2.6 km
	Walk to Ames, IA, USA                       6 mins          walking    0.5 km
	
	This command gathers the directions from Chicago, IL to Ames, IA using public transit and returns the distances in metric units.
.LINK
	Get-TravelTime
	Get-TravelDistance
	Out-TravelDirection
.ROLE
	Public~h_key~h_inMetric~s_Out-TravelDirection
#>
Function Get-TravelDirection {
	Param(
		[CmdletBinding()]
		[Parameter(Mandatory=$true,Position=0)]
		[alias("o")]
		[string]
		$origin,
		
		[Parameter(Mandatory=$true,Position=1)]
		[alias("d")]
		[string]
		$destination,
		
		[Parameter(Position=2)]
		[ValidateSet("driving","bicycling","walking","transit")]
		[alias("m")]
		[string]
		$mode = "driving",
		
		[Parameter(Position=3)]
		[alias("k")]
		[string]
		$key = "AIzaSyAFzX0BvF_GLqC8W6Mb4pEZ582Um6JdCCQ",
		
		[Parameter()]
		[Switch]
		$inMetric
	)
	$units = "imperial" # Default set to Miles

	# If Switch is selected, use 'Metric' as the Unit
	if ($inMetric) {
		$units = "metric"
	}

	# Requesting Web Page
	$webpage = ""
	$Error.Clear()
	$ErrorActionPreference = "SilentlyContinue"
	try {
		$webpage = Invoke-WebRequest "https://maps.googleapis.com/maps/api/directions/xml?origin=$origin&destination=$destination&mode=$($mode.toLower())&units=$units&key=$key" -UseBasicParsing -ErrorVariable +err
	}
	catch {
		$ErrorActionPreference = "Continue"
		Write-Error "Unable to complete web call! Check internet connection."
		$errorMsg = $Error[0].Exception.Message
		Break
	}
		
	# Capturing the HTML output
	$content = $webpage.Content

	# To Clear unwanted data from the String
	Function Clean-String($str) {
		$str = $str.replace('<div style="font-size:0.9em">','')
		$str = $str.replace('</div>','')
		$str = $str.replace('<b>','')
		$str = $str.replace('</b>','')
		$str = $str.replace('&nbsp;','')
		Return $str
	}
	
	# Get the origin and destination as returned from Google
	$origin = (Select-Xml -Content $content -xpath '//route/leg/start_address').Node.InnerText
	$destination = (Select-Xml -Content $content -xpath '//route/leg/end_address').Node.InnerText

	# Data Mining information from the XML content
	$objectList = New-Object System.Collections.Generic.List[PSObject]
	$status = (Select-Xml -Content $content -xpath '//status').Node.InnerText
	if ($status -eq 'OK') {
		$travelMode = (Select-Xml -Content $content -xpath '//route/leg/step/travel_mode').Node.InnerText
		$duration = (Select-Xml -Content $content -xpath '//route/leg/step/duration/text').Node.InnerText
		$distance = (Select-Xml -Content $content -xpath '//route/leg/step/distance/text').Node.InnerText
		$instructions = (Select-Xml -Content $content -xpath '//route/leg/step/html_instructions').Node.InnerText | %{ Clean-String $_}
		
		# Set up the first direction object. It contains the basic info.
		$start = "Leave: $origin - To: $destination"
		$d = "0 mi"
		if ($inMetric) {
			$d = "0 km"
		}
		$object = New-Object PSObject -Property @{TravelMode=$mode.ToLower();Duration=0;Distance=$d;Instruction=$start}
		$objectList.add($object)
		for ($i=0; $i -lt $instructions.count; $i++) {
			$object = New-Object PSObject -Property @{TravelMode=$travelMode[$i].ToLower();Duration=$duration[$i];Distance=$distance[$i];Instruction=$instructions[$i]}
			$objectList.add($object)
		}
	}
	else {
		# In case no data is recived due to incorrect parameters
		Write-Error "Zero Results Found:  Try changing the parameters"
		break
	}
	
	# Get the total travel distance and time. The api returns these but rounds each number off so the results are a bit different
	$objectList[0].Distance = Get-TravelDistance $objectList
	$objectList[0].Duration = Get-TravelTime $objectList
	
	Return $objectList
}

<#
.SYNOPSIS
	Retrieve the total travel time from an array of directions.
.DESCRIPTION
	This function requires an array of travel directions which can be retrieved from the command, 'Get-TravelDirection'. It will add up all the durations and return the total.
   
	~@Author:	Chris Ryan
	@FeDate:	November 16th, 2015
	@LeDate:	November 21st, 2015
.EXAMPLE
	Get-TravelTime -route $(Get-TravelDirection -origin "Chicago, IL" -destination "Ames, IA")
	
	>5 hours 24 mins
	
	This command returns the total time to travel between Chicago, IL and Ames, IA by driving.
.LINK
	Get-TravelDirection
	Get-TravelDistance
	Out-TravelDirection
.ROLE
	Private
#>
Function Get-TravelTime {
	Param(
		[CmdletBinding()]
		[Parameter(Mandatory=$true)]
		[alias("r")]
		[PSCustomObject[]]
		$route
	)
	# Validate the object
	if (!($route[0].PSObject.Properties["Duration"])) {
		Write-Error "Invalid object array!"
		break
	}
	
	# Regular expressions for the time
	$hourRegex = "(\d+)\sh"
	$minRegex = "(\d+)\sm"
	
	# Count up the duration
	$time = 0
	foreach ($dir in $route) {
		$valid = $dir.Duration -match $hourRegex
		# If hours are found, multiply by 60 and add to time
		if ($valid) {
			$time += [int]$Matches[1] * 60
		}
		
		$valid = $dir.Duration -match $minRegex
		# If minutes are found, add to time
		if ($valid) {
			$time += [int]$Matches[1]
		}
	}
	
	# Construct the return string as 'x hour(s) y minute(s)'
	$timeString = ""
	if ($time -ge 60) {
		# Find the hours and start the string
		$hour = [math]::floor($time / 60)
		$timeString = "$hour hour"
		if ($hour -gt 1) {
			$timeString += "s "
		}
		else {
			$timeString += " "
		}
		# Return the minutes left over
		$time = $time % 60
	}
	
	if ($time -gt 0) {
		# Put the minutes in the string
		$timeString += "$time min"
		if ($time -gt 1) {
			$timeString += "s"
		}
	}
	
	return $timeString
}

<#
.SYNOPSIS
	Retrieve the total travel distance from an array of directions.
.DESCRIPTION
	This function requires an array of travel directions which can be retrieved from the command, 'Get-TravelDirection'. It will add up all the distances and return the total. The distances can be provided in metric units (meters, kilometers) or imperial units (miles, feet) and will be returned in the same system.
   
	~@Author:	Chris Ryan
	@FeDate:	November 16th, 2015
	@LeDate:	November 21st, 2015
.EXAMPLE
	Get-TravelDistance -route $(Get-TravelDirection -origin "Chicago, IL" -destination "Ames, IA")
	
	>347 mi 62 ft
	
	This command returns the total distance to travel between Chicago, IL and Ames, IA by driving.
.LINK
	Get-TravelDirection
	Get-TravelTime
	Out-TravelDirection
.ROLE
	Private
#>
Function Get-TravelDistance {
	Param(
		[CmdletBinding()]
		[Parameter(Mandatory=$true)]
		[alias("r")]
		[PSCustomObject[]]
		$route
	)
	# Validate the object
	if (!($route[0].PSObject.Properties["Distance"])) {
		Write-Error "Invalid object array!"
		break
	}
	
	# Regular expressions and conversion constant for the distance
	$longRegex = "([\d.,]+)\sm"
	$shortRegex = "([\d,]+)\sf"
	$conversion = 5280
	$isMetric = $false
	# Check if the distances are metric and adjust accordingly
	if ($route[0].Distance -like "*m") {
		$isMetric = $true
		$longRegex = "([\d.,]+)\sk"
		$shortRegex = "(\d+)\sm"
		$conversion = 1000
	}
	
	# Count up the distance
	$long = 0
	$short = 0
	foreach ($dir in $route) {
		$valid = $dir.Distance -match $longRegex
		# If miles or kilometers are found, add to the long distance
		if ($valid) {
			$long += [int]$Matches[1]
		}
		
		$valid = $dir.Distance -match $shortRegex
		# If feet or meters are found, add to the short time
		if ($valid) {
			$short += [int]$Matches[1]
		}
	}
	
	# Look at the short distance and consolidate with the long distance if appropriate
	if ($short -ge $conversion) {
		$long += [math]::floor($short / $conversion)
		$short = $short % $conversion
	}
	
	# Construct the distance string
	$distanceString = ""
	if ($long -gt 0) {
		$distanceString = "$long "
		if ($isMetric) {
			$distanceString += "km "
		}
		else {
			$distanceString += "mi "
		}
	}
	if ($short -gt 0) {
		$distanceString += "$short "
		if ($isMetric) {
			$distanceString += "m"
		}
		else {
			$distanceString += "ft"
		}
	}
	
	return $distanceString
}

<#
.SYNOPSIS
	Format the directions returned from Get-TravelDirection.
.DESCRIPTION
	This function requires an array of travel directions which can be retrieved from the command, 'Get-TravelDirection'. It returns the directions as a single, formatted string. This function accepts pipeline input as well as passing an object list through the parameter. 
   
	~@Author:	Chris Ryan
	@FeDate:	November 21st, 2015
	@LeDate:	December 30th, 2015
.EXAMPLE
	Out-TravelDirection -route $(Get-TravelDirection -origin "Chicago, IL" -destination "Ames, IA")
	
	This command returns the directions between Chicago, IL and Ames, IA as a single formatted string.
.LINK
	Get-TravelDirection
	Get-TravelDistance
	Get-TravelTime
.ROLE
	Private
#>
Function Out-TravelDirection {
	Param(
		[CmdletBinding()]
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[alias("r")]
		[PSCustomObject[]]
		$route
	)
	BEGIN{
		$regex = "^Leave: (.*)\s*-\sTo: (.*)$"
		$outString = ""
		
		# Set up the counter to keep track of the index (allows for piped input)
		$pipeCount = 0
	}
	PROCESS{
		foreach ($element in $route) {
			# Get the origin, destination, and main travel mode from the first direction
			if ($pipeCount -eq 0) {
				$valid = $element.Instruction -match $regex
				if ($valid) {
					$orig = $Matches[1].Trim()
					$dest = $Matches[2].Trim()
				}
				else {
					Write-Error "Invalid directions!"
					break
				}
				$mode = $element.TravelMode
				
				# Generate the header
				$outString = "------$orig to $dest by $mode------`n`n      Total Distance: $($element.Distance)`n      Total Time: $($element.Duration)`n`n"
			}
			else {
				# Generate leading spaces, allowing up to 3 digits for the direction count (<1000)
				if ($pipeCount -lt 10) {
					$outString += "  "
				}
				elseif ($pipeCount -lt 100) {
					$outString += " "
				}
				
				# Add an instruction with distance and time
				$outString += "$($pipeCount)-> $($element.Instruction) --- $($element.Distance) - $($element.Duration)`n"
			}
			
			$pipeCount++
		}
	}
	END{
		return $outString
	}
}
