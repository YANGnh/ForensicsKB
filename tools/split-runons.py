#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
取证资料库：卷3 粘连行清理脚本（2026-广西职业技能大赛-决赛团队赛）
只处理 "## 卷 3：" 到 "## 卷 4：" 之间（PDF 转换段）。
规则（只增删换行/围栏，不删任何内容）：
1. 图片引用 ![](hash.ext) → 独立成行
2. "答案：" → **答案：** 独立行（答案截止于首个思路/命令标记）
3. 命令链分段：在命令起始符前断行，连续命令段包 ``` 围栏
用法: python tools/split-runons.py <md路径>
"""
import sys, re

def main():
    path = sys.argv[1]
    with open(path, encoding='utf-8') as f:
        content = f.read()
    lines = content.split('\n')

    CMD = r'(?:vol[- ]?f|vol\.py|python[23]? ?-c|python[23]? |tshark|strings |grep |SELECT |import |curl |file |xxd |md5sum |openssl |sqlite3 |kubectl |wget |KEY=)'
    ANS_END = r'(?:Python|vol[- ]?f|vol\.py|tshark|strings|grep|SELECT|import|curl|IDA|首先|通过|提取|分析|使用|查看|接下来|需要|存在|调用|参考|完整|指令|Phase|Step|Frame|# |解压|下载|我们)'

    out = []
    in_v3 = False
    fence_open = False

    def close_fence():
        nonlocal fence_open
        if fence_open:
            out.append('```')
            fence_open = False

    for raw in lines:
        line = raw.rstrip('\r')
        s = line.strip()

        if s.startswith('## 卷 3：'):
            in_v3 = True
            close_fence()
            out.append(line)
            continue
        if s.startswith('## 卷 4：') or s.startswith('## 卷'):
            in_v3 = False
            close_fence()
            out.append(line)
            continue
        if not in_v3:
            out.append(line)
            continue

        if not s:
            close_fence()
            out.append('')
            continue

        # 1) 图片独立行
        img_re = re.compile(r'(!\[\]\([0-9a-f]{32}\.(?:png|jpg|jpeg)\))')
        parts = img_re.split(line)
        line = ''
        for p in parts:
            if img_re.fullmatch(p):
                close_fence()
                if line.strip():
                    out.append(line.rstrip())
                    line = ''
                out.append(p)
            else:
                line += p
        if line.strip() == '':
            continue

        # 2) 答案拆分（仅处理行首 40 字内出现 答案： 且行长）
        if len(line) > 60 and re.match(r'^.{0,40}?答案[:：]', line, re.S):
            m = re.match(r'^(.*?答案[:：])(.*)$', line, re.S)
            prefix, rest = m.group(1), m.group(2)
            cut = len(rest)
            m2 = re.search(ANS_END, rest)
            if m2:
                cut = min(cut, m2.start())
            if rest and ord(rest[0]) > 0x2E80:
                m3 = re.search(r'[。！？!?，,]', rest)
                if m3:
                    cut = min(cut, m3.start() + 1)
            ans = rest[:cut].strip()
            tail = rest[cut:].strip()
            if ans:
                close_fence()
                if prefix.strip() not in ('答案：', '答案:'):
                    out.append(prefix.strip())
                out.append('**答案：** ' + ans)
                if tail:
                    line = tail
                else:
                    continue
            else:
                line = prefix + rest

        # 3) 命令链分段 + 围栏
        s = line.strip()
        if len(s) > 100 and re.search(r'(?:# |vol[- ]?f|python|tshark|strings|SELECT|import|grep|curl|KEY=)', s):
            segs = re.split(r'(?=\b(?:vol[- ]?f|vol\.py|python[23]? ?-c|python[23]? |tshark|strings |grep |SELECT |import |curl |KEY=|# |file |xxd |md5sum |openssl |sqlite3 |kubectl ))', s)
            segs = [x.strip() for x in segs if x.strip()]
            if len(segs) > 1:
                close_fence()
                code_buf = []
                text_buf = []

                def flush_text():
                    if text_buf:
                        out.append(' '.join(text_buf))
                        text_buf.clear()

                def flush_code():
                    if code_buf:
                        out.append('```')
                        out.extend(code_buf)
                        out.append('```')
                        code_buf.clear()

                for seg in segs:
                    if re.match(CMD, seg):
                        flush_text()
                        code_buf.append(seg)
                    else:
                        flush_code()
                        text_buf.append(seg)
                flush_text()
                flush_code()
                continue
        out.append(line)

    close_fence()
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(out))
    print('清理完成: %s' % path)

if __name__ == '__main__':
    main()
