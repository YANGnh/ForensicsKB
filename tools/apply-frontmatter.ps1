# ============================================================
# 取证知识库 P2：为 54 篇文档生成 YAML Frontmatter
# 读取 tools/frontmatter-data.json（单一事实源），自动：
#   - 检测工具/场景标签（关键词扫描）
#   - 统计图片引用数
#   - 从正文首段生成摘要草稿
# 用法：pwsh -File tools/apply-frontmatter.ps1 -Root <取证知识库根目录>
# ============================================================
param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [switch]$Force,
    [switch]$NoAutoTags
)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)
$today = Get-Date -Format 'yyyy-MM-dd'

$jsonPath = Join-Path $PSScriptRoot 'frontmatter-data.json'
$data = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$docs = $data.docs

# 移除已存在的自动生成 frontmatter（用于 -Force 重生成）
function Remove-ExistingFrontmatter([string]$content) {
    if ($content.TrimStart().StartsWith('---')) {
        $lines = $content -split "`r?`n"
        if ($lines.Count -gt 2) {
            for ($i = 1; $i -lt $lines.Count; $i++) {
                if ($lines[$i].Trim() -eq '---') {
                    return ($lines[($i + 1)..($lines.Count - 1)] -join "`r`n")
                }
            }
        }
    }
    return $content
}

# 自动标签关键词表：关键词 -> 标签
$autoTagMap = [ordered]@{
    'volatility'   = 'Volatility'
    'wireshark'    = 'Wireshark'
    'hashcat'      = 'hashcat'
    'cyberchef'    = 'CyberChef'
    'winhex'       = 'WinHex'
    'jadx'         = 'JADX'
    'jeb'          = 'JEB'
    'burpsuite'    = 'BurpSuite'
    'exiftool'     = 'exiftool'
    'foremost'     = 'Foremost'
    'veracrypt'    = 'VeraCrypt'
    'registryexplorer' = 'RegistryExplorer'
    'passware'     = 'Passware'
    'sqlite'       = 'SQLite'
    'mysql'        = 'MySQL'
    'redis'        = 'Redis'
    'docker'       = 'Docker'
    'kubectl'      = 'kubectl'
    'k8s'          = 'K8s'
    'kubernetes'   = 'K8s'
    'telegram'     = 'Telegram'
    'apk'          = 'APK'
    'thinkphp'     = 'thinkphp'
    'webshell'     = 'webshell'
    'sql注入'      = 'SQL注入'
    '弱口令'       = '弱口令'
    '内存取证'     = '内存取证'
    '内存分析'     = '内存取证'
    '流量'         = '网络流量'
    '隐写'         = '隐写术'
    '注册表'       = '注册表'
    '手机取证'     = '手机取证'
    '安卓'         = '手机取证'
    '服务器取证'   = '服务器取证'
    '数据库'       = '数据库取证'
    '加解密'       = '加解密'
    '解密'         = '加解密'
    '日志'         = '日志分析'
    '磁盘'         = '磁盘取证'
    '介质'         = '介质分析'
    'k8s集群'      = '云原生'
}

function Get-YamlScalar([string]$v) {
    if ($null -eq $v) { return '""' }
    # YAML 双引号标量：统一转义反斜杠与双引号，稳妥且 Obsidian 兼容
    $escaped = ($v -replace '\\', '\\') -replace '"', '\"'
    return '"' + $escaped + '"'
}

$log = [System.Collections.Generic.List[string]]::new()
$updated = 0

foreach ($doc in $docs) {
    $path = Join-Path $Root $doc.file
    if (-not (Test-Path -LiteralPath $path)) { $log.Add("跳过(不存在): $($doc.file)"); continue }
    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    if ($Force) { $content = Remove-ExistingFrontmatter $content }
    if ($content.TrimStart().StartsWith('---')) { $log.Add("跳过(已有frontmatter): $($doc.file)"); continue }

    # ---- 图片引用数 ----
    $imgCount = ([regex]::Matches($content, '(?:<img[^>]*src="|!\[[^\]]*\]\()([^")]+)')).Count

    # ---- 标签：-NoAutoTags 时仅用 JSON 精修标签（不叠加自动检测，避免误配复活） ----
    $tags = [System.Collections.Generic.List[string]]::new()
    foreach ($t in $doc.tags) { if ($t -and -not $tags.Contains($t)) { $tags.Add($t) } }
    if (-not $NoAutoTags) {
        $lower = $content.ToLowerInvariant()
        foreach ($kv in $autoTagMap.GetEnumerator()) {
            if ($lower.Contains($kv.Key) -and -not $tags.Contains($kv.Value)) { $tags.Add($kv.Value) }
        }
    }
    if ($doc.competition -and $doc.competition -ne '未知' -and -not $tags.Contains($doc.competition)) { $tags.Insert(0, $doc.competition) }
    $tagStr = '[' + (($tags | Select-Object -First 10) -join ', ') + ']'

    # ---- 摘要：JSON 精修字段优先，否则自动草稿（跳过代码块内容） ----
    $summary = $doc.summary
    if (-not $summary) {
        $inFence = $false
        foreach ($line in ($content -split "`r?`n")) {
            $t = $line.Trim()
            if ($t.StartsWith('```')) { $inFence = -not $inFence; continue }
            if ($inFence) { continue }
            if ($t -eq '' -or $t.StartsWith('#') -or $t -match '^<br') { continue }
            if ($t -match '^(原创|转载|作者|来源)\s') { continue }
            $clean = [regex]::Replace($t, '!\[[^\]]*\]\([^)]*\)', '')
            $clean = [regex]::Replace($clean, '<img[^>]*/?>', '')
            $clean = [regex]::Replace($clean, '[*_`>#\-]', ' ').Trim()
            $clean = [regex]::Replace($clean, '\s+', ' ')
            if ($clean.Length -ge 6) { $summary = $clean; break }
        }
        if ($summary.Length -gt 100) { $summary = $summary.Substring(0, 100) + '…' }
        if (-not $summary) { $summary = $doc.title }
    }

    $fm = @(
        '---'
        ('title: ' + (Get-YamlScalar $doc.title))
        ('type: ' + $doc.type)
        ('category: ' + (Get-YamlScalar $doc.category))
        ('competition: ' + (Get-YamlScalar $doc.competition))
        ('year: ' + (Get-YamlScalar $doc.year))
        ('stage: ' + (Get-YamlScalar $doc.stage))
        ('mode: ' + (Get-YamlScalar $doc.mode))
        ('tags: ' + $tagStr)
        ('images: ' + $imgCount)
        ('status: ' + (Get-YamlScalar $doc.status))
        ('source: ' + (Get-YamlScalar $doc.source))
        ('created: ' + $(if ($doc.created) { $doc.created } else { '0000-00-00' }))
        ('updated: ' + $today)
        ('summary: ' + (Get-YamlScalar $summary))
        '---'
        ''
    ) -join "`r`n"

    [System.IO.File]::WriteAllText($path, $fm + $content, $utf8)
    $log.Add("已生成: $($doc.file) [图片$imgCount 标签$($tags.Count)]")
    $updated++
}

Write-Host "=== P2 完成：更新 $updated 篇 ==="
$log | ForEach-Object { Write-Host "  $_" }
