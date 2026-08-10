"""GDScript 컴파일 검증.

check.py의 gdformat/gdlint는 문법과 스타일까지만 본다. 존재하지 않는 오토로드 메서드
호출이나 부모와 시그니처가 다른 재정의처럼 "파싱은 되지만 컴파일이 안 되는" 결함은
엔진만 잡는다 (docs/DECISIONS.md 2026-08-07).

동작: project.godot에 임시 오토로드(CompileProbe)를 붙이고 헤드리스로 한 번 띄워
res:// 아래의 .gd/.tscn/.tres를 전부 ResourceLoader.load 해 본 뒤 원래대로 되돌린다.
오토로드를 쓰는 이유는 godot --check-only가 오토로드 식별자를 해석하지 못하기 때문이다.

사용: python tools/compile_check.py
      GODOT_BIN 환경변수로 실행 파일 경로를 지정할 수 있다. 없으면 PATH에서 찾는다.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "project.godot"
PROBE = ROOT / "_compile_probe.gd"
BACKUP = ROOT / "project.godot.compile_check_bak"
AUTOLOAD_LINE = 'CompileProbe="*res://_compile_probe.gd"\n'

PROBE_SOURCE = '''extends Node

## 컴파일 검증용 임시 오토로드. tools/compile_check.py가 생성하고 지운다.

var _fail: int = 0
var _total: int = 0


func _ready() -> void:
	print("=== PROBE START ===")
	_scan("res://")
	print("=== PROBE END %d %d ===" % [_total, _fail])
	get_tree().quit(1 if _fail > 0 else 0)


func _scan(dir_path: String) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	# .gdignore가 있는 폴더는 엔진이 스캔에서 제외한다. 검사기도 같은 규칙을 따라야
	# 폐기 예정 사본이 중복 class_name으로 잡히는 가짜 실패가 나지 않는다
	if FileAccess.file_exists(dir_path.path_join(".gdignore")):
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full: String = dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with(".") and entry != "addons":
				_scan(full)
		elif entry != "_compile_probe.gd":
			for ext: String in [".gd", ".tscn", ".tres"]:
				if not entry.ends_with(ext):
					continue
				_total += 1
				if ResourceLoader.load(full) == null:
					_fail += 1
					print("FAIL  ", full)
		entry = dir.get_next()
	dir.list_dir_end()
'''


def find_godot() -> str | None:
    env = os.environ.get("GODOT_BIN")
    if env and Path(env).exists():
        return env
    for name in ("godot", "godot4", "Godot", "godot.exe"):
        found = shutil.which(name)
        if found:
            return found
    return None


def install() -> None:
    shutil.copy2(PROJECT, BACKUP)
    text = PROJECT.read_text(encoding="utf-8")
    match = re.search(r"\[autoload\]\n", text)
    if match is None:
        text = text.rstrip("\n") + "\n\n[autoload]\n\n" + AUTOLOAD_LINE
    else:
        rest = text[match.end():]
        end = rest.find("\n[")
        block = rest[:end] if end >= 0 else rest
        new_block = block.rstrip("\n") + "\n" + AUTOLOAD_LINE
        text = text[: match.end()] + new_block + (rest[end:] if end >= 0 else "")
    PROJECT.write_text(text, encoding="utf-8")
    PROBE.write_text(PROBE_SOURCE, encoding="utf-8")


def restore() -> None:
    if BACKUP.exists():
        shutil.move(str(BACKUP), str(PROJECT))
    if PROBE.exists():
        PROBE.unlink()
    uid = PROBE.with_suffix(".gd.uid")
    if uid.exists():
        uid.unlink()


def main() -> int:
    godot = find_godot()
    if godot is None:
        print("[컴파일] 건너뜀 - Godot 실행 파일을 찾지 못했다.")
        print("  GODOT_BIN 환경변수에 경로를 지정하거나 PATH에 godot을 넣어라.")
        return 0

    install()
    try:
        subprocess.run(
            [godot, "--headless", "--path", str(ROOT), "--import"],
            capture_output=True,
            text=True,
            timeout=600,
        )
        result = subprocess.run(
            [godot, "--headless", "--path", str(ROOT)],
            capture_output=True,
            text=True,
            timeout=600,
        )
    except subprocess.TimeoutExpired:
        restore()
        print("[컴파일] 실패 - 시간 초과")
        return 1
    finally:
        restore()

    output = (result.stdout or "") + (result.stderr or "")
    problems = [
        line.strip()
        for line in output.splitlines()
        if line.startswith("FAIL  ")
        or "SCRIPT ERROR" in line
        or "Compile Error" in line
        or "Parse Error" in line
    ]
    if problems:
        print(f"[컴파일] 실패 ({len(problems)}건)")
        for line in problems[:40]:
            print(f"  - {line}")
        return 1
    print("[컴파일] 통과")
    return 0


if __name__ == "__main__":
    sys.exit(main())
