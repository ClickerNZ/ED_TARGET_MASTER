# PreGenerate-ATCChatterCache.ps1
#
# Scans Elite Dangerous Journal*.log files, extracts NPC ReceiveText chatter,
# classifies each line as Station / Traffic / Security, then pre-generates
# cached Piper WAV files for every configured ATC voice in that group.
#
# Run this when Elite Dangerous is NOT being heavily used, because it may take
# a while the first time.

param(
    [string]$JournalFolder = "D:\Users\Den\Saved Games\Frontier Developments\Elite Dangerous",
    [string]$ATCModulePath = "C:\Thrustmaster\Common\PowerShell\Modules\ATCChatter",
    [switch]$Force
)

Import-Module $ATCModulePath -Force

if (-not (Test-Path -LiteralPath $JournalFolder)) {
    Write-Host "Journal folder not found: $JournalFolder" -ForegroundColor Red
    return
}

$manifestPath = Join-Path $env:TEMP "ED_ATCChatter_PreGeneratedPhrases.csv"

Write-Host "Scanning journal folder:" -ForegroundColor Yellow
Write-Host "  $JournalFolder" -ForegroundColor Yellow
Write-Host ""

$journalFiles = @(Get-ChildItem -LiteralPath $JournalFolder -Filter "Journal*.log" -File -ErrorAction SilentlyContinue |
                  Sort-Object Name)

if ($journalFiles.Count -eq 0) {
    Write-Host "No Journal*.log files found." -ForegroundColor Red
    return
}

# Unique key = Group + Text
$phrases = @{}

$totalLines = 0
$totalReceiveText = 0
$totalNpc = 0

foreach ($file in $journalFiles) {
    Write-Host ("Reading {0}" -f $file.Name) -ForegroundColor DarkGray

    try {
        Get-Content -LiteralPath $file.FullName -ErrorAction Stop | ForEach-Object {
            $line = $_
            if ([string]::IsNullOrWhiteSpace($line)) { return }
            $script:totalLines++

            if ($line -notmatch '"event"\s*:\s*"ReceiveText"') { return }

            $entry = $null
            try {
                $entry = $line | ConvertFrom-Json
            }
            catch {
                return
            }

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

            # Fallback to Message only if no localised message exists.
            # Usually the localised text is what you want spoken.
            if ([string]::IsNullOrWhiteSpace($text) -and
                $entry.PSObject.Properties.Name -contains 'Message' -and
                $null -ne $entry.Message) {
                $text = [string]$entry.Message
            }

            if ([string]::IsNullOrWhiteSpace($text)) { return }

            $from = ""
            if ($entry.PSObject.Properties.Name -contains 'From' -and $null -ne $entry.From) {
                $from = [string]$entry.From
            }

            # Preserve your original receive-text intent: NPC chatter with a real sender and real message.
            if ([string]::IsNullOrWhiteSpace($from)) { return }

            # Skip a few very common station/system boilerplate lines if they have no useful spoken content.
            # The localised chatter text is still kept.
            $msgCode = ""
            if ($entry.PSObject.Properties.Name -contains 'Message' -and $null -ne $entry.Message) {
                $msgCode = [string]$entry.Message
            }

            if (($msgCode -eq '$STATION_NoFireZone_entered;') -or
                ($msgCode -eq '$STATION_NoFireZone_exited;') -or
                ($msgCode -eq '$STATION_docking_granted;')) {
                return
            }

            $group = Get-ATCGroupForNpcReceiveText -entry $entry
            if ([string]::IsNullOrWhiteSpace($group)) { $group = "Traffic" }

            $key = $group + "|" + $text

            if (-not $phrases.ContainsKey($key)) {
                $phrases[$key] = [ordered]@{
                    Group = $group
                    Text = $text
                    FirstSeenFile = $file.Name
                    From = $from
                }
            }
        }
    }
    catch {
        Write-Host ("Failed reading {0}: {1}" -f $file.Name, $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host ("Journal files scanned : {0}" -f $journalFiles.Count) -ForegroundColor Yellow
Write-Host ("Total lines scanned   : {0}" -f $totalLines) -ForegroundColor Yellow
Write-Host ("ReceiveText events    : {0}" -f $totalReceiveText) -ForegroundColor Yellow
Write-Host ("NPC ReceiveText events: {0}" -f $totalNpc) -ForegroundColor Yellow
Write-Host ("Unique ATC phrases    : {0}" -f $phrases.Count) -ForegroundColor Yellow
Write-Host ""

if ($phrases.Count -eq 0) {
    Write-Host "No ATC phrases found to pre-generate." -ForegroundColor Yellow
    return
}

$manifest = New-Object System.Collections.ArrayList
$done = 0

foreach ($item in $phrases.Values) {
    $done++
    $group = [string]$item.Group
    $text  = [string]$item.Text

    if (
      ($group -eq "Traffic") -and
      (
        ($text -like "CMDR Clicker*") -or
        ($text -like "CMDR 2Dogs*")
      )
    ) {
      continue
    }

    Write-Host ("[{0}/{1}] {2}: {3}" -f $done, $phrases.Count, $group, $text) -ForegroundColor Cyan

    $wavFiles = @()
    try {
        $wavFiles = @(New-ATCCacheForText -Text $text -Group $group -Force:$Force)
    }
    catch {
        Write-Host ("  Failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }

    foreach ($wav in $wavFiles) {
        [void]$manifest.Add([pscustomobject]@{
            Group = $group
            Text = $text
            From = [string]$item.From
            FirstSeenFile = [string]$item.FirstSeenFile
            WaveFile = $wav
        })
    }
}

try {
    $manifest | Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding ASCII
    Write-Host ""
    Write-Host ("Manifest written: {0}" -f $manifestPath) -ForegroundColor Green
}
catch {
    Write-Host ("Failed to write manifest: {0}" -f $_.Exception.Message) -ForegroundColor Red
}

Write-Host ""
Write-Host "Pre-generation complete." -ForegroundColor Green
