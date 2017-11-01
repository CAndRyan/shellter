#

$dir = $null
try {
	$split = $args[0].Split(":")
	$dir = $($split[0] + ":" + ($split[1] -replace "/", "\"))
}
catch {
	Write-Error -Message "Invalid argument: $($args[0])"
	Exit 101
}

function Test-FilesForString {
	param(
		[Parameter(Mandatory=$True)]
		[string]
		$GitHooksPath
	)
	BEGIN {
		$repoPath = $(Resolve-Path $(Join-Path $GitHooksPath "..\..\")).Path
		$packagePath = Join-Path $repoPath "packages"
		$appPath = Join-Path $repoPath "app"
	}
	PROCESS {
		$matches = $(Get-ChildItem -Path $packagePath, $appPath -Include *.js -Recurse |
			Select-String -Pattern "^[\s\t]*[/]{0,1}[\s\t]*debugger;")
	}
	END {
		if ($matches.Count -gt 0) {
			foreach ($match in $matches) {
				$match |Out-Default
			}
			
			Exit 100
		}
	
		Exit 0
	}
}

Test-FilesForString -GitHooksPath $dir