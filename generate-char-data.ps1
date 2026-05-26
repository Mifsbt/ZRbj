$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$spriteDir = Join-Path $scriptPath "Sprite"
$spriteFiles = Get-ChildItem -LiteralPath $spriteDir -Filter "icon_hero_*.png"
$spriteIds = @($spriteFiles | ForEach-Object { $_.BaseName -replace 'icon_hero_', '' } | Where-Object { $_ -match '^\d+$' })
[Array]::Sort([int[]]$spriteIds)

$html = [System.IO.File]::ReadAllText((Join-Path $scriptPath "index.html"), [System.Text.Encoding]::UTF8)
$existingIds = @()
$pattern = '(?<=^|\s|,)(\d+):\{n:'
$matches = [regex]::Matches($html, $pattern)
foreach ($m in $matches) { $existingIds += $m.Groups[1].Value }

$newIds = @()
foreach ($id in $spriteIds) {
  $found = $false
  foreach ($eid in $existingIds) { if ($eid -eq $id) { $found = $true; break } }
  if (-not $found) { $newIds += $id }
}

if ($newIds.Length -eq 0) { Write-Host "No new sprite files to add."; exit 0 }

$sb = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $newIds.Length; $i++) {
  $sb.Append("  ${newIds[$i]}:{n:'Hero${newIds[$i]}',j:1,f:[]}") | Out-Null
  if ($i -lt $newIds.Length - 1) { $sb.Append(",") | Out-Null }
  $sb.AppendLine() | Out-Null
}

$insertPos = $html.LastIndexOf("};")
if ($insertPos -ge 0) {
  $newHtml = $html.Substring(0, $insertPos) + "," + $sb.ToString().TrimEnd() + "`r`n" + $html.Substring($insertPos)
  [System.IO.File]::WriteAllText((Join-Path $scriptPath "index.html"), $newHtml, [System.Text.Encoding]::UTF8)
  Write-Host ("Added " + $newIds.Length + " new placeholder entries.")
} else {
  Write-Host "Error: cannot find end of CHAR_DATA"
}
