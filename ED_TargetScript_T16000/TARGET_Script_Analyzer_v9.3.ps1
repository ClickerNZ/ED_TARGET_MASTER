<#
.SYNOPSIS
  TARGET Script Analyzer (v9.3) — PowerShell 5.1 Compatible
.DESCRIPTION
  Finds unused globals, locals, and functions in TARGET script packages.
  - Ignores TARGET built-ins and control statements
  - Detects alias &varname references and built-in function argument usage
  - Recognizes DeferCall(), REXEC(), EXEC(), and AutoRepeat() indirect calls
  - Retains all control structures (if/while/for/elseif)
  - Preserves line numbers while stripping /* ... */ and // comments
  - Overwrites UnusedSymbolsReport_v9_3.txt
  - Global reference detection now scans all cleaned source lines except the declaration line
#>

param([string]$Root = (Get-Location).Path)
Write-Host "Analyzing TARGET script files in $Root ..."

$IgnoredKeywords = @('MapKey','ActKey','MapAxis','SetSCurve','SetKBRate','KeyAxis',
  'Exec','Configure','Trim','Chain','Lock','Release','MapThrottle','RemapButton',
  'MapControl','Include','SetLed')
$CallIgnoreList = @('MapKey','ActKey','SetKBRate','MapAxis','SetSCurve','MapControl',
  'RemapButton','Chain','Lock','Unlock','Release','SetLed','KeyAxis','Exec','AutoRepeat','SEQ')

# Built-ins and internal functions to ignore
$BuiltInFunctionIgnoreList = @(
  'sprintf','printf','strcpy','strcmp','strlen','strsub',
  'while','if','else','for','DeferCall','REXEC','AutoRepeat','SEQ',
  'SetKBRate','KeyAxis','include'
)
# Built-ins to check for argument references
$BuiltInArgCheckList = @('sprintf','printf','strcpy','strcmp','strlen','strsub')

# Collect all TARGET script files
$files = Get-ChildItem -Path $Root -Recurse -Include *.tmc,*.tmh,*.ttm |
  Where-Object { $_.Name -notin @('target.tmh','defines.tmh','sys.tmh','hid.tmh','ED_GameBindings.ttm') }

if (-not $files) {
  Write-Host "No script files found." -ForegroundColor Yellow
  exit
}

$globals=@();$locals=@();$functions=@();$calls=@();$refs=@();$functionScopes=@()

function Remove-CommentsPreserveLines([string]$text) {
  $chars = $text.ToCharArray()
  $inBlock = $false
  $inLine = $false

  for ($i = 0; $i -lt $chars.Length; $i++) {
    if (-not $inBlock -and -not $inLine) {
      if ($i + 1 -lt $chars.Length -and $chars[$i] -eq '/' -and $chars[$i + 1] -eq '*') {
        $inBlock = $true
        $chars[$i] = ' '
        $chars[$i + 1] = ' '
        $i++
        continue
      }
      if ($i + 1 -lt $chars.Length -and $chars[$i] -eq '/' -and $chars[$i + 1] -eq '/') {
        $inLine = $true
        $chars[$i] = ' '
        $chars[$i + 1] = ' '
        $i++
        continue
      }
      continue
    }

    if ($inBlock) {
      if ($i + 1 -lt $chars.Length -and $chars[$i] -eq '*' -and $chars[$i + 1] -eq '/') {
        $chars[$i] = ' '
        $chars[$i + 1] = ' '
        $inBlock = $false
        $i++
        continue
      }
      if ($chars[$i] -ne "`r" -and $chars[$i] -ne "`n") { $chars[$i] = ' ' }
      continue
    }

    if ($inLine) {
      if ($chars[$i] -eq "`r" -or $chars[$i] -eq "`n") {
        $inLine = $false
        continue
      }
      $chars[$i] = ' '
    }
  }

  return -join $chars
}

function Escape-RegexText([string]$text) {
  return [regex]::Escape($text)
}

$linesByFile = @{}
$i = 0
$total = $files.Count

foreach ($f in $files) {
  $i++
  Write-Host "[$i/$total] $($f.Name)..."
  $rawText = Get-Content $f -Raw
  $cleanText = Remove-CommentsPreserveLines $rawText
  $clean = $cleanText -split "`r?`n"
  $linesByFile[$f.Name] = $clean
  $braceDepth = 0
  $currentFunc = $null
  $pendingFunc = $null
  $funcStart = $null

  for ($j = 0; $j -lt $clean.Count; $j++) {
    $line = $clean[$j].Trim()
    if (-not $line) { continue }

    if ($pendingFunc -and $line -match '^\{') {
      $currentFunc = $pendingFunc
      $pendingFunc = $null
      if (-not $funcStart) { $funcStart = $j + 1 }
    }

    if ($line -match '^\s*(?:define\s+|(?:(?:int|float|void|char|string|alias)\s+))([A-Za-z_][A-Za-z0-9_]*)\s*\([^;{}]*\)\s*(\{)?\s*$') {
      $fn = $matches[1]
      $hasBrace = $matches[2]
      if ($fn.Length -gt 1 -and
         ($IgnoredKeywords -notcontains $fn) -and
         ($BuiltInFunctionIgnoreList -notcontains $fn)) {
        $functions += [pscustomobject]@{ File=$f.Name; Line=$j+1; Name=$fn }
        if ($hasBrace) {
          $currentFunc = $fn
          $pendingFunc = $null
          $funcStart = $null
        } else {
          $nextNonEmpty = ''
          for ($k = $j + 1; $k -lt $clean.Count; $k++) {
            $probe = $clean[$k].Trim()
            if ($probe) { $nextNonEmpty = $probe; break }
          }
          if ($nextNonEmpty -match '^\{') {
            $pendingFunc = $fn
            $currentFunc = $null
            $funcStart = $null
          }
        }
      }
    }

    if ($line -match '^\s*define\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?!\()') {
      $vn = $matches[1]
      $isFunctionLikeDefine = ($line -match '^\s*define\s+[A-Za-z_][A-Za-z0-9_]*\s*\(')
      if (-not $isFunctionLikeDefine) {
        $globals += [pscustomobject]@{ File=$f.Name; Line=$j+1; Name=$vn; Kind='define' }
      }
    }
    elseif ($line -match '^\s*(int|float|char|alias|string)\s+([A-Za-z_][A-Za-z0-9_]*)\s*(?!\()') {
      $vn = $matches[2]
      $remainder = $line.Substring($matches[0].Length)
      $isFunctionLike = ($line -match '\([^;{}]*\)')
      if (-not $isFunctionLike) {
        if ($braceDepth -eq 0) {
          $globals += [pscustomobject]@{ File=$f.Name; Line=$j+1; Name=$vn; Kind='typed' }
        } else {
          $locals += [pscustomobject]@{ File=$f.Name; Func=$currentFunc; Line=$j+1; Name=$vn }
        }
      }
    }

    $openCount = ([regex]::Matches($line, '\{')).Count
    if ($openCount -gt 0) {
      if (($currentFunc -or $pendingFunc) -and -not $funcStart) { $funcStart = $j + 1 }
      if ($pendingFunc) {
        $currentFunc = $pendingFunc
        $pendingFunc = $null
      }
      $braceDepth += $openCount
    }

    $closeCount = ([regex]::Matches($line, '\}')).Count
    if ($closeCount -gt 0) {
      $braceDepth -= $closeCount
      if ($braceDepth -lt 0) { $braceDepth = 0 }
      if ($braceDepth -eq 0 -and $currentFunc) {
        $functionScopes += [pscustomobject]@{ File=$f.Name; Name=$currentFunc; Start=$funcStart; End=$j+1 }
        $currentFunc = $null
        $funcStart = $null
      }
    }
  }
}

# Keep only true function definitions (not calls or control statements)
$allLines = @()
foreach ($f in $files) {
  $allLines += ($linesByFile[$f.Name] |
    Where-Object { $_ -notmatch '^\s*(?:define\s+)?(?:(?:int|float|void|char|string|alias)\s+)?(?!if\b|elseif\b|while\b|for\b)[A-Za-z_][A-Za-z0-9_]*\s*\([^;{}]*\)\s*(?:\{|$)' })
}
$allText = $allLines -join "`n"

# Detect function calls (including EXEC/DeferCall/REXEC)
foreach ($f in $functions) {
  if (($CallIgnoreList -contains $f.Name) -or ($BuiltInFunctionIgnoreList -contains $f.Name)) { continue }
  $fnEsc = Escape-RegexText $f.Name
  $p1 = '(?<![\w"&])' + $fnEsc + '\s*\('
  $p2 = "(?<![A-Za-z0-9_])$fnEsc(?![A-Za-z0-9_])"
  $p3 = "DeferCall\s*\([^,]+,\s*&$fnEsc\b"
  $p4 = 'REXEC\s*\([^,]+,[^,]+,"[^"]*' + $fnEsc + '\s*\('
  $p5 = 'EXEC\s*\(\s*"[^"]*\b' + $fnEsc + '\s*\('
  $p6 = 'AutoRepeat\s*\([^)]*\&\s*' + $fnEsc + '\b'
  $definitionPattern = "^\s*(?:define\s+)?(?:(?:int|float|void|char|string|alias)\s+)?$fnEsc\s*\("

  $c1 = [regex]::Matches($allText, $p1).Count
  $c2 = [regex]::Matches($allText, $p2).Count
  $c3 = [regex]::Matches($allText, $p3).Count
  $c4 = [regex]::Matches($allText, $p4).Count
  $c5 = [regex]::Matches($allText, $p5).Count
  $c6 = [regex]::Matches($allText, $p6).Count
  $defCount = [regex]::Matches(($linesByFile[$f.File] -join "`n"), $definitionPattern, 'Multiline').Count
  if ($defCount -gt 0) { $c2 = [Math]::Max(0, $c2 - $defCount) }

  if ($c1 -gt 0 -or $c3 -gt 0 -or $c4 -gt 0 -or $c5 -gt 0 -or $c6 -gt 0) { $calls += $f.Name }
  elseif ($c2 -gt 0) { $refs += $f.Name }
}

function Count-Matches($text, $pattern) { [regex]::Matches($text, $pattern).Count }

# Detect unused globals
$ug = @()
foreach ($g in $globals) {
  $nameEsc = Escape-RegexText $g.Name
  $pattern = "(?<![A-Za-z0-9_&])&?$nameEsc(?![A-Za-z0-9_])"
  $found = 0

  foreach ($fileName in $linesByFile.Keys) {
    $fileLines = $linesByFile[$fileName]
    for ($idx = 0; $idx -lt $fileLines.Count; $idx++) {
      $lineNo = $idx + 1
      if ($fileName -eq $g.File -and $lineNo -eq $g.Line) { continue }
      $found += [regex]::Matches($fileLines[$idx], $pattern).Count
    }
  }

  if ($found -eq 0) {
    foreach ($bi in $BuiltInArgCheckList) {
      $biEsc = Escape-RegexText $bi
      $bp = "$biEsc\s*\([^)]*&?$nameEsc"
      if (([regex]::Matches($allText, $bp)).Count -gt 0) {
        $found++
        break
      }
    }
  }

  if ($found -eq 0) { $ug += $g }
}

# Detect unused locals
$ul = @()
foreach ($l in $locals) {
  if (-not $l.Func) { continue }
  $scope = ($functionScopes | Where-Object { $_.File -eq $l.File -and $_.Name -eq $l.Func } | Select-Object -First 1)
  if ($scope) {
    $fl = $linesByFile[$l.File]
    $si = [Math]::Max(0, [int]$scope.Start - 1)
    $ei = [Math]::Min($fl.Count - 1, [int]$scope.End - 1)
    $fb = $fl[$si..$ei] -join "`n"
    $nameEsc = Escape-RegexText $l.Name
    $pattern = "(?<![A-Za-z0-9_&])&?$nameEsc(?![A-Za-z0-9_])"
    $found = (Count-Matches $fb $pattern)
    if ($found -le 1) {
      foreach ($bi in $BuiltInArgCheckList) {
        $biEsc = Escape-RegexText $bi
        $bp = "$biEsc\s*\([^)]*&?$nameEsc"
        if (([regex]::Matches($fb, $bp)).Count -gt 0) { $found++ }
      }
    }
    if ($found -le 1) { $ul += $l }
  }
}

# Determine unused and referenced-only functions
$uf = $functions | Where-Object { $_.Name -notin $calls -and $_.Name -notin $refs }
$rf = $functions | Where-Object { $_.Name -in $refs -and $_.Name -notin $calls }
$uf = $uf | Where-Object { $_.Name -notin $BuiltInFunctionIgnoreList }
$rf = $rf | Where-Object { $_.Name -notin $BuiltInFunctionIgnoreList }

function Get-UniqueSymbols($items) {
  $seen = @{}
  foreach ($item in $items) {
    $key = '{0}|{1}|{2}' -f $item.File, $item.Line, $item.Name
    if (-not $seen.ContainsKey($key)) { $seen[$key] = $item }
  }
  return $seen.Values | Sort-Object File, Line, Name
}

$ug = Get-UniqueSymbols $ug
$ul = Get-UniqueSymbols $ul
$rf = Get-UniqueSymbols $rf
$uf = Get-UniqueSymbols $uf

# Output
$report = Join-Path $Root 'UnusedSymbolsReport_v9_3.txt'
$O = @()
$O += "==================== Unused Global Variables ===================="
foreach ($x in $ug) { $O += "$($x.File)($($x.Line)): $($x.Name)" }
$O += ""
$O += "==================== Unused Local Variables ===================="
foreach ($x in $ul) { $O += "$($x.File)($($x.Line)): $($x.Name) (Declared in $($x.Func))" }
$O += ""
$O += "==================== Referenced (But Not Called) Functions ===================="
foreach ($x in $rf) { $O += "$($x.File)($($x.Line)): $($x.Name)" }
$O += ""
$O += "==================== Unused Functions ===================="
foreach ($x in $uf) { $O += "$($x.File)($($x.Line)): $($x.Name)" }
$O | Set-Content -Encoding UTF8 $report -Force

Write-Host "Analysis complete. Report saved to $report"
