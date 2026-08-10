#!/usr/bin/env python3
"""노름판 이벤트 화면 프리비즈.

Godot 없이 scenes/minigame/gamble_minigame.gd의 배치 상수를 그대로 재현해
480x270 화면을 그려 본다. 판정은 재현하지 않고 배치와 겹침만 본다.
상수를 바꾸면 이 파일의 값도 함께 맞춘다.

사용법: python tools/pipeline/previz_gamble.py
산출: art_src/previz/gamble_previz.png (장면 6개 세로 배치, 2배 확대)
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "art_src/previz/gamble_previz.png"

W, H = 480, 270
BACKDROP = (13, 13, 23, 255)
INK = (230, 222, 204, 255)
INK_DIM = (153, 148, 138, 255)
LANTERN = (235, 168, 71, 255)
NIGHT = (66, 74, 122, 255)
NIGHT_DIM = (117, 117, 125, 255)
PAPER = (219, 207, 173, 255)
PAPER_EDGE = (51, 46, 41, 255)

CENTER_X = 240
FLOOR_LINE = 118
MAT_TOP_Y = 148
MAT_BOTTOM_Y = 214
MAT_TOP_HALF = 104
MAT_BOTTOM_HALF = 148
CLUTTER_SCALE = 2
CLUTTER_POS = [(-8, 96), (392, 96)]
SEATED_SCALE = 1
SEATED_WAIST_Y = 152
ART_CENTER = (40, 57)
CROWD_FAR_Y = 120
CROWD_NEAR_Y = 272
DEALER_ROW_Y = 164
PLAYER_ROW_Y = 198
POT_POS = (132, 192)
DECK_POS = (406, 156)
WALL = (23, 23, 36, 255)
FLOOR = (33, 31, 41, 255)
STRAW = (102, 87, 61, 255)
STRAW_DIM = (79, 66, 46, 255)
STRAW_EDGE = (51, 43, 31, 255)

CARD_SIZE = (18, 28)
CARD_GAP = 24
TILE_SIZE = (30, 16)
TILE_GAP = 38
DIE_SIZE = 16
DIE_GAP = 26
PIP_RADIUS = 1.6

CROWD_FAR = ["crowd_b", "crowd_d", "crowd_g", "crowd_cat"]
CROWD_NEAR = ["crowd_back_b", "crowd_back_d"]
FAR_X = [116, 160, 320, 364]


def load_png(rel: str) -> Image.Image:
    return Image.open(ROOT / rel).convert("RGBA")


def frame(sheet: str, index: int) -> Image.Image:
    im = load_png(sheet)
    return im.crop((76 * index, 0, 76 * (index + 1), 76))


def font(size: int = 9) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(ROOT / "assets/fonts/galmuri9.ttf"), size)


def center_text(draw: ImageDraw.ImageDraw, text: str, y: int, size: int, color) -> None:
    fnt = font(size)
    width = draw.textlength(text, font=fnt)
    draw.text((W / 2 - width / 2, y - size), text, font=fnt, fill=color)


def text_at(draw: ImageDraw.ImageDraw, text: str, center, size: int, color) -> None:
    fnt = font(size)
    width = draw.textlength(text, font=fnt)
    draw.text((center[0] - width / 2, center[1] - size * 0.64), text, font=fnt, fill=color)


def circle(draw: ImageDraw.ImageDraw, center, radius: float, fill=None, outline=None) -> None:
    box = [center[0] - radius, center[1] - radius, center[0] + radius, center[1] + radius]
    draw.ellipse(box, fill=fill, outline=outline)


def coin(draw: ImageDraw.ImageDraw, center, color) -> None:
    circle(draw, center, 4, fill=color, outline=PAPER_EDGE)
    draw.rectangle(
        [center[0] - 1, center[1] - 1, center[0], center[1]], fill=PAPER_EDGE
    )


def pip_offsets(count: int):
    value = max(1, min(6, count))
    spots = []
    if value % 2 == 1:
        spots.append((0, 0))
    if value >= 2:
        spots += [(-1, -1), (1, 1)]
    if value >= 4:
        spots += [(1, -1), (-1, 1)]
    if value >= 6:
        spots += [(-1, 0), (1, 0)]
    return spots


def pips(draw: ImageDraw.ImageDraw, center, count: int, spread: float) -> None:
    for dx, dy in pip_offsets(count):
        circle(draw, (center[0] + dx * spread, center[1] + dy * spread), PIP_RADIUS,
               fill=PAPER_EDGE)


def card(draw: ImageDraw.ImageDraw, center, number: int, face_up: bool, ttaeng=False) -> None:
    half = (CARD_SIZE[0] / 2, CARD_SIZE[1] / 2)
    box = [center[0] - half[0], center[1] - half[1], center[0] + half[0], center[1] + half[1]]
    if not face_up:
        draw.rectangle(box, fill=NIGHT, outline=PAPER_EDGE)
        draw.rectangle([box[0] + 3, box[1] + 3, box[2] - 3, box[3] - 3], fill=NIGHT_DIM)
        draw.rectangle([center[0] - 3, center[1] - 3, center[0] + 3, center[1] + 3], fill=LANTERN)
        return
    draw.rectangle(box, fill=PAPER, outline=PAPER_EDGE)
    draw.rectangle([center[0] - 6, center[1] - 11, center[0] + 6, center[1] - 10], fill=PAPER_EDGE)
    draw.rectangle([center[0] - 6, center[1] + 10, center[0] + 6, center[1] + 11], fill=PAPER_EDGE)
    text_at(draw, str(number), center, 18, LANTERN if ttaeng else PAPER_EDGE)


def tile(draw: ImageDraw.ImageDraw, center, value, face_up: bool) -> None:
    half = (TILE_SIZE[0] / 2, TILE_SIZE[1] / 2)
    box = [center[0] - half[0], center[1] - half[1], center[0] + half[0], center[1] + half[1]]
    if not face_up:
        draw.rectangle(box, fill=NIGHT, outline=PAPER_EDGE)
        draw.rectangle([box[0] + 3, box[1] + 3, box[2] - 3, box[3] - 3], fill=NIGHT_DIM)
        return
    draw.rectangle(box, fill=PAPER, outline=PAPER_EDGE)
    draw.rectangle(
        [center[0], center[1] - half[1] + 2, center[0], center[1] + half[1] - 2], fill=PAPER_EDGE
    )
    pips(draw, (center[0] - TILE_SIZE[0] * 0.25, center[1]), value[0], 4)
    pips(draw, (center[0] + TILE_SIZE[0] * 0.25, center[1]), value[1], 4)


def die(canvas: Image.Image, center, face: int, angle: float) -> None:
    plate = Image.new("RGBA", (DIE_SIZE + 8, DIE_SIZE + 8), (0, 0, 0, 0))
    pen = ImageDraw.Draw(plate)
    mid = (DIE_SIZE + 8) / 2
    half = DIE_SIZE / 2
    pen.rectangle([mid - half, mid - half, mid + half, mid + half], fill=PAPER, outline=PAPER_EDGE)
    pips(pen, (mid, mid), face, 5)
    if angle:
        plate = plate.rotate(math.degrees(angle), resample=Image.NEAREST)
    canvas.alpha_composite(plate, (int(center[0] - mid), int(center[1] - mid)))


def pot(draw: ImageDraw.ImageDraw, amount: int) -> None:
    count = max(1, min(12, math.ceil(amount / 10)))
    for i in range(count):
        coin(draw, (POT_POS[0], POT_POS[1] - i * 2), LANTERN)


def dealer_art(canvas: Image.Image, pose: str = "idle") -> None:
    """앉은 노름꾼. 좌우를 뒤집지 않고 조형 아래끝을 허리선에 맞춘다."""
    art = load_png("assets/sprites/enemies/gambler_%s.png" % pose)
    if SEATED_SCALE != 1:
        art = art.resize((art.width * SEATED_SCALE, art.height * SEATED_SCALE), Image.NEAREST)
    x = CENTER_X - art.width // 2
    y = SEATED_WAIST_Y - art.height
    canvas.alpha_composite(art, (int(x), int(y)))


def crowd(canvas: Image.Image, feet_y: int) -> None:
    if feet_y == CROWD_FAR_Y:
        plan = [(CROWD_FAR[i], FAR_X[i]) for i in range(len(FAR_X))]
    else:
        plan = [(CROWD_NEAR[0], 34), (CROWD_NEAR[1], 446)]
    for name, x in plan:
        art = load_png("assets/sprites/bg/act1/crowd/%s.png" % name)
        canvas.alpha_composite(art, (int(x - art.width / 2), int(feet_y - art.height)))


def mat_corners():
    return [
        (CENTER_X - MAT_TOP_HALF, MAT_TOP_Y),
        (CENTER_X + MAT_TOP_HALF, MAT_TOP_Y),
        (CENTER_X + MAT_BOTTOM_HALF, MAT_BOTTOM_Y),
        (CENTER_X - MAT_BOTTOM_HALF, MAT_BOTTOM_Y),
    ]


def base_scene(pose="idle"):
    canvas = Image.new("RGBA", (W, H), BACKDROP)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle([0, 0, W - 1, FLOOR_LINE - 1], fill=WALL)
    draw.rectangle([0, FLOOR_LINE, W - 1, H - 1], fill=FLOOR)
    draw.line([0, FLOOR_LINE, W - 1, FLOOR_LINE], fill=NIGHT)
    band = load_png("assets/sprites/bg/act1/bg_lantern_band.png")
    canvas.alpha_composite(band, (-16, 30))
    clutter = load_png("assets/sprites/bg/act1/bg_gambling_mat.png")
    clutter = clutter.resize(
        (clutter.width * CLUTTER_SCALE, clutter.height * CLUTTER_SCALE), Image.NEAREST
    )
    for at in CLUTTER_POS:
        canvas.alpha_composite(clutter, (int(at[0]), int(at[1])))
    crowd(canvas, CROWD_FAR_Y)
    dealer_art(canvas, pose)
    draw = ImageDraw.Draw(canvas)
    corners = mat_corners()
    draw.polygon(corners, fill=STRAW, outline=STRAW_EDGE)
    for i in range(1, 7):
        t = i / 7
        y = MAT_TOP_Y + (MAT_BOTTOM_Y - MAT_TOP_Y) * t
        half = MAT_TOP_HALF + (MAT_BOTTOM_HALF - MAT_TOP_HALF) * t - 4
        draw.line([CENTER_X - half, y, CENTER_X + half, y], fill=STRAW_DIM)
        x = CENTER_X - half + (0 if i % 2 == 0 else 7)
        while x < CENTER_X + half:
            draw.rectangle([x, y - 4, x, y - 1], fill=STRAW_DIM)
            x += 14
    return canvas


def finish(canvas: Image.Image) -> ImageDraw.ImageDraw:
    crowd(canvas, CROWD_NEAR_Y)
    return ImageDraw.Draw(canvas)


def header(draw: ImageDraw.ImageDraw, name: str, hint: str, coins: int, done: int) -> None:
    draw.rectangle([0, 0, W - 1, 33], fill=(13, 13, 23, 210))
    center_text(draw, name, 16, 18, LANTERN)
    center_text(draw, hint, 30, 9, INK_DIM)
    text_at(draw, "엽전 %d닢" % coins, (52, 12), 9, INK)
    text_at(draw, "%d/3판" % done, (428, 12), 9, INK)


def scene_offer() -> Image.Image:
    canvas = base_scene("idle2")
    draw = finish(canvas)
    header(draw, "투전", "두 장 합의 끝자리로 겨룬다. 같은 숫자면 땡이다", 180, 0)
    center_text(draw, "> 한 판 붙는다", 230, 9, LANTERN)
    center_text(draw, "  그냥 지나간다", 246, 9, INK_DIM)
    center_text(draw, "위아래로 고르고 점프로 결정", 264, 9, INK_DIM)
    return canvas


def scene_bet() -> Image.Image:
    canvas = base_scene()
    draw = finish(canvas)
    pot(draw, 60)
    header(draw, "투전", "두 장 합의 끝자리로 겨룬다. 같은 숫자면 땡이다", 180, 0)
    center_text(draw, "60닢", 250, 18, LANTERN)
    center_text(draw, "좌우로 조절, 점프로 건다, 아래로 자리를 뜬다", 265, 9, INK_DIM)
    return canvas


def scene_tujeon() -> Image.Image:
    canvas = base_scene()
    draw = finish(canvas)
    pot(draw, 60)
    header(draw, "투전", "두 장 합의 끝자리로 겨룬다. 같은 숫자면 땡이다", 180, 0)
    for i, number in enumerate((3, 6)):
        card(draw, (CENTER_X + (i - 0.5) * CARD_GAP, DEALER_ROW_Y), number, True)
    card(draw, (CENTER_X - 0.5 * CARD_GAP, PLAYER_ROW_Y), 8, True)
    card(draw, (CENTER_X + 0.5 * CARD_GAP, PLAYER_ROW_Y), 0, False)
    center_text(draw, "패를 뒤집는다", 246, 9, INK_DIM)
    return canvas


def scene_golpae() -> Image.Image:
    canvas = base_scene("lose")
    draw = finish(canvas)
    pot(draw, 60)
    header(draw, "골패", "두 장의 점을 모두 더한 끝자리가 높은 쪽이 이긴다", 240, 1)
    for i, value in enumerate(((2, 5), (1, 3))):
        tile(draw, (CENTER_X + (i - 0.5) * TILE_GAP, DEALER_ROW_Y), value, True)
    for i, value in enumerate(((6, 6), (4, 3))):
        tile(draw, (CENTER_X + (i - 0.5) * TILE_GAP, PLAYER_ROW_Y), value, True)
    center_text(draw, "이겼다", 232, 18, LANTERN)
    center_text(draw, "엽전 +60닢", 246, 9, LANTERN)
    center_text(draw, "나 6-6 4-3  9점   노름꾼 2-5 1-3  1점", 258, 9, INK_DIM)
    center_text(draw, "점프로 넘긴다", 268, 9, INK_DIM)
    for i in range(9):
        spread = (i - 4) * 13
        u = 0.45
        x = POT_POS[0] + spread * 0.35 + (CENTER_X + spread - POT_POS[0] - spread * 0.35) * u
        y = POT_POS[1] + (246 - POT_POS[1]) * u - math.sin(u * math.pi) * 34
        coin(draw, (x, y), LANTERN)
    return canvas


def scene_dice_roll() -> Image.Image:
    canvas = base_scene()
    draw = finish(canvas)
    pot(draw, 80)
    header(draw, "썅륙", "주사위 둘. 소는 2에서 6, 대는 8에서 12, 쌍은 같은 눈", 200, 0)
    center_text(draw, "주사위가 구른다", 246, 9, INK_DIM)
    rest = [(CENTER_X - 0.5 * DIE_GAP, 182), (CENTER_X + 0.5 * DIE_GAP, 182)]
    for i, target in enumerate(rest):
        u = 0.55
        eased = 1 - (1 - u) ** 3
        hop = abs(math.sin(u * math.pi * 3)) * 26 * (1 - u)
        x = DECK_POS[0] + (target[0] - DECK_POS[0]) * eased
        y = DECK_POS[1] + (target[1] - DECK_POS[1]) * eased - hop
        die(canvas, (x, y), (i * 3 + 2) % 6 + 1, (1 - u) * math.tau * (1 + i * 0.4))
    return canvas


def scene_dice_result() -> Image.Image:
    canvas = base_scene("win")
    draw = finish(canvas)
    pot(draw, 80)
    header(draw, "썅륙", "주사위 둘. 소는 2에서 6, 대는 8에서 12, 쌍은 같은 눈", 120, 1)
    for i, face in enumerate((5, 4)):
        die(canvas, (CENTER_X + (i - 0.5) * DIE_GAP, 182), face, 0.0)
    draw = ImageDraw.Draw(canvas)
    center_text(draw, "졌다", 232, 18, NIGHT_DIM)
    center_text(draw, "엽전 -80닢", 246, 9, NIGHT_DIM)
    center_text(draw, "나 대에 걸었다   노름꾼 5 4  합 9  대", 258, 9, INK_DIM)
    center_text(draw, "점프로 넘긴다", 268, 9, INK_DIM)
    return canvas


def main() -> int:
    shots = [
        ("제안", scene_offer()),
        ("베팅", scene_bet()),
        ("투전 뒤집기", scene_tujeon()),
        ("골패 승리", scene_golpae()),
        ("썅륙 구르는 중", scene_dice_roll()),
        ("썅륙 결과", scene_dice_result()),
    ]
    gap = 14
    sheet = Image.new("RGBA", (W, (H + gap) * len(shots)), (0, 0, 0, 255))
    label = ImageDraw.Draw(sheet)
    for i, (title, shot) in enumerate(shots):
        y = i * (H + gap)
        sheet.alpha_composite(shot, (0, y))
        label.text((4, y + H + 2), title, font=font(9), fill=INK)
    sheet = sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(OUT)
    print("wrote %s (%dx%d)" % (OUT.relative_to(ROOT), sheet.width, sheet.height))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
