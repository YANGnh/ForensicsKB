# ============================================================
# 取证资料库：例行体检
# 报告：图片断链 / 缺 frontmatter / 缺 H1 / 疑似乱码 / 缺 OCR / 孤儿图片
# 输出：_reports/integrity-report.txt
# 用法：pwsh -File tools/check-integrity.ps1 -Root <取证资料库根目录>
# ============================================================
param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)

$report = [System.Collections.Generic.List[string]]::new()
$ocrDir = Join-Path $Root 'ocr'
$reportDir = Join-Path $Root '_reports'
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

# 排除非语料文件：分区 README、根 INDEX、以及设计方案文档（后者含示例图片语法，不应计入断链）
$mds = Get-ChildItem $Root -Recurse -File -Filter *.md | Where-Object {
    $_.FullName -notmatch '\\templates\\|\\_reports\\' -and
    $_.Name -notmatch '^(README|INDEX)\.md$' -and
    $_.Name -notmatch '设计方案'
}
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

# ---- 受控词表校验（警告级，不阻断）----
# 词表见 tools/tag-vocabulary.json；未登记的标签只报告，便于归并或补登记
$vocabPath = Join-Path $PSScriptRoot 'tag-vocabulary.json'
$offVocab = [ordered]@{}
if (Test-Path -LiteralPath $vocabPath) {
    $vocab = [System.IO.File]::ReadAllText($vocabPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
    $allowed = @{}
    foreach ($grp in @('scenarios', 'competitions', 'tools', 'techniques')) {
        foreach ($v in $vocab.$grp) { if ($v) { $allowed[[string]$v] = $true } }
    }
    foreach ($f in $mds) {
        $text = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        $m = [regex]::Match($text, '(?m)^tags:\s*(.+)$')
        if (-not $m.Success) { continue }
        $raw = $m.Groups[1].Value.Trim().Trim('"').Trim('[', ']')
        # 与 build-index.ps1 一致：按逗号切分，保留含空格的多词标签
        foreach ($t in ($raw -split ',')) {
            $t = $t.Trim()
            if ($t -and -not $allowed.ContainsKey($t)) {
                if ($offVocab.Contains($t)) { $offVocab[$t] = $offVocab[$t] + 1 } else { $offVocab[$t] = 1 }
            }
        }
    }
}

$summary = @(
    "=== 取证资料库体检报告 $(Get-Date -Format 'yyyy-MM-dd HH:mm') ==="
    "文档数: $($mds.Count)"
    "图片断链: $broken"
    "缺frontmatter: $noFm"
    "缺H1: $noH1"
    "疑似乱码: $moji"
    "缺OCR(引用图无ocr文本): $noOcr"
    "孤儿图片: $($orphans.Count)"
    "非受控标签(警告): $($offVocab.Keys.Count)"
    ""
)
foreach ($o in $orphans) { $report.Add("孤儿图片: $($o.FullName.Replace($Root,'.'))") }
foreach ($k in $offVocab.Keys) {
    $report.Add("非受控标签: $k（$($offVocab[$k]) 篇）—— 请归并到既有标签，或登记到 tools/tag-vocabulary.json")
}
$all = $summary + $report
[System.IO.File]::WriteAllLines((Join-Path $reportDir 'integrity-report.txt'), $all, $utf8)
$all | ForEach-Object { Write-Host $_ }
