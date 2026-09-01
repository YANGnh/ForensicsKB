# ============================================================
# 取证知识库：新建比赛复盘
# 用法：pwsh -File tools/new-writeup.ps1 -Root <根目录> -Competition 美亚杯 -Year 2026 -Stage 决赛 [-Mode 个人赛]
# 产出：02-WriteUp/{Year}/{Year}-{Competition}-{Stage}.md（模板 + frontmatter 预填）
# ============================================================
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [Parameter(Mandatory)][string]$Competition,
    [Parameter(Mandatory)][string]$Year,
    [Parameter(Mandatory)][string]$Stage,
    [string]$Mode = ''
)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$today = Get-Date -Format 'yyyy-MM-dd'

$yearDir = Join-Path $Root "02-WriteUp\$Year"
New-Item -ItemType Directory -Path $yearDir -Force | Out-Null
$fileName = "$Year-$Competition-$Stage.md"
if ($Mode) { $fileName = "$Year-$Competition-$Stage-$Mode.md" }
$dst = Join-Path $yearDir $fileName
if (Test-Path $dst) { Write-Host "已存在: $fileName"; exit 1 }

$template = [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot '..\templates\writeup-template.md'), [System.Text.Encoding]::UTF8)
$title = "$Year $Competition $Stage"
if ($Mode) { $title = "$Year $Competition $Stage $Mode" }
$template = $template -replace 'title: 【比赛名】【年份】【阶段】', ("title: " + $title)
$template = $template -replace 'competition: 比赛名', ("competition: " + $Competition)
$template = $template -replace 'year: 2026', ("year: " + $Year)
$template = $template -replace 'stage: 初赛', ("stage: " + $Stage)
if ($Mode) { $template = $template -replace 'mode: 个人赛', ("mode: " + $Mode) }
$template = $template -replace 'created: 2026-01-01', ("created: " + $today)
$template = $template -replace 'updated: 2026-01-01', ("updated: " + $today)
$template = $template -replace '# 【比赛名】【年份】【阶段】复盘', ("# " + $title + " 复盘")

[System.IO.File]::WriteAllText($dst, $template, $utf8)
Write-Host "已创建: 02-WriteUp\$Year\$fileName"
Write-Host "下一步：填内容 → 截图入 $yearDir → pwsh tools\ocr-images.ps1 → pwsh tools\build-index.ps1"
