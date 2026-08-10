#!/usr/bin/env python3
"""hgp 로컬 검증 하네스.

Godot 에디터 없이 실행 가능한 정적 검사를 모아 실행한다.
사용법: python tools/check.py

검사 항목:
1. gdformat --check : GDScript 포맷 (gdtoolkit)
2. gdlint           : GDScript 정적 분석 (gdtoolkit)
3. 리소스 참조      : .tscn/.tres/.gd 안의 res:// 경로가 실제로 존재하는지
4. uid 중복         : 씬/리소스/스크립트 uid가 프로젝트 안에서 유일한지
5. 파일 네이밍      : snake_case 소문자 (docs/CONVENTIONS.md)
6. 줄바꿈/BOM       : CRLF와 UTF-8 BOM 금지 (LF 통일)

종료 코드: 0 = 전체 통과, 1 = 실패 항목 존재, 2 = 실행 환경 문제
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# 우리가 작성하는 GDScript가 위치하는 폴더 (addons 등 서드파티 제외)
GD_SOURCE_DIRS = ("scenes", "scripts", "autoload", "resources", "tests")
# 네이밍 규칙을 적용하는 폴더
NAMING_DIRS = ("scenes", "scripts", "autoload", "resources", "assets", "tests")
# 순회에서 제외하는 폴더
EXCLUDE_DIRS = {
    ".git", ".godot", "addons", "export", "reports", ".gdunit4_action",
    # 삭제 대기함과 복구함. 스크립트 사본이 들어 있어 검사하면 중복으로 잡힌다.
    # Godot 쪽 제외는 각 폴더의 .gdignore가 담당한다 (.gitignore 40행 주석)
    "_to_delete", "_recover",
}

TEXT_EXTS = {
    ".gd", ".tscn", ".tres", ".cfg", ".godot", ".md", ".yml", ".yaml",
    ".py", ".svg", ".import", ".sh", ".toml", ".json", ".uid",
    ".gitignore", ".gitattributes", ".gitkeep",
}

SNAKE_CASE_RE = re.compile(r"^[a-z0-9_]+$")
RES_PATH_RE = re.compile(r'"(res://[^"\n]+)"')
HEADER_UID_RE = re.compile(r'^\[(?:gd_scene|gd_resource)[^\]]*?uid="(uid://[^"]+)"')

# 줄 맨 앞 선언 키워드. GDScript의 최상위 선언은 항상 1열에서 시작한다
DECL_KEYWORDS = (
    "func ", "static func ", "class_name ", "extends ", "var ", "const ",
    "signal ", "enum ", "@export", "@onready", "@tool",
)
# 선언 키워드 앞에 잡문자 1~3자가 붙은 줄 (예: dclass_name, ㅇfunc)
STRAY_PREFIX_RE = re.compile(
    r"^(\S{1,3})(" + "|".join(re.escape(k) for k in DECL_KEYWORDS) + r")"
)
# 한글 낱자모. 완성형(가~힣)이 아니라 자모 단독은 한글 입력 중 섞여 든 흔적이다
JAMO_RE = re.compile(r"[\u3130-\u318f]")
STRING_RE = re.compile(r"\"[^\"]*\"|'[^']*'")


def iter_repo_files() -> list[Path]:
    files: list[Path] = []
    for path in sorted(REPO_ROOT.rglob("*")):
        if not path.is_file():
            continue
        rel_parts = path.relative_to(REPO_ROOT).parts
        if any(part in EXCLUDE_DIRS for part in rel_parts):
            continue
        files.append(path)
    return files


def our_gd_files() -> list[Path]:
    files: list[Path] = []
    for dir_name in GD_SOURCE_DIRS:
        base = REPO_ROOT / dir_name
        if base.is_dir():
            files.extend(sorted(base.rglob("*.gd")))
    return files


def rel(path: Path) -> str:
    return path.relative_to(REPO_ROOT).as_posix()


def check_gdtoolkit(tool: str, args: list[str], targets: list[Path]) -> list[str]:
    if not targets:
        return []
    exe = shutil.which(tool)
    if exe is None:
        return [
            f"{tool} 미설치. 설치: pip install \"gdtoolkit==4.*\" "
            "(Windows는 py -m pip 사용)"
        ]
    cmd = [exe, *args, *[str(t) for t in targets]]
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode == 0:
        return []
    output = (proc.stdout + proc.stderr).strip()
    return [f"{tool} 실패:\n{output}"]


def check_resource_refs(files: list[Path]) -> list[str]:
    errors: list[str] = []
    for path in files:
        if path.suffix not in {".tscn", ".tres", ".gd"}:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for line_no, line in enumerate(text.splitlines(), start=1):
            for match in RES_PATH_RE.finditer(line):
                res_path = match.group(1)
                target = REPO_ROOT / res_path[len("res://"):]
                if not target.exists():
                    errors.append(
                        f"{rel(path)}:{line_no} 존재하지 않는 리소스 참조: {res_path}"
                    )
    return errors


def check_uid_duplicates(files: list[Path]) -> list[str]:
    errors: list[str] = []
    seen: dict[str, str] = {}
    for path in files:
        uid = ""
        if path.suffix in {".tscn", ".tres"}:
            try:
                first_line = path.read_text(encoding="utf-8").splitlines()[0]
            except (UnicodeDecodeError, IndexError):
                continue
            match = HEADER_UID_RE.match(first_line)
            if match:
                uid = match.group(1)
        elif path.suffix == ".uid":
            uid = path.read_text(encoding="utf-8").strip()
        if not uid:
            continue
        if uid in seen:
            errors.append(f"uid 중복: {uid} ({seen[uid]} <-> {rel(path)})")
        else:
            seen[uid] = rel(path)
    return errors


def check_naming(files: list[Path]) -> list[str]:
    errors: list[str] = []
    for path in files:
        rel_parts = path.relative_to(REPO_ROOT).parts
        if rel_parts[0] not in NAMING_DIRS:
            continue
        for part in rel_parts[:-1]:
            if not SNAKE_CASE_RE.match(part):
                errors.append(f"{rel(path)} 폴더명이 snake_case가 아님: {part}")
        name = rel_parts[-1]
        if name == ".gitkeep":
            continue
        stem = name.split(".", 1)[0]
        suffixes = name.split(".")[1:]
        if not SNAKE_CASE_RE.match(stem) or any(
            not SNAKE_CASE_RE.match(s) for s in suffixes
        ):
            errors.append(f"{rel(path)} 파일명이 snake_case 소문자가 아님")
    return errors


def check_line_endings(files: list[Path]) -> list[str]:
    errors: list[str] = []
    for path in files:
        suffix = path.suffix if path.suffix else path.name
        if suffix not in TEXT_EXTS:
            continue
        data = path.read_bytes()
        if data.startswith(b"\xef\xbb\xbf"):
            errors.append(f"{rel(path)} UTF-8 BOM 포함")
        if b"\r\n" in data:
            errors.append(f"{rel(path)} CRLF 줄바꿈 포함 (LF로 통일)")
    return errors


def check_stray_chars(files: list[Path]) -> list[str]:
    """줄 맨 앞에 끼어든 잡문자와 코드 영역의 한글 낱자모를 찾는다.

    Godot 편집기에서 커서가 줄 맨 앞에 있을 때 눌린 키가 그대로 파일에 들어가면
    'dclass_name Player'나 'ㅇfunc ...' 같은 줄이 생긴다. 파싱이 통째로 깨지는데
    오류 메시지는 그 줄만 가리켜 원인을 찾기 어렵다 (2026-08-08~09 세 차례 발생).
    """
    errors: list[str] = []
    for path in files:
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for line_no, line in enumerate(text.splitlines(), start=1):
            stripped = line.lstrip()
            if stripped.startswith("#"):
                continue
            match = STRAY_PREFIX_RE.match(line)
            if match and not line.startswith(match.group(2)):
                errors.append(
                    f"{rel(path)}:{line_no} 선언 앞에 잡문자 "
                    f"{match.group(1)!r}: {line[:50]!r}"
                )
            # 주석과 문자열을 걷어낸 코드 영역에만 낱자모가 있으면 오타다
            code = STRING_RE.sub('""', line.split("#")[0])
            found = JAMO_RE.search(code)
            if found:
                errors.append(
                    f"{rel(path)}:{line_no} 코드에 한글 낱자모 "
                    f"{found.group()!r}: {line[:50]!r}"
                )
    return errors


CLASS_NAME_RE = re.compile(r"^class_name\s+([A-Za-z_]\w*)")
EXTENDS_RE = re.compile(r"^extends\s+([A-Za-z_\"][\w\"./]*)")
MEMBER_RES = (
    re.compile(r"^(?:@onready\s+|@export[^\s]*\s+)*(?:static\s+)?var\s+([A-Za-z_]\w*)"),
    re.compile(r"^const\s+([A-Za-z_]\w*)"),
    re.compile(r"^signal\s+([A-Za-z_]\w*)"),
)


def check_member_shadowing(files: list[Path]) -> list[str]:
    """부모 클래스에 이미 있는 멤버를 자식이 다시 선언하는 곳을 찾는다.

    GDScript 는 이것을 파서 오류로 낸다.
      Parser Error: The member "X" already exists in parent class Y.
    gdlint 로는 안 잡히고 에디터를 열어야 보여서, 부모에 멤버를 추가한 날 한참 뒤에
    엉뚱한 자식 파일에서 터진다 (2026-08-10 Room._player 대 room_rest._player).
    """
    parsed: dict[Path, tuple[dict[str, int], str | None, str | None]] = {}
    by_class: dict[str, Path] = {}
    by_abs: dict[Path, Path] = {}

    for path in files:
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        members: dict[str, int] = {}
        class_name = None
        parent = None
        for line_no, line in enumerate(text.splitlines(), start=1):
            if line[:1] in (" ", "\t") or not line.strip():
                continue
            for pattern in MEMBER_RES:
                found = pattern.match(line)
                if found:
                    members[found.group(1)] = line_no
                    break
            found = CLASS_NAME_RE.match(line)
            if found:
                class_name = found.group(1)
            found = EXTENDS_RE.match(line)
            if found:
                parent = found.group(1).strip('"')
        parsed[path] = (members, class_name, parent)
        by_abs[path.resolve()] = path
        if class_name:
            by_class[class_name] = path

    def resolve(name: str) -> Path | None:
        if name in by_class:
            return by_class[name]
        if name.startswith("res://"):
            return by_abs.get((ROOT / name[len("res://"):]).resolve())
        return None

    errors: list[str] = []
    for path, (members, _cls, parent) in parsed.items():
        chain: list[Path] = []
        seen: set[Path] = set()
        current = parent
        while current:
            parent_path = resolve(current)
            if parent_path is None or parent_path in seen:
                break
            seen.add(parent_path)
            chain.append(parent_path)
            current = parsed[parent_path][2]
        for name, line_no in members.items():
            for parent_path in chain:
                if name in parsed[parent_path][0]:
                    errors.append(
                        f"{rel(path)}:{line_no} {name!r} 가 부모 "
                        f"{rel(parent_path)}:{parsed[parent_path][0][name]} 에 이미 있다"
                    )
                    break
    return errors


def main() -> int:
    files = iter_repo_files()
    gd_files = our_gd_files()

    sections: list[tuple[str, list[str]]] = [
        ("gdformat", check_gdtoolkit("gdformat", ["--check"], gd_files)),
        ("gdlint", check_gdtoolkit("gdlint", [], gd_files)),
        ("잡문자/낱자모", check_stray_chars(gd_files)),
        ("부모 멤버 중복", check_member_shadowing(gd_files)),
        ("리소스 참조", check_resource_refs(files)),
        ("uid 중복", check_uid_duplicates(files)),
        ("파일 네이밍", check_naming(files)),
        ("줄바꿈/BOM", check_line_endings(files)),
    ]

    failed = False
    for title, errors in sections:
        status = "통과" if not errors else f"실패 ({len(errors)}건)"
        print(f"[{title}] {status}")
        for error in errors:
            failed = True
            print(f"  - {error}")

    print()
    if failed:
        print("검증 실패. 위 항목을 수정한 뒤 다시 실행한다.")
        return 1
    print(f"전체 통과. (.gd {len(gd_files)}개, 전체 파일 {len(files)}개 검사)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
