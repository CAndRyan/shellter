#
#
#

function Get-InvestmentSimulation {
    param (
        [Parameter(
            Mandatory=$true,
            HelpMessage="The initial investment balance"
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
            HelpMessage="The final day to simulate"
        )]
		[DateTime]
		$EndOfSimulation,
		
        [Parameter(
            Mandatory=$false,
            HelpMessage="The initial investment day"
        )]
		[DateTime]
		$StartOfSimulation = $(Get-Date),

        [Parameter(
            Mandatory=$false,
            HelpMessage="The contribution schedule"
        )]
		[ValidateSet("bimonthly", "monthly", "yearly")]
		[string]
        $ContributionSchedule = "bimonthly",

		[Parameter(Mandatory=$false)]
		[ValidateSet("daily", "monthly", "yearly")]
		[string]
        $Compounded = "yearly"
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
			Add-Member -MemberType NoteProperty -Name Schedule -Value $(New-Object -TypeName System.Collections.Generic.List[PSCustomObject]) -PassThru |
			Add-Member -MemberType NoteProperty -Name FinalBalance -Value $InitialBalance -PassThru |
			Add-Member -MemberType NoteProperty -Name TotalInterest -Value 0 -PassThru |
			Add-Member -MemberType NoteProperty -Name StartOfSimulation -Value $StartOfSimulation -PassThru |
			Add-Member -MemberType NoteProperty -Name EndOfSimulation -Value $EndOfSimulation
		
        $currentDate = $StartOfSimulation
    }
    PROCESS {
		while ($currentDate -le $EndOfSimulation) {
            $currentDate = $currentDate.AddDays(1)
            $interest = 0
            $balanceChanged = $false
            
            # Accrue interest
            if ($Compounded -eq "daily" -or 
                ($Compounded -eq "monthly" -and $currentDate.Day -eq 1)  -or
                ($Compounded -eq "yearly" -and $currentDate.Month -eq 1 -and $currentDate.Day -eq 1))
            {
                $interest = $rate * $simulation.FinalBalance
                $simulation.FinalBalance += $interest
                $simulation.TotalInterest += $interest
                $balanceChanged = $true
            }
            
            # Apply contribution
            if (($ContributionSchedule -eq "yearly" -and $currentDate.Month -eq 1 -and $currentDate.Day -eq 1) -or
                ($ContributionSchedule -eq "monthly" -and $currentDate.Day -eq 1) -or
                ($ContributionSchedule -eq "bimonthly" -and ($currentDate.Day -eq 1 -or $currentDate.Day -eq 15)))
            {
                $simulation.FinalBalance += $Contribution
                $balanceChanged = $true
            }
            
            # Update schedule if a change was made
            if ($balanceChanged) {
				$obj = New-Object -TypeName PSCustomObject
                $obj |Add-Member -MemberType NoteProperty -Name Balance -value $([System.Math]::Round($simulation.FinalBalance, 2)) -PassThru |
					Add-Member -MemberType NoteProperty -Name InterestAccrued -value $([System.Math]::Round($interest, 2)) -PassThru |
					Add-Member -MemberType NoteProperty -Name Contribution -value $Contribution -PassThru |
					Add-Member -MemberType NoteProperty -Name Date -value $currentDate
				
				$simulation.Schedule.Add($obj)
            }
		}
    }
    END {
        $simulation.FinalBalance = [System.Math]::Round($simulation.FinalBalance, 2)
        $simulation.TotalInterest = [System.Math]::Round($simulation.TotalInterest, 2)

		return $simulation
    }
}

function Find-DesiredInvestmentContribution {
    param (
        [Parameter(
            Mandatory=$true,
            HelpMessage="The desired balance at the end of the simulation"
        )]
        [decimal]
        $DesiredBalance,

        [Parameter(
            Mandatory=$true,
            HelpMessage="The initial investment balance"
        )]
        [decimal]
        $InitialBalance,

        [Parameter(
            Mandatory=$true,
            HelpMessage="The annual interest rate (in %)"
        )]
		[decimal]
		$GrowthRate,
        
        [Parameter(
            Mandatory=$true,
            HelpMessage="The final day to simulate"
        )]
		[DateTime]
		$EndOfSimulation,
		
        [Parameter(
            Mandatory=$false,
            HelpMessage="The initial investment day"
        )]
		[DateTime]
		$StartOfSimulation = $(Get-Date),

        [Parameter(
            Mandatory=$false,
            HelpMessage="The contribution schedule"
        )]
		[ValidateSet("bimonthly", "monthly", "yearly")]
		[string]
        $ContributionSchedule = "bimonthly",

		[Parameter(Mandatory=$false)]
		[ValidateSet("daily", "monthly", "yearly")]
		[string]
        $Compounded = "yearly",
        
        [Parameter(
            Mandatory=$false,
            HelpMessage="The intial contribution to solve from"
        )]
        [ValidateScript({$_ -ge 1})]
        [decimal]
        $InitialContribution = 100,

        [Parameter(
            Mandatory=$false,
            HelpMessage="The amount to change the contribution by each iteration"
        )]
        [ValidateScript({$_ -ge 1})]
        [decimal]
        $ContributionDelta = 20
    )

    $simulation = $null
    $contribution = $InitialContribution
    $complete = $false
    $previousBalance = $DesiredBalance
    $previousSim = $null
 
    do {
        $simulation = Get-InvestmentSimulation -InitialBalance $InitialBalance `
            -GrowthRate $GrowthRate `
            -EndOfSimulation $EndOfSimulation `
            -StartOfSimulation $StartOfSimulation `
            -ContributionSchedule $ContributionSchedule `
            -Compounded $Compounded `
            -Contribution $contribution

        if (($simulation.FinalBalance -eq $DesiredBalance) -or
            ($simulation.FinalBalance -lt $DesiredBalance -and $previousBalance -gt $DesiredBalance) -or
            ($simulation.FinalBalance -gt $DesiredBalance -and $previousBalance -lt $DesiredBalance))
        {
            $complete = $true
            continue
        } elseif ($simulation.FinalBalance -lt $DesiredBalance) {
            $contribution += $ContributionDelta
        } elseif ($simulation.FinalBalance -gt $DesiredBalance) {
            $contribution -= $ContributionDelta
        }

        $previousBalance = $simulation.FinalBalance
        $previousSim = $simulation
    } while (-not $complete)

    if ($simulation.FinalBalance -lt $DesiredBalance) {
        return $previousSim
    } else {
        return $simulation
    }
}
