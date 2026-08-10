"""1막 플레이스홀더 타일셋 생성기.

assets/sprites/tiles/tileset_act1.png (아틀라스)와 stall_cover.png (좌판)를 생성한다.
PixelLab 타일셋으로 교체하기 전까지 쓰는 코드 생성 플레이스홀더다 (DECISIONS 2026-08-04).

톤 규칙 (docs/ART_STYLE.md):
- 저채도 야경 기조. 재질당 4~5단 램프
- 플레이 레이어는 검정 아웃라인으로 배경과 분리한다 (배경은 아웃라인 없음)
- 디더링 미사용 (타일 전경 클린 규칙)

아틀라스 배치는 resources/tiles/tileset_act1.tres와 scripts/map/room_terrain.gd가
좌표로 참조하므로, 배치를 바꾸면 두 파일을 함께 갱신해야 한다.

사용법: python tools/pipeline/gen_tileset_act1.py
"""

from __future__ import annotations

import pathlib
import random

from PIL import Image, ImageDraw

TILE = 16
COLS = 8
ROWS = 6

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT_ATLAS = ROOT / "assets" / "sprites" / "tiles" / "tileset_act1.png"
OUT_STALL = ROOT / "assets" / "sprites" / "tiles" / "stall_cover.png"

OUTLINE = (13, 12, 14, 255)

# 재질 램프: 어두움 -> 밝음 (4~5단).
# 배경/맵 분리 원칙(DECISIONS 2026-08-03: 맵은 밝음 + 검정 아웃라인)에 맞춰
# 야간 침전된 배경보다 한 단계 밝게 잡는다.
EARTH = [(38, 33, 28), (56, 48, 40), (74, 64, 53), (94, 81, 66), (134, 117, 91)]
STONE = [(38, 40, 47), (58, 61, 71), (76, 80, 92), (96, 101, 115), (136, 143, 158)]
PLANK = [(43, 34, 26), (66, 53, 42), (87, 71, 55), (108, 88, 68), (146, 121, 94)]
GIWA = [(31, 34, 41), (51, 55, 66), (68, 73, 88), (87, 93, 110), (124, 133, 152)]
DECK = [(58, 47, 35), (84, 68, 50), (110, 90, 66), (135, 112, 82), (170, 142, 106)]


def _rng(x: int, y: int, salt: int = 0) -> random.Random:
    """타일 좌표별 결정적 난수 (재생성해도 같은 그림)."""
    return random.Random(x * 733 + y * 149 + salt * 7919)


def _speckle(d: ImageDraw.ImageDraw, ox: int, oy: int, rng: random.Random,
             color: tuple, count: int, y0: int = 0, y1: int = TILE) -> None:
    for _ in range(count):
        px = ox + rng.randrange(1, TILE - 1)
        py = oy + rng.randrange(max(1, y0), min(TILE - 1, y1))
        d.point((px, py), fill=color)


def draw_earth(d: ImageDraw.ImageDraw, ox: int, oy: int, x: int, y: int,
               top: bool, left: bool, right: bool) -> None:
    """흙길. top이면 다진 흙 표면 + 밝은 림, 아니면 어두운 속."""
    rng = _rng(x, y, 1)
    d.rectangle([ox, oy, ox + TILE - 1, oy + TILE - 1], fill=EARTH[1])
    _speckle(d, ox, oy, rng, EARTH[0], 6)
    _speckle(d, ox, oy, rng, EARTH[2], 5)
    if top:
        d.rectangle([ox, oy, ox + TILE - 1, oy + 3], fill=EARTH[3])
        d.line([(ox, oy + 1), (ox + TILE - 1, oy + 1)], fill=EARTH[4])
        for _ in range(2):
            sx = ox + rng.randrange(2, TILE - 4)
            d.rectangle([sx, oy + 2, sx + 2, oy + 3], fill=EARTH[2])
        d.line([(ox, oy), (ox + TILE - 1, oy)], fill=OUTLINE)
    if left:
        d.line([(ox, oy), (ox, oy + TILE - 1)], fill=OUTLINE)
        d.line([(ox + 1, oy + 1), (ox + 1, oy + TILE - 1)], fill=EARTH[2])
    if right:
        d.line([(ox + TILE - 1, oy), (ox + TILE - 1, oy + TILE - 1)], fill=OUTLINE)


def draw_stone(d: ImageDraw.ImageDraw, ox: int, oy: int, x: int, y: int,
               top: bool, left: bool, right: bool) -> None:
    """석축. 어긋난 큰 돌 블록 줄눈."""
    rng = _rng(x, y, 2)
    d.rectangle([ox, oy, ox + TILE - 1, oy + TILE - 1], fill=STONE[1])
    d.line([(ox, oy + 7), (ox + TILE - 1, oy + 7)], fill=STONE[0])
    off = rng.choice([3, 5])
    d.line([(ox + off + 4, oy), (ox + off + 4, oy + 7)], fill=STONE[0])
    d.line([(ox + off, oy + 8), (ox + off, oy + TILE - 1)], fill=STONE[0])
    d.line([(ox + off + 9, oy + 8), (ox + off + 9, oy + TILE - 1)], fill=STONE[0])
    d.line([(ox, oy + 8), (ox + TILE - 1, oy + 8)], fill=STONE[2])
    _speckle(d, ox, oy, rng, STONE[2], 4)
    if top:
        d.rectangle([ox, oy, ox + TILE - 1, oy + 2], fill=STONE[3])
        d.line([(ox, oy + 1), (ox + TILE - 1, oy + 1)], fill=STONE[4])
        d.line([(ox, oy), (ox + TILE - 1, oy)], fill=OUTLINE)
    if left:
        d.line([(ox, oy), (ox, oy + TILE - 1)], fill=OUTLINE)
        d.line([(ox + 1, oy + 1), (ox + 1, oy + TILE - 1)], fill=STONE[2])
    if right:
        d.line([(ox + TILE - 1, oy), (ox + TILE - 1, oy + TILE - 1)], fill=OUTLINE)


def draw_plank(d: ImageDraw.ImageDraw, ox: int, oy: int, x: int, y: int,
               top: bool, left: bool, right: bool) -> None:
    """판벽. 세로 판자와 나뭇결."""
    rng = _rng(x, y, 3)
    d.rectangle([ox, oy, ox + TILE - 1, oy + TILE - 1], fill=PLANK[1])
    for bx in (4, 9, 13):
        d.line([(ox + bx, oy), (ox + bx, oy + TILE - 1)], fill=PLANK[0])
        d.line([(ox + bx + 1, oy), (ox + bx + 1, oy + TILE - 1)], fill=PLANK[2])
    _speckle(d, ox, oy, rng, PLANK[0], 4)
    d.line([(ox, oy + 12), (ox + TILE - 1, oy + 12)], fill=PLANK[3])
    d.line([(ox, oy + 13), (ox + TILE - 1, oy + 13)], fill=PLANK[0])
    if top:
        d.rectangle([ox, oy, ox + TILE - 1, oy + 2], fill=PLANK[3])
        d.line([(ox, oy + 1), (ox + TILE - 1, oy + 1)], fill=PLANK[4])
        d.line([(ox, oy), (ox + TILE - 1, oy)], fill=OUTLINE)
    if left:
        d.line([(ox, oy), (ox, oy + TILE - 1)], fill=OUTLINE)
        d.line([(ox + 1, oy + 1), (ox + 1, oy + TILE - 1)], fill=PLANK[2])
    if right:
        d.line([(ox + TILE - 1, oy), (ox + TILE - 1, oy + TILE - 1)], fill=OUTLINE)


def draw_giwa_fill(d: ImageDraw.ImageDraw, ox: int, oy: int, x: int, y: int,
                   left: bool, right: bool) -> None:
    """기와 아래 속 (지붕 밑 구조, 어두운 목재)."""
    rng = _rng(x, y, 4)
    d.rectangle([ox, oy, ox + TILE - 1, oy + TILE - 1], fill=PLANK[0])
    d.line([(ox, oy + 5), (ox + TILE - 1, oy + 5)], fill=(26, 21, 17))
    d.line([(ox, oy + 11), (ox + TILE - 1, oy + 11)], fill=(26, 21, 17))
    _speckle(d, ox, oy, rng, PLANK[1], 5)
    if left:
        d.line([(ox, oy), (ox, oy + TILE - 1)], fill=OUTLINE)
    if right:
        d.line([(ox + TILE - 1, oy), (ox + TILE - 1, oy + TILE - 1)], fill=OUTLINE)


def draw_giwa_ridge(d: ImageDraw.ImageDraw, ox: int, oy: int, x: int, y: int,
                    left: bool, right: bool) -> None:
    """기와 마루 (평평한 지붕 정상. 걷는 면)."""
    draw_giwa_fill(d, ox, oy, x, y, False, False)
    d.rectangle([ox, oy, ox + TILE - 1, oy + 5], fill=GIWA[1])
    d.rectangle([ox, oy, ox + TILE - 1, oy + 1], fill=GIWA[3])
    d.line([(ox, oy + 1), (ox + TILE - 1, oy + 1)], fill=GIWA[4])
    for gx in (3, 8, 13):
        d.line([(ox + gx, oy + 2), (ox + gx, oy + 5)], fill=GIWA[0])
        d.line([(ox + gx + 1, oy + 2), (ox + gx + 1, oy + 5)], fill=GIWA[2])
    d.line([(ox, oy + 5), (ox + TILE - 1, oy + 5)], fill=OUTLINE)
    d.line([(ox, oy), (ox + TILE - 1, oy)], fill=OUTLINE)
    if left:
        d.line([(ox, oy), (ox, oy + TILE - 1)], fill=OUTLINE)
    if right:
        d.line([(ox + TILE - 1, oy), (ox + TILE - 1, oy + TILE - 1)], fill=OUTLINE)


def draw_giwa_slope(d: ImageDraw.ImageDraw, ox: int, oy: int, x: int, y: int,
                    up_right: bool) -> None:
    """기와 45도 경사. up_right=True면 / (오른쪽으로 오름)."""
    for py in range(TILE):
        if up_right:
            edge = TILE - 1 - py
            x0, x1 = ox + edge, ox + TILE - 1
        else:
            x0, x1 = ox, ox + py
        if x1 < x0:
            continue
        d.line([(x0, oy + py), (x1, oy + py)], fill=GIWA[1])
        surf = x0 if up_right else x1
        d.point((surf, oy + py), fill=OUTLINE)
        inner = surf + 1 if up_right else surf - 1
        if ox <= inner <= ox + TILE - 1:
            d.point((inner, oy + py), fill=GIWA[3])
        inner2 = surf + 2 if up_right else surf - 2
        if ox <= inner2 <= ox + TILE - 1:
            d.point((inner2, oy + py), fill=GIWA[2])
    for k in (5, 10):
        for py in range(TILE):
            if up_right:
                px = TILE - 1 - py + k
            else:
                px = py - k
            if 0 <= px < TILE:
                cur = d._image.getpixel((ox + px, oy + py))
                if cur[3] == 255 and cur[:3] == GIWA[1]:
                    d.point((ox + px, oy + py), fill=GIWA[0])


def draw_deck(d: ImageDraw.ImageDraw, ox: int, oy: int, x: int, y: int,
              kind: str) -> None:
    """평상 (원웨이). 상판 5px + 다리. kind: left/mid/right/single."""
    rng = _rng(x, y, 5)
    d.rectangle([ox, oy + 1, ox + TILE - 1, oy + 5], fill=DECK[2])
    d.line([(ox, oy + 2), (ox + TILE - 1, oy + 2)], fill=DECK[4])
    d.line([(ox, oy + 1), (ox + TILE - 1, oy + 1)], fill=DECK[3])
    d.line([(ox, oy + 5), (ox + TILE - 1, oy + 5)], fill=DECK[0])
    for sx in (5, 11):
        d.line([(ox + sx, oy + 1), (ox + sx, oy + 4)], fill=DECK[1])
    _speckle(d, ox, oy, rng, DECK[1], 2, 2, 5)
    d.line([(ox, oy), (ox + TILE - 1, oy)], fill=OUTLINE)
    d.line([(ox, oy + 6), (ox + TILE - 1, oy + 6)], fill=OUTLINE)
    legs = []
    if kind in ("left", "single"):
        legs.append(2)
    if kind in ("right", "single"):
        legs.append(TILE - 4)
    if kind == "mid" and rng.random() < 0.5:
        legs.append(7)
    for lx in legs:
        d.rectangle([ox + lx, oy + 7, ox + lx + 1, oy + TILE - 1], fill=DECK[1])
        d.line([(ox + lx - 1, oy + 7), (ox + lx - 1, oy + TILE - 1)], fill=OUTLINE)
        d.line([(ox + lx + 2, oy + 7), (ox + lx + 2, oy + TILE - 1)], fill=OUTLINE)
    if kind in ("left", "single"):
        d.line([(ox, oy), (ox, oy + 6)], fill=OUTLINE)
    if kind in ("right", "single"):
        d.line([(ox + TILE - 1, oy), (ox + TILE - 1, oy + 6)], fill=OUTLINE)


def draw_eave(d: ImageDraw.ImageDraw, ox: int, oy: int, x: int, y: int,
              kind: str) -> None:
    """처마 (원웨이). 기와 한 줄 + 막새 끝. kind: left/mid/right/single."""
    d.rectangle([ox, oy + 1, ox + TILE - 1, oy + 4], fill=GIWA[2])
    d.line([(ox, oy + 1), (ox + TILE - 1, oy + 1)], fill=GIWA[4])
    d.line([(ox, oy + 2), (ox + TILE - 1, oy + 2)], fill=GIWA[3])
    for gx in (3, 8, 13):
        d.line([(ox + gx, oy + 1), (ox + gx, oy + 4)], fill=GIWA[0])
    for gx in (1, 6, 11):
        d.rectangle([ox + gx, oy + 5, ox + gx + 3, oy + 6], fill=GIWA[1])
        d.point((ox + gx + 1, oy + 5), fill=GIWA[3])
    d.line([(ox, oy), (ox + TILE - 1, oy)], fill=OUTLINE)
    d.line([(ox, oy + 4), (ox + TILE - 1, oy + 4)], fill=OUTLINE)
    if kind in ("left", "single"):
        d.line([(ox, oy), (ox, oy + 5)], fill=OUTLINE)
    if kind in ("right", "single"):
        d.line([(ox + TILE - 1, oy), (ox + TILE - 1, oy + 5)], fill=OUTLINE)


def build_atlas() -> Image.Image:
    img = Image.new("RGBA", (COLS * TILE, ROWS * TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def at(cx: int, cy: int) -> tuple:
        return cx * TILE, cy * TILE

    # 0행 흙길: top, top변형, topL, topR, fill, fill변형, 좌fill, 우fill
    for i, (top, left, right) in enumerate([
        (True, False, False), (True, False, False),
        (True, True, False), (True, False, True),
        (False, False, False), (False, False, False),
        (False, True, False), (False, False, True),
    ]):
        ox, oy = at(i, 0)
        draw_earth(d, ox, oy, i, 0, top, left, right)

    # 1행 석축: top, topL, topR, fill, fill변형, 좌fill, 우fill, 단독기둥
    for i, (top, left, right) in enumerate([
        (True, False, False), (True, True, False), (True, False, True),
        (False, False, False), (False, False, False),
        (False, True, False), (False, False, True), (True, True, True),
    ]):
        ox, oy = at(i, 1)
        draw_stone(d, ox, oy, i, 1, top, left, right)

    # 2행 판벽: 배치는 석축과 동일
    for i, (top, left, right) in enumerate([
        (True, False, False), (True, True, False), (True, False, True),
        (False, False, False), (False, False, False),
        (False, True, False), (False, False, True), (True, True, True),
    ]):
        ox, oy = at(i, 2)
        draw_plank(d, ox, oy, i, 2, top, left, right)

    # 3행 기와: 마루, 마루L, 마루R, 속, 속L, 속R, 경사/, 경사\
    draw_giwa_ridge(d, *at(0, 3), 0, 3, False, False)
    draw_giwa_ridge(d, *at(1, 3), 1, 3, True, False)
    draw_giwa_ridge(d, *at(2, 3), 2, 3, False, True)
    draw_giwa_fill(d, *at(3, 3), 3, 3, False, False)
    draw_giwa_fill(d, *at(4, 3), 4, 3, True, False)
    draw_giwa_fill(d, *at(5, 3), 5, 3, False, True)
    draw_giwa_slope(d, *at(6, 3), 6, 3, True)
    draw_giwa_slope(d, *at(7, 3), 7, 3, False)

    # 4행 평상 (원웨이)
    for i, kind in enumerate(["left", "mid", "right", "single"]):
        ox, oy = at(i, 4)
        draw_deck(d, ox, oy, i, 4, kind)

    # 5행 처마 (원웨이)
    for i, kind in enumerate(["left", "mid", "right", "single"]):
        ox, oy = at(i, 5)
        draw_eave(d, ox, oy, i, 5, kind)

    return img


def build_stall() -> Image.Image:
    """파괴 가능 좌판 (48x32). 차양 + 판 상판 + 다리, 검정 아웃라인."""
    w, h = 48, 32
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # 차양 (저채도 감청/저채도 홍 줄. 청사초롱 계열 절충, 고채도 금지)
    awn_a = (64, 70, 92)
    awn_b = (98, 66, 66)
    for i in range(6):
        x0 = i * 8
        d.rectangle([x0, 2, x0 + 7, 8], fill=awn_a if i % 2 == 0 else awn_b)
    d.rectangle([0, 2, w - 1, 3], fill=(120, 126, 148))
    for i in range(6):
        x0 = i * 8
        d.rectangle([x0 + 2, 9, x0 + 5, 10], fill=awn_a if i % 2 == 0 else awn_b)
    d.rectangle([0, 1, w - 1, 1], fill=OUTLINE)
    d.line([(0, 2), (0, 10)], fill=OUTLINE)
    d.line([(w - 1, 2), (w - 1, 10)], fill=OUTLINE)
    # 상판
    d.rectangle([2, 16, w - 3, 20], fill=PLANK[3])
    d.line([(2, 17), (w - 3, 17)], fill=PLANK[4])
    d.line([(2, 20), (w - 3, 20)], fill=PLANK[1])
    d.rectangle([2, 15, w - 3, 15], fill=OUTLINE)
    d.rectangle([2, 21, w - 3, 21], fill=OUTLINE)
    # 물건 (호박색 소품 + 단지)
    d.rectangle([8, 12, 13, 14], fill=(150, 110, 58))
    d.point((9, 12), fill=(190, 150, 84))
    d.rectangle([20, 11, 26, 14], fill=STONE[3])
    d.rectangle([21, 10, 25, 10], fill=STONE[2])
    d.rectangle([33, 12, 38, 14], fill=(98, 66, 66))
    # 다리
    for lx in (4, w - 8):
        d.rectangle([lx, 22, lx + 2, h - 1], fill=PLANK[2])
        d.line([(lx - 1, 22), (lx - 1, h - 1)], fill=OUTLINE)
        d.line([(lx + 3, 22), (lx + 3, h - 1)], fill=OUTLINE)
    d.rectangle([4, 26, w - 6, 27], fill=PLANK[1])
    return img


def main() -> None:
    OUT_ATLAS.parent.mkdir(parents=True, exist_ok=True)
    build_atlas().save(OUT_ATLAS)
    build_stall().save(OUT_STALL)
    print(f"wrote {OUT_ATLAS}")
    print(f"wrote {OUT_STALL}")


if __name__ == "__main__":
    main()
