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
        $tags = [regex]::Matches($fm['tags'], '[\w\u4e00-\u9fff\-\.]+') | ForEach-Object { $_.Value } | Where-Object { $_ -notmatch '^\[|\]$' }
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
$json = [ordered]@{
    generated_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK')
    kb_name = '取证知识库'
    kb_root = '取证知识库/'
    doc_count = $docs.Count
    readme = 'README.md'
    docs = $docs
} | ConvertTo-Json -Depth 6
$json = '# 本文件由 tools/build-index.ps1 生成，禁止手改' + "`r`n" + $json
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
    "共 $($docs.Count) 篇文档；图片总引用 $(($docs | Measure-Object images -Sum).Sum) 处，OCR 覆盖 $(($docs | Measure-Object ocr_covered -Sum).Sum) 处。"
    ''
) + $rows
[System.IO.File]::WriteAllText((Join-Path $Root 'INDEX.md'), ($md -join "`r`n"), $utf8)

Write-Host "=== P5 完成：$($docs.Count) 篇索引已生成 ==="
Write-Host "  INDEX.md / index.json"
