# ============================================================
# 取证知识库：乱码文件修复（尽力而为）
# 尝试多种编码链还原，选 CJK 命中最多者，写出 .recovered.md 与报告。
# 注意：有损乱码（字节已丢失为 ?）无法完整还原，需人工重录。
# 用法：pwsh -File tools/repair-encoding.ps1 -Path <文件.md> [-Out <输出.md>]
# ============================================================
param(
    [Parameter(Mandatory)][string]$Path,
    [string]$Out = ''
)
$ErrorActionPreference = 'Stop'
$utf8 = [System.Text.UTF8Encoding]::new($false)

$bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $Path))
$gbk = [System.Text.Encoding]::GetEncoding(936)
$cp1252 = [System.Text.Encoding]::GetEncoding(1252)

$candidates = [ordered]@{}
# 链1：utf8文本 -> gbk字节 -> utf8
$t1 = [System.Text.Encoding]::UTF8.GetString($bytes)
$candidates['utf8->gbk->utf8'] = [System.Text.Encoding]::UTF8.GetString($gbk.GetBytes($t1))
# 链2：utf8文本 -> cp1252字节 -> utf8
$candidates['utf8->cp1252->utf8'] = [System.Text.Encoding]::UTF8.GetString($cp1252.GetBytes($t1))
# 链3：直接按 gbk 读
$candidates['gbk直读'] = $gbk.GetString($bytes)

$best = ''; $bestName = ''; $bestScore = -1
foreach ($kv in $candidates.GetEnumerator()) {
    $score = ([regex]::Matches($kv.Value, '[\u4e00-\u9fff]')).Count - ([regex]::Matches($kv.Value, [char]0xFFFD)).Count * 5
    Write-Host ("链 {0}: CJK={1} 替换符={2}" -f $kv.Key, ([regex]::Matches($kv.Value, '[\u4e00-\u9fff]')).Count, ([regex]::Matches($kv.Value, [char]0xFFFD)).Count)
    if ($score -gt $bestScore) { $bestScore = $score; $best = $kv.Value; $bestName = $kv.Key }
}
if (-not $Out) { $Out = [System.IO.Path]::ChangeExtension((Resolve-Path $Path), '.recovered.md') }
[System.IO.File]::WriteAllText($Out, $best, $utf8)
Write-Host "最佳链: $bestName → $Out"
Write-Host "提示：若结果仍有大量 ? 或乱码，说明原始损坏有损（字节已丢），请对照上下文/网络资料人工重录。"
