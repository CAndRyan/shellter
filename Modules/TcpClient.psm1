
function New-TcpConnection {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [string]
        $HostName,

        [parameter(Mandatory=$true)]
        [string]
        $Port,

        [parameter()]
        [switch]
        $NoKeepAlive
    )

    $tcpClient = New-Object -TypeName System.Net.Sockets.TcpClient
    $tcpClient.Client.SetSocketOption([System.Net.Sockets.SocketOptionLevel]::Socket, [System.Net.Sockets.SocketOptionName]::KeepAlive, $(-not $NoKeepAlive))
    $tcpClient.Connect($HostName, $Port)

    return $tcpClient
}

function Close-TcpConnection {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.Net.Sockets.TcpClient]
        $Client
    )

    $Client.Close()
}

function Redo-TcpConnection {
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.Net.Sockets.TcpClient]
        $Client
    )

    if (($Client.Client -ne $null) -and $(Client.Client.RemoteEndPoint -ne $null)) {
        $Client.Connect($Client.Client.RemoteEndPoint)
    }
    # else {
    #     Write-Verbose "Unable"
    # }
}
