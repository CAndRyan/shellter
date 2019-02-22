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

    #
}
