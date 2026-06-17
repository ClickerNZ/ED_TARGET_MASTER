# TTSMonitor-v28.ps1 - EDMCOverlay module integration
#
# This script is now the single/preeminent audio processor:
# 1. TARGET Script TTS queue has priority.
# 2. ATC chatter is processed only when the TARGET TTS queue is idle.
# 3. PSJournal.ps1 must only call Add-ATCChatter; it must not call Invoke-ATCChatter.

# -------------------------
# Paths
# -------------------------
$queueFolder = "C:\Thrustmaster\Common\Output\TTSQueue"
$archiveFolder = Join-Path -Path $queueFolder -ChildPath "Archive"

$ttsModulePath = "C:\Thrustmaster\Common\PowerShell\Modules\TTS"
$atcModulePath = "C:\Thrustmaster\Common\PowerShell\Modules\ATCChatter"
$edmcOverlayModulePath = "C:\Thrustmaster\Common\PowerShell\Modules\EDMCOverlay"

$atcCacheUpdateScript = Join-Path -Path $PSScriptRoot -ChildPath "Update-ATCChatterCacheFromRecentJournals.ps1"

$MyVersion = "28"

$EnableEDMCOverlay = $true

# -------------------------
# Setup
# -------------------------
if (!(Test-Path $archiveFolder)) {
    New-Item -ItemType Directory -Path $archiveFolder -Force | Out-Null
}

Import-Module $ttsModulePath -Force
Import-Module $atcModulePath -Force

if ($EnableEDMCOverlay) {
    try {
        Import-Module $edmcOverlayModulePath -Force -ErrorAction Stop
        Write-Host "EDMCOverlay module imported. Connection will be opened on first overlay message." -ForegroundColor DarkCyan
    }
    catch {
        Write-Host ("EDMCOverlay module import failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        Write-Host "TTSMonitor will continue without overlay output." -ForegroundColor Yellow
        $EnableEDMCOverlay = $false
    }
}

try {
    $atcCmd = Get-Command Invoke-ATCChatter -ErrorAction Stop
    #Write-Host ("ATCChatter module loaded from: {0}" -f $atcCmd.Module.Path) -ForegroundColor DarkCyan
}
catch {
    Write-Host "ERROR: Invoke-ATCChatter was not imported. Check ATCChatter module path." -ForegroundColor Red
}

$script:ATCCacheMissDetected = $false

function Invoke-ATCCacheUpdateIfNeeded {
    if (-not $script:ATCCacheMissDetected) { return }

    Write-Host "" 
    Write-Host "ATC cache misses detected during this session." -ForegroundColor Yellow
    Write-Host "Running ATC cache updater before TTSMonitor exits..." -ForegroundColor Yellow

    if (-not (Test-Path -LiteralPath $atcCacheUpdateScript)) {
        Write-Host ("ATC cache updater script not found: {0}" -f $atcCacheUpdateScript) -ForegroundColor Red
        Write-Host ""
        return
    }

    try {
        & $atcCacheUpdateScript -RecentJournalCount 2
        Write-Host "ATC cache update completed." -ForegroundColor Green
    }
    catch {
        Write-Host ("ATC cache update failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }

    Write-Host ""
}

function Test-FileLocked {
    param([string]$FilePath)

    try {
        $stream = [System.IO.File]::Open($FilePath, 'Open', 'ReadWrite', 'None')
        if ($stream) { $stream.Close() }
        return $false
    }
    catch {
        return $true
    }
}

function Move-TTSFileToArchive {
    param([System.IO.FileInfo]$File)

    try {
        $destinationPath = Join-Path -Path $archiveFolder -ChildPath $File.Name
        Move-Item $File.FullName -Destination $destinationPath -Force
    }
    catch {
        Write-Host "Failed to archive $($File.Name): $_" -ForegroundColor Red
    }
}

function Get-TTSQueueFiles {
    return @(Get-ChildItem -Path $queueFolder -Filter "TTSMsg*.json" -ErrorAction SilentlyContinue |
        Sort-Object {
            try {
                [int]($_.BaseName.Substring(6,4))
            }
            catch {
                999999
            }
        })
}

function Invoke-TargetTTSFile {
    param([System.IO.FileInfo]$File)

    # Wait until the file is not locked (retry up to 10 times)
    $attempts = 0
    while (Test-FileLocked -FilePath $File.FullName -and $attempts -lt 10) {
        Start-Sleep -Milliseconds 100
        $attempts++
    }

    if (Test-FileLocked -FilePath $File.FullName) {
        Write-Host "File $($File.Name) is locked after multiple attempts. Skipping for now." -ForegroundColor Red
        return $false
    }

    # Archive stale queue files without speaking them.
    $fileAge = (Get-Date) - $File.LastWriteTime
    if ($fileAge.TotalMinutes -ge 2) {
        Write-Host "File $($File.Name) is older than 2 minutes (Age: $([math]::Round($fileAge.TotalMinutes,2)) minutes), archiving it." -ForegroundColor Yellow
        Move-TTSFileToArchive -File $File
        return $true
    }

    try {
        $json = Get-Content $File.FullName -Raw | ConvertFrom-Json
    }
    catch {
        Write-Host "Failed to read JSON from $($File.Name): $_. Skipping this file." -ForegroundColor Red
        return $false
    }

    $expectedSeq = $File.BaseName.Substring(6,4)
    if ($json.TTSSeq -ne $expectedSeq) {
        Write-Host "WARNING: Sequence mismatch in file $($File.Name): Expected $expectedSeq, got $($json.TTSSeq)." -ForegroundColor Yellow
    }

    $ttsString = $json.TTSString
    $ttsVoice  = $json.TTSVoice
    $ttsRate   = $json.TTSRate
    $ttsVolume = $json.TTSVolume

	$overlayText  = $json.OverlayText
	$overlayId    = if ($json.OverlayId)    { $json.OverlayId }    else { "target-overlay" }
	$overlayColor = if ($json.OverlayColor) { $json.OverlayColor } else { "yellow" }
	$overlaySize  = if ($json.OverlaySize)  { $json.OverlaySize }  else { "large" }
	$overlayX     = if ($json.OverlayX)     { [int]$json.OverlayX } else { 600 }
	$overlayY     = if ($json.OverlayY)     { [int]$json.OverlayY } else { 700 }
	$overlayTTL   = if ($json.OverlayTTL)   { [int]$json.OverlayTTL } else { 10 }

    $localtime = (Get-Date).ToString('HH:mm:ss')

	if ($EnableEDMCOverlay -and -not [string]::IsNullOrWhiteSpace($overlayText)) {
		
#		Write-Host ("[OVERLAY - {0}] - {1}" -f $localtime, $overlayText) -ForegroundColor Magenta
		Write-Host ("[OVR - {0}] - {1}" -f $localtime, $overlayText) -ForegroundColor Magenta

		Send-EDMCOverlayMessage `
			-Id $overlayId `
			-Text $overlayText `
			-Color $overlayColor `
			-Size $overlaySize `
			-X $overlayX `
			-Y $overlayY `
			-TTL $overlayTTL
	}

    if ($ttsString) {
        Write-Host ("[TTS - {0}] - {1}" -f $localtime, $ttsString) -ForegroundColor Cyan
        try {
            [TTS]::SpeakText($ttsString, $ttsVoice, $ttsRate, $ttsVolume)
        }
        catch {
            Write-Host "Error during TARGET TTS processing: $_" -ForegroundColor Red
        }
    }
	else {
		if ([string]::IsNullOrWhiteSpace($overlayText)) {
			Write-Host "No TTSString or OverlayText found in $($File.Name)." -ForegroundColor Red
		}
	}
	
    Move-TTSFileToArchive -File $File

    if ($ttsString -match "GAME HALTED") {
        Write-Host "Game Halted detected." -ForegroundColor Yellow

        Invoke-ATCCacheUpdateIfNeeded

        Write-Host "Exiting in 30 seconds..." -ForegroundColor Yellow
        Start-Sleep -Milliseconds 30000

        if ($EnableEDMCOverlay) { Disconnect-EDMCOverlay }
        Stop-Process -Id $PID -Force
    }

    return $true
}

# -------------------------
# Startup
# -------------------------
$voice = "Microsoft Catherine"
$rate  = 1
$volume = 80

try {
    [TTS]::SpeakText("Text to speech monitor, version $MyVersion loading.", $voice, $rate, $volume)
    Start-Sleep -Milliseconds 500	
    [TTS]::SpeakText("Processing T T S, and A T C queues.", $voice, $rate, $volume)
}
catch {
    Write-Host "Startup TTS failed: $_" -ForegroundColor Red
}

try {
    $host.UI.RawUI.WindowTitle = "TTS Monitor v$MyVersion - TARGET + ATC"
} catch {
    Write-Host "Could not set window title: $_"
}

Write-Host "Monitoring TARGET TTS queue: $queueFolder" -ForegroundColor Yellow
Write-Host "ATC chatter is processed only when TARGET TTS is idle." -ForegroundColor DarkCyan

# -------------------------
# Main processing loop
# -------------------------
while ($true) {
		$didWork = $false

		# TARGET Script TTS always wins.
		$files = Get-TTSQueueFiles

		if ($files.Count -gt 0) {
			foreach ($file in $files) {
				$result = Invoke-TargetTTSFile -File $file
				if ($result) { $didWork = $true }
			}

			# If TARGET TTS actually did work, do not process ATC in the same pass.
			# This keeps TARGET messages ahead of background chatter.
			#
			# If TARGET files exist but could not be processed, do NOT starve ATC forever.
			if ($didWork) {
				continue
			}
		}

		# ATC is background chatter. It only runs when TARGET TTS is idle
		# or when TARGET queue files are present but no TARGET work was actually processed.
		try {
			$atcResult = Invoke-ATCChatter

			if ($null -ne $atcResult) {

				if ($atcResult.Played) {
					Write-Host ("[ATC - {0}] - {1}" -f `
						(Get-Date -Format "HH:mm:ss"), `
						$atcResult.Text) -ForegroundColor Yellow

					$didWork = $true
				}
				elseif ($atcResult.Miss) {
					$script:ATCCacheMissDetected = $true

					Write-Host ("[ATC CACHE MISS - {0}] - {1}" -f `
						(Get-Date -Format "HH:mm:ss"), `
						$atcResult.Text) -ForegroundColor Red

					$didWork = $true
				}
				elseif ($atcResult.Error) {
					Write-Host ("[ATC ERROR - {0}] - {1}" -f `
						(Get-Date -Format "HH:mm:ss"), `
						$atcResult.ErrorMessage) -ForegroundColor Red

					$didWork = $true
				}
				elseif ($atcResult -eq $true) {
					# Backwards compatibility if an older ATCChatter module is accidentally imported.
					$didWork = $true
				}
			}
		}
		catch {
			Write-Host "ATC processing error: $_" -ForegroundColor Red
		}

		if (-not $didWork) {
			Start-Sleep -Milliseconds 250
		}
	}
