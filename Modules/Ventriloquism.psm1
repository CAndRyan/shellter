Function Invoke-ThrowCommand {
    param(
        [Parameter(Mandatory=$true)]
        [ScriptBlock]
        $Command,

        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]
        $Location
    )

    Push-Location $Location

    try {
        Invoke-Command -ScriptBlock $Command
    } catch {
        throw $_
    } finally {
        Pop-Location
    }
}
