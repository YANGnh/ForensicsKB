# ============================================================
# 取证资料库：PNG → WebP 批量压缩工具（方案 A）
# - 遍历全部 .png（排除 ocr/），ffmpeg libwebp 转 q90
# - 新文件按内容 MD5 哈希命名（hash.webp），与知识库命名模型一致（自动去重）
# - 生成映射表 tools/image-map-png2webp.json（供 md 引用改写）
# - 转换失败的 PNG 保留原样（不进映射表）
# 用法：pwsh -File tools/compress-png2webp.ps1 -Root <根目录> [-Quality 90]
# ============================================================
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [int]$Quality = 90
)
$ErrorActionPreference = 'Continue'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$ff = "D:\Programs\ffmpeg-8.0-essentials_build\bin\ffmpeg.exe"
if (-not (Test-Path $ff)) { Write-Host "ffmpeg 未找到: $ff"; exit 1 }

$map = [ordered]@{}
$failed = [System.Collections.Generic.List[string]]::new()
$pngs = Get-ChildItem $Root -Recurse -File -Filter *.png | Where-Object { $_.FullName -notmatch '\\ocr\\' }
$total = $pngs.Count
$done = 0
$tmpDir = Join-Path $env:TEMP 'png2webp_tmp'
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

$md5 = [System.Security.Cryptography.MD5]::Create()
$started = Get-Date

foreach ($img in $pngs) {
    $done++
    if ($done % 200 -eq 0) { Write-Host "[$done/$total] 已处理 $([Math]::Round(($done/$total)*100))% $([Math]::Round(((Get-Date)-$started).TotalSeconds))s" }
    $tmp = Join-Path $tmpDir ("t_" + [guid]::NewGuid().ToString('N') + ".webp")
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $ff -y -loglevel error -i $img.FullName -c:v libwebp -quality $Quality $tmp 2>$null
    $ErrorActionPreference = $prevEap
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $tmp)) {
        $failed.Add($img.FullName)
        Remove-Item $tmp -ErrorAction SilentlyContinue
        continue
    }
    $bytes = [System.IO.File]::ReadAllBytes($tmp)
    $hash = [BitConverter]::ToString($md5.ComputeHash($bytes)).Replace('-', '').ToLower()
    $newName = "$hash.webp"
    $dest = Join-Path $img.DirectoryName $newName
    if (Test-Path $dest) { Remove-Item $tmp -Force } else { Move-Item $tmp $dest -Force }
    $map[$img.Name] = $newName
}

# 保存映射表
$mapJson = [ordered]@{ generated_at = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'); quality = $Quality; count = $map.Count; map = $map } | ConvertTo-Json -Depth 3
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot 'image-map-png2webp.json'), $mapJson, $utf8)
# 失败清单
[System.IO.File]::WriteAllLines((Join-Path $PSScriptRoot 'png2webp-failed.txt'), $failed, $utf8)

Write-Host "=== PNG→WebP 完成 ==="
Write-Host "总 PNG: $total | 成功: $($map.Count) | 失败: $($failed.Count)"
Write-Host "映射表: tools\image-map-png2webp.json | 失败清单: tools\png2webp-failed.txt"
