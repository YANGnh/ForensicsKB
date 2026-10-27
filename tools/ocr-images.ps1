# ============================================================
# 取证资料库 P4：图片 OCR 文本索引（L1 检索层）
# - 每张图片产出 ocr/<图片名>.txt（增量：已生成且图片未变则跳过）
# - 内置噪声过滤规则（§7.2.1 ②）：水印剥离、UI 固定元素标记
# - 无 tesseract 时产出 ocr/_pending.txt 待处理清单
# 用法：pwsh -File tools/ocr-images.ps1 -Root <取证资料库根目录>
#       可选 -Limit 50 只处理前 N 张（测试用）
# ============================================================
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [int]$Limit = 0
)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)

$ocrDir = Join-Path $Root 'ocr'
New-Item -ItemType Directory -Path $ocrDir -Force | Out-Null

# ---- 噪声过滤规则（标记不删除原文；OCR 文本中剥离） ----
$watermarks = @(
    '公众号·金星路406取证人',
    '金星路406取证人',
    '公众号: 金星路406取证人'
)
$uiChrome = @(
    '^序号\s+日志时间\s+主机名',
    '日志描述',
    '^过滤\s*$',
    '^搜索\s*$'
)

function Format-OcrText([string]$raw) {
    # 1) 剥离水印
    foreach ($w in $watermarks) { $raw = $raw.Replace($w, '[水印已滤除]') }
    # 2) 压缩空白
    $lines = $raw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($l in $lines) {
        $isChrome = $false
        foreach ($c in $uiChrome) { if ($l -match $c) { $isChrome = $true; break } }
        if ($isChrome) { $out.Add("[UI] $l") } else { $out.Add($l) }
    }
    return ($out -join "`r`n")
}

# ---- tesseract 发现：进程 PATH → 注册表机器 PATH（安装后环境快照未刷新时兜底） ----
$tess = Get-Command tesseract -ErrorAction SilentlyContinue
if (-not $tess) {
    $machinePath = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment' -Name Path -ErrorAction SilentlyContinue).Path
    $tessDir = ($machinePath -split ';' | Where-Object { $_ -match 'tesseract|ocr' } | Where-Object { Test-Path (Join-Path $_ 'tesseract.exe') } | Select-Object -First 1)
    if ($tessDir) {
        $env:Path = "$tessDir;$env:Path"
        $tess = Get-Command tesseract
        Write-Host "tesseract 已从注册表 PATH 发现: $tessDir"
    }
}
$images = Get-ChildItem $Root -Recurse -File | Where-Object { $_.Extension -in @('.png', '.jpg', '.jpeg', '.webp') -and $_.FullName -notlike "$ocrDir*" }
$done = 0; $skipped = 0; $noText = 0; $pending = [System.Collections.Generic.List[string]]::new()

if ($tess) {
    # 检查语言包
    $langs = 'eng'
    $tessLangs = & tesseract --list-langs 2>&1
    if ($tessLangs -match 'chi_sim') { $langs = 'chi_sim+eng' }
    Write-Host "tesseract: $($tess.Source) (langs: $langs)"
    $n = 0
    foreach ($img in $images) {
        if ($Limit -gt 0 -and $n -ge $Limit) { break }
        $n++
        $outFile = Join-Path $ocrDir ($img.Name + '.txt')
        if ((Test-Path $outFile) -and (Get-Item $outFile).LastWriteTime -ge $img.LastWriteTime) { $skipped++; continue }
        # PS5.1：tesseract 的 stderr 提示（如 Estimating resolution）在 EAP=Stop 下会抛 NativeCommandError，临时放宽
        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $raw = & tesseract $img.FullName stdout -l $langs 2>$null
        $ErrorActionPreference = $prevEap
        $header = "# OCR: $($img.Name)`r`n# 来源: $($img.FullName.Replace($Root,'.'))`r`n# 引擎: tesseract($langs)`r`n# 生成: $(Get-Date -Format 'yyyy-MM-dd HH:mm')`r`n`r`n"
        if ($LASTEXITCODE -eq 0 -and $raw) {
            $text = Format-OcrText ($raw -join "`r`n")
            [System.IO.File]::WriteAllText($outFile, $header + $text, $utf8)
            $done++
        } elseif ($LASTEXITCODE -eq 0) {
            # 识别成功但无文字（照片/纯图/空白截图）——标记"无文本"，避免永久挂起
            [System.IO.File]::WriteAllText($outFile, $header + '# 结果: 无可用文本（tesseract 未识别到文字）' + "`r`n", $utf8)
            $noText++
        } else {
            $pending.Add($img.FullName.Replace($Root, '.'))
        }
    }
} else {
    Write-Host "tesseract 未安装：跳过批量 OCR，生成待处理清单（可安装 tesseract 后重跑，或用 AI 视觉批量补 OCR）"
    foreach ($img in $images) {
        $outFile = Join-Path $ocrDir ($img.Name + '.txt')
        if (Test-Path $outFile) { $skipped++ } else { $pending.Add($img.FullName.Replace($Root, '.')) }
    }
}

[System.IO.File]::WriteAllLines((Join-Path $ocrDir '_pending.txt'), $pending, $utf8)
Write-Host "=== P4 完成：新生成 $done，无文本标记 $noText，跳过 $skipped，待处理 $($pending.Count)（见 ocr\_pending.txt）==="
