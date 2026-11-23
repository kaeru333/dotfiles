#!/usr/bin/env python3
"""Antigravity Stop フック: English practice mode の採点結果を Claude Code と同じ SQLite DB に記録する．"""

from __future__ import annotations

import json
import re
import sqlite3
import sys
from datetime import datetime
from pathlib import Path

DB_PATH = Path.home() / ".local/share/english-practice/log.db"
SCORE_RE = re.compile(r"📝\s*Score:\s*(\d+)\s*/\s*10\s*(?:[—\-:]\s*(.*))?")
BETTER_RE = re.compile(r"✏️\s*Better:\s*(.+)")
GLOSS_RE = re.compile(r"💡\s*(.+)")
USER_REQ_RE = re.compile(r"<USER_REQUEST>\s*(.*?)\s*</USER_REQUEST>", re.S)

SCHEMA = """
CREATE TABLE IF NOT EXISTS entries (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    prompt_id  TEXT UNIQUE NOT NULL,
    session_id TEXT,
    cwd        TEXT,
    created_at TEXT NOT NULL,
    prompt     TEXT NOT NULL,
    score      INTEGER,
    reason     TEXT,
    better     TEXT,
    glossary   TEXT
);
"""


def extract_user_prompt(raw: str) -> str | None:
    m = USER_REQ_RE.search(raw)
    txt = (m.group(1) if m else raw).strip()
    if not txt or txt.startswith("<"):
        return None
    return txt


def record_latest(payload: dict) -> None:
    tp = payload.get("transcriptPath")
    if not isinstance(tp, str) or not tp:
        return
    tfile = Path(tp)
    if not tfile.is_file():
        return

    conv_id = str(payload.get("conversationId") or "")
    cwd = str(payload.get("cwd") or "")

    steps = []
    for line in tfile.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            steps.append(json.loads(line))
        except Exception:
            continue

    last_user_idx = None
    for i in range(len(steps) - 1, -1, -1):
        if steps[i].get("type") == "USER_INPUT":
            last_user_idx = i
            break
    if last_user_idx is None:
        return

    u_step = steps[last_user_idx]
    prompt = extract_user_prompt(str(u_step.get("content") or ""))
    if not prompt:
        return

    replies = [
        str(s.get("content") or "")
        for s in steps[last_user_idx + 1 :]
        if s.get("type") == "PLANNER_RESPONSE" and s.get("content")
    ]
    reply = "\n".join(replies)
    sm = SCORE_RE.search(reply)
    if not sm:
        return

    score = int(sm.group(1))
    reason = (sm.group(2) or "").strip()
    bm = BETTER_RE.search(reply)
    better = bm.group(1).strip() if bm else ""
    glosses = [gm.group(1).strip() for gm in GLOSS_RE.finditer(reply)]
    glossary = "\n".join(glosses)

    step_idx = u_step.get("step_index", last_user_idx)
    prompt_id = f"agy:{conv_id}:{step_idx}"
    created_at = str(u_step.get("created_at") or datetime.now().isoformat())

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(DB_PATH) as conn:
        conn.executescript(SCHEMA)
        conn.execute(
            """
            INSERT OR IGNORE INTO entries
              (prompt_id, session_id, cwd, created_at, prompt, score, reason, better, glossary)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (prompt_id, conv_id, cwd, created_at, prompt, score, reason, better, glossary),
        )
        conn.commit()


def main() -> None:
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
        record_latest(payload)
    except Exception:
        pass
    print("{}")


if __name__ == "__main__":
    main()
