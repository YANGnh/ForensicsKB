#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
取证知识库转换工具：docx → markdown（纯 Python 标准库，零依赖）
- 提取正文文本（含表格转 Markdown 表格）
- 提取内嵌图片：统一按内容 MD5 哈希命名输出（自动去重），md 中以相对路径引用
用法: python docx2md.py <input.docx> <output.md> <image_out_dir>
"""
import sys, os, re, zipfile, hashlib
import xml.etree.ElementTree as ET

W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
R = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
A = 'http://schemas.openxmlformats.org/drawingml/2006/main'
V = 'urn:schemas-microsoft-com:vml'
PIC = 'http://schemas.openxmlformats.org/drawingml/2006/picture'

def q(tag):  return '{%s}%s' % (W, tag)
def qa(tag): return '{%s}%s' % (A, tag)
def qr(tag): return '{%s}%s' % (R, tag)
def qv(tag): return '{%s}%s' % (V, tag)

def main():
    if len(sys.argv) < 4:
        print('用法: python docx2md.py <input.docx> <output.md> <image_out_dir>')
        sys.exit(1)
    src, out_md, img_dir = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(img_dir, exist_ok=True)

    zf = zipfile.ZipFile(src)
    doc = ET.fromstring(zf.read('word/document.xml'))
    rels = ET.fromstring(zf.read('word/_rels/document.xml.rels'))
    relmap = {}
    for rel in rels:
        relmap[rel.get('Id')] = rel.get('Target')
    media = {}
    for name in zf.namelist():
        if name.startswith('word/media/'):
            media[os.path.basename(name)] = zf.read(name)

    def resolve(rid):
        target = relmap.get(rid, '')
        base = os.path.basename(target)
        data = media.get(base)
        if data is None:
            return None
        h = hashlib.md5(data).hexdigest()
        ext = os.path.splitext(base)[1].lower()
        if ext not in ('.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'):
            ext = '.png'
        out = os.path.join(img_dir, h + ext)
        if not os.path.exists(out):
            with open(out, 'wb') as f:
                f.write(data)
        return h + ext

    def para_text_imgs(p):
        style = ''
        pPr = p.find(q('pPr'))
        if pPr is not None:
            ps = pPr.find(q('pStyle'))
            if ps is not None:
                style = ps.get(q('val')) or ''
        texts = []
        for t in p.iter(q('t')):
            texts.append(t.text or '')
        imgs = []
        for blip in p.iter(qa('blip')):
            rid = blip.get(qr('embed'))
            if rid:
                f = resolve(rid)
                if f:
                    imgs.append(f)
        for imgd in p.iter(qv('imagedata')):
            rid = imgd.get(qr('id'))
            if rid:
                f = resolve(rid)
                if f:
                    imgs.append(f)
        return style, ''.join(texts).strip(), imgs

    def render_para(p):
        style, txt, imgs = para_text_imgs(p)
        s = style.lower()
        if s.startswith('heading') or s.startswith('标题'):
            digits = ''.join(ch for ch in style if ch.isdigit())
            lvl = min(int(digits) if digits else 1, 6)
            return ('#' * lvl) + ' ' + txt if txt else ''
        if txt and imgs:
            return txt + '\n\n' + '\n'.join('![](%s)' % f for f in imgs)
        if imgs:
            return '\n'.join('![](%s)' % f for f in imgs)
        if txt:
            return txt
        return ''

    lines = []
    def walk(elem):
        for child in elem:
            tag = child.tag
            if tag == q('p'):
                r = render_para(child)
                if r:
                    lines.append(r)
            elif tag == q('tbl'):
                rows = []
                for tr in child.findall(q('tr')):
                    cells = []
                    for tc in tr.findall(q('tc')):
                        ct = []
                        for p in tc.findall(q('p')):
                            r = render_para(p)
                            if r:
                                ct.append(r.replace('\n', ' '))
                        cells.append(' '.join(ct).strip())
                    rows.append(cells)
                if rows and any(rows[0]):
                    lines.append('| ' + ' | '.join(rows[0]) + ' |')
                    lines.append('|' + '---|' * len(rows[0]))
                    for row in rows[1:]:
                        lines.append('| ' + ' | '.join(row) + ' |')
            elif tag == q('sdt'):
                walk(child)
            elif tag == q('sectPr'):
                pass

    body = doc.find(q('body'))
    if body is not None:
        walk(body)

    with open(out_md, 'w', encoding='utf-8') as f:
        f.write('\n\n'.join(l for l in lines if l and l.strip()) + '\n')
    n_img = len([x for x in os.listdir(img_dir) if os.path.isfile(os.path.join(img_dir, x))])
    print('docx2md 完成: %s -> %s (图片 %d 张, 输出目录 %s)' % (src, out_md, n_img, img_dir))

if __name__ == '__main__':
    main()
