# 取证知识库

个人电子数据取证笔记的整理版：**比赛复盘（WriteUp）+ 取证技巧/工具速查**，共 56 篇 Markdown + 3,465 张图片（约 184 MB）。全部本地存储，Obsidian 可直接作为 vault 打开；AI 代理可直接读取检索。

- 源数据：`取证笔记/`（原始文件夹，只读，未修改）——2026-09 已由用户主动移出归档，本库为迁移后的工作副本
- 机器索引：`index.json`（由 `tools/build-index.ps1` 生成，禁止手改）
- 人读索引：`INDEX.md`

## 目录结构

```
取证知识库/
├── README.md            ← 本文件（AI/人 第一站）
├── INDEX.md             ← 全量文档索引表（脚本生成）
├── index.json           ← 机器可读索引（脚本生成）
├── 01-取证技巧/         ← 方法/工具/速查，按主题分 12 个子目录
│   ├── README.md        ← 主题导航 + 各文档一句话简介（脚本生成）
│   ├── 01-内存取证/ 02-网络取证/ 03-密码加密/ 04-隐写文件/ 05-应用分析/
│   ├── 06-数据库/ 07-服务器云/ 08-手机取证/ 09-介质磁盘/ 10-日志分析/
│   ├── 11-工具速查/ 99-培训记录/
├── 02-WriteUp/          ← 比赛复盘，按年份 2024/2025/2026
│   ├── README.md        ← 年份 × 比赛 × 阶段 总索引（脚本生成）
├── ocr/                 ← 图片 OCR 文本索引（<图片文件名>.txt）；_pending.txt 为待处理清单
├── templates/           ← writeup / technique 模板
└── tools/               ← 维护脚本（Windows PowerShell 5.1+，零第三方依赖）
```

## 元数据（每篇文档头部 YAML Frontmatter）

`title / type(writeup|technique|reference|training) / category / competition / year / stage / mode / tags / images / status / source / created / updated / summary`

受控词表以 `tools/tag-vocabulary.json` 为准（新增标签须登记；`check-integrity.ps1` 会把未登记标签列为警告）：
- 场景：服务器取证 / 内存取证 / 磁盘取证 / 手机取证 / 网络流量 / 数据库取证 / APK分析 / 隐写术 / 加解密 / 云原生 / 日志分析 / 注册表 / 介质分析 / 程序功能分析 / 恶意程序 / 邮件取证 / 区块链
- 比赛：美亚杯 / 数证杯 / FIC / 盘古石杯 / 龙信杯 / 獬豸杯 / 精武杯 / 平航杯 / 山东联赛 / 陕西联赛 / 广西职业技能大赛 / 能力验证 / 国赛 / 南宁
- 工具：Volatility / Wireshark / hashcat / CyberChef / WinHex / X-ways / FTK Imager / 010Editor / JADX / JEB / BurpSuite / exiftool / Foremost / VeraCrypt / Passware / SQLite / MySQL / Redis / Docker / K8s / kubectl / Telegram / IDA / blutter / Frida / phpMyAdmin / CobaltStrike / Laravel
- 技术：webshell / thinkphp / SQL注入 / 弱口令 / Windows日志 / 正则表达式 / 培训

> frontmatter 的单一事实源是 `tools/frontmatter-data.json`。`apply-frontmatter.ps1 -Force` 会用 JSON **整体覆盖**文档现有 frontmatter——请先用 `-DryRun` 预览；正式运行前会把旧 frontmatter 备份到 `_reports/frontmatter-backup-*.txt`，并列出与文档不一致的字段。

## 给 AI 的使用说明

1. **优先用检索工具**：`.\tools\search.ps1 <关键词>` 一次搜完 56 篇正文 + 3,465 份截图 OCR，可用 `-Type` / `-Competition` / `-Year` / `-Stage` / `-Tags` 过滤，`-List` 只看命中哪些文档。命中截图时会回指所属文档。
2. 先读本 README，再读 `INDEX.md` 或 `index.json` 选择目标文档（`02-WriteUp/README.md` 与 `01-取证技巧/README.md` 是分区导航）。
3. 检索策略：按 `type` 过滤（writeup / technique）→ 按 `competition`/`year`/`stage` 或 `tags` 过滤 → 打开文档。
4. 文档内图片为相对路径（相对 md 所在目录），按需打开查看；截图内容可先查 `ocr/` 同名文本（L1 检索层），再决定是否看图（L2 视觉层）。
5. **答案信源规则**：每题结论以正文 `**答案：**` 行为准（干净结构化文本）；截图/OCR 只作证据与佐证，不用于提取答案（噪声隔离，见设计方案 §7.2.1）。注意：该格式目前仅在最新文档中统一，其余文档的答案多为 `flag{...}` 或 `答案：` 行，检索时需一并匹配。
6. 多篇冲突时以 `status=完整` 且 `source=原创` 者优先，并注明来源文档。
7. 不确定时搜索 keywords（含 `ocr/` 全文，可命中截图内容）而非猜测。

## 维护（SOP）

> 脚本按 Windows PowerShell 5.1+ 编写，**不需要 PowerShell 7**（本机未安装 `pwsh`）。下表用 `.\tools\xxx.ps1` 形式，在 PowerShell 中于本目录直接执行即可；若在 cmd / 资源管理器地址栏，请改用 `powershell -File tools\xxx.ps1`。

| 操作 | 命令 |
|---|---|
| 全文检索 | `.\tools\search.ps1 关键词`（可加 `-Competition 美亚杯` / `-Year 2025` / `-Tags Volatility`；`-OnlyOcr` 只搜截图，`-List` 只列文档） |
| 新增比赛复盘 | `.\tools\new-writeup.ps1 -Competition 美亚杯 -Year 2026 -Stage 决赛`，填模板 → 截图入年份目录 → `.\tools\ocr-images.ps1` → `.\tools\build-index.ps1` |
| 新增复盘（多文件/Word/PDF） | ① `python tools/docx2md.py <x.docx> <tmp.md> <tmp-img>` / `python tools/pdf2md.py <x.pdf> <tmp.md> <tmp-img>`；② `.\tools\merge-writeup.ps1 -Out <目标md> -Files <列表>`；③ 图入年份目录 → OCR → 索引 |
| 新增技巧笔记 | 复制 `templates/technique-template.md` 到对应主题目录，填 frontmatter → 重建索引 |
| 重建索引 | `.\tools\build-index.ps1`（一并刷新 INDEX.md、index.json 与两个分区 README） |
| 体检 | `.\tools\check-integrity.ps1`（断链/缺frontmatter/缺H1/乱码/缺OCR/非受控标签） |
| 图片 OCR | `.\tools\ocr-images.ps1`（需本地 tesseract + chi_sim 语言包；未装时生成待处理清单） |
| 重生成 frontmatter | `.\tools\apply-frontmatter.ps1 -Force -DryRun` 先预览；确认后再去掉 `-DryRun`（会备份旧值并列出覆盖项） |

## git 版本管理（本地仓库 + GitHub 远程，2026-09-01）

仓库位于本目录，文本（md/json/ocr/脚本）普通入库，**图片由 Git LFS 管理**（见 `.gitattributes`）：PNG 已压缩为 WebP q90（视觉无损，241.9MB→约120MB），JPG 原样保留，共 3,465 个文件约 184MB。

```bash
git add -A && git commit -m "说明改了什么"   # 改完一批笔记就提交一次（存档）
git push                                    # 推送到 GitHub（图片走 LFS 上传）
git log --oneline                           # 看历史
git checkout -- <文件>                      # 误改后恢复该文件
```

远程：`origin` → https://github.com/YANGnh/ForensicsKB.git（私有仓库）。首次推送前本地需 `git lfs install`（已配置）；图片修改后 push 会自动走 LFS 上传。仓库级身份：`git config user.name / user.email`（当前为 Windows 用户名，可自行修改）。注意：GitHub LFS 免费额度为 1GB 存储 + 每月 1GB 下载流量（当前图片约 184MB，日常增量推送不受影响，频繁完整克隆会消耗流量）。

## 当前状态（2026-09-10）

- ✅ 56 篇全部带 frontmatter / H1 / 统一图片语法（2026-09-01 新增《2026广西职业技能大赛》初赛/决赛个人赛/决赛团队赛 3 篇，其中团队赛含 docx/pdf 转换，已完成清理与人工校对，status=完整）
- ✅ 索引：INDEX.md + index.json（图片 3,465 张 / 3,491 处引用；index.json 为标准 JSON，可直接被 python/jq 解析）
- ✅ 分区导航：`02-WriteUp/README.md`（年份 × 比赛 × 阶段）+ `01-取证技巧/README.md`（主题 × 文档简介），随索引自动重建
- ✅ 图片 OCR：3,465 张全部生成 OCR 文本（`ocr/`，tesseract chi_sim+eng）；其中约 100 张标记"无可用文本"、约 83 张仅识别出 1–20 字符（照片/纯图，属正常）
- ✅ 工具链（2026-09-10）：新增 `tools/search.ps1` 全文检索（正文 + 截图 OCR，支持元数据过滤）；新增受控词表 `tools/tag-vocabulary.json` 并在体检中校验；修正多词标签被拆散（`FTK Imager`）、frontmatter 重生成会静默回滚手改、标签被截断为 10 个三处问题
- ⚠️ 待办：6 个标签未纳入受控词表（小众APP / 中文乱码 / 事件ID / 安卓 / 数据提取 / 数据分析），待归并或登记
- ⚠️ 待办：`2024-国赛-复盘.md` 因正文有损乱码已从语料排除（原始文件随 `取证笔记/` 一并移出归档，重录后可通过 `tools/new-writeup.ps1` 重新纳入）；若干转载文缺失原图（已注释标记）；个别 `status=待完善` 文档答案留白待补；关键截图 caption/kind 标注（L3 增强，可选）
- 📌 已完成：git 本地版本管理 + GitHub 私有远程（见上节"git 版本管理"）

*详见 `取证知识库-设计方案.md`（工作区根目录）。*
