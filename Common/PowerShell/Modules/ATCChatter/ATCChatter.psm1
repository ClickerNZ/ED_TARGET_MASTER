# ATCChatter.psm1
# Elite Dangerous NPC "ATC-like" chatter.
# PowerShell 5.1 compatible.
#
# DESIGN:
# - Add-ATCChatter is fast/non-blocking. It writes a tiny JSON queue file and returns.
# - TTSMonitor.ps1 is now the only audio worker.
# - Piper WAVs are cached so repeated ATC phrases do not need to be regenerated.
# - Runtime playback uses pre-filtered WAV files from C:\Thrustmaster\Common\Piper\ATCChatter_Filtered.
# - Filtering is done offline by Filter-ATCChatterCache.ps1, not during gameplay.

# -------------------------
# Config - Piper TTS
# -------------------------
$script:PiperExePath     = "C:\Users\Den\AppData\Local\Programs\Python\Python313\Scripts\piper.exe"
$script:PiperModelFolder = "C:\Thrustmaster\Common\Piper\Voices"

# Use your renamed Piper voice model filenames here.
$script:AllVoices = @(
  "alan.onnx",
  "alba.onnx",
  "amy.onnx",
  "aru.onnx",
  "barbera.onnx",
  "bill.onnx",
  "bob.onnx",
  "bryce.onnx",
  "colin.onnx",
  "cori.onnx",
  "danny.onnx",
  "darla.onnx",
  "jenny.onnx",
  "jock.onnx",
  "joe.onnx",
  "john.onnx",
  "kathleen.onnx",
  "kristin.onnx",
  "kusal.onnx",
  "lessac.onnx",
  "michelle.onnx",
  "norman.onnx",
  "ryan.onnx",
  "semaine.onnx"
)

$script:VoiceGroups = @{
  Station  = @("alan.onnx","alba.onnx","amy.onnx","aru.onnx","barbera.onnx","bill.onnx","bob.onnx","bryce.onnx")
  Security = @("colin.onnx","cori.onnx","danny.onnx","darla.onnx","jenny.onnx","jock.onnx","joe.onnx","kathleen.onnx")
  Traffic  = @("john.onnx","kristin.onnx","kusal.onnx","lessac.onnx","michelle.onnx","norman.onnx","ryan.onnx","semaine.onnx")
}

# Piper timing controls.
# Piper: higher length_scale = slower.
$script:PiperLengthScale = 1.10
$script:PiperNoiseScale  = 0.667
$script:PiperNoiseW      = 0.8

# ATC chatter loudness, used by Windows Media Player COM playback.
# This does NOT affect TARGET TTS volume.
# Lower this if ATC is still too forward in the mix.
$script:ATCVolume = 100

# WAV/cache output
$script:WaveOutputFolder = "C:\Thrustmaster\Common\Piper\ATCChatter"
$script:FilteredCacheFolder = "C:\Thrustmaster\Common\Piper\ATCChatter_Filtered"

# Runtime playback uses the filtered cache. Keep the original folder as the unfiltered Piper source cache.
$script:CacheFolder      = $script:WaveOutputFolder

$script:KeepWaveFiles    = $true
$script:MaxLooseWaveFiles = 9999

# Disk queue used so PSJournal is never blocked by Piper generation or playback.
$script:QueueFolder        = "c:\thrustmaster\common\Output\ED_ATCChatter_Queue"
$script:ArchiveQueueFolder = Join-Path $script:QueueFolder "Archive"

$script:MaxQueueFiles      = 250

# Mute flags/state (driven by Status.json, if your PSJournal calls Update-ATCChatterStateFromStatus)
$script:IsDocked = $false
$script:IsOnFoot = $false
$script:IsInFSS  = $false
$script:Muted    = $false

function Initialize-ATCWaveFolder {
  if (-not (Test-Path -LiteralPath $script:WaveOutputFolder)) {
    New-Item -Path $script:WaveOutputFolder -ItemType Directory -Force | Out-Null
  }
  if (-not (Test-Path -LiteralPath $script:CacheFolder)) {
    New-Item -Path $script:CacheFolder -ItemType Directory -Force | Out-Null
  }
  if (-not (Test-Path -LiteralPath $script:FilteredCacheFolder)) {
    New-Item -Path $script:FilteredCacheFolder -ItemType Directory -Force | Out-Null
  }
}

function Initialize-ATCQueueFolder {
  if (-not (Test-Path -LiteralPath $script:QueueFolder)) {
    New-Item -Path $script:QueueFolder -ItemType Directory -Force | Out-Null
  }
  if (-not (Test-Path -LiteralPath $script:ArchiveQueueFolder)) {
    New-Item -Path $script:ArchiveQueueFolder -ItemType Directory -Force | Out-Null
  }
}

function Remove-OldATCWaveFiles {
  return 
}

function Remove-OldATCQueueFiles {
  Initialize-ATCQueueFolder
  try {
    $files = @(Get-ChildItem -LiteralPath $script:QueueFolder -Filter "ATC_*.json" -File -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending)
    if ($files.Count -gt $script:MaxQueueFiles) {
      $files | Select-Object -Skip $script:MaxQueueFiles | Remove-Item -Force -ErrorAction SilentlyContinue
    }
  } catch { }
}

function ConvertTo-ATCCommandLineArg {
  param([string]$Value)
  if ($null -eq $Value) { return '""' }
  $escaped = $Value -replace '\\(?=")', '\' -replace '"', '\"'
  if ($escaped -match '\s|"' -or $escaped.Length -eq 0) { return '"' + $escaped + '"' }
  return $escaped
}

function Resolve-ATCPiperModelPath {
  param([string]$Voice)
  if ([string]::IsNullOrWhiteSpace($Voice)) { return $null }
  if (Test-Path -LiteralPath $Voice) { return (Resolve-Path -LiteralPath $Voice).Path }
  $candidate = Join-Path $script:PiperModelFolder $Voice
  if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
  return $null
}

function Test-ATCPiperAvailable {
  try {
    $cmd = Get-Command $script:PiperExePath -ErrorAction SilentlyContinue
    if ($null -ne $cmd) { return $true }
    if (Test-Path -LiteralPath $script:PiperExePath) { return $true }
  } catch { }
  return $false
}

function Get-ATCTextHash {
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

function ConvertTo-ATCSafeFilePart {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return "Unknown" }
  $safe = $Value -replace '[^\w\-]+', '_'
  $safe = $safe.Trim('_')
  if ($safe.Length -gt 32) { $safe = $safe.Substring(0, 32) }
  if ([string]::IsNullOrWhiteSpace($safe)) { return "Unknown" }
  return $safe
}

function Format-ATCSpokenText {
  param([string]$Text)

  if ([string]::IsNullOrWhiteSpace($Text)) { return "" }

  $spoken = $Text.Trim()
  $spoken = $spoken -replace '\s+', ' '
  $spoken = $spoken -replace '(\.|!|\?)', '$1 '
  $spoken = $spoken -replace ',', ', '

  # FDev ATC text often contains awkward pauses before Commander/Pilot/etc.
  # Example: "Welcome back, Commander" -> "Welcome back Commander"
  $spoken = $spoken -replace ',\s+(Commander|Pilot|Officer|Control)\b', ' $1'

  # Expand common Elite Dangerous unit abbreviations after numbers.
  # Examples:
  #   1250cr -> 1250 credits
  #   1250 CR -> 1250 credits
  #   12t -> 12 tons
  #   12 T -> 12 tons
  $spoken = $spoken -replace '\b(\d+(?:\.\d+)?)\s*cr\b', '$1 credits'
  $spoken = $spoken -replace '\b(\d+(?:\.\d+)?)\s*t\b', '$1 tons'

  $spoken = $spoken -replace '\s+', ' '
  return $spoken.Trim()
}

function Get-ATCVoiceList {
  return @($script:AllVoices)
}

function Get-ATCVoicesForGroup {
  param([string]$Group = "Traffic")

  if ([string]::IsNullOrWhiteSpace($Group)) { $Group = "Traffic" }
  if ($script:VoiceGroups.ContainsKey($Group)) {
    $list = @($script:VoiceGroups[$Group] | Where-Object { $script:AllVoices -contains $_ })
    if ($list.Count -gt 0) { return $list }
  }
  return @($script:AllVoices)
}

function Pick-ATCVoice {
  param([string]$Group = "Traffic")

  $candidates = @(Get-ATCVoicesForGroup -Group $Group)
  $available = @($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace((Resolve-ATCPiperModelPath -Voice $_)) })
  if ($available.Count -gt 0) { return ($available | Get-Random) }
  if ($candidates.Count -gt 0) { return $candidates[0] }
  return $null
}

function Get-ATCCachedWavePath {
  param(
    [string]$Text,
    [string]$Group = "Traffic",
    [string]$Voice
  )

  Initialize-ATCWaveFolder

  $spoken = Format-ATCSpokenText -Text $Text
  $keyText = ("Voice={0}|Group={1}|Length={2}|Noise={3}|NoiseW={4}|Text={5}" -f `
    $Voice, $Group, $script:PiperLengthScale, $script:PiperNoiseScale, $script:PiperNoiseW, $spoken)

  $hash = Get-ATCTextHash -Text $keyText
  $groupSafe = ConvertTo-ATCSafeFilePart -Value $Group
  $voiceSafe = ConvertTo-ATCSafeFilePart -Value ([System.IO.Path]::GetFileNameWithoutExtension($Voice))

  return (Join-Path $script:CacheFolder ("ATC_{0}_{1}_{2}.wav" -f $groupSafe, $voiceSafe, $hash.Substring(0, 16)))
}

function Get-ATCFilteredWavePath {
  param(
    [string]$Text,
    [string]$Group = "Traffic",
    [string]$Voice
  )

  $rawPath = Get-ATCCachedWavePath -Text $Text -Group $Group -Voice $Voice
  $fileName = [System.IO.Path]::GetFileName($rawPath)

  return (Join-Path $script:FilteredCacheFolder $fileName)
}

function New-ATCWaveFile {
  param(
    [string]$Text,
    [string]$Voice,
    [string]$Group = "Traffic",
    [switch]$Force
  )

  if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
  Initialize-ATCWaveFolder

  if (-not (Test-ATCPiperAvailable)) {
    Write-Host "ATCChatter: Piper executable not found. Check `$script:PiperExePath." -ForegroundColor Red
    return $null
  }

  $modelPath = Resolve-ATCPiperModelPath -Voice $Voice
  if ([string]::IsNullOrWhiteSpace($modelPath)) {
    Write-Host ("ATCChatter: Piper voice model not found: {0}" -f $Voice) -ForegroundColor Red
    return $null
  }

  $spoken = Format-ATCSpokenText -Text $Text
  $outFile = Get-ATCCachedWavePath -Text $spoken -Group $Group -Voice $Voice

  if ((-not $Force) -and (Test-Path -LiteralPath $outFile)) {
    return $outFile
  }

  try {
    $argList = @(
      "--model", $modelPath,
      "--output_file", $outFile,
      "--length_scale", ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:0.###}", [double]$script:PiperLengthScale)),
      "--noise_scale",  ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:0.###}", [double]$script:PiperNoiseScale)),
      "--noise_w",      ([string]::Format([System.Globalization.CultureInfo]::InvariantCulture, "{0:0.###}", [double]$script:PiperNoiseW))
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $script:PiperExePath
    $psi.Arguments = (($argList | ForEach-Object { ConvertTo-ATCCommandLineArg $_ }) -join " ")
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    try { $psi.StandardInputEncoding = [System.Text.Encoding]::UTF8 } catch { }

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    [void]$proc.Start()
    $proc.StandardInput.WriteLine($spoken)
    $proc.StandardInput.Close()
    [void]$proc.StandardOutput.ReadToEnd()
    $stdErr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    if ($proc.ExitCode -ne 0) {
      Write-Host ("ATCChatter: Piper failed. ExitCode={0}" -f $proc.ExitCode) -ForegroundColor Red
      if (-not [string]::IsNullOrWhiteSpace($stdErr)) { Write-Host $stdErr -ForegroundColor DarkYellow }
      try { if (Test-Path -LiteralPath $outFile) { Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue } } catch { }
      return $null
    }

    if (-not (Test-Path -LiteralPath $outFile)) {
      Write-Host "ATCChatter: Piper completed but no WAV file was created." -ForegroundColor Red
      return $null
    }

    Remove-OldATCWaveFiles
    return $outFile
  }
  catch {
    Write-Host ("ATCChatter: Error generating Piper WAV: {0}" -f $_.Exception.Message) -ForegroundColor Red
    try { if (Test-Path -LiteralPath $outFile) { Remove-Item -LiteralPath $outFile -Force -ErrorAction SilentlyContinue } } catch { }
    return $null
  }
  finally {
    try { if ($null -ne $proc) { $proc.Dispose() } } catch { }
  }
}

function Invoke-ATCWavePlayback {
  param(
    [string]$WaveFile,
    [int]$Volume = -1
  )

  # IMPORTANT:
  # Do not use Windows Media Player COM here.
  # WMP COM volume can affect the shared PowerShell audio session and its
  # playState loop was able to block TTSMonitor for up to 5 minutes.
  #
  # ATC volume should be handled by the WAV files themselves later
  # during pregeneration / filtering, not by playback-time volume control.

  if ([string]::IsNullOrWhiteSpace($WaveFile)) { return }
  if (-not (Test-Path -LiteralPath $WaveFile)) { return }

  try {
    $sp = New-Object System.Media.SoundPlayer
    $sp.SoundLocation = $WaveFile
    $sp.Load()
    $sp.PlaySync()
  }
  catch {
    Write-Host ("ATCChatter: SoundPlayer failed for WAV: {0}" -f $_.Exception.Message) -ForegroundColor Red
  }
  finally {
    try {
      if ($null -ne $sp) { $sp.Dispose() }
    } catch { }
  }
}


function Get-ATCChatterMuted { return $script:Muted }

function Clear-ATCChatterQueue {
  Initialize-ATCQueueFolder
  try { Get-ChildItem -LiteralPath $script:QueueFolder -Filter "ATC_*.json" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue } catch { }
}

function Update-ATCChatterMuteState {
  $newMuted = ($script:IsDocked -or $script:IsOnFoot -or $script:IsInFSS)
  $changed = ($newMuted -ne $script:Muted)
  $script:Muted = $newMuted
  if ($changed -and $script:Muted) { Clear-ATCChatterQueue }
}

function Update-ATCChatterStateFromStatus {
  param([pscustomobject]$status)

  if (-not $status) { return }
  $flags  = 0
  $flags2 = 0
  $gui    = 0

  if ($status.PSObject.Properties.Name -contains 'Flags' -and $null -ne $status.Flags) { $flags = [int64]$status.Flags }
  if ($status.PSObject.Properties.Name -contains 'Flags2' -and $null -ne $status.Flags2) { $flags2 = [int64]$status.Flags2 }
  if ($status.PSObject.Properties.Name -contains 'GuiFocus' -and $null -ne $status.GuiFocus) { $gui = [int]$status.GuiFocus }

  $script:IsDocked = (($flags  -band 1) -ne 0)
  $script:IsOnFoot = (($flags2 -band 1) -ne 0)
  $script:IsInFSS  = ($gui -eq 9)

  Update-ATCChatterMuteState
}

function Get-ATCGroupForNpcReceiveText {
  param([pscustomobject]$entry)

  $fromL = ""; $from = ""; $msgL = ""; $msg = ""
  if ($entry -and ($entry.PSObject.Properties.Name -contains 'From_Localised') -and $null -ne $entry.From_Localised) { $fromL = [string]$entry.From_Localised }
  if ($entry -and ($entry.PSObject.Properties.Name -contains 'From') -and $null -ne $entry.From) { $from = [string]$entry.From }
  if ($entry -and ($entry.PSObject.Properties.Name -contains 'Message_Localised') -and $null -ne $entry.Message_Localised) { $msgL = [string]$entry.Message_Localised }
  if ($entry -and ($entry.PSObject.Properties.Name -contains 'Message') -and $null -ne $entry.Message) { $msg = [string]$entry.Message }

  if ($fromL -match 'Platform|Starport|Dock|Traffic Control|Control' -or
      $from  -match 'Platform|TrafficControl|Control' -or
      $msgL  -match 'Docking request granted|Docking request denied|No fire zone|starport protocol|pad|landing pad' -or
      $msg   -match 'DockingChatter|docking_granted|docking_denied|NoFireZone') { return "Station" }

  if ($fromL -match 'Security|Police|Authority|Service|System Authority Vessel' -or
      $from  -match 'Police|Security|Authority|System Authority Vessel' -or
      $msgL  -match 'scan detected|criminal|hostile|fine|bounty|security' -or
      $msg   -match 'Police|Security') { return "Security" }

  return "Traffic"
}

function Add-ATCChatter {
  param(
    [string]$text,
    [string]$group = "Traffic"
  )

  # Fast/non-blocking: write a small JSON queue file only.
  if ([string]::IsNullOrWhiteSpace($text)) { return }
  if ($script:Muted) { return }

  $t = $text.Trim()
  if ($t.Length -gt 500) { $t = $t.Substring(0, 500) }

  if ([string]::IsNullOrWhiteSpace($group)) { $group = "Traffic" }

  # Ignore specific CMDR traffic chatter.
  # This assumes the CMDR name is at the start of the text.
  if (
    ($group -eq "Traffic") -and
    (
      ($t -like "CMDR Clicker*") -or
      ($t -like "CMDR 2Dogs*")
    )
  ) {
    return
  }

  Initialize-ATCQueueFolder
  # Do NOT scan/clean the queue here. Add-ATCChatter must remain ultra-fast
  # so ProcessJournal/MyJournalData updates are never delayed by ATC chatter.

  $stamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
  $guid  = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
  $tmpFile = Join-Path $script:QueueFolder ("ATC_{0}_{1}.tmp" -f $stamp, $guid)
  $jsonFile = Join-Path $script:QueueFolder ("ATC_{0}_{1}.json" -f $stamp, $guid)

  $item = [ordered]@{
    Text = $t
    Group = $group
    Created = (Get-Date).ToString("s")
  }

  try {
    ($item | ConvertTo-Json -Compress) | Set-Content -LiteralPath $tmpFile -Encoding ASCII
    Move-Item -LiteralPath $tmpFile -Destination $jsonFile -Force
  } catch {
    try { if (Test-Path -LiteralPath $tmpFile) { Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue } } catch { }
  }
}

function Get-NextATCQueueFile {
  Initialize-ATCQueueFolder
  try {
    return @(Get-ChildItem -LiteralPath $script:QueueFolder -Filter "ATC_*.json" -File -ErrorAction SilentlyContinue |
             Sort-Object Name |
             Select-Object -First 1)[0]
  } catch { return $null }
}

function Invoke-ATCChatter {
  if ($script:Muted) { return $null }

  $file = Get-NextATCQueueFile
  if ($null -eq $file) { return $null }

  $workFile = $file.FullName + ".work"

  try {
    Move-Item -LiteralPath $file.FullName -Destination $workFile -Force
  } catch {
    return $null
  }

  $item = $null

  try {
    $item = Get-Content -LiteralPath $workFile -Raw -ErrorAction Stop | ConvertFrom-Json
  } catch {
    try { Remove-Item -LiteralPath $workFile -Force -ErrorAction SilentlyContinue } catch { }
    return $null
  }

  $text  = [string]$item.Text
  $group = ([string]$item.Group).Trim()

  if ([string]::IsNullOrWhiteSpace($group)) { $group = "Traffic" }

  if ([string]::IsNullOrWhiteSpace($text)) {
    try { Remove-Item -LiteralPath $workFile -Force -ErrorAction SilentlyContinue } catch { }
    return $null
  }

  try {
    $voices = @(Get-ATCVoicesForGroup -Group $group)

    $cachedFiles = @()

    foreach ($voice in $voices) {
      $candidate = Get-ATCFilteredWavePath -Text $text -Group $group -Voice $voice

      if (Test-Path -LiteralPath $candidate) {
        $cachedFiles += $candidate
      }
    }

    if ($cachedFiles.Count -eq 0) {
      return [pscustomobject]@{
        Played = $false
        Miss   = $true
        Group  = $group
        Text   = $text
      }
    }

    $wav = $cachedFiles | Get-Random

    Invoke-ATCWavePlayback -WaveFile $wav

    return [pscustomobject]@{
      Played = $true
      Miss    = $false
      Group   = $group
      Text    = $text
      Wave    = $wav
    }
  }
  catch {
    return [pscustomobject]@{
      Played = $false
      Error  = $true
      Group  = $group
      Text   = $text
      Message = $_.Exception.Message
    }
  }
  finally {
    try {
      $archiveName = [System.IO.Path]::GetFileName($workFile) -replace '\.work$', '.done'
      Move-Item -LiteralPath $workFile -Destination (Join-Path $script:ArchiveQueueFolder $archiveName) -Force -ErrorAction SilentlyContinue
    } catch {
      try { Remove-Item -LiteralPath $workFile -Force -ErrorAction SilentlyContinue } catch { }
    }
  }
}

function New-ATCCacheForText {
  param(
    [string]$Text,
    [string]$Group = "Traffic",
    [switch]$Force
  )

  if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
  if ([string]::IsNullOrWhiteSpace($Group)) { $Group = "Traffic" }

  $made = @()
  $voices = @(Get-ATCVoicesForGroup -Group $Group)

  foreach ($voice in $voices) {
    $wav = New-ATCWaveFile -Text $Text -Voice $voice -Group $Group -Force:$Force
    if (-not [string]::IsNullOrWhiteSpace($wav)) {
      $made += $wav
    }
  }

  return $made
}

Export-ModuleMember -Function `
  Add-ATCChatter, Invoke-ATCChatter, `
  Get-ATCGroupForNpcReceiveText, Update-ATCChatterStateFromStatus, `
  Get-ATCChatterMuted, Clear-ATCChatterQueue, `
  New-ATCWaveFile, New-ATCCacheForText, `
  Get-ATCVoiceList, Get-ATCVoicesForGroup, Format-ATCSpokenText
