# ============================================================
# 取证资料库：全文检索（正文 + OCR 截图文本）
# 数据源：index.json（文档元数据）+ 各文档引用的 ocr/<图片名>.txt
# 用法：
#   .\tools\search.ps1 docker-ce
#   .\tools\search.ps1 微信 -Competition 美亚杯 -Year 2025
#   .\tools\search.ps1 volatility -Type technique
#   .\tools\search.ps1 勒索 -OnlyOcr            # 只搜截图
#   .\tools\search.ps1 flag -List               # 只看命中哪些文档
#
# 参数：
#   -Pattern        关键词或正则（非法正则自动降级为纯文本匹配）
#   -Type           按类型过滤：writeup / technique / reference / training
#   -Competition    按比赛过滤（模糊匹配）
#   -Year/-Stage    按年份/阶段过滤（Stage 模糊匹配）
#   -Tags           按标签过滤（命中任一即可）
#   -OnlyDocs       只搜正文
#   -OnlyOcr        只搜截图 OCR
#   -List           只列出符合条件的文档，不做全文匹配
#   -CaseSensitive  区分大小写（默认不区分）
#   -Max            最多输出多少条命中（默认 200）
# ============================================================
param(
    [Parameter(Mandatory = $true, Position = 0)][string]$Pattern,
    [string]$Type,
    [string]$Competition,
    [string]$Year,
    [string]$Stage,
    [string[]]$Tags,
    [switch]$OnlyDocs,
    [switch]$OnlyOcr,
    [switch]$List,
    [switch]$CaseSensitive,
    [switch]$IncludeFrontmatter,
    [int]$Max = 200,
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)
$ErrorActionPreference = 'Stop'

$indexPath = Join-Path $Root 'index.json'
if (-not (Test-Path -LiteralPath $indexPath)) {
    Write-Host "找不到 index.json，请先运行：.\tools\build-index.ps1" -ForegroundColor Red
    exit 1
}
$idx = [System.IO.File]::ReadAllText($indexPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

# ---- 索引新鲜度提示（索引早于任何"被索引文档"时告警，避免漏检）----
# 只比较 index.json 中登记的语料文档，忽略 README/INDEX/设计方案等非语料文件
$indexed = @{}
foreach ($d in $idx.docs) { $indexed[$d.path] = $true }
$newest = Get-ChildItem $Root -Recurse -File -Filter *.md -ErrorAction SilentlyContinue |
    Where-Object {
        $rel = $_.FullName.Substring($Root.Length).TrimStart('\', '/') -replace '\\', '/'
        $indexed.ContainsKey($rel)
    } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($newest -and (Get-Item -LiteralPath $indexPath).LastWriteTime -lt $newest.LastWriteTime) {
    Write-Host "[提示] index.json 早于最新文档（$($newest.Name)），可能漏检，建议先运行 .\tools\build-index.ps1" -ForegroundColor Yellow
}

# ---- 过滤 ----
$sel = @($idx.docs)
if ($Type)        { $sel = @($sel | Where-Object { $_.type -eq $Type }) }
if ($Competition) { $sel = @($sel | Where-Object { $_.competition -like "*$Competition*" }) }
if ($Year)        { $sel = @($sel | Where-Object { $_.year -eq $Year }) }
if ($Stage)       { $sel = @($sel | Where-Object { $_.stage -like "*$Stage*" }) }
if ($Tags) {
    $sel = @($sel | Where-Object {
        $docTags = @($_.tags); $ok = $false
        foreach ($t in $Tags) { if ($docTags -contains $t) { $ok = $true; break } }
        $ok
    })
}
if ($sel.Count -eq 0) { Write-Host "没有符合过滤条件的文档。" -ForegroundColor Yellow; exit 0 }

if ($List) {
    Write-Host "=== 匹配文档 $($sel.Count) 篇 ===" -ForegroundColor Cyan
    foreach ($d in ($sel | Sort-Object path)) {
        Write-Host ("  [{0,-9}] {1}" -f $d.type, $d.path)
    }
    exit 0
}

# ---- 匹配器 ----
$opt = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
if ($CaseSensitive) { $opt = [System.Text.RegularExpressions.RegexOptions]::None }
try {
    $rx = New-Object System.Text.RegularExpressions.Regex($Pattern, $opt)
} catch {
    $rx = New-Object System.Text.RegularExpressions.Regex([regex]::Escape($Pattern), $opt)
    Write-Host "[提示] 不是合法正则，已按纯文本匹配。" -ForegroundColor Yellow
}

$hits = 0; $docHits = 0; $ocrHits = 0; $hitDocs = [System.Collections.Generic.HashSet[string]]::new()

# ---- 搜正文 ----
if (-not $OnlyOcr) {
    foreach ($d in ($sel | Sort-Object path)) {
        $full = Join-Path $Root $d.path
        if (-not (Test-Path -LiteralPath $full)) { continue }
        $lines = [System.IO.File]::ReadAllLines($full, [System.Text.Encoding]::UTF8)

        # 默认跳过 YAML frontmatter（title/tags/summary 属元数据噪声，
        # 需要按元数据筛选请用 -List / -Tags；要连同 frontmatter 一起搜用 -IncludeFrontmatter）
        $start = 0
        if (-not $IncludeFrontmatter -and $lines.Count -gt 1 -and $lines[0].Trim() -eq '---') {
            for ($i = 1; $i -lt $lines.Count; $i++) {
                if ($lines[$i].Trim() -eq '---') { $start = $i + 1; break }
            }
        }

        $n = 0
        for ($i = $start; $i -lt $lines.Count; $i++) {
            if ($hits -ge $Max) { break }
            if ($rx.IsMatch($lines[$i])) {
                Write-Host ("[正文] {0}:{1}" -f $d.path, ($i + 1)) -ForegroundColor Green
                Write-Host ("       " + $lines[$i].Trim())
                $hits++; $n++
                [void]$hitDocs.Add($d.path)
            }
        }
        if ($n -gt 0) { $docHits++ }
    }
}

# ---- 搜 OCR（截图文本），并回指所属文档 ----
if (-not $OnlyDocs) {
    $img2doc = @{}
    foreach ($d in $sel) {
        $full = Join-Path $Root $d.path
        if (-not (Test-Path -LiteralPath $full)) { continue }
        $txt = [System.IO.File]::ReadAllText($full, [System.Text.Encoding]::UTF8)
        foreach ($m in [regex]::Matches($txt, '!\[[^\]]*\]\(([^)]+)\)')) {
            $base = [System.IO.Path]::GetFileName($m.Groups[1].Value.Trim())
            if ($base -and -not $img2doc.ContainsKey($base)) { $img2doc[$base] = $d.path }
        }
    }
    $ocrDir = Join-Path $Root 'ocr'
    foreach ($img in ($img2doc.Keys | Sort-Object)) {
        if ($hits -ge $Max) { break }
        $f = Join-Path $ocrDir ($img + '.txt')
        if (-not (Test-Path -LiteralPath $f)) { continue }
        $lines = [System.IO.File]::ReadAllLines($f, [System.Text.Encoding]::UTF8)
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($hits -ge $Max) { break }
            if ($lines[$i].StartsWith('#')) { continue }   # 跳过 OCR 文件头
            if ($rx.IsMatch($lines[$i])) {
                Write-Host ("[截图] {0}  →  {1}" -f $img, $img2doc[$img]) -ForegroundColor DarkCyan
                Write-Host ("       " + $lines[$i].Trim())
                $hits++; $ocrHits++
                [void]$hitDocs.Add($img2doc[$img])
            }
        }
    }
}

Write-Host ""
Write-Host ("=== 命中 {0} 条（正文 {1} 篇 / 截图 {2} 条），涉及 {3} 篇文档 ===" -f $hits, $docHits, $ocrHits, $hitDocs.Count) -ForegroundColor Cyan
if ($hits -ge $Max) { Write-Host "（已达 -Max $Max 上限，可能还有更多命中）" -ForegroundColor Yellow }
if ($hits -eq 0) { Write-Host "没有命中。可换关键词，或用 -List 先确认过滤范围。" -ForegroundColor Yellow }
