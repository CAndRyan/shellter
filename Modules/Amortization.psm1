#
#
#

function Get-Amortization {
	param(
		[Parameter(Mandatory=$true)]
		[decimal]
		$LoanAmount,
		
		[Parameter(Mandatory=$true)]
		[decimal]
		$Apr,
		
		[Parameter(Mandatory=$true)]
		[ValidateSet("daily", "monthly", "yearly")]
		[string]
		$Compounded,
		
		[Parameter(Mandatory=$true, HelpMessage="Enter an amount to be paid 12 times per year")]
		[decimal]
		$MonthlyPayment
	)
	BEGIN {
		$evalsPerYear = 0
		switch ($Compounded) {
			"daily" { $evalsPerYear = 365 }
			"monthly" { $evalsPerYear = 12 }
			"yearly" { $evalsPerYear = 1 }
			default { throw "Invalid Compounded value" }
		}
		
		$rate = $($Apr / 100 / $evalsPerYear)
		
		$amortization = New-Object -TypeName PSCustomObject
		$amortization |Add-Member -MemberType NoteProperty -Name Principal -Value $LoanAmount -PassThru |
			Add-Member -MemberType NoteProperty -Name Apr -Value $Apr -PassThru |
			Add-Member -MemberType NoteProperty -Name MonthlyPayment -Value $MonthlyPayment -PassThru |
			Add-Member -MemberType NoteProperty -Name CompoundRate -Value $rate -PassThru |
			Add-Member -MemberType NoteProperty -Name Schedule -Value $null -PassThru |
			Add-Member -MemberType NoteProperty -Name TotalCost -Value 0 -PassThru |
			Add-Member -MemberType NoteProperty -Name TotalInterest -Value 0 -PassThru |
			Add-Member -MemberType NoteProperty -Name TotalDays -Value 0
		
		
		$schedule = New-Object -TypeName System.Collections.Generic.List[PSCustomObject]
		$principalLeft = $LoanAmount
		$days = 0
	}
	PROCESS {
		$interestToPay = 0
		
		while($principalLeft -gt $MonthlyPayment) {
			$days++
			$interest = $rate * $principalLeft
			$principalLeft = $principalLeft + $interest
			$interestToPay = $interestToPay + $interest
			
			if ($days % 30 -eq 0) {
				$principalLeft = $principalLeft - $MonthlyPayment
				
				$obj = New-Object -TypeName PSCustomObject
				$obj |Add-Member -MemberType NoteProperty -Name Principal -value $($MonthlyPayment - $interestToPay) -PassThru |
					Add-Member -MemberType NoteProperty -Name Interest -value $interestToPay -PassThru |
					Add-Member -MemberType NoteProperty -Name Balance -value $principalLeft -PassThru |
					Add-Member -MemberType NoteProperty -Name Day -value $days
				
				$schedule.Add($obj)
				$interestToPay = 0
			}
		}
		
		$final = New-Object -TypeName PSCustomObject
		$final |Add-Member -MemberType NoteProperty -Name Principal -value $principalLeft -PassThru |
			Add-Member -MemberType NoteProperty -Name Interest -value 0 -PassThru |
			Add-Member -MemberType NoteProperty -Name Balance -value 0 -PassThru |
			Add-Member -MemberType NoteProperty -Name Day -value $days
		
		$schedule.Add($final)
	}
	END {
		$amortization.TotalCost = ($days / 30) * $MonthlyPayment + $principalLeft
		$amortization.TotalInterest = $amortization.TotalCost - $LoanAmount
		$amortization.TotalDays = $days
		$amortization.Schedule = $schedule
		
		return $amortization
	}
}
