# ============================================================
# 取证知识库：例行体检
# 报告：图片断链 / 缺 frontmatter / 缺 H1 / 疑似乱码 / 缺 OCR / 孤儿图片
# 输出：_reports/integrity-report.txt
# 用法：pwsh -File tools/check-integrity.ps1 -Root <取证知识库根目录>
# ============================================================
param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)

$report = [System.Collections.Generic.List[string]]::new()
$ocrDir = Join-Path $Root 'ocr'
$reportDir = Join-Path $Root '_reports'
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

$mds = Get-ChildItem $Root -Recurse -File -Filter *.md | Where-Object { $_.FullName -notmatch '\\templates\\|\\_reports\\' -and $_.Name -notin @('README.md', 'INDEX.md', '设计方案.md') }
$broken = 0; $noFm = 0; $noH1 = 0; $moji = 0; $noOcr = 0
$referenced = @{}

foreach ($f in $mds) {
    $rel = $f.FullName.Replace($Root, '.')
    $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    # frontmatter
    if (-not $text.TrimStart().StartsWith('---')) { $noFm++; $report.Add("缺frontmatter: $rel") }
    # 乱码
    if (([regex]::Matches($text, [char]0xFFFD)).Count -gt 0) { $moji++; $report.Add("含替换符(U+FFFD): $rel") }
    # H1（frontmatter 之后首个非空行；按行定位首对 ---，避免正文含 --- 误切）
    $body = $text
    $linesAll = $text -split "`r?`n"
    if ($linesAll.Count -gt 2 -and $linesAll[0].Trim() -eq '---') {
        for ($i = 1; $i -lt $linesAll.Count; $i++) {
            if ($linesAll[$i].Trim() -eq '---') { $body = ($linesAll[($i + 1)..($linesAll.Count - 1)] -join "`r`n"); break }
        }
    }
    $first = ($body -split "`r?`n" | Where-Object { $_.Trim() -ne '' } | Select-Object -First 1)
    if (-not $first -or $first -notmatch '^#\s') { $noH1++; $report.Add("缺H1: $rel") }
    # 图片引用
    $dir = $f.DirectoryName
    [regex]::Matches($text, '(?:<img[^>]*src="|!\[[^\]]*\]\()([^")]+)') | ForEach-Object {
        $name = $_.Groups[1].Value.Trim()
        if ($name -match '^(https?://|data:|/)') { return }
        if (-not (Test-Path (Join-Path $dir $name))) { $broken++; $report.Add("图片断链: $rel → $name") }
        $base = [System.IO.Path]::GetFileName($name)
        $referenced[$base] = $true
        if (-not (Test-Path (Join-Path $ocrDir ($base + '.txt')))) { $noOcr++; }
    }
}
# 孤儿图片（被引用集合之外）
$imgExts = @('.png', '.jpg', '.jpeg', '.webp')
$allImgs = Get-ChildItem $Root -Recurse -File | Where-Object { $_.Extension -in $imgExts -and $_.FullName -notlike "$ocrDir*" }
$orphans = $allImgs | Where-Object { -not $referenced.ContainsKey($_.Name) }

$summary = @(
    "=== 取证知识库体检报告 $(Get-Date -Format 'yyyy-MM-dd HH:mm') ==="
    "文档数: $($mds.Count)"
    "图片断链: $broken"
    "缺frontmatter: $noFm"
    "缺H1: $noH1"
    "疑似乱码: $moji"
    "缺OCR(引用图无ocr文本): $noOcr"
    "孤儿图片: $($orphans.Count)"
    ""
)
foreach ($o in $orphans) { $report.Add("孤儿图片: $($o.FullName.Replace($Root,'.'))") }
$all = $summary + $report
[System.IO.File]::WriteAllLines((Join-Path $reportDir 'integrity-report.txt'), $all, $utf8)
$all | ForEach-Object { Write-Host $_ }
