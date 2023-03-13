#
#
#

function Get-LineNumber {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][int]$Index
    )

    $contentsAsLines = Get-Content $Path
    $currentIndex = 0

    for ($i = 0; $i -lt $contentsAsLines.Count; $i++) {
        $endOfLineIndex = $contentsAsLines[$i].Length + $currentIndex + 1;  # NOTE: the newline character must be accounted for between lines

        if ($Index -lt $endOfLineIndex) {
            return $i + 1
        }

        $currentIndex = $endOfLineIndex + 1
    }

    return -1
}

function Search-ForTextAcrossFiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Text,  # TODO: support pattern input
        [Parameter()][string]$FileFilter = "*",
        [Parameter()][switch]$RecurseDisabled,
        [Parameter()][switch]$FirstMatchOnly,
        [Parameter()][switch]$SkipLineNumber
    )

    $escapedText = $Text -replace '([\.\[\][(\)\\])','\$1'
    $pattern = "`n?(.*($escapedText).*)`n"
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    $results = Get-ChildItem -Path $Path -Filter $FileFilter -File -Recurse:$(-not $RecurseDisabled) |
        Select-Object -ExpandProperty FullName |
        ForEach-Object {
            $filePath = $_
            $matchInfo = Get-Content $filePath -Raw |
                Select-String -Pattern $pattern -AllMatches:$(-not $FirstMatchOnly)

            if ($null -ne $matchInfo) {
                $innerResults = $matchInfo.Matches |ForEach-Object {
                    $groups = $_.Groups

                    if ($SkipLineNumber) {
                        return New-Object PSCustomObject -Property @{
                            Line = $groups[1].Value;
                        }
                    }
                    
                    $startLineIndex = $groups[1].Index
                    $innerMatchStartIndex = $groups[2].Index - $startLineIndex
                    $innerMatchLength = $groups[2].Length
                    $lineNumber = Get-LineNumber $filePath $startLineIndex

                    return New-Object PSCustomObject -Property @{
                        Line = $groups[1].Value;
                        StartIndex = $innerMatchStartIndex;
                        EndIndex = $innerMatchStartIndex + $innerMatchLength - 1;
                        LineNumber = $lineNumber;
                    }
                }

                New-Object PSCustomObject -Property @{
                    File = $filePath;
                    Matches = $innerResults;
                }
            }
        }

    $stopwatch.Stop()
    Write-Verbose "Search elapsed time > $($stopwatch.Elapsed.ToString())"

    return $results
}
