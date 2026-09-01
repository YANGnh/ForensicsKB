#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
卷3 收尾补丁（Python 版，无转义问题）：
1. "答案：短token+中文问题" → "**答案：** token" + 换行 + 中文
2. "版本号vol-fmemdump"（无空格粘连）→ 断行
只处理 卷3 区间；只增删换行，不删内容。
"""
import re, sys

def main():
    path = sys.argv[1]
    with open(path, encoding='utf-8') as f:
        content = f.read()
    lines = content.split('\n')
    out = []
    in_v3 = False
    for l in lines:
        s = l.strip()
        if s.startswith('## 卷 3：'):
            in_v3 = True
        elif s.startswith('## 卷 4：') or (s.startswith('## 卷') and not s.startswith('## 卷 3：')):
            in_v3 = False
        if not in_v3 or s.startswith('```') or s.startswith('![]('):
            out.append(l)
            continue
        # 模式1: 答案：短token + 中文 → 拆两行
        m = re.match(r'^答案[:：]([A-Za-z0-9_.\-/]+)([\u4e00-\u9fff].+)$', l)
        if m:
            out.append('**答案：** ' + m.group(1))
            out.append(m.group(2))
            continue
        # 模式2: 行首版本号/短token 无空格粘连 vol 命令 → 断行
        m = re.match(r'^([0-9][0-9a-zA-Z_.\-]{1,30})(vol[- ]?f)', l)
        if m:
            out.append(m.group(1))
            out.append(l[m.end(1):])
            continue
        out.append(l)
    with open(path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(out))
    print('收尾补丁完成')

if __name__ == '__main__':
    main()
