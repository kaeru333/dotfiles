#!/usr/bin/env python3
"""Antigravity SessionStart フック: herdr 状態通知 & 未移行 CLAUDE.md の自動参照．"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


def notify_herdr(payload: dict) -> None:
    """herdr ペイン内で起動している場合，Claude 互換ペイロードに変換して通知する．"""
    script = Path.home() / ".claude/hooks/herdr-agent-state.sh"
    if not script.exists() or os.environ.get("HERDR_ENV") != "1":
        return
    compat = {
        "hook_event_name": "SessionStart",
        "session_id": payload.get("conversationId") or "",
        "transcript_path": payload.get("transcriptPath") or "",
        "cwd": payload.get("cwd") or "",
        "source": "startup",
    }
    try:
        subprocess.run(
            ["bash", str(script), "session"],
            input=json.dumps(compat),
            text=True,
            capture_output=True,
            timeout=5,
        )
    except Exception:
        pass


def collect_unmigrated_claude_md(payload: dict) -> list[str]:
    """AGENTS.md が未作成のプロジェクトに CLAUDE.md があれば読み込む．"""
    roots: list[Path] = []
    cwd = payload.get("cwd")
    if isinstance(cwd, str) and cwd:
        roots.append(Path(cwd))
    for wp in payload.get("workspacePaths") or []:
        if isinstance(wp, str) and wp:
            p = Path(wp)
            if p not in roots:
                roots.append(p)

    home_dir = Path.home().resolve()
    global_claude = (home_dir / ".claude/CLAUDE.md").resolve()
    seen: set[Path] = set()
    injected: list[str] = []

    for start in roots:
        cur = start.resolve()
        while True:
            claude_md = cur / "CLAUDE.md"
            agents_md = cur / "AGENTS.md"
            if claude_md.is_file():
                real = claude_md.resolve()
                if real != global_claude and real not in seen and not agents_md.exists():
                    seen.add(real)
                    try:
                        txt = claude_md.read_text(encoding="utf-8", errors="replace").strip()
                        if txt and not txt.startswith("@AGENTS.md"):
                            injected.append(
                                f"[自動参照: {claude_md} (AGENTS.md 未移行のため読み込み)]\n\n{txt[:24000]}"
                            )
                    except Exception:
                        pass
            if (cur / ".git").exists() or cur == home_dir or cur.parent == cur:
                break
            cur = cur.parent
    return injected


def main() -> None:
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        payload = {}

    notify_herdr(payload)
    extra_rules = collect_unmigrated_claude_md(payload)
    if extra_rules:
        out = {
            "injectSteps": [
                {"systemMessage": {"systemMessage": "\n\n---\n\n".join(extra_rules)}}
            ]
        }
        print(json.dumps(out, ensure_ascii=False))
    else:
        print("{}")


if __name__ == "__main__":
    main()
