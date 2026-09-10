# ============================================================
# 取证知识库 P5：生成 INDEX.md（人读）+ index.json（机器读）
# 数据源：文档实际 frontmatter（单一事实源 tools/frontmatter-data.json 决定文件清单）
# 用法：pwsh -File tools/build-index.ps1 -Root <取证知识库根目录>
# ============================================================
param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)

$ocrDir = Join-Path $Root 'ocr'
$data = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot 'frontmatter-data.json'), [System.Text.Encoding]::UTF8) | ConvertFrom-Json

function Get-Frontmatter([string]$path) {
    $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    if (-not $text.TrimStart().StartsWith('---')) { return $null }
    $lines = $text -split "`r?`n"
    $fm = @{}
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { break }
        $m = [regex]::Match($lines[$i], '^([A-Za-z_]+):\s*(.*)$')
        if ($m.Success) { $fm[$m.Groups[1].Value] = $m.Groups[2].Value.Trim().Trim('"') }
    }
    return $fm
}

$docs = [System.Collections.Generic.List[object]]::new()
foreach ($doc in $data.docs) {
    $path = Join-Path $Root $doc.file
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $fm = Get-Frontmatter $path
    if (-not $fm) { continue }
    $text = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)

    # 图片数与 OCR 覆盖
    $imgRefs = [regex]::Matches($text, '(?:<img[^>]*src="|!\[[^\]]*\]\()([^")]+)') | ForEach-Object { $_.Groups[1].Value.Trim() } | Where-Object { $_ -notmatch '^(https?://|data:|/)' } | Sort-Object -Unique
    $ocrCovered = 0
    foreach ($ref in $imgRefs) {
        $base = [System.IO.Path]::GetFileName($ref)
        if (Test-Path (Join-Path $ocrDir ($base + '.txt'))) { $ocrCovered++ }
    }

    $tags = @()
    if ($fm['tags']) {
        # 按逗号切分（标签内允许含空格，如 "FTK Imager"）；此前按空白分词会把多词标签拆散
        $tags = @($fm['tags'].Trim().Trim('[', ']') -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
    }
    $docs.Add([pscustomobject]@{
        path = $doc.file
        title = $fm['title']
        type = $fm['type']
        category = $fm['category']
        competition = $fm['competition']
        year = $fm['year']
        stage = $fm['stage']
        mode = $fm['mode']
        tags = @($tags)
        images = $imgRefs.Count
        ocr_covered = $ocrCovered
        status = $fm['status']
        source = $fm['source']
        created = $fm['created']
        updated = $fm['updated']
        summary = $fm['summary']
        chars = $text.Length
    })
}

# ---- index.json ----
# 注意：JSON 标准不支持注释行。生成说明写入 _comment 字段，
# 以保证 index.json 可被 python/jq/各语言标准 JSON 解析器直接读取（此前以 '# ' 行前置会导致解析失败）。
$json = [ordered]@{
    _comment = '本文件由 tools/build-index.ps1 自动生成，禁止手改'
    generated_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')
    kb_name = '取证知识库'
    kb_root = '取证知识库/'
    doc_count = $docs.Count
    readme = 'README.md'
    docs = $docs
} | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText((Join-Path $Root 'index.json'), $json, $utf8)

# ---- INDEX.md ----
$rows = [System.Collections.Generic.List[string]]::new()
$rows.Add('| 路径 | 类型 | 标题 | 比赛 | 年份 | 阶段 | 标签 | 图 | OCR | 状态 |')
$rows.Add('|---|---|---|---|---|---|---|---|---|---|')
foreach ($d in ($docs | Sort-Object type, path)) {
    $tagStr = ($d.tags | Select-Object -First 6) -join ' '
    $rows.Add("| $($d.path) | $($d.type) | $($d.title) | $($d.competition) | $($d.year) | $($d.stage) | $tagStr | $($d.images) | $($d.ocr_covered) | $($d.status) |")
}
$md = @(
    '# 取证知识库索引'
    ''
    "> 由 tools/build-index.ps1 自动生成（$(Get-Date -Format 'yyyy-MM-dd HH:mm')），机器可读版本见 index.json，禁止手改。"
    ''
    "共 $($docs.Count) 篇文档；图片 $(($docs | Measure-Object images -Sum).Sum) 张（按文档去重），OCR 覆盖 $(($docs | Measure-Object ocr_covered -Sum).Sum) 处。"
    ''
) + $rows
[System.IO.File]::WriteAllText((Join-Path $Root 'INDEX.md'), ($md -join "`r`n"), $utf8)

# ---- 分区 README（随索引一并重建，避免手工维护过期）----
$stamp = "> 由 tools/build-index.ps1 自动生成（$(Get-Date -Format 'yyyy-MM-dd HH:mm')），禁止手改。"

function Format-Cell([string]$s) {
    if ([string]::IsNullOrEmpty($s)) { return '' }
    return ($s -replace '\|', '\|')
}

# 01-取证技巧/README.md
$tech = @($docs | Where-Object { $_.path -like '01-*' } | Sort-Object path)
$topicCounts = [ordered]@{}
foreach ($d in $tech) {
    $parts = $d.path -split '/'
    if ($parts.Count -ge 3) {
        $k = $parts[1]
        if ($topicCounts.Contains($k)) { $topicCounts[$k] = $topicCounts[$k] + 1 } else { $topicCounts[$k] = 1 }
    }
}
$t = [System.Collections.Generic.List[string]]::new()
$t.Add('# 取证技巧 · 方法与工具速查')
$t.Add('')
$t.Add($stamp)
$t.Add('')
$t.Add("共 $($tech.Count) 篇，按 $($topicCounts.Count) 个主题目录组织。文档内图片为相对路径；截图内容可先查 ocr/ 同名文本（L1 检索层），再决定是否看图（L2 视觉层）。")
$t.Add('')
$t.Add('## 主题目录')
$t.Add('')
$t.Add('| 目录 | 篇数 |')
$t.Add('|---|---|')
foreach ($k in $topicCounts.Keys) { $t.Add("| $k | $($topicCounts[$k]) |") }
$t.Add('')
$t.Add('## 全部文档')
$t.Add('')
$t.Add('| 文档 | 类型 | 标签 | 图 | 状态 | 摘要 |')
$t.Add('|---|---|---|---|---|---|')
foreach ($d in $tech) {
    $rel = $d.path -replace '^01-取证技巧/', ''
    $tagStr = (($d.tags | Select-Object -First 5) -join ' ')
    $t.Add("| [$rel]($rel) | $($d.type) | $tagStr | $($d.images) | $($d.status) | $(Format-Cell $d.summary) |")
}
[System.IO.File]::WriteAllText((Join-Path $Root '01-取证技巧\README.md'), ($t -join "`r`n"), $utf8)

# 02-WriteUp/README.md
$wu = @($docs | Where-Object { $_.path -like '02-*' })
$years = @($wu | ForEach-Object { $_.year } | Sort-Object -Unique -Descending)
$comps = @($wu | ForEach-Object { $_.competition } | Where-Object { $_ -and $_ -ne '未知' } | Sort-Object -Unique)
$w = [System.Collections.Generic.List[string]]::new()
$w.Add('# 比赛复盘总索引')
$w.Add('')
$w.Add($stamp)
$w.Add('')
$w.Add("共 $($wu.Count) 篇复盘，覆盖 $($years.Count) 个年份、$($comps.Count) 项赛事。正文结构为「题目 → 答案 → 思路/命令 → 截图」；答案以正文答案行为准，截图仅作证据与佐证。")
$w.Add('')
foreach ($y in $years) {
    $inYear = @($wu | Where-Object { $_.year -eq $y } | Sort-Object competition, stage, path)
    $w.Add("## $y（$($inYear.Count) 篇）")
    $w.Add('')
    $w.Add('| 比赛 | 阶段 | 标题 | 图 | 状态 | 文档 |')
    $w.Add('|---|---|---|---|---|---|')
    foreach ($d in $inYear) {
        $rel = $d.path -replace '^02-WriteUp/', ''
        $w.Add("| $($d.competition) | $($d.stage) | $(Format-Cell $d.title) | $($d.images) | $($d.status) | [$rel]($rel) |")
    }
    $w.Add('')
}
[System.IO.File]::WriteAllText((Join-Path $Root '02-WriteUp\README.md'), ($w -join "`r`n"), $utf8)

Write-Host "=== P5 完成：$($docs.Count) 篇索引已生成 ==="
Write-Host "  INDEX.md / index.json / 01-取证技巧/README.md / 02-WriteUp/README.md"
