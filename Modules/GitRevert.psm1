#
# GitRevert.psm1
#

function Get-GitRevertCommit {
	param(
		[Parameter(Mandatory=$true)]
		[string]
		$CommitHashToRevert
	)
	BEGIN {
		$fileDetails = Get-GitCommitStatus -CommitHash $CommitHashToRevert
	}
	PROCESS {
		foreach ($detail in $fileDetails) {
			if ($detail.Status -eq "M") {
				& git checkout "$CommitHashToRevert~1" -- "`"$($detail.Path)`""
			}
			elseif ($detail.Status -eq "A") {
				Remove-Item -Path $detail.Path
			}
		}
	}
	END {
		#
	}
}

function Get-GitCommitStatus {
	param(
		[Parameter(Mandatory=$true)]
		[string]
		$CommitHash,

		[Parameter()]
		[switch]
		$NamesOnly
	)
	BEGIN {
		$files = New-Object -TypeName System.Collections.Generic.List[PSCustomObject]
		$command = "& git diff-tree --no-commit-id"

		if ($NamesOnly) {
			$command += " --name-only"
		}
		else {
			$command += " --name-status"
		}

		$command += " -r $CommitHash"
	}
	PROCESS {
		$data = Invoke-Expression -Command $command 

		foreach ($line in $data) {
			$file = New-Object -TypeName PSCustomObject

			if ($NamesOnly) {
				$file |Add-Member -MemberType NoteProperty -Name Status -Value "?" -PassThru |
					Add-Member -MemberType NoteProperty -Name Path -Value $line.Replace("/", "\")
			}
			else {
				$file |Add-Member -MemberType NoteProperty -Name Status -Value $line[0] -PassThru |
					Add-Member -MemberType NoteProperty -Name Path -Value $line.Substring(1).TrimStart().Replace("/", "\")
			}

			$files.Add($file)
		}
	}
	END {
		return $files
	}
}
