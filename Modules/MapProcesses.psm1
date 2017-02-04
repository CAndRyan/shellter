$global:MapProcesses = @{}

function Register-WithMapProcess {
	param(
		[Parameter(ValueFromPipeline = $true)]
        [System.Diagnostics.Process[]]
        $Process
	)
	PROCESS {
		foreach ($proc in $Process) {
			if ($proc.MainWindowHandle -ne $null) {
				$MapProcesses.Add($MapProcesses.Count, @{})
				$MapProcesses[$MapProcesses.Count - 1].Add($proc.ProcessName, $proc)
			}
		}
	}
}

function Start-AndMapProcess {
	param(
		[parameter(Mandatory=$true)]
		[String]
		$Path
	)
	
	Start-Process -FilePath $Path -PassThru |Register-WithMapProcess 
}

function Get-FromMapProcesses {
	param(
		[parameter(Mandatory=$true)]
		[Int]
		$Index
	)
	
	return $MapProcesses[$Index].Values[0]
}

function Start-FromMapProcesses {
	param(
		[parameter(Mandatory=$true)]
		[Int]
		$Index
	)
	
	(Get-FromMapProcesses -Index $Index).Start()
}

function Stop-FromMapProcesses {
	param(
		[parameter(Mandatory=$true)]
		[Int]
		$Index
	)
	
	(Get-FromMapProcesses -Index $Index).Kill()
}
