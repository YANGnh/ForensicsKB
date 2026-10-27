# ============================================================
# 取证资料库 P1 迁移脚本
# 功能：把 取证笔记/ 的 54 篇 md + 3,285 张图复制进 取证资料库/
#       （源目录只读，不修改）；执行 WriteUp 重命名、技巧归类、
#       图片按引用复制。产出迁移清单到 _reports/。
# 用法：pwsh -File tools/migrate.ps1
# ============================================================
param(
    [string]$Src = "..\..\取证笔记",
    [string]$Dst = ".."
)
$ErrorActionPreference = "Stop"

$srcRoot = (Resolve-Path $Src).Path
$dstRoot = (Resolve-Path $Dst).Path
$reportDir = Join-Path $dstRoot "_reports"
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null

$manifest = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$utf8 = [System.Text.UTF8Encoding]::new($false)

Write-Host "源: $srcRoot"
Write-Host "目标: $dstRoot"

# ---------------- WriteUp 重命名映射：源相对路径 → 目标相对路径 ----------------
$writeupMap = @(
    # 2024
    @('WriteUp\2024WP\2024FIC第四届全国网络空间取证竞赛决赛参考wp.md', '02-WriteUp\2024\2024-FIC-决赛.md'),
    @('WriteUp\2024WP\2024FIC第四届全国网络空间取证竞赛线上初赛全解参考wp.md', '02-WriteUp\2024\2024-FIC-初赛.md'),
    @('WriteUp\2024WP\2024“美亚杯”第十届中国电子数据取证大赛团队赛参考WP.md', '02-WriteUp\2024\2024-美亚杯-团队赛.md'),
    @('WriteUp\2024WP\2024“美亚杯”第十届中国电子数据取证大赛资格赛参考WP.md', '02-WriteUp\2024\2024-美亚杯-资格赛.md'),
    @('WriteUp\2024WP\2024国赛个人赛（数证杯决赛）（自己写的）.md', '02-WriteUp\2024\2024-数证杯-决赛个人赛.md'),
    @('WriteUp\2024WP\2024国赛团体赛（数证杯决赛）（自己写的.md', '02-WriteUp\2024\2024-数证杯-决赛团体赛.md'),
    @('WriteUp\2024WP\2024国赛复盘.md', '02-WriteUp\2024\2024-国赛-复盘.md'),
    @('WriteUp\2024WP\2024数证杯初赛WP.md', '02-WriteUp\2024\2024-数证杯-初赛.md'),
    @('WriteUp\2024WP\2024第二届“盘古石杯”全国电子数据取证大赛总决赛不完全题解.md', '02-WriteUp\2024\2024-盘古石杯-总决赛.md'),
    @('WriteUp\2024WP\2024警察大学第七届“精武杯”电子数据取证技能比武暨信息安全协会社团邀请赛参考wp.md', '02-WriteUp\2024\2024-精武杯-比武.md'),
    @('WriteUp\2024WP\2024龙信杯WP.md', '02-WriteUp\2024\2024-龙信杯.md'),
    @('WriteUp\2024WP\【全解】2024第二届“盘古石杯”全国电子数据取证大赛晋级赛参考WP.md', '02-WriteUp\2024\2024-盘古石杯-晋级赛.md'),
    @('WriteUp\2024WP\某电子取证比武复盘WP.md', '02-WriteUp\2024\2024-电子取证比武-复盘.md'),
    # 2025
    @('WriteUp\2025WP\202507能力验证（总队培训）.md', '02-WriteUp\2025\2025-能力验证-培训.md'),
    @('WriteUp\2025WP\20250925广西职业技能大赛.md', '02-WriteUp\2025\2025-广西职业技能大赛.md'),
    @('WriteUp\2025WP\20251218.md', '02-WriteUp\2025\2025-国赛-复盘.md'),
    @('WriteUp\2025WP\2025FIC全国网络空间取证大赛初赛参考WP（除数据分析题目）.md', '02-WriteUp\2025\2025-FIC-初赛参考WP.md'),
    @('WriteUp\2025WP\2025FIC决赛-WXjzc.md', '02-WriteUp\2025\2025-FIC-决赛-WXjzc.md'),
    @('WriteUp\2025WP\2025FIC决赛-XDforensics-wiki.md', '02-WriteUp\2025\2025-FIC-决赛-XDforensics-wiki.md'),
    @('WriteUp\2025WP\2025FIC初赛.md', '02-WriteUp\2025\2025-FIC-初赛.md'),
    @('WriteUp\2025WP\2025山东联赛.md', '02-WriteUp\2025\2025-山东联赛.md'),
    @('WriteUp\2025WP\2025平航杯.md', '02-WriteUp\2025\2025-平航杯.md'),
    @('WriteUp\2025WP\2025年盘古石决赛.md', '02-WriteUp\2025\2025-盘古石杯-决赛.md'),
    @('WriteUp\2025WP\2025数证杯决赛个人赛.md', '02-WriteUp\2025\2025-数证杯-决赛个人赛.md'),
    @('WriteUp\2025WP\2025数证杯决赛团队赛.md', '02-WriteUp\2025\2025-数证杯-决赛团队赛.md'),
    @('WriteUp\2025WP\2025数证杯决赛团队赛附加题试卷.md', '02-WriteUp\2025\2025-数证杯-决赛附加题.md'),
    @('WriteUp\2025WP\2025数证杯初赛.md', '02-WriteUp\2025\2025-数证杯-初赛.md'),
    @('WriteUp\2025WP\2025盘古石杯初赛.md', '02-WriteUp\2025\2025-盘古石杯-初赛.md'),
    @('WriteUp\2025WP\2025第二届獬豸杯电子数据取证竞赛参考WP.md', '02-WriteUp\2025\2025-獬豸杯.md'),
    @('WriteUp\2025WP\2025美亚杯.md', '02-WriteUp\2025\2025-美亚杯.md'),
    @('WriteUp\2025WP\2025陕西联赛-团体赛.md', '02-WriteUp\2025\2025-陕西联赛-团体赛.md'),
    @('WriteUp\2025WP\2025龙信杯电子数据取证竞赛Writeup.md', '02-WriteUp\2025\2025-龙信杯.md'),
    # 2026
    @('WriteUp\2026WP\20260623初赛.md', '02-WriteUp\2026\2026-南宁-初赛.md'),
    @('WriteUp\2026WP\20260626团队赛.md', '02-WriteUp\2026\2026-南宁-团队赛.md')
)

$imgExts = @('.png', '.jpg', '.jpeg')

# ---------------- 复制 WriteUp md（重命名） ----------------
foreach ($m in $writeupMap) {
    $s = Join-Path $srcRoot $m[0]
    $d = Join-Path $dstRoot $m[1]
    if (-not (Test-Path -LiteralPath $s)) { $warnings.Add("缺失源文件: $($m[0])"); continue }
    Copy-Item -LiteralPath $s -Destination $d -Force
    $manifest.Add("md,$($m[0]),$($m[1])")
}

# ---------------- 复制 WriteUp 图片（按年份整目录平铺） ----------------
foreach ($yr in @('2024', '2025', '2026')) {
    $srcImgDir = Join-Path $srcRoot "WriteUp\${yr}WP"
    $dstImgDir = Join-Path $dstRoot "02-WriteUp\$yr"
    if (-not (Test-Path -LiteralPath $srcImgDir)) { continue }
    $imgs = Get-ChildItem -LiteralPath $srcImgDir -File | Where-Object { $_.Extension -in $imgExts }
    foreach ($img in $imgs) {
        Copy-Item -LiteralPath $img.FullName -Destination (Join-Path $dstImgDir $img.Name) -Force
    }
    $manifest.Add("imgdir,WriteUp\${yr}WP,$($imgs.Count) 张 → 02-WriteUp\$yr")
    Write-Host "  [img] $yr : $($imgs.Count) 张"
}

# ---------------- 取证技巧：归类 + 按引用复制图片 ----------------
$topicMap = @(
    @('内存分析.md', '01-内存取证'),
    @('WireShark分析实战手册.md', '02-网络取证'),
    @('网络流量分析.md', '02-网络取证'),
    @('Cobaltstrike流量解密.md', '02-网络取证'),
    @('hashcat wiki.md', '03-密码加密'),
    @('加解密.md', '03-密码加密'),
    @('常见文件文件头和隐写术总结.md', '04-隐写文件'),
    @('APK分析.md', '05-应用分析'),
    @('小众APK分析.md', '05-应用分析'),
    @('程序功能分析.md', '05-应用分析'),
    @('数据库分析.md', '06-数据库'),
    @('服务器分析.md', '07-服务器云'),
    @('K8s分析.md', '07-服务器云'),
    @('手机取证分析.md', '08-手机取证'),
    @('介质分析.md', '09-介质磁盘'),
    @('Windows日志事件ID表.md', '10-日志分析'),
    @('取证软件使用.md', '11-工具速查'),
    @('正则表达式.md', '11-工具速查'),
    @('20230515美亚培训.md', '99-培训记录'),
    @('20240716鉴定所培训.md', '99-培训记录')
)

$srcTechImgDir = Join-Path $srcRoot '取证技巧'
$techImages = Get-ChildItem -LiteralPath $srcTechImgDir -File | Where-Object { $_.Extension -in $imgExts }
$usedImages = @{}

foreach ($m in $topicMap) {
    $s = Join-Path $srcTechImgDir $m[0]
    $d = Join-Path $dstRoot "01-取证技巧\$($m[1])\$($m[0])"
    if (-not (Test-Path -LiteralPath $s)) { $warnings.Add("缺失源文件: 取证技巧\$($m[0])"); continue }
    Copy-Item -LiteralPath $s -Destination $d -Force
    $manifest.Add("md,取证技巧\$($m[0]),01-取证技巧\$($m[1])\$($m[0])")
    # 解析该 md 引用的图片并复制到同目录
    $content = [System.IO.File]::ReadAllText($s, [System.Text.Encoding]::UTF8)
    [regex]::Matches($content, '(?:<img[^>]*src="|!\[[^\]]*\]\()([^")]+)') | ForEach-Object {
        $name = $_.Groups[1].Value.Trim()
        if ($name -match '^(https?://|data:|/)') { return }
        $usedImages[$name] = $true
        $imgSrc = Join-Path $srcTechImgDir $name
        if (Test-Path -LiteralPath $imgSrc) {
            Copy-Item -LiteralPath $imgSrc -Destination (Join-Path $dstRoot "01-取证技巧\$($m[1])\$name") -Force
        } else {
            $warnings.Add("技巧引用图片缺失: $($m[0]) → $name")
        }
    }
}

# 取证技巧未引用图片 → _未引用
$leftovers = $techImages | Where-Object { -not $usedImages.ContainsKey($_.Name) }
foreach ($img in $leftovers) {
    Copy-Item -LiteralPath $img.FullName -Destination (Join-Path $dstRoot "01-取证技巧\_未引用\$($img.Name)") -Force
    $manifest.Add("img,取证技巧未引用,$($img.Name)")
    $warnings.Add("取证技巧未引用图片(已复制到 _未引用): $($img.Name)")
}

# ---------------- 报告 ----------------
$manifestPath = Join-Path $reportDir 'migration-manifest.csv'
$warnPath = Join-Path $reportDir 'migration-warnings.txt'
[System.IO.File]::WriteAllLines($manifestPath, $manifest, $utf8)
[System.IO.File]::WriteAllLines($warnPath, $warnings, $utf8)
Write-Host ""
Write-Host "=== 迁移完成 ==="
Write-Host "md 复制: $($manifest | Where-Object { $_ -like 'md,*' } | Measure-Object).Count 条"
Write-Host "警告: $($warnings.Count) 条（详见 _reports\migration-warnings.txt）"
$warnings | ForEach-Object { Write-Host "  WARN: $_" }
