# http://windowsitpro.com/powershell/take-control-powershell-consoles-colors

function Get-Color {
	param([Switch] $Table)

	# If -table exists, output a color list.
	if ($Table) {
	  for ($bg = 0; $bg -lt 0x10; $bg++) {
		for ($fg = 0; $fg -lt 0x10; $fg++) {
		  Write-Host -nonewline -background $bg -foreground $fg `
			(" {0:X}{1:X} " -f $bg,$fg)
		}
		Write-Host
	  }
	  #exit
	}

	# Output the current colors as a string.
	" {0:X}{1:X} " -f [Int] $HOST.UI.RawUI.BackgroundColor,
	  [Int] $HOST.UI.RawUI.ForegroundColor
}

function Set-Color {
	param([String] $Color = $(throw "Please specify a color."))

	# Trap the error and exit the script if the user
	# specified an invalid parameter.
	trap [System.Management.Automation.RuntimeException] {
	  Write-Error -errorrecord $ERROR[0]
	  #exit
	}

	# Assume -color specifies a hex value and cast it to a [Byte].
	$newcolor = [Byte] ("0x{0}" -f $Color)
	# Split the color into background and foreground colors. The 
	# [Math]::Truncate method returns a [Double], so cast it to an [Int].
	$bg = [Int] [Math]::Truncate($newcolor / 0x10)
	$fg = $newcolor -band 0xF

	# If the background and foreground colors match, throw an error;
	# otherwise, set the colors.
	if ($bg -eq $fg) {
	  Write-Error "The background and foreground colors must not match."
	} else {
	  $HOST.UI.RawUI.BackgroundColor = $bg
	  $HOST.UI.RawUI.ForegroundColor = $fg
	}
}