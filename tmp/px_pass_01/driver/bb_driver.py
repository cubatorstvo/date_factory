#!/usr/bin/env python3
"""Development-only black-box platform driver for PLAYER EXPERIENCE PASS 01.

Capabilities (only):
- launch Godot with isolated APPDATA user profile
- focus game window
- send ordinary keyboard / relative mouse input
- capture game-window screenshots

Forbidden: game-state reads/mutations, Story APIs, Godot remote/inspector.
"""

from __future__ import annotations

import argparse
import ctypes
import ctypes.wintypes as wt
import os
import subprocess
import sys
import time
from pathlib import Path

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32
kernel32 = ctypes.windll.kernel32

HWND = wt.HWND
LPARAM = wt.LPARAM
WNDENUMPROC = ctypes.WINFUNCTYPE(ctypes.c_bool, HWND, LPARAM)

SM_CXSCREEN = 0
SM_CYSCREEN = 1

# Virtual-key codes
VK = {
    "ESCAPE": 0x1B,
    "RETURN": 0x0D,
    "SPACE": 0x20,
    "LEFT": 0x25,
    "UP": 0x26,
    "RIGHT": 0x27,
    "DOWN": 0x28,
    "A": 0x41,
    "D": 0x44,
    "E": 0x45,
    "Q": 0x51,
    "R": 0x52,
    "S": 0x53,
    "W": 0x57,
    "F1": 0x70,
    "TAB": 0x09,
}

INPUT_MOUSE = 0
INPUT_KEYBOARD = 1
KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_SCANCODE = 0x0008
MOUSEEVENTF_MOVE = 0x0001
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
MOUSEEVENTF_ABSOLUTE = 0x8000
MOUSEEVENTF_MOVE_NOCOALESCE = 0x2000
SW_RESTORE = 9
SW_SHOW = 5


class MOUSEINPUT(ctypes.Structure):
    _fields_ = [
        ("dx", wt.LONG),
        ("dy", wt.LONG),
        ("mouseData", wt.DWORD),
        ("dwFlags", wt.DWORD),
        ("time", wt.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]


class KEYBDINPUT(ctypes.Structure):
    _fields_ = [
        ("wVk", wt.WORD),
        ("wScan", wt.WORD),
        ("dwFlags", wt.DWORD),
        ("time", wt.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]


class HARDWAREINPUT(ctypes.Structure):
    _fields_ = [
        ("uMsg", wt.DWORD),
        ("wParamL", wt.WORD),
        ("wParamH", wt.WORD),
    ]


class INPUT_UNION(ctypes.Union):
    _fields_ = [("mi", MOUSEINPUT), ("ki", KEYBDINPUT), ("hi", HARDWAREINPUT)]


class INPUT(ctypes.Structure):
    _fields_ = [("type", wt.DWORD), ("union", INPUT_UNION)]


class RECT(ctypes.Structure):
    _fields_ = [
        ("left", ctypes.c_long),
        ("top", ctypes.c_long),
        ("right", ctypes.c_long),
        ("bottom", ctypes.c_long),
    ]


class BITMAPINFOHEADER(ctypes.Structure):
    _fields_ = [
        ("biSize", wt.DWORD),
        ("biWidth", ctypes.c_long),
        ("biHeight", ctypes.c_long),
        ("biPlanes", wt.WORD),
        ("biBitCount", wt.WORD),
        ("biCompression", wt.DWORD),
        ("biSizeImage", wt.DWORD),
        ("biXPelsPerMeter", ctypes.c_long),
        ("biYPelsPerMeter", ctypes.c_long),
        ("biClrUsed", wt.DWORD),
        ("biClrImportant", wt.DWORD),
    ]


class BITMAPINFO(ctypes.Structure):
    _fields_ = [("bmiHeader", BITMAPINFOHEADER), ("bmiColors", wt.DWORD * 3)]


def _send_input(*inputs: INPUT) -> None:
    n = len(inputs)
    arr = (INPUT * n)(*inputs)
    sent = user32.SendInput(n, ctypes.byref(arr), ctypes.sizeof(INPUT))
    if sent != n:
        raise RuntimeError(f"SendInput sent {sent}/{n}")


def key_down(vk: int) -> None:
    inp = INPUT(type=INPUT_KEYBOARD)
    inp.union.ki = KEYBDINPUT(wVk=vk, wScan=0, dwFlags=0, time=0, dwExtraInfo=None)
    _send_input(inp)


def key_up(vk: int) -> None:
    inp = INPUT(type=INPUT_KEYBOARD)
    inp.union.ki = KEYBDINPUT(wVk=vk, wScan=0, dwFlags=KEYEVENTF_KEYUP, time=0, dwExtraInfo=None)
    _send_input(inp)


def tap_key(name: str, hold_s: float = 0.05) -> None:
    vk = VK[name.upper()]
    key_down(vk)
    time.sleep(hold_s)
    key_up(vk)


def hold_key(name: str, duration_s: float) -> None:
    vk = VK[name.upper()]
    key_down(vk)
    time.sleep(duration_s)
    key_up(vk)


def mouse_move_rel(dx: int, dy: int) -> None:
    inp = INPUT(type=INPUT_MOUSE)
    inp.union.mi = MOUSEINPUT(
        dx=int(dx),
        dy=int(dy),
        mouseData=0,
        dwFlags=MOUSEEVENTF_MOVE | MOUSEEVENTF_MOVE_NOCOALESCE,
        time=0,
        dwExtraInfo=None,
    )
    _send_input(inp)


def mouse_click_screen(x: int, y: int) -> None:
    sx = user32.GetSystemMetrics(SM_CXSCREEN)
    sy = user32.GetSystemMetrics(SM_CYSCREEN)
    ax = int(x * 65535 / max(sx - 1, 1))
    ay = int(y * 65535 / max(sy - 1, 1))
    move = INPUT(type=INPUT_MOUSE)
    move.union.mi = MOUSEINPUT(dx=ax, dy=ay, mouseData=0, dwFlags=MOUSEEVENTF_MOVE | MOUSEEVENTF_ABSOLUTE, time=0, dwExtraInfo=None)
    down = INPUT(type=INPUT_MOUSE)
    down.union.mi = MOUSEINPUT(dx=ax, dy=ay, mouseData=0, dwFlags=MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_ABSOLUTE, time=0, dwExtraInfo=None)
    up = INPUT(type=INPUT_MOUSE)
    up.union.mi = MOUSEINPUT(dx=ax, dy=ay, mouseData=0, dwFlags=MOUSEEVENTF_LEFTUP | MOUSEEVENTF_ABSOLUTE, time=0, dwExtraInfo=None)
    _send_input(move, down, up)


def find_windows_by_title_substr(substr: str) -> list[tuple[int, str]]:
    found: list[tuple[int, str]] = []

    @WNDENUMPROC
    def _enum(hwnd, _lparam):
        if not user32.IsWindowVisible(hwnd):
            return True
        length = user32.GetWindowTextLengthW(hwnd)
        if length <= 0:
            return True
        buf = ctypes.create_unicode_buffer(length + 1)
        user32.GetWindowTextW(hwnd, buf, length + 1)
        title = buf.value
        if substr.lower() in title.lower():
            found.append((int(hwnd), title))
        return True

    user32.EnumWindows(_enum, 0)
    return found


def focus_window(hwnd: int) -> None:
    user32.ShowWindow(hwnd, SW_RESTORE)
    user32.ShowWindow(hwnd, SW_SHOW)
    # Attach thread input to allow SetForegroundWindow from this process.
    fg = user32.GetForegroundWindow()
    pid = wt.DWORD()
    fg_tid = user32.GetWindowThreadProcessId(fg, ctypes.byref(pid))
    cur_tid = kernel32.GetCurrentThreadId()
    user32.AttachThreadInput(cur_tid, fg_tid, True)
    user32.BringWindowToTop(hwnd)
    user32.SetForegroundWindow(hwnd)
    user32.SetActiveWindow(hwnd)
    user32.AttachThreadInput(cur_tid, fg_tid, False)
    time.sleep(0.15)


def get_client_rect_screen(hwnd: int) -> tuple[int, int, int, int]:
    rect = RECT()
    user32.GetClientRect(hwnd, ctypes.byref(rect))
    pt = wt.POINT(0, 0)
    user32.ClientToScreen(hwnd, ctypes.byref(pt))
    left, top = pt.x, pt.y
    right = left + (rect.right - rect.left)
    bottom = top + (rect.bottom - rect.top)
    return left, top, right, bottom


def capture_window_png(hwnd: int, out_path: Path) -> dict:
    left, top, right, bottom = get_client_rect_screen(hwnd)
    width = max(right - left, 1)
    height = max(bottom - top, 1)

    hwnd_dc = user32.GetDC(0)
    mem_dc = gdi32.CreateCompatibleDC(hwnd_dc)
    bmp = gdi32.CreateCompatibleBitmap(hwnd_dc, width, height)
    old = gdi32.SelectObject(mem_dc, bmp)
    gdi32.BitBlt(mem_dc, 0, 0, width, height, hwnd_dc, left, top, 0x00CC0020)  # SRCCOPY

    bmi = BITMAPINFO()
    bmi.bmiHeader.biSize = ctypes.sizeof(BITMAPINFOHEADER)
    bmi.bmiHeader.biWidth = width
    bmi.bmiHeader.biHeight = -height  # top-down
    bmi.bmiHeader.biPlanes = 1
    bmi.bmiHeader.biBitCount = 32
    bmi.bmiHeader.biCompression = 0  # BI_RGB

    buf_len = width * height * 4
    buf = (ctypes.c_ubyte * buf_len)()
    gdi32.GetDIBits(mem_dc, bmp, 0, height, buf, ctypes.byref(bmi), 0)

    gdi32.SelectObject(mem_dc, old)
    gdi32.DeleteObject(bmp)
    gdi32.DeleteDC(mem_dc)
    user32.ReleaseDC(0, hwnd_dc)

    # Write PNG via Pillow
    from PIL import Image

    img = Image.frombuffer("RGB", (width, height), bytes(buf), "raw", "BGRX", 0, 1)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(out_path, "PNG")
    return {
        "path": str(out_path),
        "width": width,
        "height": height,
        "client_rect": [left, top, right, bottom],
    }


def wait_for_window(substr: str, timeout_s: float = 60.0) -> tuple[int, str]:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        wins = find_windows_by_title_substr(substr)
        # Prefer exact-ish game window; skip editor if both present.
        for hwnd, title in wins:
            t = title.lower()
            if "editor" in t:
                continue
            if "godot" in t and "date factory" not in t:
                continue
            return hwnd, title
        if wins:
            return wins[0]
        time.sleep(0.25)
    raise TimeoutError(f"Window containing '{substr}' not found in {timeout_s}s")


def launch_game(
    godot: Path,
    project: Path,
    user_appdata: Path,
    log_path: Path,
    resolution: str = "1920x1080",
) -> subprocess.Popen:
    user_appdata.mkdir(parents=True, exist_ok=True)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    # Isolate Godot user:// away from developer profile.
    env["APPDATA"] = str(user_appdata.resolve())
    # Prefer windowed for capture reliability.
    cmd = [
        str(godot),
        "--path",
        str(project),
        "--resolution",
        resolution,
        "--windowed",
    ]
    log_f = open(log_path, "w", encoding="utf-8", errors="replace")
    log_f.write(f"# launch_cmd: {' '.join(cmd)}\n")
    log_f.write(f"# APPDATA={env['APPDATA']}\n")
    log_f.write(f"# cwd={project}\n")
    log_f.write(f"# started_utc={time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}\n")
    log_f.flush()
    proc = subprocess.Popen(
        cmd,
        cwd=str(project),
        env=env,
        stdout=log_f,
        stderr=subprocess.STDOUT,
        stdin=subprocess.DEVNULL,
    )
    # Keep handle on process; log file kept open by Popen
    proc._px_log_file = log_f  # type: ignore[attr-defined]
    return proc


def stop_process(proc: subprocess.Popen | None, timeout_s: float = 8.0) -> None:
    if proc is None:
        return
    if proc.poll() is None:
        proc.terminate()
        try:
            proc.wait(timeout=timeout_s)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=5)
    log_f = getattr(proc, "_px_log_file", None)
    if log_f:
        try:
            log_f.write(f"\n# ended_utc={time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}\n")
            log_f.write(f"# exit_code={proc.returncode}\n")
            log_f.close()
        except Exception:
            pass


def main() -> int:
    ap = argparse.ArgumentParser(description="PX Pass 01 black-box driver primitives")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_launch = sub.add_parser("launch")
    p_launch.add_argument("--godot", required=True)
    p_launch.add_argument("--project", required=True)
    p_launch.add_argument("--user-appdata", required=True)
    p_launch.add_argument("--log", required=True)
    p_launch.add_argument("--resolution", default="1920x1080")
    p_launch.add_argument("--pid-file", required=True)

    p_wait = sub.add_parser("wait-window")
    p_wait.add_argument("--title", default="DATE FACTORY")
    p_wait.add_argument("--timeout", type=float, default=60.0)
    p_wait.add_argument("--hwnd-file", required=True)

    p_focus = sub.add_parser("focus")
    p_focus.add_argument("--hwnd", type=int, required=True)

    p_shot = sub.add_parser("shot")
    p_shot.add_argument("--hwnd", type=int, required=True)
    p_shot.add_argument("--out", required=True)

    p_keys = sub.add_parser("keys")
    p_keys.add_argument("--hwnd", type=int, required=True)
    p_keys.add_argument("--seq", required=True, help="Comma list: W:0.4,E,RETURN,MOUSE:120,-10")

    p_click = sub.add_parser("click-client")
    p_click.add_argument("--hwnd", type=int, required=True)
    p_click.add_argument("--x", type=int, required=True, help="client x")
    p_click.add_argument("--y", type=int, required=True, help="client y")

    p_stop = sub.add_parser("stop-pid")
    p_stop.add_argument("--pid", type=int, required=True)

    args = ap.parse_args()

    if args.cmd == "launch":
        proc = launch_game(
            Path(args.godot),
            Path(args.project),
            Path(args.user_appdata),
            Path(args.log),
            args.resolution,
        )
        Path(args.pid_file).write_text(str(proc.pid), encoding="utf-8")
        print(f"pid={proc.pid}")
        # Detach: do not wait; caller owns lifecycle via pid
        # Close our inherited wait; child keeps log open via OS handle duplication.
        # Actually on Windows the open file handle is inherited; closing parent handle is OK if child has its own.
        return 0

    if args.cmd == "wait-window":
        hwnd, title = wait_for_window(args.title, args.timeout)
        Path(args.hwnd_file).write_text(f"{hwnd}\n{title}\n", encoding="utf-8")
        print(f"hwnd={hwnd}")
        print(f"title={title}")
        return 0

    if args.cmd == "focus":
        focus_window(args.hwnd)
        print("focused")
        return 0

    if args.cmd == "shot":
        meta = capture_window_png(args.hwnd, Path(args.out))
        print(meta)
        return 0

    if args.cmd == "keys":
        focus_window(args.hwnd)
        time.sleep(0.05)
        for token in args.seq.split(","):
            token = token.strip()
            if not token:
                continue
            if token.upper().startswith("SLEEP:"):
                time.sleep(float(token.split(":", 1)[1]))
                continue
            if token.upper().startswith("MOUSE:"):
                _, rest = token.split(":", 1)
                dx_s, dy_s = rest.split(":")
                mouse_move_rel(int(dx_s), int(dy_s))
                time.sleep(0.02)
                continue
            if ":" in token:
                name, dur_s = token.split(":", 1)
                hold_key(name, float(dur_s))
            else:
                tap_key(token)
            time.sleep(0.05)
        print("keys_ok")
        return 0

    if args.cmd == "click-client":
        focus_window(args.hwnd)
        left, top, _, _ = get_client_rect_screen(args.hwnd)
        mouse_click_screen(left + args.x, top + args.y)
        print(f"clicked={left + args.x},{top + args.y}")
        return 0

    if args.cmd == "stop-pid":
        try:
            os.kill(args.pid, 15)
        except Exception:
            subprocess.run(["taskkill", "/PID", str(args.pid), "/T", "/F"], check=False)
        print("stopped")
        return 0

    return 2


if __name__ == "__main__":
    sys.exit(main())
