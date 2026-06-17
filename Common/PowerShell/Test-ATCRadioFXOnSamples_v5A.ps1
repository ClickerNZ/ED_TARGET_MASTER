# Test-ATCRadioFXOnSamples_v5A.ps1
# Non-destructive RadioFX test script.
# Creates comparison WAVs using the existing sample WAV files in C:\Thrustmaster\Common\Samples.
# v5A: keeps the preferred V4A style, but makes the start cue louder and 2x longer. End squelch unchanged.

$ErrorActionPreference = 'Stop'

$SampleFolder = 'C:\Thrustmaster\Common\Samples'
$OutputFolder = Join-Path $SampleFolder 'RadioFX_Test'

$StartFxFolder = 'C:\Thrustmaster\Common\Piper\RadioFX\Start'
$EndFxFolder   = 'C:\Thrustmaster\Common\Piper\RadioFX\End'

$FFmpegPath = 'ffmpeg.exe'

if (-not (Test-Path -LiteralPath $SampleFolder)) {
    throw "Sample folder not found: $SampleFolder"
}

if (-not (Test-Path -LiteralPath $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

# Use the original B end squelch if present. Fall back to the first end FX file.
$EndFx = Join-Path $EndFxFolder 'End_01_kshht.wav'
if (-not (Test-Path -LiteralPath $EndFx)) {
    $EndFx = @(Get-ChildItem -LiteralPath $EndFxFolder -Filter '*.wav' -File -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
}
if ([string]::IsNullOrWhiteSpace($EndFx) -or -not (Test-Path -LiteralPath $EndFx)) {
    throw "No end FX WAV found in: $EndFxFolder"
}

# Temporary generated start FX files for this test only.
$TempFolder = Join-Path $OutputFolder '_TempFX_v5A'
if (-not (Test-Path -LiteralPath $TempFolder)) {
    New-Item -ItemType Directory -Path $TempFolder -Force | Out-Null
}

function Invoke-FFmpeg {
    param([string[]]$Arguments)

    & $FFmpegPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "FFmpeg exited with code $LASTEXITCODE"
    }
}

function New-StartFx {
    param(
        [string]$Name,
        [string]$Filter
    )

    $outFile = Join-Path $TempFolder ($Name + '.wav')

    Invoke-FFmpeg @(
        '-y',
        '-hide_banner',
        '-loglevel', 'error',
        '-f', 'lavfi',
        '-i', $Filter,
        '-ar', '48000',
        '-ac', '1',
        '-sample_fmt', 's16',
        $outFile
    )

    return $outFile
}

# V5A: preferred V4A style, but louder and twice as long.
# End squelch remains unchanged.
$StartFxList = @()

$StartFxList += [pscustomobject]@{
    Name = 'V5A_louder_longer_key_beep'
    Path = New-StartFx -Name 'V5A_louder_longer_key_beep' -Filter "sine=frequency=1600:duration=0.190,volume=1.20,afade=t=in:st=0:d=0.008,afade=t=out:st=0.150:d=0.040"
}

$samples = @(Get-ChildItem -LiteralPath $SampleFolder -Filter '*.wav' -File -ErrorAction SilentlyContinue |
             Where-Object { $_.DirectoryName -ne $OutputFolder })

if ($samples.Count -eq 0) {
    throw "No sample WAV files found in: $SampleFolder"
}

$created = 0
$failed = 0

foreach ($sample in $samples) {
    foreach ($startFx in $StartFxList) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($sample.Name)
        $outFile = Join-Path $OutputFolder ("{0}_{1}.wav" -f $baseName, $startFx.Name)

        try {
            # Create a short silence gap after start FX so it is perceptible before speech begins.
            # Chain: StartFX + 45ms silence + sample + EndFX.
            Invoke-FFmpeg @(
                '-y',
                '-hide_banner',
                '-loglevel', 'error',
                '-i', $startFx.Path,
                '-f', 'lavfi',
                '-i', 'anullsrc=r=48000:cl=mono:d=0.045',
                '-i', $sample.FullName,
                '-i', $EndFx,
                '-filter_complex', '[0:a][1:a][2:a][3:a]concat=n=4:v=0:a=1[out]',
                '-map', '[out]',
                '-ar', '48000',
                '-ac', '1',
                '-sample_fmt', 's16',
                $outFile
            )

            Write-Host ("Created: {0}" -f $outFile) -ForegroundColor Green
            $created++
        }
        catch {
            Write-Host ("FAILED {0} / {1}: {2}" -f $sample.Name, $startFx.Name, $_.Exception.Message) -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host ""
Write-Host ("Radio FX v5A sample test complete. Created={0} Failed={1}" -f $created, $failed) -ForegroundColor Cyan
Write-Host ("Output: {0}" -f $OutputFolder) -ForegroundColor Cyan
