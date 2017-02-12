<#
.SYNOPSIS
	Retrieve the weather for the provided location from the Weather Underground HTTP web API.
.DESCRIPTION
	This function requires a string input for the location and there is an optional switch to retrieve the data in metric units. Imperial units are used by default. You can retrieve an API key from: "http://www.wunderground.com/weather/api", just sign up for a free account. The free key provides 2500 queries per day.
   
	~@Author:	Chris Ryan
	@FeDate:	November 17th, 2015
	@LeDate:	November 18th, 2015
.EXAMPLE
	Get-WeatherCurrent "Portland, OR"
	
	Location      : Portland, OR
	Station       : Portland - West Hills, Portland, Oregon
	Elevation     : 820 ft
	Time          : 5:51:25 PM 11/18/2015
	Temperature   : 45.5 F
	Conditions    : Overcast
	Wind          : Winds from the SSW at 0.0 mph (gusts of 0 mph)
	Humidity      : 91%
	Pressure      : 30.27 in, trending up
	Dewpoint      : 43 F
	HeatIndex     : NA
	WindChill     : 46 F
	Precipitation : 0.33 in
	Visibility    : 10.0 mi
	
	This command produces the above output for Portland, OR which includes the weather stations used, time 
	of measurement, and all the current conditions.
.LINK
	Get-WeatherForecast
.ROLE
	Public~h_key~h_inMetric
#>
Function Get-WeatherCurrent {
	Param(
		[CmdletBinding()]
		[Parameter(Mandatory=$true,Position=0)]
		[alias("l")]
		[string]
		$location,
		
		[Parameter(Mandatory=$true,Position=1)]
		[alias("k")]
		[string]
		$key,
		
		[Parameter()]
		[Switch]
		$inMetric
	)
	# Invoke web request and retrieve the xml content
	$webpage = ""
	$Error.Clear()
	$ErrorActionPreference = "SilentlyContinue"
	try {
		$webpage = Invoke-WebRequest "https://api.wunderground.com/api/$key/conditions/q/$location.xml" -UseBasicParsing
	}
	catch {
		$ErrorActionPreference = "Continue"
		Write-Error "Unable to complete web call! Check internet connection."
		$errorMsg = $Error[0].Exception.Message
		Break
	}
	
	$content = $webpage.Content
	
	# Check if an error was found from the api request
	if (Select-Xml -Content $content -xpath '//error') {
		$errorType = (Select-Xml -Content $content -xpath '//error/type').node.InnerText.ToUpper()
		$errorMsg = (Select-Xml -Content $content -xpath '//error/description').node.InnerText
		Write-Error "Error during data retrieval"
		Write-Verbose "$errorType - $errorMsg"
		break
	}
	
	# Check if useful data was actually retrieved
	if (!(Select-Xml -Content $content -xpath '//current_observation')) {
		Write-Error "Invalid data returned! Try changing the location."
		break
	}
	
	# Get the location specified, as returned from the api call
	$location = (Select-Xml -Content $content -xpath '//display_location/full').Node.InnerText
	
	# Get the station used for this reading
	$station = (Select-Xml -Content $content -xpath '//observation_location/full').Node.InnerText
	
	# Get the elevation (ft or m)
	$elevation = ""
	if (!($inMetric)) {
		$elevation = (Select-Xml -Content $content -xpath '//observation_location/elevation').Node.InnerText
	}
	else {
		$elevation = $((Select-Xml -Content $content -xpath '//display_location/elevation').Node.InnerText.Split('.'))[0] + " m"
	}
	
	# Get the local time when the reading was taken
	$time = Get-Date (Select-Xml -Content $content -xpath '//observation_time_rfc822').Node.InnerText -Format "h:mm:ss tt MM/dd/yyyy"
	
	# Get the temperature (F or C)
	$temp = ""
	if (!($inMetric)) {
		$temp = (Select-Xml -Content $content -xpath '//temp_f').Node.InnerText + " F"
	}
	else {
		$temp = (Select-Xml -Content $content -xpath '//temp_c').Node.InnerText + " C"
	}
	
	# Get the current cloud\sun (sky) conditions
	$sky = (Select-Xml -Content $content -xpath '//weather').Node.InnerText
	
	# Get the wind direction and speed (constant and gust)
	$windDir = (Select-Xml -Content $content -xpath '//wind_dir').Node.InnerText
	$windSpd = ""
	if (!($inMetric)) {
		$windSpd = (Select-Xml -Content $content -xpath '//wind_mph').Node.InnerText + " mph"
	}
	else {
		$windSpd = (Select-Xml -Content $content -xpath '//wind_kph').Node.InnerText + " kph"
	}
	$windGust = ""
	if (!($inMetric)) {
		$windGust = (Select-Xml -Content $content -xpath '//wind_gust_mph').Node.InnerText + " mph"
	}
	else {
		$windGust = (Select-Xml -Content $content -xpath '//wind_gust_kph').Node.InnerText + " kph"
	}
	$windString = "Winds from the $windDir at $windSpd (gusts of $windGust)"
	
	# Get the relative humidity
	$humidity = (Select-Xml -Content $content -xpath '//relative_humidity').Node.InnerText
	
	# Get the barometric pressure and it's trending direction (into one string)
	$pressure = ""
	if (!($inMetric)) {
		$pressure = (Select-Xml -Content $content -xpath '//pressure_in').Node.InnerText + " in"
	}
	else {
		$pressure = (Select-Xml -Content $content -xpath '//pressure_mb').Node.InnerText + " mb"
	}
	if ((Select-Xml -Content $content -xpath '//pressure_trend').Node.InnerText -eq "-") {
		$pressure += ", trending down"
	}
	else {
		$pressure += ", trending up"
	}
	
	# Get the dewpoint temperature
	$dewPoint = ""
	if (!($inMetric)) {
		$dewPoint = (Select-Xml -Content $content -xpath '//dewpoint_f').Node.InnerText + " F"
	}
	else {
		$dewPoint = (Select-Xml -Content $content -xpath '//dewpoint_c').Node.InnerText + " C"
	}
	
	# Get the heat index
	$heatIndex = "NA"
	if (!($inMetric)) {
		if ((Select-Xml -Content $content -xpath '//heat_index_f').Node.InnerText -ne "NA") {
			$heatIndex = (Select-Xml -Content $content -xpath '//heat_index_f').Node.InnerText + " F"
		}
	}
	else {
		if ((Select-Xml -Content $content -xpath '//heat_index_c').Node.InnerText -ne "NA") {
			$heatIndex = (Select-Xml -Content $content -xpath '//heat_index_c').Node.InnerText + " C"
		}
	}
	
	# Get the windchill 
	$windChill = "NA"
	if (!($inMetric)) {
		if ((Select-Xml -Content $content -xpath '//windchill_f').Node.InnerText -ne "NA") {
			$windChill = (Select-Xml -Content $content -xpath '//windchill_f').Node.InnerText + " F"
		}
	}
	else {
		if ((Select-Xml -Content $content -xpath '//windchill_c').Node.InnerText -ne "NA") {
			$windChill = (Select-Xml -Content $content -xpath '//windchill_c').Node.InnerText + " C"
		}
	}
	
	# Get the temperature adjusted for windchill or heat index
	<# $feelsLike = ""
	if (!($inMetric)) {
		$feelsLike = (Select-Xml -Content $content -xpath '//feelslike_f').Node.InnerText + " F"
	}
	else {
		$feelsLike = (Select-Xml -Content $content -xpath '//feelslike_c').Node.InnerText + " C"
	} #>
	
	# Get the precipitation so far today
	$precip = "0"
	if (!($inMetric)) {
		if ((Select-Xml -Content $content -xpath '//precip_today_in').Node.InnerText -ne "") {
			$precip = (Select-Xml -Content $content -xpath '//precip_today_in').Node.InnerText
		}
		$precip = "$precip in"
	}
	else {
		if ((Select-Xml -Content $content -xpath '//precip_today_metric').Node.InnerText -ne "") {
			$precip = (Select-Xml -Content $content -xpath '//precip_today_metric').Node.InnerText
		}
		$precip = "$precip mm"
	}
	
	# Get the precipitation so far today
	$visib = ""
	if (!($inMetric)) {
		$visib = (Select-Xml -Content $content -xpath '//visibility_mi').Node.InnerText + " mi"
	}
	else {
		$visib = (Select-Xml -Content $content -xpath '//visibility_km').Node.InnerText + " km"
	}
	
	# Generate the weather object
	$weather = New-Object -TypeName PSObject
	$weather |Add-Member -MemberType NoteProperty -Name Location -Value $location -PassThru |
		Add-Member -MemberType NoteProperty -Name Station -Value $station -PassThru |
		Add-Member -MemberType NoteProperty -Name Elevation -Value $elevation -PassThru |
		Add-Member -MemberType NoteProperty -Name Time -Value $time -PassThru |
		Add-Member -MemberType NoteProperty -Name Temperature -Value $temp -PassThru |
		Add-Member -MemberType NoteProperty -Name Conditions -Value $sky -PassThru |
		Add-Member -MemberType NoteProperty -Name Wind -Value $windString -PassThru |
		Add-Member -MemberType NoteProperty -Name Humidity -Value $humidity -PassThru |
		Add-Member -MemberType NoteProperty -Name Pressure -Value $pressure -PassThru |
		Add-Member -MemberType NoteProperty -Name Dewpoint -Value $dewPoint -PassThru |
		Add-Member -MemberType NoteProperty -Name HeatIndex -Value $heatIndex -PassThru |
		Add-Member -MemberType NoteProperty -Name WindChill -Value $windChill -PassThru |
		#Add-Member -MemberType NoteProperty -Name FeelsLike -Value $feelsLike -PassThru |
		Add-Member -MemberType NoteProperty -Name Precipitation -Value $precip -PassThru |
		Add-Member -MemberType NoteProperty -Name Visibility -Value $visib
		
	return $weather
}

<#
.SYNOPSIS
	Retrieve the weather forecast for the provided location from the Weather Underground HTTP web API.
.DESCRIPTION
	This function requires a string input for the location and there is an optional switch to retrieve the data in metric units. Imperial units are used by default. You can retrieve an API key from: "http://www.wunderground.com/weather/api", just sign up for a free account. The free key provides 2500 queries per day.
   
	~@Author:	Chris Ryan
	@FeDate:	November 18th, 2015
	@LeDate:	November 19th, 2015
.EXAMPLE
	Get-WeatherForecast "Portland, OR"
	
	This command 
.LINK
	Get-WeatherCurrent
.ROLE
	Public~h_key~h_inMetric
#>
Function Get-WeatherForecast {
	Param(
		[CmdletBinding()]
		[Parameter(Mandatory=$true,Position=0)]
		[alias("l")]
		[string]
		$location,
		
		[Parameter(Mandatory=$true,Position=1)]
		[alias("k")]
		[string]
		$key,
		
		[Parameter()]
		[Switch]
		$inMetric
	)
	# Invoke web request and retrieve the xml content
	$webpage = ""
	$Error.Clear()
	$ErrorActionPreference = "SilentlyContinue"
	try {
		$webpage = Invoke-WebRequest "https://api.wunderground.com/api/$key/forecast/q/$location.xml" -UseBasicParsing
	}
	catch {
		$ErrorActionPreference = "Continue"
		Write-Error "Unable to complete web call! Check internet connection."
		$errorMsg = $Error[0].Exception.Message
		Break
	}
	
	$content = $webpage.Content
	
	# Check if an error was found from the api request
	if (Select-Xml -Content $content -xpath '//error') {
		$errorType = (Select-Xml -Content $content -xpath '//error/type').node.InnerText.ToUpper()
		$errorMsg = (Select-Xml -Content $content -xpath '//error/description').node.InnerText
		Write-Error "Error during data retrieval"
		Write-Verbose "$errorType - $errorMsg"
		break
	}
	
	# Check if useful data was actually retrieved
	if (!(Select-Xml -Content $content -xpath '//forecast')) {
		Write-Error "Invalid data returned! Try changing the location."
		break
	}
	
	# Extract the forecast information for each day
	$dayOfWeek = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/date/weekday').node.InnerText
	$month = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/date/month').node.InnerText
	$day = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/date/day').node.InnerText
	$year = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/date/year').node.InnerText
	$dateString = @(0) * $dayOfWeek.Count		# initialize the array as the size of forecast days
	for ($i = 0; $i -lt $dayOfWeek.Count; $i++) {
		$dateString[$i] = "$($dayOfWeek[$i]), $($month[$i])/$($day[$i])/$($year[$i])"
	}
	
	# Get the date and time the forecast was retrieved
	$dateRet = (Select-Xml -Content $content -xpath '//txt_forecast/date').node.InnerText
	$dateRet = "$($dateString[0]), $dateRet"
	
	# Get the high and low temperatures
	$high = @(0) * $dayOfWeek.Count
	if (!($inMetric)) {
		$high = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/high/fahrenheit').node.InnerText
	}
	else {
		$high = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/high/celsius').node.InnerText
	}
	$low = @(0) * $dayOfWeek.Count
	if (!($inMetric)) {
		$low = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/low/fahrenheit').node.InnerText
	}
	else {
		$low = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/low/celsius').node.InnerText
	}
	for ($i = 0; $i -lt $high.Count; $i++) {
		if (!($inMetric)) {
			$high[$i] = "$($high[$i]) F"
			$low[$i] = "$($low[$i]) F"
		}
		else {
			$high[$i] = "$($high[$i]) C"
			$low[$i] = "$($low[$i]) C"
		}
	}
	
	# Get the weather conditions
	$conditions = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/conditions').node.InnerText
	
	# Get the precipitation and snow quantities for each day
	$precip = @(0) * $dayOfWeek.Count
	if (!($inMetric)) {
		$precip = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/qpf_allday/in').node.InnerText
	}
	else {
		$precip = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/qpf_allday/mm').node.InnerText
	}
	$snow = @(0) * $dayOfWeek.Count
	if (!($inMetric)) {
		$snow = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/snow_allday/in').node.InnerText
	}
	else {
		$snow = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/snow_allday/cm').node.InnerText
	}
	for ($i = 0; $i -lt $precip.Count; $i++) {
		if (!($inMetric)) {
			$precip[$i] = "$($precip[$i]) in"
			$snow[$i] = "$($snow[$i]) in"
		}
		else {
			$precip[$i] = "$($precip[$i]) mm"
			$snow[$i] = "$($snow[$i]) cm"
		}
	}
	
	# Get the wind forecast, average and gusts and direction
	$wind = @(0) * $dayOfWeek.Count
	$windDir = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/avewind/dir').node.InnerText
	$avgWind = @()
	if (!($inMetric)) {
		$avgWind = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/avewind/mph').node.InnerText
	}
	else {
		$avgWind = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/avewind/kph').node.InnerText
	}
	$maxWind = @()
	if (!($inMetric)) {
		$maxWind = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/maxwind/mph').node.InnerText
	}
	else {
		$maxWind = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/maxwind/kph').node.InnerText
	}
	for ($i = 0; $i -lt $dayOfWeek.Count; $i++) {
		if (!($inMetric)) {
			$wind[$i] = "$($windDir[$i]) winds averaging $($avgWind[$i]) mph (gusts at $($maxWind[$i]) mph)"
		}
		else {
			$wind[$i] = "$($windDir[$i]) winds averaging $($avgWind[$i]) kph (gusts at $($maxWind[$i]) kph)"
		}
	}
	
	# Get the average humidity for each day
	$avgHumid = (Select-Xml -Content $content -xpath '//simpleforecast/forecastdays/forecastday/avehumidity').node.InnerText
	for ($i = 0; $i -lt $dayOfWeek.Count; $i++) {
		$avgHumid[$i] = "$($avgHumid[$i])%"
	}
	
	# Get the daytime and nighttime info strings (should be twice the number of days, 8)
	$infoStrings = @(0) * $dayOfWeek.Count
	if (!($inMetric)) {
		$infoStrings = (Select-Xml -Content $content -xpath '//txt_forecast/forecastdays/forecastday/fcttext').node.InnerText
	}
	else {
		$infoStrings = (Select-Xml -Content $content -xpath '//txt_forecast/forecastdays/forecastday/fcttext_metric').node.InnerText
	}
	$dayStrings = @(0) * $dayOfWeek.Count
	$nightStrings = @(0) * $dayOfWeek.Count
	for ($i = 0; $i -lt $dayOfWeek.Count; $i++) {
		$dayStrings[$i] = $infoStrings[2 * $i]
		$nightStrings[$i] = $infoStrings[2 * $i + 1]
	}
	
	# Generate the forecast objects
	$forecastArray = @(0) * $dayOfWeek.Count
	for ($i = 0; $i -lt $dayOfWeek.Count; $i++) {
		$forecast = New-Object -TypeName PSObject
		$forecast |Add-Member -MemberType NoteProperty -Name Location -Value $location -PassThru |
			Add-Member -MemberType NoteProperty -Name Date -Value $dateString[$i] -PassThru |
			Add-Member -MemberType NoteProperty -Name High -Value $high[$i] -PassThru |
			Add-Member -MemberType NoteProperty -Name Low -Value $low[$i] -PassThru |
			Add-Member -MemberType NoteProperty -Name Conditions -Value $conditions[$i] -PassThru |
			Add-Member -MemberType NoteProperty -Name Wind -Value $wind[$i] -PassThru |
			Add-Member -MemberType NoteProperty -Name Humidity -Value $avgHumid[$i] -PassThru |
			Add-Member -MemberType NoteProperty -Name Precipitation -Value $precip[$i] -PassThru |
			Add-Member -MemberType NoteProperty -Name Snow -Value $snow[$i] -PassThru |
			Add-Member -MemberType NoteProperty -Name Day -Value $dayStrings[$i] -PassThru |
			Add-Member -MemberType NoteProperty -Name Night -Value $nightStrings[$i] -PassThru |
			Add-Member -MemberType NoteProperty -Name Updated -Value $dateRet
		$forecastArray[$i] = $forecast
	}
		
	return $forecastArray
}