# Filter-ATCChatterCache_v3_RadioFX.ps1
# Applies the accepted ATC radio/muffle/static filter plus V5A radio key-up and end squelch.
# PowerShell 5.1 compatible.
#
# Source/original cache:
#   C:\Thrustmaster\Common\Piper\ATCChatter
# Filtered/runtime cache:
#   C:\Thrustmaster\Common\Piper\ATCChatter_Filtered
#
# Output filenames are intentionally identical to the source filenames so
# ATCChatter.psm1 can locate the filtered files using the same cache key.

param(
    [string]$SourceFolder = "C:\Thrustmaster\Common\Piper\ATCChatter",
    [string]$OutputFolder = "C:\Thrustmaster\Common\Piper\ATCChatter_Filtered",
    [string]$FFmpegPath = "ffmpeg.exe",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Info {
    param([string]$Message, [string]$Color = "Gray")
    Write-Host ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $Message) -ForegroundColor $Color
}

if (-not (Get-Command $FFmpegPath -ErrorAction SilentlyContinue)) {
    throw "FFmpeg was not found using path: $FFmpegPath"
}

if (-not (Test-Path -LiteralPath $SourceFolder)) {
    throw "Source folder not found: $SourceFolder"
}

if (-not (Test-Path -LiteralPath $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

$sourceFiles = @(Get-ChildItem -LiteralPath $SourceFolder -Filter "ATC_*.wav" -File -ErrorAction Stop | Sort-Object Name)

if ($sourceFiles.Count -eq 0) {
    Write-Info "No ATC_*.wav files found in $SourceFolder" "Yellow"
    return
}

Write-Info ("Source:   {0}" -f $SourceFolder) "Cyan"
Write-Info ("Output:   {0}" -f $OutputFolder) "Cyan"
Write-Info ("Files:    {0}" -f $sourceFiles.Count) "Cyan"
Write-Info ("Force:    {0}" -f [bool]$Force) "Cyan"
Write-Info "Profile:  Radio filter + V6 tuned start key-up + End_01 soft squelch" "Cyan"

# V6 tuned start cue:
#   sine key-up, 0.190s, volume 0.90, frequency 1360 Hz, short fade in/out.
# End squelch:
#   same soft kshht profile used in accepted sample testing.
# Voice filter:
#   same accepted radio/muffle/static filter with 5% volume boost.
$FilterComplex = @"
[1:a]volume=0.90,afade=t=in:st=0:d=0.008,afade=t=out:st=0.150:d=0.040,aformat=sample_rates=48000:channel_layouts=mono[start];
anoisesrc=color=pink:amplitude=0.25:d=30[noise];
[0:a]volume=1.365,highpass=f=320,lowpass=f=850,equalizer=f=1250:t=q:w=1.3:g=5,acompressor=threshold=-22dB:ratio=3:attack=5:release=70[voicebase];
[voicebase][noise]amix=inputs=2:duration=first:weights=1 0.22[voice];
[3:a]highpass=f=500,lowpass=f=3000,afade=t=in:st=0:d=0.008,afade=t=out:st=0.075:d=0.045,volume=1.24,aformat=sample_rates=48000:channel_layouts=mono[end];
[start][2:a][voice][end]concat=n=4:v=0:a=1[out]
"@

# Flatten whitespace to avoid command-line parsing issues.
$FilterComplex = ($FilterComplex -replace "`r", "" -replace "`n", "" )

$done = 0
$created = 0
$skipped = 0
$failed = 0

foreach ($file in $sourceFiles) {
    $done++
    $outFile = Join-Path $OutputFolder $file.Name
    $tmpFile = $outFile + ".tmp.wav"

    if ((-not $Force) -and (Test-Path -LiteralPath $outFile)) {
        $skipped++
        if (($done % 50) -eq 0) {
            Write-Info ("Progress {0}/{1} | Created={2} Skipped={3} Failed={4}" -f $done, $sourceFiles.Count, $created, $skipped, $failed) "DarkCyan"
        }
        continue
    }

    try {
        if (Test-Path -LiteralPath $tmpFile) {
            Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
        }

        & $FFmpegPath `
            -y `
            -hide_banner `
            -loglevel error `
            -i $file.FullName `
            -f lavfi `
#           -i "sine=frequency=1600:duration=0.190:sample_rate=48000" ` # blip sound at start of ATCChatter message 
            -i "sine=frequency=1360:duration=0.190:sample_rate=48000" `
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
            throw "FFmpeg exited with code $LASTEXITCODE"
        }

        if (-not (Test-Path -LiteralPath $tmpFile)) {
            throw "FFmpeg did not create output file"
        }

        Move-Item -LiteralPath $tmpFile -Destination $outFile -Force
        $created++
    }
    catch {
        $failed++
        Write-Info ("FAILED {0}: {1}" -f $file.Name, $_.Exception.Message) "Red"
        try {
            if (Test-Path -LiteralPath $tmpFile) {
                Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
            }
        } catch { }
    }

    if (($done % 25) -eq 0) {
        Write-Info ("Progress {0}/{1} | Created={2} Skipped={3} Failed={4}" -f $done, $sourceFiles.Count, $created, $skipped, $failed) "DarkCyan"
    }
}

Write-Info "Filtering complete." "Green"
Write-Info ("Created={0} Skipped={1} Failed={2}" -f $created, $skipped, $failed) "Green"
Write-Info ("Filtered cache ready: {0}" -f $OutputFolder) "Green"
