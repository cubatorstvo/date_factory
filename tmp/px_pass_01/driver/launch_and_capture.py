#!/usr/bin/env python3
"""Launch DATE FACTORY with isolated APPDATA and capture compositor screenshots."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

from PIL import ImageGrab

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from bb_driver import (  # noqa: E402
    find_windows_by_title_substr,
    focus_window,
    get_client_rect_screen,
    hold_key,
    mouse_click_screen,
    mouse_move_rel,
    tap_key,
)


def pick_game_window() -> tuple[int, str]:
    wins = find_windows_by_title_substr("DATE FACTORY")
    for hwnd, title in wins:
        if "Godot Engine" in title and "(DEBUG)" not in title:
            continue
        if title.startswith("DATE FACTORY"):
            return hwnd, title
    raise RuntimeError(f"No game window in {wins}")


def grab(hwnd: int, out: Path) -> dict:
    focus_window(hwnd)
    time.sleep(0.25)
    left, top, right, bottom = get_client_rect_screen(hwnd)
    img = ImageGrab.grab(bbox=(left, top, right, bottom), all_screens=True)
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    gray = img.convert("L").resize((64, 36))
    mean = sum(gray.getdata()) / (64 * 36)
    return {"path": str(out), "size": img.size, "mean_luma": mean, "rect": [left, top, right, bottom]}


def launch(godot: Path, project: Path, user_appdata: Path, log_path: Path, resolution: str) -> subprocess.Popen:
    if user_appdata.exists():
        # clean profile
        import shutil

        shutil.rmtree(user_appdata)
    user_appdata.mkdir(parents=True)
    log_path.parent.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["APPDATA"] = str(user_appdata.resolve())
    cmd = [str(godot), "--path", str(project), "--resolution", resolution, "--windowed"]
    log_f = open(log_path, "w", encoding="utf-8", errors="replace")
    log_f.write(f"# cmd={' '.join(cmd)}\n# APPDATA={env['APPDATA']}\n# utc={time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}\n")
    log_f.flush()
    proc = subprocess.Popen(
        cmd,
        cwd=str(project),
        env=env,
        stdout=log_f,
        stderr=subprocess.STDOUT,
        stdin=subprocess.DEVNULL,
    )
    proc._log_f = log_f  # type: ignore[attr-defined]
    return proc


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--persona", required=True)
    ap.add_argument("--godot", default=r"C:\Users\User\Downloads\Godot_v4.7.1-stable_win64\Godot_v4.7.1-stable_win64_console.exe")
    ap.add_argument("--project", default=str(ROOT))
    ap.add_argument("--resolution", default="1920x1080")
    ap.add_argument("--wait", type=float, default=8.0)
    ap.add_argument("--shot", default="")
    ap.add_argument("--keys", default="")
    ap.add_argument("--click-client", default="")
    ap.add_argument("--pid-file", default="")
    ap.add_argument("--no-launch", action="store_true")
    args = ap.parse_args()

    px = Path(args.project) / "tmp" / "px_pass_01"
    user = px / f"userdata_{args.persona}"
    stamp = time.strftime("%Y%m%d_%H%M%S")
    log_path = px / "logs" / f"godot_{args.persona}_{stamp}.log"
    cmd_path = px / "logs" / f"commands_{args.persona}.txt"

    proc = None
    if not args.no_launch:
        proc = launch(Path(args.godot), Path(args.project), user, log_path, args.resolution)
        cmd_path.write_text(
            "\n".join(
                [
                    f"utc={time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}",
                    f"pid={proc.pid}",
                    f"APPDATA={user.resolve()}",
                    f"godot={args.godot}",
                    f"args=--path {args.project} --resolution {args.resolution} --windowed",
                    f"log={log_path}",
                    "ui_scale_intent=100% via empty isolated profile",
                ]
            ),
            encoding="utf-8",
        )
        if args.pid_file:
            Path(args.pid_file).write_text(str(proc.pid), encoding="utf-8")
        print(f"pid={proc.pid}")
        print(f"log={log_path}")
        time.sleep(args.wait)

    hwnd, title = pick_game_window()
    print(f"hwnd={hwnd}")
    print(f"title={title}")

    if args.click_client:
        x_s, y_s = args.click_client.split(",")
        focus_window(hwnd)
        left, top, _, _ = get_client_rect_screen(hwnd)
        mouse_click_screen(left + int(x_s), top + int(y_s))
        print(f"clicked_client={args.click_client}")

    if args.keys:
        focus_window(hwnd)
        time.sleep(0.05)
        for token in args.keys.split(","):
            token = token.strip()
            if not token:
                continue
            if token.upper().startswith("SLEEP:"):
                time.sleep(float(token.split(":", 1)[1]))
            elif token.upper().startswith("MOUSE:"):
                _, rest = token.split(":", 1)
                dx_s, dy_s = rest.split(":")
                mouse_move_rel(int(dx_s), int(dy_s))
            elif ":" in token:
                name, dur = token.split(":", 1)
                hold_key(name, float(dur))
            else:
                tap_key(token)
            time.sleep(0.04)
        print("keys_ok")

    if args.shot:
        meta = grab(hwnd, Path(args.shot))
        print(meta)

    # keep process running; caller stops later
    if proc is not None:
        print(f"keep_pid={proc.pid}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
