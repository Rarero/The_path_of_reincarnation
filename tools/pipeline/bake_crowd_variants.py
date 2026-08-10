#!/usr/bin/env python3
"""1막 군상 변형 추출 (요청서 012 그리드 재수확, 2026-08-05 복작복작 디렉팅).

입력: art_src/generated/pixellab/grids/act1_crowd_grid.png (256x256, 32px 셀 8x8)
출력: assets/sprites/bg/act1/crowd/ 아래 변형 스프라이트

기존 crowd_a~f는 정면 위주 6종만 수확한 상태였다. 배경 군상이 전부 정면을
보는 문제(2026-08-05 디렉팅)를 고치기 위해 같은 그리드에서 뒷모습 5종,
환호 2종, 맨손 정면 2종, 아이, 고양이를 추가 수확한다.

처리: 셀 크롭 -> 알파 이진화(128) -> 알파 bbox 트림. 색은 손대지 않는다
(그리드가 이미 무드 앵커 팔레트로 생성된 원본이다).

사용: python tools/pipeline/bake_crowd_variants.py
"""

from __future__ import annotations

import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
GRID = ROOT / "art_src" / "generated" / "pixellab" / "grids" / "act1_crowd_grid.png"
OUT_DIR = ROOT / "assets" / "sprites" / "bg" / "act1" / "crowd"

CELL = 32

# 이름 -> (셀 열, 셀 행). 0 기준. 그리드 육안 판독 결과 (2026-08-05)
CELLS: dict[str, tuple[int, int]] = {
    # 뒷모습 (좌판 손님, 구경꾼 용)
    "crowd_back_a": (1, 0),  # 갓 쓴 검은 도포 뒷모습
    "crowd_back_b": (7, 1),  # 맨머리 뒷모습
    "crowd_back_c": (6, 5),  # 패랭이 뒷모습
    "crowd_back_d": (2, 6),  # 어두운 두루마기 뒷모습
    "crowd_back_e": (2, 7),  # 갈색 저고리 뒷모습
    # 환호 (씨름 구경꾼 용. 팔을 든 자세)
    "crowd_cheer_a": (4, 5),  # 패랭이 쓰고 팔 든 남자
    "crowd_cheer_b": (5, 5),  # 갓 쓰고 팔 든 남자
    # 맨손 정면 (씨름꾼 겸 일반 행인)
    "crowd_g": (2, 4),  # 맨손 도깨비
    "crowd_h": (6, 4),  # 맨손 도깨비 (다른 체형)
    # 특수 (행인 다양화)
    "crowd_child": (5, 7),  # 아이
    "crowd_cat": (7, 7),  # 저자 고양이
}


def bake(name: str, col: int, row: int, grid: Image.Image) -> tuple[int, int]:
    cell = grid.crop((col * CELL, row * CELL, (col + 1) * CELL, (row + 1) * CELL))
    r, g, b, a = cell.split()
    a = a.point(lambda v: 255 if v >= 128 else 0)
    cell = Image.merge("RGBA", (r, g, b, a))
    bbox = cell.getbbox()
    if bbox is None:
        raise SystemExit(f"{name}: 셀 ({col},{row})이 비어 있다")
    cell = cell.crop(bbox)
    out = OUT_DIR / f"{name}.png"
    cell.save(out)
    return cell.size


def main() -> int:
    grid = Image.open(GRID).convert("RGBA")
    if grid.size != (256, 256):
        raise SystemExit(f"그리드 크기가 규격(256x256)이 아니다: {grid.size}")
    for name, (col, row) in CELLS.items():
        size = bake(name, col, row, grid)
        print(f"{name}.png {size[0]}x{size[1]} <- cell({col},{row})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
