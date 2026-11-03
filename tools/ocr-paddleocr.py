#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""用本地 Umi-OCR（PaddleOCR）重做图片 OCR，并按内容路由。

策略（与 _reports/OCR-Umi-100张试点报告.md 一致）：
  - 中文 UI / 聊天 / 表格 / 低质图：Umi-OCR 中文模型 -> ocr_paddleocr/
  - 代码 / 终端 / 命令 / 哈希：保留 tesseract -> ocr_tesseract/（不写 Paddle 文件）
检索与索引优先读 ocr_paddleocr/，缺失时回退 ocr_tesseract/。

用法示例：
  python tools/ocr-paddleocr.py --dry-run
  python tools/ocr-paddleocr.py --start --limit 5
  python tools/ocr-paddleocr.py --start --workers 2
  python tools/ocr-paddleocr.py --start --force

注意：脚本退出时会结束它自己启动的 Umi-OCR 进程树（taskkill /T），
不会结束运行前就已存在的 Umi-OCR 服务。
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

DEFAULT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_UMI = Path(r"C:\Users\nhy10\Desktop\Forensics\Umi-OCR_Paddle_v2.1.5\Umi-OCR.exe")
API = "http://127.0.0.1:1224"
IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}

# 强代码标记：避免把普通英文 UI 误判成代码。
CODE_TOKENS = re.compile(
    r"\b(public|private|protected|static|void|class|import|package|function|def|"
    r"#include|std::|System\.out|console\.log|println|Exception|SELECT|FROM|WHERE|"
    r"INSERT|UPDATE|CREATE|curl|wget|sudo|apt|yum|kubectl|powershell|cmd|bash|"
    r"with|for|while|if|else|print|return|open|exit|echo|export|"
    r"cat|ls|cd|grep|awk|sed|chmod|chown|ssh|scp|mysql|sqlmap)\b",
    re.IGNORECASE,
)


def eprint(*args: object) -> None:
    print(*args, file=sys.stderr, flush=True)


def strip_header(text: str) -> str:
    """去掉旧 OCR 的 # 文件头，只保留正文用于分类。"""
    lines = text.splitlines()
    body = []
    for line in lines:
        if line.startswith("#") and not body:
            continue
        body.append(line)
    return "\n".join(body).strip()


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8-sig", errors="replace")
    except OSError:
        return ""


def features(text: str) -> dict:
    ns = re.sub(r"\s", "", text)
    n = len(ns) or 1
    cjk = len(re.findall(r"[\u4e00-\u9fff]", text))
    ascii_alnum = sum(1 for c in text if c.isascii() and c.isalnum())
    tokens = CODE_TOKENS.findall(text)
    symbols = text.count("{") + text.count("}") + text.count(";") + text.count("=>")
    return {
        "chars": len(text),
        "nonspace": len(ns),
        "cjk": cjk,
        "cjk_ratio": round(cjk / n, 4),
        "ascii_ratio": round(ascii_alnum / n, 4),
        "code_tokens": len(tokens),
        "code_token_kinds": len(set(t.lower() for t in tokens)),
        "symbols": symbols,
    }


def classify(text: str) -> tuple[str, str, dict]:
    """返回 (engine, reason, features)。engine 为 paddleocr 或 tesseract。"""
    f = features(text)
    # 代码特征：多个强 token，且中文很少（中文注释多的代码仍优先 tesseract）。
    if f["code_token_kinds"] >= 2 and f["cjk_ratio"] < 0.12:
        return "tesseract", "code-tokens", f
    if (
        f["symbols"] >= 6
        and f["ascii_ratio"] > 0.65
        and f["cjk_ratio"] < 0.12
    ):
        return "tesseract", "code-symbols", f
    if (
        f["code_token_kinds"] >= 1
        and f["cjk_ratio"] < 0.03
        and f["ascii_ratio"] > 0.80
        and f["symbols"] >= 2
    ):
        return "tesseract", "code-ascii", f
    return "paddleocr", "chinese-or-general", f


def http_json(url: str, payload: dict | None = None, timeout: int = 120) -> dict:
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8", errors="replace"))


def server_ready() -> bool:
    try:
        http_json(f"{API}/api/ocr/get_options", timeout=2)
        return True
    except Exception:
        return False


def port_owner_pids() -> list[int]:
    """用 PowerShell 查 1224 端口占用者，避免 netstat 本地化解析。"""
    try:
        out = subprocess.run(
            [
                "powershell.exe",
                "-NoProfile",
                "-Command",
                "(Get-NetTCPConnection -LocalPort 1224 -State Listen -ErrorAction SilentlyContinue | "
                "Where-Object { $_.OwningProcess -gt 0 } | "
                "Select-Object -ExpandProperty OwningProcess -Unique) -join ','",
            ],
            capture_output=True,
            text=True,
            timeout=15,
            encoding="utf-8",
            errors="replace",
        )
        return [int(x) for x in (out.stdout or "").replace("\ufeff", "").split(",") if x.strip().isdigit()]
    except Exception:
        return []


def umi_pids() -> list[int]:
    """列出所有 Umi-OCR.exe 进程（按进程名，避免只依赖端口）。"""
    try:
        out = subprocess.run(
            [
                "powershell.exe",
                "-NoProfile",
                "-Command",
                "(Get-Process -Name 'Umi-OCR' -ErrorAction SilentlyContinue | "
                "Select-Object -ExpandProperty Id) -join ','",
            ],
            capture_output=True,
            text=True,
            timeout=15,
            encoding="utf-8",
            errors="replace",
        )
        return [int(x) for x in (out.stdout or "").replace("\ufeff", "").split(",") if x.strip().isdigit()]
    except Exception:
        return []


def kill_tree(pid: int) -> None:
    try:
        subprocess.run(
            ["taskkill", "/PID", str(pid), "/T", "/F"],
            capture_output=True,
            timeout=20,
            encoding="utf-8",
            errors="replace",
        )
    except Exception:
        pass


def start_server(exe: Path) -> list[int] | None:
    """用 ShellExecute 启动 Umi-OCR，返回监听 1224 的 PID 列表；失败返回 None。

    不能直接用 subprocess.Popen：后台/非交互会话里 Qt GUI 会以 exit 1 退出。
    os.startfile 走 ShellExecute，能落到当前桌面会话。
    """
    if not exe.exists():
        eprint(f"[!] 找不到 Umi-OCR：{exe}")
        return None
    eprint(f"[*] 启动 Umi-OCR：{exe}")
    try:
        os.startfile(str(exe))
    except OSError as exc:
        eprint(f"[!] ShellExecute 启动失败：{exc}")
        return None
    deadline = time.time() + 40
    while time.time() < deadline:
        if server_ready():
            time.sleep(0.5)
            pids = umi_pids() or port_owner_pids()
            eprint(f"[*] Umi-OCR 已就绪（PID {pids or '未知'}）")
            return pids
        time.sleep(0.5)
    eprint("[!] 等待 Umi-OCR 服务超时")
    for pid in port_owner_pids():
        kill_tree(pid)
    return None


def stop_server(pids: list[int]) -> None:
    """结束本次启动的 Umi-OCR 进程树，并兜底检查进程/端口。"""
    targets = set(pids) | set(umi_pids()) | set(port_owner_pids())
    for pid in sorted(targets):
        eprint(f"[*] 结束 Umi-OCR 进程树 PID {pid}")
        kill_tree(pid)
    time.sleep(1.0)
    leftovers = set(umi_pids()) | set(port_owner_pids())
    for pid in sorted(leftovers):
        eprint(f"[*] 清理残留进程 PID {pid}")
        kill_tree(pid)
    if umi_pids() or port_owner_pids():
        eprint("[!] 仍有 Umi-OCR/PaddleOCR 残留，请手动检查")
    else:
        eprint("[*] Umi-OCR 已关闭，端口 1224 已释放")


def ocr_one(image: Path, options: dict, timeout: int = 120) -> dict:
    raw = image.read_bytes()
    payload = {
        "base64": base64.b64encode(raw).decode("ascii"),
        "options": options,
    }
    last_err = None
    for attempt in range(3):
        try:
            obj = http_json(f"{API}/api/ocr", payload, timeout=timeout)
            if obj.get("code") == 100:
                data = obj.get("data", "")
                if isinstance(data, dict):
                    data = data.get("text", "")
                return {"ok": True, "text": data or ""}
            last_err = f"API code={obj.get('code')} msg={obj.get('msg')}"
        except Exception as exc:  # noqa: BLE001 - 需要把网络错误记入 manifest
            last_err = f"{type(exc).__name__}: {exc}"
        time.sleep(1.5 * (attempt + 1))
    return {"ok": False, "error": last_err or "unknown"}


def write_ocr(path: Path, image: Path, root: Path, text: str, reason: str, opts: dict) -> None:
    rel = image.relative_to(root).as_posix()
    header = (
        f"# OCR: {image.name}\n"
        f"# 来源: ./{rel}\n"
        f"# 引擎: Umi-OCR 2.1.5 / PaddleOCR (config_chinese, limit_side_len={opts['ocr.limit_side_len']}, {opts['tbpu.parser']})\n"
        f"# 路由: {reason}\n"
        f"# 生成: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n"
    )
    body = "\n".join(line.rstrip() for line in (text or "").replace("\r\n", "\n").split("\n")).strip()
    if not body:
        body = "# 结果: 无可用文本（Umi-OCR 未识别到文字）"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\r\n") as fh:
        fh.write(header + body + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="Umi-OCR PaddleOCR 路由重做")
    parser.add_argument("--root", default=str(DEFAULT_ROOT), help="资料库根目录")
    parser.add_argument("--umi-exe", default=str(DEFAULT_UMI), help="Umi-OCR.exe 路径")
    parser.add_argument("--start", action="store_true", help="API 未启动时自动启动 Umi-OCR")
    parser.add_argument("--keep-server", action="store_true", help="退出时保留 Umi-OCR（不推荐）")
    parser.add_argument("--limit", type=int, default=0, help="只处理前 N 张（测试）")
    parser.add_argument("--workers", type=int, default=2, help="并发请求数")
    parser.add_argument("--force", action="store_true", help="覆盖已有 ocr_paddleocr 文件")
    parser.add_argument("--dry-run", action="store_true", help="只分类并写 _routing.json，不 OCR")
    parser.add_argument("--timeout", type=int, default=120, help="单张 OCR 超时秒数")
    parser.add_argument("--log", default="", help="额外日志文件（UTF-8）")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    ocr_t = root / "ocr_tesseract"
    ocr_p = root / "ocr_paddleocr"
    if not ocr_t.exists():
        eprint(f"[!] 找不到 {ocr_t}；请先把原 ocr/ 重命名为 ocr_tesseract/")
        return 2
    ocr_p.mkdir(parents=True, exist_ok=True)

    log_fh = None
    if args.log:
        log_fh = open(args.log, "w", encoding="utf-8", buffering=1)

    def log(msg: str) -> None:
        print(msg, flush=True)
        if log_fh:
            log_fh.write(msg + "\n")

    images = sorted(
        p
        for p in root.rglob("*")
        if p.is_file()
        and p.suffix.lower() in IMAGE_EXTS
        and "ocr_tesseract" not in p.parts
        and "ocr_paddleocr" not in p.parts
        and ".git" not in p.parts
        and "_reports" not in p.parts
    )
    if args.limit:
        images = images[: args.limit]
    log(f"[*] 待处理图片：{len(images)}")

    # 分类：用 ocr_tesseract 的正文做路由依据；没有旧 OCR 时默认 Paddle。
    routing: dict[str, dict] = {}
    counts = {"paddleocr": 0, "tesseract": 0}
    for img in images:
        rel = img.relative_to(root).as_posix()
        old_path = ocr_t / (img.name + ".txt")
        old_text = strip_header(read_text(old_path)) if old_path.exists() else ""
        engine, reason, feat = classify(old_text)
        counts[engine] += 1
        routing[rel] = {
            "engine": engine,
            "reason": reason,
            **feat,
            "old_ocr": old_path.exists(),
        }

    manifest = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "engine": "Umi-OCR 2.1.5 / PaddleOCR (config_chinese)",
        "options": {
            "ocr.language": "models/config_chinese.txt",
            "ocr.limit_side_len": 2880,
            "tbpu.parser": "multi_para",
            "data.format": "text",
        },
        "counts": {"total": len(images), **counts},
        "routing": routing,
    }
    (ocr_p / "_routing.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    log(f"[*] 路由：PaddleOCR {counts['paddleocr']}，tesseract {counts['tesseract']}")
    log(f"[*] 清单：{ocr_p / '_routing.json'}")
    if args.dry_run:
        return 0

    pids: list[int] = []
    started = False
    if not server_ready():
        if not args.start:
            eprint("[!] Umi-OCR API 未启动；请先启动 Umi-OCR，或加 --start")
            return 2
        started_pids = start_server(Path(args.umi_exe))
        if started_pids is None:
            return 2
        pids.extend(started_pids)
        started = True
    else:
        log("[*] 检测到已有 Umi-OCR 服务（退出时不会关闭）")

    opts = manifest["options"]
    ok = empty = skipped = tess = failed = 0
    t0 = time.time()
    pending: list[str] = []

    def task(img: Path) -> tuple[Path, dict, str]:
        rel = img.relative_to(root).as_posix()
        route = routing[rel]
        out = ocr_p / (img.name + ".txt")
        if route["engine"] != "paddleocr":
            # 路由改变后，旧 Paddle 结果不能继续盖住 tesseract。
            if out.exists():
                out.unlink()
            return img, {"status": "tesseract"}, route["reason"]
        if out.exists() and not args.force:
            return img, {"status": "skipped"}, route["reason"]
        res = ocr_one(img, opts, timeout=args.timeout)
        return img, res, route["reason"]

    try:
        with ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
            futures = {pool.submit(task, img): img for img in images}
            for i, fut in enumerate(as_completed(futures), 1):
                img, res, reason = fut.result()
                rel = img.relative_to(root).as_posix()
                out = ocr_p / (img.name + ".txt")
                status = res.get("status")
                if status == "skipped":
                    skipped += 1
                    routing[rel]["status"] = "skipped"
                elif status == "tesseract":
                    tess += 1
                    routing[rel]["status"] = "tesseract-fallback"
                elif res.get("ok"):
                    text = (res.get("text") or "").strip()
                    if text:
                        write_ocr(out, img, root, text, reason, opts)
                        ok += 1
                        routing[rel]["status"] = "paddleocr"
                    else:
                        empty += 1
                        routing[rel]["status"] = "empty-fallback"
                        if out.exists():
                            out.unlink()
                else:
                    failed += 1
                    routing[rel]["status"] = "failed"
                    routing[rel]["error"] = res.get("error")
                    pending.append(rel)
                if i % 25 == 0 or i == len(images):
                    log(
                        f"[{i}/{len(images)}] paddle={ok} empty={empty} "
                        f"tesseract={tess} skipped={skipped} failed={failed} "
                        f"elapsed={time.time() - t0:.0f}s"
                    )
    finally:
        (ocr_p / "_routing.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        (ocr_p / "_pending.txt").write_text(
            "\n".join(f"./{p}" for p in pending) + ("\n" if pending else ""), encoding="utf-8"
        )
        if started and not args.keep_server:
            stop_server(pids)

    log(
        f"=== 完成：Paddle {ok}，空文本 {empty}，tesseract {tess}，已存在跳过 {skipped}，"
        f"失败 {failed}；耗时 {time.time() - t0:.0f}s ==="
    )
    if log_fh:
        log_fh.close()
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
