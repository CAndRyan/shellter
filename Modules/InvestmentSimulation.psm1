#
#
#

function Get-InvestmentSimulationDefault {
    param (
        [Parameter(
            Mandatory=$true,
            HelpMessage="The initial investment balance (at beginning of initial year)"
        )]
        [decimal]
        $InitialBalance,

        [Parameter(
            Mandatory=$true,
            HelpMessage="The contribution amount per inflow"
        )]
        [decimal]
        $Contribution,

        [Parameter(
            Mandatory=$true,
            HelpMessage="The annual interest rate (in %)"
        )]
		[decimal]
		$GrowthRate,
        
        [Parameter(
            Mandatory=$true,
            HelpMessage="The number of years to simulate"
        )]
		[int]
		$NumberOfYears
    )

    return Get-InvestmentSimulation -InitialBalance $InitialBalance `
        -Contribution $Contribution `
        -GrowthRate $GrowthRate `
        -StartYear $(Get-Date |Select-Object -ExpandProperty Year) `
        -NumberOfYears $NumberOfYears `
        -ContributionSchedule "bimonthly" `
        -Compounded "daily"
}

function Get-InvestmentSimulation {
    param (
        [Parameter(
            Mandatory=$true,
            HelpMessage="The initial investment balance (at beginning of initial year)"
        )]
        [decimal]
        $InitialBalance,

        [Parameter(
            Mandatory=$true,
            HelpMessage="The contribution amount per inflow"
        )]
        [decimal]
        $Contribution,

        [Parameter(
            Mandatory=$true,
            HelpMessage="The annual interest rate (in %)"
        )]
		[decimal]
		$GrowthRate,
        
        [Parameter(
            Mandatory=$true,
            HelpMessage="The initial investment year"
        )]
		[int]
		$StartYear,

        [Parameter(
            Mandatory=$true,
            HelpMessage="The number of years to simulate"
        )]
		[int]
		$NumberOfYears,
		
        [Parameter(
            Mandatory=$true,
            HelpMessage="The contribution schedule"
        )]
		[ValidateSet("bimonthly", "monthly", "yearly")]
		[string]
        $ContributionSchedule,

		[Parameter(Mandatory=$true)]
		[ValidateSet("daily", "monthly", "yearly")]
		[string]
        $Compounded
    )
    BEGIN {
        $evalsPerYear = 0
		switch ($Compounded) {
			"daily" { $evalsPerYear = 365 }
			"monthly" { $evalsPerYear = 12 }
			"yearly" { $evalsPerYear = 1 }
			default { throw "Invalid Compounded value" }
		}
		
        $rate = $($GrowthRate / 100 / $evalsPerYear)
        
        $simulation = New-Object -TypeName PSCustomObject
		$simulation |Add-Member -MemberType NoteProperty -Name Balance -Value $InitialBalance -PassThru |
			Add-Member -MemberType NoteProperty -Name GrowthRate -Value $GrowthRate -PassThru |
			Add-Member -MemberType NoteProperty -Name Contribution -Value $Contribution -PassThru |
			Add-Member -MemberType NoteProperty -Name ContributionSchedule -Value $ContributionSchedule -PassThru |
			Add-Member -MemberType NoteProperty -Name CompoundRate -Value $rate -PassThru |
			Add-Member -MemberType NoteProperty -Name Compounded -Value $Compounded -PassThru |
			Add-Member -MemberType NoteProperty -Name Schedule -Value $null -PassThru |
			Add-Member -MemberType NoteProperty -Name FinalBalance -Value 0 -PassThru |
			Add-Member -MemberType NoteProperty -Name TotalInterest -Value 0 -PassThru |
			Add-Member -MemberType NoteProperty -Name StartYear -Value $StartYear -PassThru |
			Add-Member -MemberType NoteProperty -Name FinalYear -Value 0
		
		
		$schedule = New-Object -TypeName System.Collections.Generic.List[PSCustomObject]
		$balance = $InitialBalance
		$days = 0
        $interestAccrued = 0
        $currentYear = $StartYear
    }
    PROCESS {
		while ($currentYear -le $MonthlyPayment) {
			$days++
			$interest = $rate * $balance
			$balance = $balance + $interest
			$interestAccrued = $interestAccrued + $interest
			
			if ($days % 30 -eq 0) {
				$balance = $balance + $Contribution
            }
            
            if ($days % 365 -eq 0) {
                $currentYear++
				
				$obj = New-Object -TypeName PSCustomObject
                    Add-Member -MemberType NoteProperty -Name Balance -value $balance -PassThru |
					Add-Member -MemberType NoteProperty -Name Interest -value $interest -PassThru |
					Add-Member -MemberType NoteProperty -Name Year -value $currentYear
				
				$schedule.Add($obj)
				$interest = 0
            }
		}
		
		$final = New-Object -TypeName PSCustomObject
		$final |Add-Member -MemberType NoteProperty -Name Principal -value $balance -PassThru |
			Add-Member -MemberType NoteProperty -Name Interest -value 0 -PassThru |
			Add-Member -MemberType NoteProperty -Name Balance -value 0 -PassThru |
			Add-Member -MemberType NoteProperty -Name Day -value $days
		
		$schedule.Add($final)
    }
    END {
        $simulation.FinalBalance = $balance
		$simulation.TotalInterest = $interestAccrued
		$simulation.FinalYear = $currentYear
		$simulation.Schedule = $schedule
		
		return $simulation
    }
}
