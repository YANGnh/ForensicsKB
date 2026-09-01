#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
取证知识库转换工具：PDF → markdown（纯 Python 标准库，零依赖）
- 文本型 PDF（Chromium/Word 导出）：提取文本（ToUnicode CMap 映射）+ 内嵌图片
- 图片统一按内容 MD5 哈希命名输出（自动去重），按内容流顺序插入 md
- 扫描件/图片型 PDF：文本为空，仅能提取图片（需另行 OCR）
用法: python pdf2md.py <input.pdf> <output.md> <image_out_dir>
"""
import sys, os, re, zlib, hashlib, struct

# ---------------- PDF 对象与字典解析 ----------------

def parse_objects(data):
    objs = {}
    for m in re.finditer(rb'(\d+)\s+\d+\s+obj\b', data):
        num = int(m.group(1))
        start = m.end()
        i = start
        while True:
            j = data.find(b'endobj', i)
            if j < 0:
                break
            chunk = data[start:j]
            if chunk.count(b'<<') == chunk.count(b'>>'):
                objs[num] = chunk
                break
            i = j + 6
    return objs

TOK_RE = re.compile(rb'<<|>>|\[|\]|/[\w.]+|\((?:\\.|[^()\\])*\)|<[0-9A-Fa-f\s]+>|\d+\.\d+|\d+|[A-Za-z]+', re.S)

def lex(b):
    return [m.group(0) for m in TOK_RE.finditer(b)]

def decode_pdf_string(raw):
    raw = raw[1:-1]
    out = bytearray()
    i = 0
    while i < len(raw):
        c = raw[i]
        if c == 0x5C:
            i += 1
            if i >= len(raw):
                break
            n = raw[i]
            if n in b'nrtbf':
                out.append({ord('n'): 10, ord('r'): 13, ord('t'): 9, ord('b'): 8, ord('f'): 12}[n])
            elif n in b'()\\':
                out.append(n)
            elif 48 <= n <= 55:
                out.append(int(raw[i:i+3], 8) & 0xFF)
                i += 2
            else:
                out.append(n)
        else:
            out.append(c)
        i += 1
    return bytes(out)

def parse_value(tokens, i):
    t = tokens[i]
    if t == b'<<':
        d = {}
        i += 1
        while i < len(tokens) and tokens[i] != b'>>':
            key = tokens[i]
            if key.startswith(b'/'):
                v, i = parse_value(tokens, i + 1)
                d[key[1:].decode('latin-1')] = v
            else:
                i += 1
        return d, i + 1
    if t == b'[':
        arr = []
        i += 1
        while i < len(tokens) and tokens[i] != b']':
            v, ni = parse_value(tokens, i)
            arr.append(v)
            i = ni
        return arr, i + 1
    if t.startswith(b'('):
        return decode_pdf_string(t), i + 1
    if t.startswith(b'<') and t != b'<<':
        return t, i + 1
    if t.startswith(b'/'):
        return t, i + 1
    if re.match(rb'^\d+$', t) and i + 2 < len(tokens) and tokens[i + 2] == b'R':
        return ('ref', int(t), int(tokens[i + 1])), i + 3
    return t, i + 1

def obj_dict(obj):
    """对象原始内容 -> (dict, 剩余bytes)"""
    toks = lex(obj)
    if not toks or toks[0] != b'<<':
        return None, obj
    return parse_value(toks, 0)[0], obj

def get_stream(obj, objs):
    d, rest = obj_dict(obj)
    if d is None:
        return None, None
    sm = re.search(rb'stream\r?\n', rest)
    if not sm:
        return d, None
    se = rest.find(b'endstream', sm.end())
    raw = rest[sm.end():se]
    flt = d.get('Filter')
    if isinstance(flt, bytes) and b'FlateDecode' in flt:
        try:
            return d, zlib.decompress(raw)
        except Exception:
            return d, None
    if isinstance(flt, bytes) and b'DCTDecode' in flt:
        return d, raw
    if isinstance(flt, list):
        for f in flt:
            if isinstance(f, bytes) and b'FlateDecode' in f:
                try:
                    return d, zlib.decompress(raw)
                except Exception:
                    return d, None
    return d, raw

def deref(v, objs):
    if isinstance(v, tuple) and v and v[0] == 'ref':
        return objs.get(v[1])
    return v

# ---------------- ToUnicode CMap ----------------

def parse_cmap(stream):
    cmap = {}
    if not stream:
        return cmap
    txt = stream.decode('latin-1', 'ignore')
    for m in re.finditer(r'beginbfchar(.*?)endbfchar', txt, re.S):
        for pair in re.finditer(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>', m.group(1)):
            try:
                code = int(pair.group(1), 16)
                u = bytes.fromhex(pair.group(2)).decode('utf-16-be', 'ignore')
                if u:
                    cmap[code] = u
            except Exception:
                pass
    for m in re.finditer(r'beginbfrange(.*?)endbfrange', txt, re.S):
        for tri in re.finditer(r'<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>', m.group(1)):
            try:
                lo = int(tri.group(1), 16)
                hi = int(tri.group(2), 16)
                start = bytes.fromhex(tri.group(3))
                if len(start) == 2:
                    base = int.from_bytes(start, 'big')
                    for c in range(lo, hi + 1):
                        cmap[c] = chr(base + (c - lo))
            except Exception:
                pass
    return cmap

# ---------------- 页面遍历 ----------------

def walk_pages(node, objs, out, seen):
    obj = deref(node, objs)
    if obj is None:
        return
    d, _ = obj_dict(obj)
    if d is None:
        return
    t = d.get('Type')
    if isinstance(t, bytes) and b'/Page' in t and b'/Pages' not in t:
        if id(obj) not in seen:
            seen.add(id(obj))
            out.append(obj)
        return
    kids = d.get('Kids') or d.get('Pages')
    if isinstance(kids, list):
        for k in kids:
            walk_pages(k, objs, out, seen)
    elif kids is not None:
        walk_pages(kids, objs, out, seen)

# ---------------- 资源与图片 ----------------

def get_resources(page, objs):
    d, _ = obj_dict(page)
    if d is None:
        return {}, {}
    res = d.get('Resources')
    if isinstance(res, dict):
        rd = res
    else:
        res_obj = deref(res, objs)
        rd, _ = obj_dict(res_obj) if res_obj else (None, None)
    if rd is None:
        return {}, {}
    fonts = {}
    fd = rd.get('Font')
    if isinstance(fd, dict):
        fd_d = fd
    else:
        fd_obj = deref(fd, objs)
        fd_d, _ = obj_dict(fd_obj) if fd_obj else (None, None)
    if fd_d:
        for name, val in fd_d.items():
            font_obj = deref(val, objs)
            if font_obj is None:
                continue
            fo_d, _ = obj_dict(font_obj)
            if not fo_d:
                continue
            tu = fo_d.get('ToUnicode')
            cmap = {}
            if tu is not None:
                tu_obj = deref(tu, objs)
                if tu_obj is not None:
                    _, s = get_stream(tu_obj, objs)
                    cmap = parse_cmap(s)
            fonts[name] = cmap
    xobjs = {}
    xd = rd.get('XObject')
    if isinstance(xd, dict):
        xd_d = xd
    else:
        xo_obj = deref(xd, objs)
        xd_d, _ = obj_dict(xo_obj) if xo_obj else (None, None)
    if xd_d:
        for name, val in xd_d.items():
            if isinstance(val, tuple) and val and val[0] == 'ref':
                xobjs[name] = val[1]
    return fonts, xobjs

def extract_images(xobjs, objs, img_dir):
    out = {}
    for name, num in xobjs.items():
        obj = objs.get(num)
        if obj is None:
            continue
        d, stream = get_stream(obj, objs)
        if d is None or stream is None:
            continue
        if d.get('Subtype') != b'/Image':
            continue
        flt = d.get('Filter')
        try:
            w = int(d.get('Width', 0))
            h = int(d.get('Height', 0))
        except Exception:
            continue
        if w <= 0 or h <= 0:
            continue
        if isinstance(flt, bytes) and b'DCTDecode' in flt:
            fname = hashlib.md5(stream).hexdigest() + '.jpg'
            with open(os.path.join(img_dir, fname), 'wb') as f:
                f.write(stream)
            out[name] = fname
        elif isinstance(flt, bytes) and b'FlateDecode' in flt:
            try:
                bpc = int(d.get('BitsPerComponent', 8))
                cs = d.get('ColorSpace')
                comps = 3
                if isinstance(cs, bytes):
                    if b'DeviceGray' in cs:
                        comps = 1
                    elif b'DeviceCMYK' in cs:
                        comps = 4
                rowlen = (w * bpc * comps + 7) // 8
                if len(stream) < rowlen * h:
                    continue
                png = b'\x89PNG\r\n\x1a\n'
                def chunk(t, d2):
                    return struct.pack('>I', len(d2)) + t + d2 + struct.pack('>I', zlib.crc32(t + d2))
                color_type = {1: 0, 3: 2, 4: 6}.get(comps, 2)
                ihdr = struct.pack('>IIBBBBB', w, h, bpc, color_type, 0, 0, 0)
                png += chunk(b'IHDR', ihdr)
                scanlines = b''.join(b'\x00' + stream[i * rowlen:(i + 1) * rowlen] for i in range(h))
                png += chunk(b'IDAT', zlib.compress(scanlines, 6))
                png += chunk(b'IEND', b'')
                fname = hashlib.md5(png).hexdigest() + '.png'
                with open(os.path.join(img_dir, fname), 'wb') as f:
                    f.write(png)
                out[name] = fname
            except Exception:
                continue
    return out

def content_streams(page, objs):
    d, _ = obj_dict(page)
    if d is None:
        return []
    c = d.get('Contents')
    streams = []
    if isinstance(c, list):
        for item in c:
            obj = deref(item, objs)
            if obj is not None:
                _, s = get_stream(obj, objs)
                if s:
                    streams.append(s)
    else:
        obj = deref(c, objs)
        if obj is not None:
            _, s = get_stream(obj, objs)
            if s:
                streams.append(s)
    return streams

def decode_text(s, cur_font, fonts):
    if cur_font and cur_font in fonts and fonts[cur_font]:
        cmap = fonts[cur_font]
        return ''.join(cmap.get(b, '') for b in s)
    return s.decode('latin-1', 'ignore')

# ---------------- 主流程 ----------------

def main():
    if len(sys.argv) < 4:
        print('用法: python pdf2md.py <input.pdf> <output.md> <image_out_dir>')
        sys.exit(1)
    src, out_md, img_dir = sys.argv[1], sys.argv[2], sys.argv[3]
    os.makedirs(img_dir, exist_ok=True)
    data = open(src, 'rb').read()
    objs = parse_objects(data)

    root_num = None
    for m in re.finditer(rb'/Root\s+(\d+)\s+\d+\s+R', data):
        root_num = int(m.group(1))
        break
    pages = []
    if root_num is not None:
        walk_pages(('ref', root_num, 0), objs, pages, set())

    lines = []
    n_img = 0
    for pi, page in enumerate(pages):
        fonts, xobjs = get_resources(page, objs)
        imgs = extract_images(xobjs, objs, img_dir)
        n_img += len(imgs)
        page_lines = []
        for stream in content_streams(page, objs):
            i = 0
            cur_font = None
            buf = []

            def flush():
                nonlocal buf
                if buf:
                    page_lines.append(''.join(buf))
                    buf = []

            while i < len(stream):
                if stream[i:i+2] == b'BT':
                    flush()
                    i += 2
                    continue
                if stream[i:i+2] == b'ET':
                    flush()
                    i += 2
                    continue
                if stream[i:i+1] == b'(':
                    j = i
                    depth = 0
                    while j < len(stream):
                        if stream[j:j+1] == b'\\':
                            j += 2
                            continue
                        if stream[j:j+1] == b'(':
                            depth += 1
                        elif stream[j:j+1] == b')':
                            depth -= 1
                            if depth == 0:
                                break
                        j += 1
                    s = decode_pdf_string(stream[i:j+1])
                    op_end = j + 1
                    while op_end < len(stream) and stream[op_end:op_end+1] in b' \r\n\t':
                        op_end += 1
                    if stream[op_end:op_end+2].startswith(b'Tj'):
                        text = decode_text(s, cur_font, fonts)
                        if text:
                            buf.append(text)
                        i = op_end + 2
                        continue
                    i = j + 1
                    continue
                # 十六进制字符串 <XXXX> Tj（Chromium 逐字形输出）
                if stream[i:i+1] == b'<' and stream[i:i+2] != b'<<':
                    j = stream.find(b'>', i)
                    if j < 0:
                        break
                    try:
                        s = bytes.fromhex(stream[i+1:j].decode('latin-1').replace(' ', ''))
                    except Exception:
                        s = b''
                    op_end = j + 1
                    while op_end < len(stream) and stream[op_end:op_end+1] in b' \r\n\t':
                        op_end += 1
                    if stream[op_end:op_end+2].startswith(b'Tj'):
                        text = decode_text(s, cur_font, fonts)
                        if text:
                            buf.append(text)
                        i = op_end + 2
                        continue
                    i = j + 1
                    continue
                m = re.match(rb'/([A-Za-z0-9_]+)\s+[0-9.]+\s+Tf\b', stream[i:])
                if m:
                    cur_font = m.group(1).decode('latin-1')
                    i += m.end()
                    continue
                m = re.match(rb'/([A-Za-z0-9_]+)\s+Do\b', stream[i:])
                if m:
                    name = m.group(1).decode('latin-1')
                    flush()
                    if name in imgs:
                        page_lines.append('![](%s)' % imgs[name])
                    i += m.end()
                    continue
                m = re.match(rb'\[\s*(?:\((?:[^()\\]|\\.)*\)|<[0-9A-Fa-f\s]+>|[0-9.]+|\s)*\]\s*TJ\b', stream[i:])
                if m:
                    txt = ''
                    for pm in re.finditer(rb'\((?:[^()\\]|\\.)*\)|<[0-9A-Fa-f\s]+>', m.group(0)):
                        tok = pm.group(0)
                        if tok.startswith(b'('):
                            txt += decode_text(decode_pdf_string(tok), cur_font, fonts)
                        else:
                            try:
                                s = bytes.fromhex(tok[1:-1].decode('latin-1').replace(' ', ''))
                                txt += decode_text(s, cur_font, fonts)
                            except Exception:
                                pass
                    if txt:
                        buf.append(txt)
                    i += m.end()
                    continue
                i += 1
            flush()
        if page_lines:
            # 合并碎片行为段落：段界 = 空行 / 句末标点 / 答案标记 / 序号开头
            merged = []
            buf = []
            for raw_line in page_lines:
                t = raw_line.strip()
                if not t:
                    if buf:
                        merged.append(''.join(buf))
                        buf = []
                    continue
                if buf and (buf[-1].endswith(('。', '！', '？', '?', '!', '．')) or t.startswith(('答案', '答：')) or re.match(r'^\d+[、.\s]', t)):
                    merged.append(''.join(buf))
                    buf = []
                buf.append(t)
            if buf:
                merged.append(''.join(buf))
            lines.append('<!-- PDF 第%d页 -->' % (pi + 1))
            lines.extend(merged)

    with open(out_md, 'w', encoding='utf-8') as f:
        f.write('\n\n'.join(l for l in lines if l) + '\n')
    print('pdf2md 完成: 页数 %d, 图片 %d 张, 输出 %s' % (len(pages), n_img, out_md))

if __name__ == '__main__':
    main()
