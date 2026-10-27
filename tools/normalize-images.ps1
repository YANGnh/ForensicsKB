# ============================================================
# 取证资料库 P3：正文规范化
# 1) <img src="x" ...> → ![](x)（统一图片语法）
# 2) 断图引用（hash. 缺扩展名 / ../attachments/ 失效路径）→ <!-- 缺失图片: x -->
# 3) 缺 H1 标题的文件补 # {title}（取自 frontmatter）
# 4) 清理 <br/> 噪音
# 用法：pwsh -File tools/normalize-images.ps1 -Root <取证资料库根目录>
# ============================================================
param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)

$report = [System.Collections.Generic.List[string]]::new()
$files = Get-ChildItem $Root -Recurse -File -Filter *.md | Where-Object { $_.FullName -notmatch '\\templates\\|\\_reports\\' }
$changed = 0

foreach ($f in $files) {
    $content = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $orig = $content

    # ---- 拆 frontmatter 与正文 ----
    $fmBlock = ''
    $fmTitle = ''
    $body = $content
    if ($content.TrimStart().StartsWith('---')) {
        $lines = $content -split "`r?`n"
        $fmEnd = -1
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -eq '---') { $fmEnd = $i; break }
        }
        if ($fmEnd -gt 0) {
            $fmBlock = ($lines[0..$fmEnd] -join "`r`n") + "`r`n"
            $body = ($lines[($fmEnd + 1)..($lines.Count - 1)] -join "`r`n")
            $m = [regex]::Match($fmBlock, 'title:\s*"([^"]*)"')
            if (-not $m.Success) { $m = [regex]::Match($fmBlock, 'title:\s*([^\r\n]+)') }
            if ($m.Success) { $fmTitle = $m.Groups[1].Value.Trim().Trim('"') }
        }
    }

    # ---- <br/> → 空行 ----
    $body = $body -replace '<br\s*/?>', "`r`n"

    # ---- <img src="x" ...> → ![](x) ----
    $imgRx = '<img\s+[^>]*?src=["'']([^"'']+)["''][^>]*?/?>'
    $body = [regex]::Replace($body, $imgRx, {
        param($m) '![](' + $m.Groups[1].Value + ')'
    })

    # ---- 断图引用 → 注释（hash. 缺扩展名 / ../attachments/ 失效路径） ----
    $brokenRx = '!\[[^\]]*\]\((?:[0-9a-f]{32}\.|\.\./attachments/[^)]+)\)'
    foreach ($b in [regex]::Matches($body, $brokenRx)) {
        $report.Add("缺失图片: $($f.FullName.Replace($Root,'.')) → $($b.Value)")
    }
    $body = [regex]::Replace($body, $brokenRx, '<!-- 缺失图片（转载源图未导出） -->')

    # ---- 补 H1 ----
    $bodyLines = $body -split "`r?`n"
    $hasH1 = $false
    foreach ($l in $bodyLines) {
        $t = $l.Trim()
        if ($t -eq '') { continue }
        if ($t -match '^#\s') { $hasH1 = $true }
        break
    }
    if (-not $hasH1 -and $fmTitle) {
        $body = "# $fmTitle`r`n`r`n" + $body
        $report.Add("补H1: $($f.FullName.Replace($Root,'.')) → $fmTitle")
    }

    # ---- 压缩多余空行（≥3 连续空行 → 2） ----
    $body = [regex]::Replace($body, "(`r?`n){3,}", "`r`n`r`n")

    # ---- 重组 ----
    $newContent = if ($fmBlock) { $fmBlock + $body } else { $body }
    if ($newContent -ne $orig) {
        [System.IO.File]::WriteAllText($f.FullName, $newContent, $utf8)
        $changed++
    }
}

Write-Host "=== P3 完成：修改 $changed / $($files.Count) 篇 ==="
$report | ForEach-Object { Write-Host "  $_" }
Write-Host "报告共 $($report.Count) 条"
