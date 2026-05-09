#!/usr/bin/env python3
"""Build a single SQLite DB from the bundled per-surah JSON files.

Run from the project root:
    python3 tool/build_quran_db.py

Reads:
    assets/quran/list.json       # surah metadata
    assets/quran/{1..114}.json   # ayahs with arabic + translations

Writes:
    assets/db/quran.db
"""

from __future__ import annotations

import json
import os
import sqlite3
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
QURAN_DIR = ROOT / "assets" / "quran"
OUT_PATH = ROOT / "assets" / "db" / "quran.db"


SCHEMA = """
PRAGMA journal_mode=DELETE;
PRAGMA page_size=4096;

CREATE TABLE surahs (
    number                    INTEGER PRIMARY KEY,
    name                      TEXT NOT NULL,
    english_name              TEXT NOT NULL,
    english_name_translation  TEXT NOT NULL,
    revelation_type           TEXT NOT NULL,
    ayah_count                INTEGER NOT NULL
);

CREATE TABLE ayahs (
    surah            INTEGER NOT NULL,
    number_in_surah  INTEGER NOT NULL,
    number_global    INTEGER NOT NULL,
    arabic           TEXT NOT NULL,
    translation_en   TEXT,
    translation_ar   TEXT,
    translation_ku   TEXT,
    juz              INTEGER NOT NULL,
    page             INTEGER NOT NULL,
    sajda            INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (surah, number_in_surah)
);

CREATE INDEX idx_ayahs_page ON ayahs(page);
CREATE INDEX idx_ayahs_juz ON ayahs(juz);
CREATE INDEX idx_ayahs_global ON ayahs(number_global);
"""


def main() -> int:
    if not QURAN_DIR.is_dir():
        print(f"error: {QURAN_DIR} does not exist", file=sys.stderr)
        return 1

    list_path = QURAN_DIR / "list.json"
    if not list_path.exists():
        print(f"error: {list_path} missing", file=sys.stderr)
        return 1

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    if OUT_PATH.exists():
        OUT_PATH.unlink()

    conn = sqlite3.connect(OUT_PATH)
    try:
        conn.executescript(SCHEMA)

        with list_path.open(encoding="utf-8") as f:
            surahs = json.load(f)

        conn.executemany(
            "INSERT INTO surahs (number, name, english_name, "
            "english_name_translation, revelation_type, ayah_count) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            [
                (
                    s["number"],
                    s["name"],
                    s["englishName"],
                    s["englishNameTranslation"],
                    s["revelationType"],
                    s["ayahCount"],
                )
                for s in surahs
            ],
        )

        ayah_rows: list[tuple] = []
        total = 0
        for entry in surahs:
            surah_num = entry["number"]
            surah_path = QURAN_DIR / f"{surah_num}.json"
            if not surah_path.exists():
                print(f"warn: {surah_path} missing", file=sys.stderr)
                continue
            with surah_path.open(encoding="utf-8") as f:
                payload = json.load(f)
            for a in payload["ayahs"]:
                trans = a.get("translations", {}) or {}
                ayah_rows.append(
                    (
                        surah_num,
                        a["numberInSurah"],
                        a["number"],
                        a["arabic"],
                        trans.get("en"),
                        trans.get("ar"),
                        trans.get("ku"),
                        a["juz"],
                        a["page"],
                        1 if a.get("sajda") else 0,
                    )
                )
                total += 1

        conn.executemany(
            "INSERT INTO ayahs (surah, number_in_surah, number_global, arabic, "
            "translation_en, translation_ar, translation_ku, juz, page, sajda) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ayah_rows,
        )

        conn.commit()
        conn.execute("ANALYZE")
        conn.execute("VACUUM")
        conn.commit()

        size = OUT_PATH.stat().st_size
        print(f"wrote {OUT_PATH} ({size / (1024 * 1024):.2f} MB, {total} ayahs)")
    finally:
        conn.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
