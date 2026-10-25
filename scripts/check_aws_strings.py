#!/usr/bin/env python3
"""resource / data ブロックの中に ASCII 以外の文字（日本語など）がないか調べる。

AWS の API には、IAM の description やセキュリティグループの description など、
ASCII（ラテン文字）しか受け付けない項目がある。apply の途中で失敗しないよう、
plan より前にここで検出する。

対象外:
  - コメント（#、//、/* */）
  - variable / output / locals / terraform などのブロック（AWS に送られない）
  - 行末に「allow-non-ascii」と書いた行（意図して日本語を送る場合の例外指定）

前提: terraform fmt 済みであること（トップレベルのブロックが行頭の「}」で閉じる）。
"""

import re
import sys
from pathlib import Path

BLOCK_START = re.compile(r'^(resource|data)\s+"([^"]+)"\s+"([^"]+)"')
ALLOW_MARK = "allow-non-ascii"


def strip_comments(line: str, in_block_comment: bool) -> tuple[str, bool]:
    """1行からコメント部分を除いた文字列を返す。文字列リテラル内の # は残す。"""
    out = []
    i = 0
    in_string = False
    while i < len(line):
        ch = line[i]
        nxt = line[i + 1] if i + 1 < len(line) else ""

        if in_block_comment:
            if ch == "*" and nxt == "/":
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue

        if in_string:
            out.append(ch)
            if ch == "\\":
                out.append(nxt)
                i += 2
                continue
            if ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            out.append(ch)
        elif ch == "#" or (ch == "/" and nxt == "/"):
            break
        elif ch == "/" and nxt == "*":
            in_block_comment = True
            i += 2
            continue
        else:
            out.append(ch)
        i += 1

    return "".join(out), in_block_comment


def check_file(path: Path) -> list[tuple[int, str, str]]:
    findings = []
    current_block = None
    in_block_comment = False

    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if current_block is None:
            m = BLOCK_START.match(raw)
            if m:
                current_block = f'{m.group(1)}.{m.group(2)}.{m.group(3)}'
            continue

        if raw == "}":
            current_block = None
            in_block_comment = False
            continue

        code, in_block_comment = strip_comments(raw, in_block_comment)
        if ALLOW_MARK in raw:
            continue

        bad = [ch for ch in code if ord(ch) > 127]
        if bad:
            findings.append((lineno, current_block, raw.strip()))

    return findings


def main(argv: list[str]) -> int:
    root = Path(argv[1]) if len(argv) > 1 else Path(".")
    files = sorted(
        p for p in root.rglob("*.tf") if ".terraform" not in p.parts
    )

    total = 0
    for path in files:
        for lineno, block, text in check_file(path):
            total += 1
            # GitHub Actions のアノテーション形式（PR やジョブ画面の該当行に表示される）
            print(
                f"::error file={path},line={lineno}::"
                f"Non-ASCII text in {block} (AWS may reject it): {text}"
            )

    if total:
        print(
            f"\n{total} 件見つかりました。resource / data ブロック内の文字列は英語で書き、"
            "日本語の説明はコメント（#）に移してください。"
        )
        return 1

    print(f"OK: {len(files)} 個の .tf ファイルを確認し、問題はありませんでした。")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
