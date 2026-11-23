#!/usr/bin/env python3
"""Antigravity PreToolUse フック: 機密ファイル保護 (.env / secrets.fish) & pytest メモリガード．"""

from __future__ import annotations

import fnmatch
import json
import re
import sys
from pathlib import Path

SECRET_NAME_PATTERNS = (
    ".env",
    "*.env",
    ".env.*",
    "secrets.fish",
    "*secrets.fish",
    "private_secrets.fish.tmpl",
)

CMD_SECRET_RE = re.compile(
    r"""(^|[\s/"'])(\.env(\.[A-Za-z0-9_.-]+)?|[A-Za-z0-9_.-]*\.env|[A-Za-z0-9_.-]*secrets\.fish(\.tmpl)?)($|[\s"'])"""
)
PYTEST_RE = re.compile(r"(^|[^A-Za-z0-9_/.-])pytest([^A-Za-z0-9_.-]|$)")
MEMSAFE_RE = re.compile(r"(^|\s)mem-safe\s|MemoryMax=")


def is_secret_path(path_str: str) -> bool:
    name = Path(path_str).name
    if name in (".env.example", ".env.sample", ".env.template"):
        return False
    return any(fnmatch.fnmatch(name, pat) for pat in SECRET_NAME_PATTERNS)


def deny(reason: str) -> None:
    print(json.dumps({"decision": "deny", "reason": reason}, ensure_ascii=False))
    raise SystemExit(0)


def main() -> None:
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        print(json.dumps(dict(decision="ask")))
        return

    tc = payload.get("toolCall") or {}
    tool_name = tc.get("name") or ""
    args = tc.get("args") or {}
    cwd = payload.get("cwd") or ""

    if tool_name in ("read_file", "edit_file", "write_file"):
        target = args.get("Path") or ""
        if isinstance(target, str) and target and is_secret_path(target):
            deny(f"セキュリティポリシーにより機密ファイル ({Path(target).name}) へのアクセスは禁止されています．")

    if tool_name == "run_command":
        cmd = args.get("CommandLine") or ""
        if isinstance(cmd, str):
            if CMD_SECRET_RE.search(cmd) and not re.search(r"\.env\.(example|sample|template)", cmd):
                if re.search(r"\b(cat|head|tail|less|more|grep|rg|sed|awk|bat|vim|nvim|nano|python|python3)\b", cmd):
                    deny("セキュリティポリシーにより .env / secrets.fish 系のシェル読み取りは禁止されています．")

            if "/nakatalab/compe/2025" in f"{cwd} {cmd}":
                if PYTEST_RE.search(cmd) and not MEMSAFE_RE.search(cmd):
                    deny("メモリ枯渇の再発防止のため，pytest は mem-safe を付けて実行してください．例: mem-safe uv run pytest")

    print(json.dumps(dict(decision="ask")))


if __name__ == "__main__":
    main()
