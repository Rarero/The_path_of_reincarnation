"""PixelLab 소스에서 1막 지형 아틀라스를 조립한다 (요청서 021).

입력 (2026-08-05 PixelLab 분류 정리로 경로 개정):
- art_src/generated/pixellab/grids/act1_tileset_{earth,stone,plank,giwa}_16.png
  : PixelLab 사이드스크롤러 타일셋 (64x64, 4x4). 각 시트에서 fill 셀 (2,1)과
  top 셀 (2,0)을 뽑아 재질 텍스처로 쓴다
- art_src/generated/pixellab/objects/act1_obj_pyeongsang_48.png (평상),
  act1_obj_eave_48.png (처마), act1_obj_stall_48.png (좌판) : PixelLab 오브젝트 (48x48)

출력:
- assets/sprites/tiles/tileset_act1.png : 8x6 아틀라스 (room_terrain.gd 배치)
- assets/sprites/tiles/stall_cover.png : 좌판 스프라이트

원리:
- PixelLab의 재질 질감(흙, 돌, 판자, 기와)을 살리되, 방 오토타일이 요구하는
  8열 배치(표면/속/코너/좌우 가장자리)는 fill/top 두 타일 + 검정 아웃라인 덧대기로
  프로그램 조립한다. 아웃라인은 ART_STYLE 5장(플레이 레이어 분리 신호)을 유지한다
- 배경 야간 톤과의 명도 위계를 위해 채도를 낮춘다 (배경보다 밝고 채도 낮은 맵)

사용: python tools/pipeline/assemble_tileset_act1.py
"""

from __future__ import annotations

import colorsys
import pathlib

from PIL import Image, ImageDraw

TILE = 16
ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "art_src" / "generated" / "pixellab"
SRC_GRIDS = SRC / "grids"
SRC_OBJECTS = SRC / "objects"
OUT_ATLAS = ROOT / "assets" / "sprites" / "tiles" / "tileset_act1.png"
OUT_STALL = ROOT / "assets" / "sprites" / "tiles" / "stall_cover.png"

OUTLINE = (13, 12, 14, 255)
FILL_CELL = (2, 1)  # PixelLab 시트에서 사방 막힌 속
TOP_CELL = (2, 0)  # PixelLab 시트에서 위 열린 표면

## 재질별 톤 (채도 배율, 명도 배율, 그림자 상향).
## 배경 조각은 bake_bg_act1.py가 아웃라인을 걷고 침전시키므로 맵은 반대로 들어 올린다.
## 침전 후 배경 평균이 대략 (50, 45, 70)이라 플레이 표면은 그보다 확실히 밝아야 한다.
## 흙길은 원본이 붉어 채도를 크게 낮추지 않으면 살구색으로 뜬다
TONE_EARTH = (0.55, 1.02, 0.10)
TONE_STONE = (0.72, 1.06, 0.15)
TONE_PLANK = (0.62, 1.08, 0.17)
TONE_GIWA = (0.68, 1.08, 0.19)
TONE_BENCH = (0.72, 1.02, 0.11)
TONE_EAVE = (0.72, 1.02, 0.13)
## 파괴 가능 좌판은 상호작용 대상이라 채도를 가장 높게 두고 살짝만 올린다
TONE_STALL = (0.92, 1.05, 0.05)
## 아틀라스 행 수 (0~5 지형, 6 장식)
ATLAS_ROWS = 7


def desaturate(
    img: Image.Image, factor: float, darken: float = 1.0, shadow: float = 0.0
) -> Image.Image:
    """채도를 factor배로 낮추고 명도를 darken배 한 뒤 그림자를 shadow만큼 들어 올린다.

    단순 곱셈만으로는 원래 어두운 재질(기와, 판벽)이 배경 침전값 위로 올라오지 않는다.
    바닥을 함께 올려야 플레이 레이어가 배경보다 밝다는 위계가 성립한다.
    """
    out = img.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            s *= factor
            v = min(1.0, v * darken + shadow)
            nr, ng, nb = colorsys.hsv_to_rgb(h, s, v)
            px[x, y] = (int(nr * 255), int(ng * 255), int(nb * 255), a)
    return out


def cell(sheet: Image.Image, cx: int, cy: int) -> Image.Image:
    return sheet.crop((cx * TILE, cy * TILE, cx * TILE + TILE, cy * TILE + TILE))


def add_outline(tile: Image.Image, left: bool, right: bool, top: bool = False) -> Image.Image:
    """지정한 변에 검정 아웃라인 1px을 덧댄다."""
    out = tile.copy()
    px = out.load()
    for y in range(TILE):
        if left:
            px[0, y] = OUTLINE
        if right:
            px[TILE - 1, y] = OUTLINE
    if top:
        for x in range(TILE):
            px[x, 0] = OUTLINE
    return out


def make_top(fill: Image.Image) -> Image.Image:
    """fill에서 표면(걷는 면) 타일을 만든다. 상단 3px를 밝게 올리고 검정 아웃라인.

    PixelLab 시트의 top 셀은 재질마다 세로기둥/가로표면이 섞여 일관되지 않아,
    fill 질감에 밝은 지표선을 직접 얹는 편이 안정적이다 (ART_STYLE 검정 아웃라인 유지).
    """
    out = fill.copy()
    px = out.load()
    for x in range(TILE):
        # 상단 3px 명도 상승 (지표 하이라이트)
        for y, boost in ((1, 1.55), (2, 1.3), (3, 1.12)):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (min(255, int(r * boost)), min(255, int(g * boost)),
                            min(255, int(b * boost)), a)
        px[x, 0] = OUTLINE
    return out


def load_material(name: str, tone: tuple) -> tuple[Image.Image, Image.Image]:
    sheet = desaturate(
        Image.open(SRC_GRIDS / f"act1_tileset_{name}_16.png").convert("RGBA"), *tone
    )
    fill = cell(sheet, *FILL_CELL)
    return make_top(fill), fill


def make_slope(fill: Image.Image, top: Image.Image, up_right: bool) -> Image.Image:
    """기와 45도 경사. fill을 삼각 마스크하고 사면에 마루색 + 아웃라인."""
    out = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    fpx = fill.load()
    tpx = top.load()
    # 마루 표면색 (top 타일 상단 평균)
    sr = sg = sb = n = 0
    for x in range(TILE):
        r, g, b, a = tpx[x, 1]
        if a:
            sr += r
            sg += g
            sb += b
            n += 1
    surf = (sr // max(n, 1), sg // max(n, 1), sb // max(n, 1), 255)
    opx = out.load()
    for py in range(TILE):
        edge = (TILE - 1 - py) if up_right else py
        for x in range(TILE):
            filled = (x >= edge) if up_right else (x <= edge)
            if filled:
                opx[x, py] = fpx[x, py]
    # 사면 라인에 아웃라인 + 마루 하이라이트
    for py in range(TILE):
        edge = (TILE - 1 - py) if up_right else py
        if 0 <= edge < TILE:
            opx[edge, py] = OUTLINE
            inner = edge + 1 if up_right else edge - 1
            if 0 <= inner < TILE and opx[inner, py][3]:
                opx[inner, py] = surf
    return out


def strip_tile(band: Image.Image, x_off: int, leg_left: bool, leg_right: bool,
               leg_src: Image.Image, leg_x: int) -> Image.Image:
    """오브젝트 상판 밴드에서 16px 원웨이 타일을 만든다. 상판을 타일 상단에 얹는다."""
    out = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    # 상판 6px
    top = band.crop((x_off, 0, x_off + TILE, 7))
    out.alpha_composite(top, (0, 0))
    opx = out.load()
    # 상판 상/하단 아웃라인 보강
    for x in range(TILE):
        if opx[x, 0][3]:
            pass
    # 다리 (leg_src에서 세로 스트립 복제)
    if leg_left or leg_right:
        leg = leg_src.crop((leg_x, 0, leg_x + 3, leg_src.height))
        if leg_left:
            out.alpha_composite(leg.crop((0, 6, 3, TILE)), (2, 6))
        if leg_right:
            out.alpha_composite(leg.crop((0, 6, 3, TILE)), (TILE - 5, 6))
    return out


def build_strip_row(obj: Image.Image, band_top: int, band_h: int) -> list[Image.Image]:
    """평상/처마 오브젝트에서 좌/중/우/단독 4타일을 만든다."""
    bbox = obj.getbbox()
    content = obj.crop((bbox[0], band_top, bbox[2], band_top + band_h))
    # 폭을 48로 리샘플해 16px 3구간으로 자른다
    content = content.resize((48, band_h), Image.NEAREST)
    band = Image.new("RGBA", (48, TILE), (0, 0, 0, 0))
    band.alpha_composite(content, (0, 0))
    # 다리 소스: 오브젝트 하단
    leg_src = obj.crop((bbox[0], band_top + band_h, bbox[2], obj.height)).resize(
        (48, max(1, obj.height - band_top - band_h)), Image.NEAREST
    )
    left = strip_tile(band, 0, True, False, leg_src, 4)
    mid = strip_tile(band, 16, False, False, leg_src, 20)
    right = strip_tile(band, 32, False, True, leg_src, 40)
    single = strip_tile(band, 16, True, True, leg_src, 20)
    # 끝단 아웃라인
    left = add_outline(left, True, False)
    right = add_outline(right, False, True)
    single = add_outline(single, True, True)
    return [left, mid, right, single]


def paste(atlas: Image.Image, tile: Image.Image, cx: int, cy: int) -> None:
    atlas.alpha_composite(tile, (cx * TILE, cy * TILE))


def _avg(img: Image.Image, y0: int, y1: int) -> tuple:
    """타일 세로 구간의 평균색. 장식이 재질 팔레트를 따라가게 한다."""
    px = img.load()
    acc = [0, 0, 0]
    n = 0
    for y in range(y0, y1):
        for x in range(TILE):
            r, g, b, a = px[x, y]
            if a:
                acc[0] += r
                acc[1] += g
                acc[2] += b
                n += 1
    if n == 0:
        return (120, 96, 72, 255)
    return tuple(v // n for v in acc) + (255,)


def _shade(color: tuple, factor: float) -> tuple:
    return tuple(min(255, int(c * factor)) for c in color[:3]) + (255,)


def build_decor_row(p_fill: Image.Image, p_top: Image.Image,
                    s_top: Image.Image) -> list[Image.Image]:
    """장식 기둥과 서까래 (docs/ROOM_SPEC.md 5장 장식 심볼).

    공중에 뜬 평상, 처마, 지붕에 지지 구조를 붙여 당위성을 만든다.
    콜리전이 없어 통행과 도달 가능성에 영향을 주지 않는다.
    """
    # 기둥은 지형 판벽보다 한 단 밝게 뽑는다. 실루엣이 가늘어 어두우면 배경에 묻힌다
    wood = _shade(_avg(p_fill, 4, 12), 1.30)
    wood_lit = _shade(_avg(p_top, 0, 4), 1.35)
    wood_dark = _shade(wood, 0.62)
    stone = _avg(s_top, 0, 4)
    stone_dark = _shade(stone, 0.66)
    tiles = []

    def new_tile() -> tuple:
        img = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
        return img, ImageDraw.Draw(img)

    def shaft(d: ImageDraw.ImageDraw, y0: int, y1: int) -> None:
        d.rectangle([6, y0, 9, y1], fill=wood)
        d.line([(6, y0), (6, y1)], fill=wood_lit)
        d.line([(9, y0), (9, y1)], fill=wood_dark)
        d.line([(5, y0), (5, y1)], fill=OUTLINE)
        d.line([(10, y0), (10, y1)], fill=OUTLINE)

    # 0 기둥 상단: 까치발이 발판을 받친다
    img, d = new_tile()
    shaft(d, 0, TILE - 1)
    d.rectangle([3, 0, 12, 1], fill=wood_lit)
    d.line([(3, 0), (12, 0)], fill=OUTLINE)
    for k in range(4):
        d.point((4 - k, 2 + k), fill=wood)
        d.point((4 - k, 3 + k), fill=wood_dark)
        d.point((11 + k, 2 + k), fill=wood)
        d.point((11 + k, 3 + k), fill=wood_dark)
    tiles.append(img)

    # 1 기둥 몸통
    img, d = new_tile()
    shaft(d, 0, TILE - 1)
    d.line([(7, 5), (8, 5)], fill=wood_dark)
    d.line([(7, 11), (8, 11)], fill=wood_dark)
    tiles.append(img)

    # 2 기둥 밑동: 주춧돌 위에 선다
    img, d = new_tile()
    shaft(d, 0, 10)
    d.rectangle([3, 11, 12, TILE - 1], fill=stone)
    d.line([(3, 11), (12, 11)], fill=_shade(stone, 1.25))
    d.line([(3, TILE - 1), (12, TILE - 1)], fill=stone_dark)
    d.line([(2, 11), (2, TILE - 1)], fill=OUTLINE)
    d.line([(13, 11), (13, TILE - 1)], fill=OUTLINE)
    d.line([(3, 10), (12, 10)], fill=OUTLINE)
    tiles.append(img)

    # 3 서까래: 지붕과 처마 밑에 드러난 구조재
    img, d = new_tile()
    for gx in (1, 6, 11):
        d.rectangle([gx, 0, gx + 2, 5], fill=wood)
        d.line([(gx, 0), (gx + 2, 0)], fill=wood_lit)
        d.line([(gx - 1, 0), (gx - 1, 5)], fill=OUTLINE)
        d.line([(gx + 3, 0), (gx + 3, 5)], fill=OUTLINE)
        d.line([(gx, 6), (gx + 2, 6)], fill=OUTLINE)
    tiles.append(img)
    return tiles


def build() -> None:
    atlas = Image.new("RGBA", (8 * TILE, ATLAS_ROWS * TILE), (0, 0, 0, 0))

    # 재질 로드 (채도 하향 + 명도 상향).
    # 배경 조각은 bake_bg_act1.py가 아웃라인을 걷고 침전시키므로, 맵은 반대로 들어 올린다.
    # 두 방향을 함께 걸어야 "밝고 아웃라인 있는 것이 만질 수 있는 것"이라는 규칙이 읽힌다
    e_top, e_fill = load_material("earth", TONE_EARTH)
    s_top, s_fill = load_material("stone", TONE_STONE)
    p_top, p_fill = load_material("plank", TONE_PLANK)
    g_top, g_fill = load_material("giwa", TONE_GIWA)

    # 0행 흙길: top,top, topL, topR, fill,fill, 좌fill, 우fill
    paste(atlas, e_top, 0, 0)
    paste(atlas, e_top, 1, 0)
    paste(atlas, add_outline(e_top, True, False), 2, 0)
    paste(atlas, add_outline(e_top, False, True), 3, 0)
    paste(atlas, e_fill, 4, 0)
    paste(atlas, e_fill, 5, 0)
    paste(atlas, add_outline(e_fill, True, False), 6, 0)
    paste(atlas, add_outline(e_fill, False, True), 7, 0)

    # 1행 석축 / 2행 판벽: top, topL, topR, fill, fill, 좌fill, 우fill, 단독기둥
    for row, (mt, mf) in ((1, (s_top, s_fill)), (2, (p_top, p_fill))):
        paste(atlas, mt, 0, row)
        paste(atlas, add_outline(mt, True, False), 1, row)
        paste(atlas, add_outline(mt, False, True), 2, row)
        paste(atlas, mf, 3, row)
        paste(atlas, mf, 4, row)
        paste(atlas, add_outline(mf, True, False), 5, row)
        paste(atlas, add_outline(mf, False, True), 6, row)
        paste(atlas, add_outline(mt, True, True), 7, row)

    # 3행 기와: 마루, 마루L, 마루R, 속, 속L, 속R, 경사/, 경사\
    paste(atlas, g_top, 0, 3)
    paste(atlas, add_outline(g_top, True, False), 1, 3)
    paste(atlas, add_outline(g_top, False, True), 2, 3)
    paste(atlas, g_fill, 3, 3)
    paste(atlas, add_outline(g_fill, True, False), 4, 3)
    paste(atlas, add_outline(g_fill, False, True), 5, 3)
    paste(atlas, make_slope(g_fill, g_top, True), 6, 3)
    paste(atlas, make_slope(g_fill, g_top, False), 7, 3)

    # 4행 평상, 5행 처마
    bench = desaturate(
        Image.open(SRC_OBJECTS / "act1_obj_pyeongsang_48.png").convert("RGBA"), *TONE_BENCH
    )
    eave = desaturate(
        Image.open(SRC_OBJECTS / "act1_obj_eave_48.png").convert("RGBA"), *TONE_EAVE
    )
    for i, t in enumerate(build_strip_row(bench, 15, 6)):
        paste(atlas, t, i, 4)
    for i, t in enumerate(build_strip_row(eave, 7, 6)):
        paste(atlas, t, i, 5)

    # 6행 장식 (콜리전 없음): 기둥 상단, 기둥 몸통, 기둥 밑동, 서까래
    for i, t in enumerate(build_decor_row(p_fill, p_top, s_top)):
        paste(atlas, t, i, 6)

    atlas.save(OUT_ATLAS)
    print(f"wrote {OUT_ATLAS}")

    # 좌판: act1_obj_stall_48 (홍백 차양) 채도 하향
    stall = desaturate(
        Image.open(SRC_OBJECTS / "act1_obj_stall_48.png").convert("RGBA"), *TONE_STALL
    )
    stall.save(OUT_STALL)
    print(f"wrote {OUT_STALL} {stall.size}")


if __name__ == "__main__":
    build()
