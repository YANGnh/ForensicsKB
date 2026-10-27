# ============================================================
# 取证资料库：多文件 WriteUp 合并工具
# 把一个比赛阶段的多个来源文件（md / docx转换md / pdf转换md）合并为一篇 KB 文档
# 用法：
#   pwsh -File tools/merge-writeup.ps1 -Out <目标md> -SectionPrefix <节标题前缀> -Files @(f1,f2,...)
#   pwsh -File tools/merge-writeup.ps1 -Out <目标md> -SectionPrefix "挑战" -Files (Get-ChildItem ...).FullName
# 特性：剥离源文件 frontmatter；去 PDF 页标注释；H1 降为 ## 节标题；空行规范化
# ============================================================
param(
    [Parameter(Mandatory)][string]$Out,
    [string]$SectionPrefix = '小节',
    [Parameter(Mandatory)][string[]]$Files
)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)

function Remove-Frontmatter([string]$content) {
    $lines = $content -split "`r?`n"
    if ($lines.Count -gt 2 -and $lines[0].Trim() -eq '---') {
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -eq '---') {
                return ($lines[($i + 1)..($lines.Count - 1)] -join "`r`n")
            }
        }
    }
    return $content
}

$sections = [System.Collections.Generic.List[string]]::new()
$n = 0
foreach ($f in $Files) {
    $n++
    if (-not (Test-Path -LiteralPath $f)) { Write-Host "跳过(不存在): $f"; continue }
    $content = [System.IO.File]::ReadAllText($f, [System.Text.Encoding]::UTF8)
    $content = Remove-Frontmatter $content
    # 去 PDF 页标注释
    $content = ($content -split "`r?`n" | Where-Object { $_ -notmatch '^<!-- PDF 第\d+页 -->$' }) -join "`r`n"
    # 提取 H1 作为节名（若存在）
    $title = [System.IO.Path]::GetFileNameWithoutExtension($f)
    $m = [regex]::Match($content, '(?m)^#\s+(.+)$')
    if ($m.Success) { $title = $m.Groups[1].Value.Trim() }
    # H1 → 节标题
    $content = [regex]::Replace($content, '(?m)^#\s+', '### ')
    # 压缩多余空行
    $content = [regex]::Replace($content, "(`r?`n){3,}", "`r`n`r`n").Trim()
    $sections.Add("## $SectionPrefix $n：$title`r`n`r`n$content")
}

$dir = Split-Path $Out -Parent
New-Item -ItemType Directory -Path $dir -Force | Out-Null
$joined = ($sections -join "`r`n`r`n---`r`n`r`n")
[System.IO.File]::WriteAllText($Out, $joined + "`r`n", $utf8)
Write-Host "合并完成: $Out ($($sections.Count) 节)"
