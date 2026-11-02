#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""修复 01/02/03 语料 frontmatter 的 created / images / ocr_covered / 标签。

默认 dry-run，只打印将要发生的修改；加 --apply 才写入。
写入时保留原文件的 BOM 与换行风格（CRLF/LF）。

用法：
  python tools/fix-frontmatter.py --created-from-git --sync-images \
      --drop-tags "小众APP,中文乱码,安卓,事件ID,数据提取,数据分析"
  python tools/fix-frontmatter.py --apply --created-from-git --sync-images \
      --drop-tags "小众APP,中文乱码,安卓,事件ID,数据提取,数据分析"
"""
import argparse
import os
import re
import subprocess
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORPUS = ("01-取证技巧", "02-WriteUp", "03-理论知识")
IMG_RE = re.compile(r'(?:<img[^>]*src="|!\[[^\]]*\]\()([^")]+)')
FM_RE = re.compile(r'^---\r?\n(.*?)\r?\n---\r?\n', re.S)


def docs():
    out = []
    for d in CORPUS:
        base = os.path.join(ROOT, d)
        for cur, _, fs in os.walk(base):
            for f in fs:
                if f.endswith(".md") and f != "README.md":
                    out.append(os.path.join(cur, f))
    return sorted(out)


def git_first_date(rel):
    try:
        p = subprocess.run(["git", "log", "--follow", "--diff-filter=A", "--format=%cs", "--", rel],
                           cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
        dates = [x.strip() for x in p.stdout.splitlines() if x.strip()]
        return dates[-1] if dates else None
    except Exception:
        return None


def unique_images(text):
    body = FM_RE.sub("", text, count=1)
    refs = []
    for m in IMG_RE.finditer(body):
        r = m.group(1).strip()
        if r.startswith(("http://", "https://", "//")):
            continue
        refs.append(r)
    return refs


def set_field(fm_lines, key, value):
    pat = re.compile(r'^%s\s*:.*$' % re.escape(key))
    for i, line in enumerate(fm_lines):
        if pat.match(line):
            fm_lines[i] = f"{key}: {value}"
            return True
    return False


def get_field(fm_lines, key):
    pat = re.compile(r'^%s\s*:\s*(.*)$' % re.escape(key))
    for line in fm_lines:
        m = pat.match(line)
        if m:
            return m.group(1).strip().strip('"').strip("'")
    return None


def drop_tags(fm_lines, drop):
    for i, line in enumerate(fm_lines):
        m = re.match(r'^tags\s*:\s*\[(.*)\]\s*$', line)
        if not m:
            continue
        tags = [t.strip().strip('"').strip("'") for t in m.group(1).split(",") if t.strip()]
        kept = [t for t in tags if t not in drop]
        removed = [t for t in tags if t in drop]
        if removed:
            fm_lines[i] = "tags: [" + ", ".join(kept) + "]"
            return kept
        return None
    return None


def process(path, args):
    with open(path, "rb") as f:
        raw = f.read()
    bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig")
    m = FM_RE.match(text)
    if not m:
        return [f"{os.path.relpath(path, ROOT)}: 缺少 frontmatter，跳过"]
    fm = m.group(1)
    crlf = "\r\n" in fm
    fm_lines = fm.split("\r\n") if crlf else fm.split("\n")
    changes = []
    rel = os.path.relpath(path, ROOT).replace(os.sep, "/")

    if args.created_from_git:
        created = get_field(fm_lines, "created")
        if created in (None, "", "0000-00-00"):
            d = git_first_date(rel) or "2026-09-01"
            if set_field(fm_lines, "created", d):
                changes.append(f"created: {created or '(缺失)'} -> {d}")

    if args.sync_images:
        refs = unique_images(text)
        n = len(set(refs))
        old = get_field(fm_lines, "images")
        if old != str(n):
            if set_field(fm_lines, "images", str(n)):
                changes.append(f"images: {old} -> {n}")

    if args.drop_tags:
        drop = set(t.strip() for t in args.drop_tags.split(",") if t.strip())
        kept = drop_tags(fm_lines, drop)
        if kept is not None:
            before = get_field(fm_lines, "tags")
            if before is not None:
                changes.append("tags 移除后: [" + ", ".join(kept) + "]")

    if not changes:
        return []
    if args.apply:
        new_fm = ("\r\n" if crlf else "\n").join(fm_lines)
        new_text = text[:m.start(1)] + new_fm + text[m.end(1):]
        data = new_text.encode("utf-8")
        if bom:
            data = b"\xef\xbb\xbf" + data
        with open(path, "wb") as f:
            f.write(data)
    prefix = "" if args.apply else "[dry-run] "
    return [f"{prefix}{rel}: " + "; ".join(changes)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="写入修改（默认只预览）")
    ap.add_argument("--created-from-git", action="store_true")
    ap.add_argument("--sync-images", action="store_true")
    ap.add_argument("--drop-tags", default="")
    args = ap.parse_args()

    if not (args.created_from_git or args.sync_images or args.drop_tags):
        ap.error("至少指定一个修复项")

    total = 0
    for p in docs():
        for line in process(p, args):
            print(line)
            total += 1
    print(f"\n{'已写入' if args.apply else '将修改'} {total} 处；共扫描 {len(docs())} 篇")


if __name__ == "__main__":
    main()
