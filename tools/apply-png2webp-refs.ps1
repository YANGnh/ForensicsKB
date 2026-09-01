# ============================================================
# 取证知识库：应用 PNG→WebP 映射（在 compress-png2webp.ps1 之后运行）
# 1) 改写全部 md 中的图片引用：hash.png → hash.webp（按映射表，保留 alt 文本）
# 2) 删除已转换的旧 PNG（映射表中的名字，任意目录）
# 3) 清理失效的 OCR 文本（旧 hash.png.txt）
# 用法：pwsh -File tools/apply-png2webp-refs.ps1 -Root <根目录>
# ============================================================
param([string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)

$mapPath = Join-Path $PSScriptRoot 'image-map-png2webp.json'
if (-not (Test-Path $mapPath)) { Write-Host "映射表不存在，先运行 compress-png2webp.ps1"; exit 1 }
$mapObj = [System.IO.File]::ReadAllText($mapPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$map = @{}
foreach ($prop in $mapObj.map.PSObject.Properties) { $map[$prop.Name] = $prop.Value }
Write-Host "映射条目: $($map.Count)"

# 1) 改写 md 引用（映射表键为 hash.png，正则捕获 32 位哈希，查找时补 .png 后缀）
$changed = 0; $refTotal = 0; $refMapped = 0; $refMiss = [System.Collections.Generic.List[string]]::new()
Get-ChildItem $Root -Recurse -File -Filter *.md | Where-Object { $_.FullName -notmatch '\\templates\\|\\_reports\\' -and $_.Name -ne '设计方案.md' } | ForEach-Object {
    $text = [System.IO.File]::ReadAllText($_.FullName, [System.Text.Encoding]::UTF8)
    $orig = $text
    $refTotal += ([regex]::Matches($text, '!\[[^\]]*\]\(([0-9a-f]{32})\.png\)')).Count
    $text = [regex]::Replace($text, '(!\[[^\]]*\]\()([0-9a-f]{32})\.png(\))', {
        param($m)
        $old = $m.Groups[2].Value + '.png'
        if ($map.ContainsKey($old)) { $refMapped++; return $m.Groups[1].Value + $map[$old] + $m.Groups[3].Value }
        $refMiss.Add($old)
        return $m.Value
    })
    if ($text -ne $orig) {
        [System.IO.File]::WriteAllText($_.FullName, $text, $utf8)
        $changed++
    }
}
Write-Host "md 改写: $changed 篇 | 图片引用 $refTotal 处 | 已映射 $refMapped 处 | 未映射 $($refMiss.Count)"
if ($refMiss.Count -gt 0) { $refMiss | Select-Object -First 5 | ForEach-Object { "  未映射: $_" } }

# 2) 删除已转换的旧 PNG
$delCount = 0
Get-ChildItem $Root -Recurse -File -Filter *.png | Where-Object { $_.FullName -notmatch '\\ocr\\' } | ForEach-Object {
    if ($map.ContainsKey($_.Name)) {
        Remove-Item $_.FullName -Force
        $delCount++
    }
}
Write-Host "已删除旧 PNG: $delCount 个"

# 3) 清理失效 OCR 文本（旧 hash.png.txt；映射表键为 hash.png）
$ocrDir = Join-Path $Root 'ocr'
$ocrDel = 0
if (Test-Path $ocrDir) {
    Get-ChildItem $ocrDir -File -Filter '*.png.txt' | ForEach-Object {
        $base = $_.BaseName  # xxx.png
        $hashName = [System.IO.Path]::GetFileNameWithoutExtension($base)  # hash
        if ($map.ContainsKey($hashName + '.png')) {
            Remove-Item $_.FullName -Force
            $ocrDel++
        }
    }
}
Write-Host "已清理旧 OCR 文本: $ocrDel 个"
Write-Host "=== 完成：下一步跑 ocr-images.ps1 生成新 WebP 的 OCR ==="
