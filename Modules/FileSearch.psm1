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

    Get-ChildItem -Path $Path -Filter $FileFilter -File -Recurse:$(-not $RecurseDisabled) |
        Select-Object -ExpandProperty FullName |
        ForEach-Object {
            $filePath = $_
            $matchInfo = Get-Content $filePath -Raw |
                Select-String -Pattern $pattern -AllMatches:$(-not $FirstMatchOnly)

            if ($null -ne $matchInfo) {
                $matches = $matchInfo.Matches |ForEach-Object {
                    $groups = $_.Groups
                    $startLineIndex = $groups[1].Index
                    $innerMatchStartIndex = $groups[2].Index - $startLineIndex
                    $innerMatchLength = $groups[2].Length

                    New-Object PSCustomObject -Property @{
                        Line = $groups[1].Value;
                        StartIndex = $innerMatchStartIndex;
                        EndIndex = $innerMatchStartIndex + $innerMatchLength - 1;
                        LineNumber = $(-not $SkipLineNumber) ? $(Get-LineNumber $filePath $startLineIndex) : $null;
                    }
                }

                New-Object PSCustomObject -Property @{
                    File = $filePath;
                    Matches = $matches;
                }
            }
        }
}
