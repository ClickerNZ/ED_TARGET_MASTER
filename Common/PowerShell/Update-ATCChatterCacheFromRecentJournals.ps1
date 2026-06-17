# Update-ATCChatterCacheFromRecentJournals.ps1
# PowerShell 5.1 compatible.
#
# Purpose:
#   Top up the ATC chatter WAV cache from the most recent Elite Dangerous journal files.
#   This is intended to be run after a game session to catch any ATC phrases that were
#   not already pregenerated.
#
# What it does:
#   1. Reads the newest Journal*.log files.
#   2. Extracts NPC ReceiveText chatter.
#   3. Uses ATCChatter.psm1 to classify Station / Traffic / Security.
#   4. Generates any missing original Piper WAVs into:
#        C:\Thrustmaster\Common\Piper\ATCChatter
#   5. Generates any missing filtered/radio WAVs into:
#        C:\Thrustmaster\Common\Piper\ATCChatter_Filtered
#
# Runtime playback still uses the filtered folder.

param(
    [string]$JournalFolder = "D:\Users\Den\Saved Games\Frontier Developments\Elite Dangerous",
    [string]$ATCModulePath = "C:\Thrustmaster\Common\PowerShell\Modules\ATCChatter",
    [string]$PiperExePath = "C:\Users\Den\AppData\Local\Programs\Python\Python313\Scripts\piper.exe",
    [string]$PiperModelFolder = "C:\Thrustmaster\Common\Piper\Voices",
    [string]$OriginalCacheFolder = "C:\Thrustmaster\Common\Piper\ATCChatter",
    [string]$FilteredCacheFolder = "C:\Thrustmaster\Common\Piper\ATCChatter_Filtered",
    [string]$FFmpegPath = "ffmpeg.exe",
    [int]$RecentJournalCount = 2,
    [switch]$ForceRaw,
    [switch]$ForceFiltered
)

$ErrorActionPreference = "Stop"

# Keep these aligned with ATCChatter.psm1.
$PiperLengthScale = 1.10
$PiperNoiseScale  = 0.667
$PiperNoiseW      = 0.8

# Keep these aligned with ATCChatter.psm1.
$VoiceGroups = @{
    Station  = @("alan.onnx","alba.onnx","amy.onnx","aru.onnx","barbera.onnx","bill.onnx","bob.onnx","bryce.onnx")
    Security = @("colin.onnx","cori.onnx","danny.onnx","darla.onnx","jenny.onnx","jock.onnx","joe.onnx","kathleen.onnx")
    Traffic  = @("john.onnx","kristin.onnx","kusal.onnx","lessac.onnx","michelle.onnx","norman.onnx","ryan.onnx","semaine.onnx")
}

# Legacy radio filter profile. Current RadioFX filter is embedded in New-FilteredWave.
$RadioFilter = "anoisesrc=color=pink:amplitude=0.25:d=30[noise];[0:a]volume=1.365,highpass=f=320,lowpass=f=850,equalizer=f=1250:t=q:w=1.3:g=5,acompressor=threshold=-22dB:ratio=3:attack=5:release=70[voice];[voice][noise]amix=inputs=2:duration=first:weights=1 0.22"

function Write-Info {
    param([string]$Message, [string]$Color = "Gray")
    Write-Host ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $Message) -ForegroundColor $Color
}

function ConvertTo-ATCSafeFilePartLocal {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return "Unknown" }
    $safe = $Value -replace '[^\w\-]+', '_'
    $safe = $safe.Trim('_')
    if ($safe.Length -gt 32) { $safe = $safe.Substring(0, 32) }
    if ([string]::IsNullOrWhiteSpace($safe)) { return "Unknown" }
    return $safe
}

function Get-ATCTextHashLocal {
    param([string]$Text)
    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $hash = $sha1.ComputeHash($bytes)
        return (($hash | ForEach-Object { $_.ToString("x2") }) -join "")
    }
    finally {
        if ($null -ne $sha1) { $sha1.Dispose() }
    }
}

function Get-ATCCacheFileNameLocal {
    param(
        [string]$Text,
        [string]$Group,
        [string]$Voice
    )

    $spoken = Format-ATCSpokenText -Text $Text
    $keyText = ("Voice={0}|Group={1}|Length={2}|Noise={3}|NoiseW={4}|Text={5}" -f `
        $Voice, $Group, $PiperLengthScale, $PiperNoiseScale, $PiperNoiseW, $spoken)

    $hash = Get-ATCTextHashLocal -Text $keyText
    $groupSafe = ConvertTo-ATCSafeFilePartLocal -Value $Group
    $voiceSafe = ConvertTo-ATCSafeFilePartLocal -Value ([System.IO.Path]::GetFileNameWithoutExtension($Voice))

    return ("ATC_{0}_{1}_{2}.wav" -f $groupSafe, $voiceSafe, $hash.Substring(0, 16))
}

function ConvertTo-CommandLineArgLocal {
    param([string]$Value)
    if ($null -eq $Value) { return '""' }
    $escaped = $Value -replace '\\(?=")', '\' -replace '"', '\"'
    if ($escaped -match '\s|"' -or $escaped.Length -eq 0) { return '"' + $escaped + '"' }
    return $escaped
}

function New-RawPiperWave {
    param(
        [string]$Text,
        [string]$Group,
        [string]$Voice,
        [string]$OutFile
    )

    $modelPath = Join-Path $PiperModelFolder $Voice
    if (-not (Test-Path -LiteralPath $modelPath)) {
        Write-Info ("Missing Piper model: {0}" -f $modelPath) "Red"
        return $false
    }

    $spoken = Format-ATCSpokenText -Text $Text

    $argList = @(
        "--model", $modelPath,
        "--output_file", $OutFile,
        "--length_scale", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:0.###}", [double]$PiperLengthScale)),
        "--noise_scale",  ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:0.###}", [double]$PiperNoiseScale)),
        "--noise_w",      ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:0.###}", [double]$PiperNoiseW))
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $PiperExePath
    $psi.Arguments = (($argList | ForEach-Object { ConvertTo-CommandLineArgLocal $_ }) -join " ")
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    try { $psi.StandardInputEncoding = [System.Text.Encoding]::UTF8 } catch { }

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    try {
        [void]$proc.Start()
        $proc.StandardInput.WriteLine($spoken)
        $proc.StandardInput.Close()
        [void]$proc.StandardOutput.ReadToEnd()
        $stdErr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        if ($proc.ExitCode -ne 0) {
            Write-Info ("Piper failed for [{0}] {1}. ExitCode={2}" -f $Group, $Voice, $proc.ExitCode) "Red"
            if (-not [string]::IsNullOrWhiteSpace($stdErr)) { Write-Info $stdErr "DarkYellow" }
            return $false
        }

        if (-not (Test-Path -LiteralPath $OutFile)) {
            Write-Info ("Piper completed but did not create: {0}" -f $OutFile) "Red"
            return $false
        }

        return $true
    }
    finally {
        try { if ($null -ne $proc) { $proc.Dispose() } } catch { }
    }
}

function New-FilteredWave {
    param(
        [string]$InputFile,
        [string]$OutputFile
    )

    $tmpFile = $OutputFile + ".tmp.wav"

    # Current accepted production profile:
    #   - radio/muffle/static voice profile
    #   - start key-up cue
    #   - +6 dB end squelch
    $FilterComplex = @"
[1:a]highpass=f=500,lowpass=f=3000,afade=t=in:st=0:d=0.008,afade=t=out:st=0.075:d=0.045,volume=0.90,aformat=sample_rates=48000:channel_layouts=mono[start];
anoisesrc=color=pink:amplitude=0.25:d=30[noise];
[0:a]volume=1.365,highpass=f=320,lowpass=f=850,equalizer=f=1250:t=q:w=1.3:g=5,acompressor=threshold=-22dB:ratio=3:attack=5:release=70[voicebase];
[voicebase][noise]amix=inputs=2:duration=first:weights=1 0.22[voice];
[3:a]highpass=f=500,lowpass=f=3000,afade=t=in:st=0:d=0.008,afade=t=out:st=0.075:d=0.045,volume=1.24,aformat=sample_rates=48000:channel_layouts=mono[end];
[start][2:a][voice][end]concat=n=4:v=0:a=1[out]
"@
    $FilterComplex = ($FilterComplex -replace "`r", "" -replace "`n", "" )

    try {
        if (Test-Path -LiteralPath $tmpFile) {
            Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
        }

        & $FFmpegPath `
            -y `
            -hide_banner `
            -loglevel error `
            -i $InputFile `
            -f lavfi `
            -i "anoisesrc=color=pink:amplitude=0.23:d=0.120" `
            -f lavfi `
            -i "anullsrc=r=48000:cl=mono:d=0.045" `
            -f lavfi `
            -i "anoisesrc=color=pink:amplitude=0.23:d=0.120" `
            -filter_complex $FilterComplex `
            -map "[out]" `
            -ar 48000 `
            -ac 1 `
            -sample_fmt s16 `
            $tmpFile

        if ($LASTEXITCODE -ne 0) {
            Write-Info ("FFmpeg failed. ExitCode={0}" -f $LASTEXITCODE) "Red"
            return $false
        }

        if (-not (Test-Path -LiteralPath $tmpFile)) {
            Write-Info "FFmpeg did not create output file." "Red"
            return $false
        }

        Move-Item -LiteralPath $tmpFile -Destination $OutputFile -Force
        return $true
    }
    finally {
        try {
            if (Test-Path -LiteralPath $tmpFile) {
                Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
            }
        } catch { }
    }
}

if (-not (Test-Path -LiteralPath $JournalFolder)) { throw "Journal folder not found: $JournalFolder" }
if (-not (Test-Path -LiteralPath $ATCModulePath)) { throw "ATC module path not found: $ATCModulePath" }
if (-not (Test-Path -LiteralPath $PiperExePath)) { throw "Piper not found: $PiperExePath" }
if (-not (Get-Command $FFmpegPath -ErrorAction SilentlyContinue)) { throw "FFmpeg not found using path: $FFmpegPath" }

if (-not (Test-Path -LiteralPath $OriginalCacheFolder)) { New-Item -ItemType Directory -Path $OriginalCacheFolder -Force | Out-Null }
if (-not (Test-Path -LiteralPath $FilteredCacheFolder)) { New-Item -ItemType Directory -Path $FilteredCacheFolder -Force | Out-Null }

Import-Module $ATCModulePath -Force

$journalFiles = @(Get-ChildItem -LiteralPath $JournalFolder -Filter "Journal*.log" -File -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending |
                  Select-Object -First $RecentJournalCount)

if ($journalFiles.Count -eq 0) {
    Write-Info "No Journal*.log files found." "Yellow"
    return
}

Write-Info ("Scanning newest journal files: {0}" -f $journalFiles.Count) "Cyan"
foreach ($jf in $journalFiles) { Write-Info ("  {0}" -f $jf.Name) "DarkCyan" }

# Unique key = Group + Text
$phrases = @{}
$totalReceiveText = 0
$totalNpc = 0

foreach ($file in $journalFiles) {
    Write-Info ("Reading {0}" -f $file.Name) "DarkGray"
    Get-Content -LiteralPath $file.FullName -ErrorAction Stop | ForEach-Object {
        $line = $_
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        if ($line -notmatch '"event"\s*:\s*"ReceiveText"') { return }

        $entry = $null
        try { $entry = $line | ConvertFrom-Json } catch { return }
        if ($null -eq $entry) { return }
        if (-not ($entry.PSObject.Properties.Name -contains 'event')) { return }
        if ($entry.event -ne "ReceiveText") { return }

        $script:totalReceiveText++

        $channel = ""
        if ($entry.PSObject.Properties.Name -contains 'Channel' -and $null -ne $entry.Channel) {
            $channel = ([string]$entry.Channel).ToLowerInvariant()
        }
        if ($channel -ne "npc") { return }

        $script:totalNpc++

        $text = ""
        if ($entry.PSObject.Properties.Name -contains 'Message_Localised' -and $null -ne $entry.Message_Localised) {
            $text = [string]$entry.Message_Localised
        }
        if ([string]::IsNullOrWhiteSpace($text) -and
            $entry.PSObject.Properties.Name -contains 'Message' -and
            $null -ne $entry.Message) {
            $text = [string]$entry.Message
        }
        if ([string]::IsNullOrWhiteSpace($text)) { return }

        $from = ""
        if ($entry.PSObject.Properties.Name -contains 'From' -and $null -ne $entry.From) { $from = [string]$entry.From }
        if ([string]::IsNullOrWhiteSpace($from)) { return }

        $msgCode = ""
        if ($entry.PSObject.Properties.Name -contains 'Message' -and $null -ne $entry.Message) { $msgCode = [string]$entry.Message }
        if (($msgCode -eq '$STATION_NoFireZone_entered;') -or
            ($msgCode -eq '$STATION_NoFireZone_exited;') -or
            ($msgCode -eq '$STATION_docking_granted;')) {
            return
        }

        $group = Get-ATCGroupForNpcReceiveText -entry $entry
        if ([string]::IsNullOrWhiteSpace($group)) { $group = "Traffic" }

        if (($group -eq "Traffic") -and (($text -like "CMDR Clicker*") -or ($text -like "CMDR 2Dogs*"))) {
            return
        }

        $key = $group + "|" + $text
        if (-not $phrases.ContainsKey($key)) {
            $phrases[$key] = [ordered]@{
                Group = $group
                Text = $text
                From = $from
                FirstSeenFile = $file.Name
            }
        }
    }
}

Write-Info ("ReceiveText events    : {0}" -f $totalReceiveText) "Yellow"
Write-Info ("NPC ReceiveText events: {0}" -f $totalNpc) "Yellow"
Write-Info ("Unique ATC phrases    : {0}" -f $phrases.Count) "Yellow"

if ($phrases.Count -eq 0) {
    Write-Info "No ATC phrases found to top up." "Yellow"
    return
}

$manifest = New-Object System.Collections.ArrayList
$done = 0
$rawCreated = 0
$rawSkipped = 0
$filteredCreated = 0
$filteredSkipped = 0
$failed = 0

foreach ($item in $phrases.Values) {
    $done++
    $group = [string]$item.Group
    $text = [string]$item.Text
    if (-not $VoiceGroups.ContainsKey($group)) { $group = "Traffic" }

    Write-Info ("[{0}/{1}] {2}: {3}" -f $done, $phrases.Count, $group, $text) "Cyan"

    foreach ($voice in @($VoiceGroups[$group])) {
        $fileName = Get-ATCCacheFileNameLocal -Text $text -Group $group -Voice $voice
        $rawFile = Join-Path $OriginalCacheFolder $fileName
        $filteredFile = Join-Path $FilteredCacheFolder $fileName

        try {
            if ($ForceRaw -or (-not (Test-Path -LiteralPath $rawFile))) {
                if (New-RawPiperWave -Text $text -Group $group -Voice $voice -OutFile $rawFile) {
                    $rawCreated++
                } else {
                    $failed++
                    continue
                }
            } else {
                $rawSkipped++
            }

            if ($ForceFiltered -or (-not (Test-Path -LiteralPath $filteredFile))) {
                if (New-FilteredWave -InputFile $rawFile -OutputFile $filteredFile) {
                    $filteredCreated++
                } else {
                    $failed++
                    continue
                }
            } else {
                $filteredSkipped++
            }

            [void]$manifest.Add([pscustomobject]@{
                Group = $group
                Text = $text
                From = [string]$item.From
                FirstSeenFile = [string]$item.FirstSeenFile
                Voice = $voice
                RawFile = $rawFile
                FilteredFile = $filteredFile
            })
        }
        catch {
            $failed++
            Write-Info ("FAILED [{0}] {1}: {2}" -f $group, $voice, $_.Exception.Message) "Red"
        }
    }
}

$manifestPath = Join-Path $FilteredCacheFolder ("ATCChatter_RecentTopUp_{0}.csv" -f (Get-Date -Format "yyyyMMdd_HHmmss"))
try {
    $manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII
    Write-Info ("Manifest written: {0}" -f $manifestPath) "Green"
} catch {
    Write-Info ("Failed to write manifest: {0}" -f $_.Exception.Message) "Red"
}

Write-Info "Recent journal ATC top-up complete." "Green"
Write-Info ("Raw Created={0} Raw Skipped={1} Filtered Created={2} Filtered Skipped={3} Failed={4}" -f $rawCreated, $rawSkipped, $filteredCreated, $filteredSkipped, $failed) "Green"
