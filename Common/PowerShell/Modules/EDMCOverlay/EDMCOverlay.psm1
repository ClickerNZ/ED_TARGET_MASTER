# EDMCOverlay.psm1
#
# Persistent TCP helper for EDMCOverlay.
# Protocol: one-line JSON over TCP 127.0.0.1:5010, UTF-8 encoded, terminated with LF.

$script:EDMCOverlayClient = $null
$script:EDMCOverlayStream = $null
$script:EDMCOverlayServer = "127.0.0.1"
$script:EDMCOverlayPort = 5010
$script:EDMCOverlayLogPath = Join-Path -Path $env:TEMP -ChildPath "EDMCOverlay-Test.log"

function Test-EDMCOverlayConnected {
    if ($null -eq $script:EDMCOverlayClient) { return $false }
    if ($null -eq $script:EDMCOverlayStream) { return $false }
    if (-not $script:EDMCOverlayClient.Connected) { return $false }
    return $true
}

function Connect-EDMCOverlay {
    param(
        [string]$Server = "127.0.0.1",
        [int]$Port = 5010
    )

    $script:EDMCOverlayServer = $Server
    $script:EDMCOverlayPort = $Port

    if (Test-EDMCOverlayConnected) {
        return $true
    }

    Disconnect-EDMCOverlay

    try {
        $script:EDMCOverlayClient = New-Object System.Net.Sockets.TcpClient
        $script:EDMCOverlayClient.NoDelay = $true
        $script:EDMCOverlayClient.Connect($script:EDMCOverlayServer, $script:EDMCOverlayPort)

        $script:EDMCOverlayStream = $script:EDMCOverlayClient.GetStream()

        Write-Host ("[EDMCOverlay] Connected to {0}:{1}" -f $script:EDMCOverlayServer, $script:EDMCOverlayPort) -ForegroundColor DarkCyan
        Add-Content -Path $script:EDMCOverlayLogPath -Value ("[CONNECT] {0} {1}:{2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $script:EDMCOverlayServer, $script:EDMCOverlayPort)

        return $true
    }
    catch {
        Write-Host ("[EDMCOverlay ERROR] Connect failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Add-Content -Path $script:EDMCOverlayLogPath -Value ("[CONNECT ERROR] {0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $_.Exception.Message)

        Disconnect-EDMCOverlay
        return $false
    }
}

function Disconnect-EDMCOverlay {
    try {
        if ($null -ne $script:EDMCOverlayStream) {
            $script:EDMCOverlayStream.Flush()
            $script:EDMCOverlayStream.Close()
        }
    }
    catch {
        # Ignore cleanup errors.
    }

    try {
        if ($null -ne $script:EDMCOverlayClient) {
            $script:EDMCOverlayClient.Close()
        }
    }
    catch {
        # Ignore cleanup errors.
    }

    $script:EDMCOverlayStream = $null
    $script:EDMCOverlayClient = $null
}

function Send-EDMCOverlayMessage {
    param(
        [string]$Id = "target-overlay",
        [string]$Text,
        [string]$Color = "yellow",
        [string]$Size = "normal",
        [int]$X = 1500,
        [int]$Y = 720,
        [int]$TTL = 10
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $false
    }

    if (-not (Test-EDMCOverlayConnected)) {
        if (-not (Connect-EDMCOverlay -Server $script:EDMCOverlayServer -Port $script:EDMCOverlayPort)) {
            return $false
        }
    }

    try {
        $msg = @{
            id    = $Id
            color = $Color
            text  = $Text
            size  = $Size
            x     = $X
            y     = $Y
            ttl   = $TTL
        } | ConvertTo-Json -Compress

    #    Write-Host "[EDMCOverlay JSON] $msg" -ForegroundColor Cyan
        Add-Content -Path $script:EDMCOverlayLogPath -Value $msg

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($msg + "`n")
        $script:EDMCOverlayStream.Write($bytes, 0, $bytes.Length)
        $script:EDMCOverlayStream.Flush()

        return $true
    }
    catch {
        Write-Host ("[EDMCOverlay ERROR] Send failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
        Add-Content -Path $script:EDMCOverlayLogPath -Value ("[SEND ERROR] {0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $_.Exception.Message)

        Disconnect-EDMCOverlay
        return $false
    }
}

Export-ModuleMember -Function Connect-EDMCOverlay, Send-EDMCOverlayMessage, Disconnect-EDMCOverlay
