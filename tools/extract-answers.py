#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从 02-WriteUp 复盘文档中抽取「题目 → 答案」对。

实际语料存在多种答案形态（README 已说明），本脚本按以下优先级识别：
  1. **答案：** 行（含 `**答案**：`）  -> method=answer-line
  2. `结果为...` 内联代码                -> method=inline-result
  3. 题干后紧邻的 ``` 代码块             -> method=code-block
  4. flag{...}                          -> method=flag
  5. 题干后第一行非空文本（兜底）        -> method=first-line（低置信度）

用法：
  python tools/extract-answers.py "02-WriteUp/2025/2025-FIC-初赛.md"
  python tools/extract-answers.py --all --stats
  python tools/extract-answers.py --all --json > answers.json
  python tools/extract-answers.py <doc> --limit 5
"""
import argparse
import json
import os
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HEAD_Q = re.compile(r'^(#{2,4})\s+(?:\*\*)?(\d+)\s*[.、．]\s*(.*?)(?:\*\*)?\s*$')
Q_HEAD = re.compile(r'^(#{2,4})\s+Q(\d+)\s*[.、．:：]?\s*(.*?)\s*$', re.I)
BOLD_Q = re.compile(r'^\*\*\s*(\d+)\s*[、.．]\s*(.+?)\s*\*\*\s*$')
PLAIN_Q = re.compile(r'^(\d{1,3})\s*[、.．]\s*(.+)$')
ANS_LINE = re.compile(r'(?:\*\*答案[：:]\*\*|\*\*答案\*\*\s*[：:])\s*(.*)')
RESULT = re.compile(r'结果为\s*`([^`]+)`')
FLAG = re.compile(r'flag\{[^}\r\n]+\}')
IMG = re.compile(r'^\s*(?:!\[|<img)')
FENCE = re.compile(r'^\s*```')
SCORE = re.compile(r'[（(]\s*\d+\s*分\s*[)）]')
TYPE_TAG = re.compile(r'\[[^\]]{1,10}\]')
HEADING_ANY = re.compile(r'^#{1,6}\s')
NUM_PREFIX = re.compile(r'^(\d{1,2})\s+(.+)$')
NONQ = re.compile(r'(概览|准备|背景|信息|步骤|思路|总结|附录|清单|概述|详解|工具|环境|目录|比赛)')
QUESTION_HINT = re.compile(r'[\[【](?:填空题|单选题|多选题|判断题|简答题|问答题|实操题|标准格式|答案格式|答案提交格式|提交格式)|(?:答案|提交)格式')


def read_doc(path):
    text = open(path, encoding="utf-8-sig", newline="").read()
    m = re.match(r'^---\r?\n.*?\r?\n---\r?\n', text, re.S)
    body = text[m.end():] if m else text
    offset = text[:m.end()].count("\n") if m else 0
    lines = body.splitlines()
    return lines, offset


def clean_question(s):
    s = s.strip().strip("*").strip()
    s = TYPE_TAG.sub("", s)
    s = SCORE.sub("", s)
    s = re.sub(r'\s{2,}', " ", s)
    return s.strip(" ：:，,")


def heading_question(text):
    """无编号标题也可能是题干：以问号/答案格式/两位数序号开头。"""
    t = text.strip()
    if not t:
        return False
    if t.endswith(("？", "?")) or "？" in t or "?" in t:
        return True
    if "[标准格式" in t or "[答案格式" in t or "[按照实际值" in t:
        return True
    if NUM_PREFIX.match(t):
        return True
    return False


def find_anchors(lines):
    """返回 [line_idx, num, question_text, level, seq]；seq 用于无编号标题。"""
    anchors = []
    for i, line in enumerate(lines):
        m = HEAD_Q.match(line)
        if m:
            text = clean_question(m.group(3))
            if "[" not in text and not text.endswith(("？", "?")) and "？" not in text and NONQ.search(text):
                continue
            anchors.append([i, m.group(2), text, len(m.group(1)), 0])
            continue
        m = Q_HEAD.match(line)
        if m:
            anchors.append([i, m.group(2), clean_question(m.group(3)), len(m.group(1)), 0])
            continue
        m = BOLD_Q.match(line)
        if m:
            anchors.append([i, m.group(1), clean_question(m.group(2)), 0, 0])
            continue
        m = PLAIN_Q.match(line)
        if m:
            text = m.group(2)
            if ("[标准格式" in text or "[答案格式" in text or "[按照实际值" in text
                    or text.rstrip().endswith(("？", "?"))):
                anchors.append([i, m.group(1), clean_question(text), 0, 0])
            continue
        m = re.match(r'^(#{2,4})\s+(.+?)\s*$', line)
        if m and heading_question(m.group(2)):
            text = m.group(2)
            num = ""
            nm = NUM_PREFIX.match(text)
            if nm:
                num, text = nm.group(1), nm.group(2)
            anchors.append([i, num, clean_question(text), len(m.group(1)), 0])
    # 无编号题按出现顺序补号
    seq = 0
    for a in anchors:
        if not a[1]:
            seq += 1
            a[1] = str(seq)
            a[4] = 1
    return anchors


def segment_end(lines, anchors, idx):
    """当前题干到下一个题干/同级或更高级标题为止。"""
    start = anchors[idx][0]
    level = anchors[idx][3]
    end = len(lines)
    if idx + 1 < len(anchors):
        end = anchors[idx + 1][0]
    for j in range(start + 1, end):
        if level and HEADING_ANY.match(lines[j]):
            lv = len(lines[j]) - len(lines[j].lstrip("#"))
            if lv <= level:
                end = j
                break
    return end


def first_fence(lines, start, end):
    i = start
    while i < end:
        if FENCE.match(lines[i]):
            j = i + 1
            buf = []
            while j < end and not FENCE.match(lines[j]):
                buf.append(lines[j])
                j += 1
            content = "\n".join(buf).strip()
            if content:
                return content, i
            i = j + 1
        else:
            i += 1
    return None, None


def prev_text(lines, i, floor=0):
    j = i - 1
    while j >= floor:
        s = lines[j].strip()
        if s and not IMG.match(s) and not FENCE.match(s) and s not in ("---", "***", "```"):
            return s
        j -= 1
    return ""


def nearest_question(lines, i, floor=0):
    """答案行之前最近的题干：问号结尾行 / 题目段 / 最近标题。"""
    p = prev_text(lines, i, floor)
    if p and not re.match(r'^\s*(?:\*\*)?答案', p) and (
            p.endswith(("？", "?")) or "？" in p
            or QUESTION_HINT.search(p)
            or re.match(r'^\d{1,3}\s*[、.．]', p)):
        return clean_question(p)
    heading = ""
    j = i - 1
    while j >= floor:
        s = lines[j].strip()
        if not s:
            j -= 1
            continue
        if HEADING_ANY.match(s):
            title = re.sub(r'^#+\s*', '', s).strip("*：: ")
            if title in ("题目", "题目描述", "问题"):
                t, _ = first_text(lines, j, min(j + 10, len(lines)))
                if t:
                    return clean_question(t)
            if not heading:
                heading = title
            j -= 1
            continue
        if "答案" not in s and (s.endswith(("？", "?")) or "？" in s or QUESTION_HINT.search(s)):
            return clean_question(s)
        j -= 1
    return clean_question(heading)


def first_text(lines, start, end):
    for i in range(start + 1, end):
        s = lines[i].strip()
        if not s or IMG.match(s) or FENCE.match(s) or HEADING_ANY.match(s):
            continue
        if s.startswith("<!--"):
            continue
        if s.strip("*：: ") in ("答案", "参考答案", "答"):
            continue
        return s, i
    return None, None


def bad_flag(token, line):
    if any(k in line for k in ("答案格式", "标准格式", "提交格式", "格式：", "格式为")):
        return True
    inner = token[5:-1]
    if inner in ("...", "…", "xxx", "XXX"):
        return True
    return False


def extract(path):
    lines, offset = read_doc(path)
    anchors = find_anchors(lines)
    pairs = []
    seen_answers = set()

    anchor_lines = {a[0] for a in anchors}

    # 1) 题干锚点 -> 答案（内联结果 / 答案行 / 代码块 / flag / 首行）
    for k, (start, num, question, level, seq) in enumerate(anchors):
        end = segment_end(lines, anchors, k)
        ans = method = ans_line = None
        conf = "high"

        for j in range(start + 1, end):
            m = ANS_LINE.search(lines[j])
            if m and m.group(1).strip():
                ans, method, ans_line = m.group(1).strip().strip("`*").strip(), "answer-line", j
                break
        if ans is None:
            for j in range(start + 1, end):
                m = RESULT.search(lines[j])
                if m:
                    ans, method, ans_line = m.group(1).strip(), "inline-result", j
                    break
        if ans is None:
            code, fence_line = first_fence(lines, start + 1, end)
            if code:
                ans, method, ans_line, conf = code, "code-block", fence_line, "medium"
        if ans is None:
            for j in range(start + 1, end):
                m = FLAG.search(lines[j])
                if m and not bad_flag(m.group(0), lines[j]):
                    ans, method, ans_line, conf = m.group(0), "flag", j, "medium"
                    break
        if ans is None:
            text, j = first_text(lines, start, end)
            if text and len(text) <= 200:
                ans, method, ans_line, conf = text, "first-line", j, "low"

        if ans is None:
            continue
        if ans_line is not None:
            seen_answers.add(ans_line)
        pairs.append({
            "line": (ans_line if ans_line is not None else start) + offset + 1,
            "num": num,
            "question": question,
            "answer": ans,
            "method": method,
            "confidence": conf,
        })

    # 2) 游离的 **答案：** / flag 行（不在任何题干段落内）
    def inside_anchor(i):
        for k, (start, _, _, _, _) in enumerate(anchors):
            if start < i < segment_end(lines, anchors, k):
                return True
        return False

    for i, line in enumerate(lines):
        if i in seen_answers or i in anchor_lines or inside_anchor(i):
            continue
        m = ANS_LINE.search(line)
        if m and m.group(1).strip():
            ans = m.group(1).strip().strip("`*").strip()
            pairs.append({
                "line": i + offset + 1,
                "num": "",
                "question": nearest_question(lines, i),
                "answer": ans,
                "method": "answer-line",
                "confidence": "high",
            })
            seen_answers.add(i)
            continue
        fm = FLAG.search(line)
        if fm and not bad_flag(fm.group(0), line):
            pairs.append({
                "line": i + offset + 1,
                "num": "",
                "question": nearest_question(lines, i),
                "answer": fm.group(0),
                "method": "flag",
                "confidence": "medium",
            })
            seen_answers.add(i)

    pairs.sort(key=lambda x: x["line"])
    return pairs, lines, anchors


def style_of(pairs):
    if not pairs:
        return "非结构化"
    counts = {}
    for p in pairs:
        counts[p["method"]] = counts.get(p["method"], 0) + 1
    order = ["answer-line", "inline-result", "code-block", "flag", "first-line"]
    best = max(order, key=lambda k: counts.get(k, 0))
    label = {
        "answer-line": "答案行",
        "inline-result": "结果为内联",
        "code-block": "题干+代码块",
        "flag": "flag",
        "first-line": "题干+首行",
    }[best]
    if sum(1 for v in counts.values() if v >= 3) > 1:
        return "混合（" + label + "为主）"
    return label


def print_pairs(pairs, path, limit):
    print(f"== {path} ==")
    for p in pairs[:limit]:
        num = (p["num"] + ". ") if p["num"] else ""
        print(f"[{p['line']:>4}] {num}{p['question'][:80]}")
        ans = p["answer"].replace("\n", " ⏎ ")
        print(f"       答案: {ans[:160]}  ({p['method']}, {p['confidence']})")
    if len(pairs) > limit:
        print(f"... 共 {len(pairs)} 对，仅显示前 {limit} 对")
    print()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("doc", nargs="?")
    ap.add_argument("--all", action="store_true", help="扫描 02-WriteUp 下全部 md")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--stats", action="store_true")
    ap.add_argument("--limit", type=int, default=10)
    args = ap.parse_args()

    if args.all:
        docs = []
        for d, _, fs in os.walk(os.path.join(ROOT, "02-WriteUp")):
            for f in fs:
                if f.endswith(".md") and f != "README.md":
                    docs.append(os.path.join(d, f))
        docs.sort()
    elif args.doc:
        docs = [args.doc if os.path.isabs(args.doc) else os.path.join(ROOT, args.doc)]
    else:
        ap.error("需要 <doc> 或 --all")

    all_out = []
    for d in docs:
        rel = os.path.relpath(d, ROOT).replace(os.sep, "/")
        pairs, _, _ = extract(d)
        if args.json:
            all_out.append({"path": rel, "style": style_of(pairs), "pairs": pairs})
        elif args.stats:
            print(f"{rel:<55} {style_of(pairs):<16} {len(pairs):>3} 对")
        else:
            print_pairs(pairs, rel, args.limit)
    if args.json:
        print(json.dumps(all_out, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
