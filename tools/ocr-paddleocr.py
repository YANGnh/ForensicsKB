#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""用本地 Umi-OCR（PaddleOCR）为资料库图片生成 OCR 文本。

只使用一个 OCR 方案：Umi-OCR 2.1.5 / PaddleOCR 中文模型，输出到
ocr_paddleocr/<图片名>.txt。

用法：
  python tools/ocr-paddleocr.py --dry-run
  python tools/ocr-paddleocr.py --start --limit 5
  python tools/ocr-paddleocr.py --start --workers 2
  python tools/ocr-paddleocr.py --start --force

脚本退出时会结束它自己启动的 Umi-OCR 进程树（taskkill /T），并复查
1224 端口；不会结束运行前就已经存在的 Umi-OCR 服务。
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import time
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from pathlib import Path

DEFAULT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_UMI = Path(r"C:\Users\nhy10\Desktop\Forensics\Umi-OCR_Paddle_v2.1.5\Umi-OCR.exe")
API = "http://127.0.0.1:1224"
IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}

OPTIONS = {
    "ocr.language": "models/config_chinese.txt",
    "ocr.limit_side_len": 2880,
    "tbpu.parser": "multi_para",
    "data.format": "text",
}


def eprint(*args: object) -> None:
    print(*args, file=sys.stderr, flush=True)


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
    """用 PowerShell 查 1224 端口监听者，避免 netstat 本地化解析。"""
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


def ocr_one(image: Path, timeout: int = 120) -> dict:
    raw = image.read_bytes()
    payload = {
        "base64": base64.b64encode(raw).decode("ascii"),
        "options": OPTIONS,
    }
    last_err = None
    for attempt in range(3):
        try:
            obj = http_json(f"{API}/api/ocr", payload, timeout=timeout)
            code = obj.get("code")
            if code == 100:
                data = obj.get("data", "")
                if isinstance(data, dict):
                    data = data.get("text", "")
                return {"ok": True, "text": data or "", "no_text": False}
            if code == 101:
                return {"ok": True, "text": "", "no_text": True}
            last_err = f"API code={code} msg={obj.get('msg')}"
        except Exception as exc:  # noqa: BLE001 - 需要把网络错误记入 pending
            last_err = f"{type(exc).__name__}: {exc}"
        time.sleep(1.5 * (attempt + 1))
    return {"ok": False, "error": last_err or "unknown"}


def write_ocr(path: Path, image: Path, root: Path, text: str, no_text: bool) -> None:
    rel = image.relative_to(root).as_posix()
    header = (
        f"# OCR: {image.name}\n"
        f"# 来源: ./{rel}\n"
        f"# 引擎: Umi-OCR 2.1.5 / PaddleOCR "
        f"(config_chinese, limit_side_len={OPTIONS['ocr.limit_side_len']}, {OPTIONS['tbpu.parser']})\n"
        f"# 生成: {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n"
    )
    body = "\n".join(line.rstrip() for line in (text or "").replace("\r\n", "\n").split("\n")).strip()
    if no_text or not body:
        body = "# 结果: 无可用文本（Umi-OCR 未识别到文字）"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\r\n") as fh:
        fh.write(header + body + "\n")


def main() -> int:
    parser = argparse.ArgumentParser(description="用 Umi-OCR/PaddleOCR 全量生成图片 OCR")
    parser.add_argument("--root", default=str(DEFAULT_ROOT), help="资料库根目录")
    parser.add_argument("--umi-exe", default=str(DEFAULT_UMI), help="Umi-OCR.exe 路径")
    parser.add_argument("--start", action="store_true", help="API 未启动时自动启动 Umi-OCR")
    parser.add_argument("--keep-server", action="store_true", help="退出时保留 Umi-OCR（不推荐）")
    parser.add_argument("--limit", type=int, default=0, help="只处理前 N 张（测试）")
    parser.add_argument("--workers", type=int, default=2, help="并发请求数")
    parser.add_argument("--force", action="store_true", help="覆盖已有 ocr_paddleocr 文件")
    parser.add_argument("--dry-run", action="store_true", help="只统计，不 OCR")
    parser.add_argument("--timeout", type=int, default=120, help="单张 OCR 超时秒数")
    parser.add_argument("--log", default="", help="额外日志文件（UTF-8）")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    ocr_dir = root / "ocr_paddleocr"
    ocr_dir.mkdir(parents=True, exist_ok=True)

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
        and "ocr_paddleocr" not in p.parts
        and ".git" not in p.parts
        and "_reports" not in p.parts
    )
    if args.limit:
        images = images[: args.limit]
    missing = [img for img in images if not (ocr_dir / (img.name + ".txt")).exists()]
    log(f"[*] 图片：{len(images)}；已有 OCR：{len(images) - len(missing)}；待生成：{len(missing)}")
    if args.dry_run:
        if log_fh:
            log_fh.close()
        return 0

    pids: list[int] = []
    started = False
    if not server_ready():
        if not args.start:
            eprint("[!] Umi-OCR API 未启动；请先启动 Umi-OCR，或加 --start")
            if log_fh:
                log_fh.close()
            return 2
        found = start_server(Path(args.umi_exe))
        if found is None:
            if log_fh:
                log_fh.close()
            return 2
        pids.extend(found)
        started = True
    else:
        log("[*] 检测到已有 Umi-OCR 服务（退出时不会关闭）")

    ok = empty = skipped = failed = 0
    t0 = time.time()
    pending: list[str] = []

    def task(img: Path) -> tuple[Path, dict]:
        out = ocr_dir / (img.name + ".txt")
        if out.exists() and not args.force:
            return img, {"status": "skipped"}
        return img, ocr_one(img, timeout=args.timeout)

    try:
        with ThreadPoolExecutor(max_workers=max(1, args.workers)) as pool:
            futures = {pool.submit(task, img): img for img in images}
            for i, fut in enumerate(as_completed(futures), 1):
                img, res = fut.result()
                out = ocr_dir / (img.name + ".txt")
                status = res.get("status")
                if status == "skipped":
                    skipped += 1
                elif res.get("ok"):
                    if res.get("no_text") or not (res.get("text") or "").strip():
                        empty += 1
                        write_ocr(out, img, root, "", no_text=True)
                    else:
                        ok += 1
                        write_ocr(out, img, root, res.get("text", ""), no_text=False)
                else:
                    failed += 1
                    pending.append(img.relative_to(root).as_posix())
                if i % 25 == 0 or i == len(images):
                    log(
                        f"[{i}/{len(images)}] paddle={ok} empty={empty} "
                        f"skipped={skipped} failed={failed} elapsed={time.time() - t0:.0f}s"
                    )
    finally:
        pending_path = ocr_dir / "_pending.txt"
        if pending:
            pending_path.write_text("\n".join(f"./{p}" for p in pending) + "\n", encoding="utf-8")
        elif pending_path.exists():
            pending_path.unlink()
        if started and not args.keep_server:
            stop_server(pids)

    log(
        f"=== 完成：Paddle {ok}，无文本 {empty}，已存在跳过 {skipped}，失败 {failed}；"
        f"耗时 {time.time() - t0:.0f}s ==="
    )
    if log_fh:
        log_fh.close()
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
