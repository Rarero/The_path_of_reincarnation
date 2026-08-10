#!/usr/bin/env python3
"""신규 적 임시 스프라이트 굽기 (2026-08-09 사용자 지시: 군상 그리드 재활용).

입력: art_src/generated/pixellab/grids/act1_crowd_grid.png (256x256, 32px 셀 8x8)
출력: assets/sprites/enemies/ 아래 개체별 idle 스프라이트

배경 군상 그리드는 이미 PixelLab에서 무드 앵커 팔레트로 생성한 원본이다.
그 안에 장물아비와 짐꾼에 그대로 쓸 수 있는 인물이 있어 잘라서 적 스프라이트로 쓴다.
잡도깨비 프레임을 색만 바꿔 쓰던 자리표시보다 판별이 훨씬 낫다.

달걀도깨비는 그리드에 대응 인물이 없어 2026-08-09에 PixelLab 웹 UI(Objects,
Sidescroller, 48px, 1 Direction)로 새로 생성했다. 16프레임 중 남보라 바탕에 난색
얼룩이 있는 1번을 채택했다. 원본은 art_src/generated/pixellab/chars/act1_egg_v1.png,
인게임분은 assets/sprites/enemies/egg_idle_e.png(21x26)다. 이 스크립트는 군상
그리드에서 자르는 두 종만 다룬다.

처리: 셀 크롭 -> 알파 이진화(128) -> 알파 bbox 트림 -> NEAREST 1.5배 확대.
1.5배인 이유: 군상은 배경 밀도(25~29px)로 생성됐고 적 규격은 40px 안팎이다.
정수배(2배)면 잡도깨비보다 커져 위협 등급과 실루엣 크기가 어긋난다.

사용: python tools/pipeline/bake_enemy_placeholders.py
"""

from __future__ import annotations

import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
GRID = ROOT / "art_src" / "generated" / "pixellab" / "grids" / "act1_crowd_grid.png"
OUT_DIR = ROOT / "assets" / "sprites" / "enemies"

CELL = 32
SCALE = 1.5

# 출력 파일명 -> (셀 열, 셀 행, 선정 근거)
PICKS: dict[str, tuple[int, int, str]] = {
    "thief_idle_e.png": (2, 1, "장물아비: 허리에 장물 바구니를 메고 한 손에 물건을 든 도깨비"),
    "porter_idle_e.png": (7, 2, "짐꾼: 패랭이를 쓰고 큰 짐 덩어리를 진 인물. 짐이 몸을 덮어 정면 가드로 읽힌다"),
}


def bake(cell_x: int, cell_y: int) -> Image.Image:
    grid = Image.open(GRID).convert("RGBA")
    box = (cell_x * CELL, cell_y * CELL, (cell_x + 1) * CELL, (cell_y + 1) * CELL)
    cut = grid.crop(box)
    # 알파 이진화. 반투명 잔털을 없애 픽셀 경계를 살린다
    alpha = cut.getchannel("A").point(lambda v: 255 if v >= 128 else 0)
    cut.putalpha(alpha)
    bbox = cut.getbbox()
    if bbox is None:
        raise SystemExit("빈 셀: %d,%d" % (cell_x, cell_y))
    cut = cut.crop(bbox)
    size = (max(1, round(cut.width * SCALE)), max(1, round(cut.height * SCALE)))
    return cut.resize(size, Image.NEAREST)


def main() -> None:
    if not GRID.exists():
        raise SystemExit("그리드가 없다: %s" % GRID)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for name, (cx, cy, why) in PICKS.items():
        image = bake(cx, cy)
        out = OUT_DIR / name
        image.save(out)
        print("%-22s %2dx%-2d  셀 %d,%d  %s" % (name, image.width, image.height, cx, cy, why))


if __name__ == "__main__":
    main()
