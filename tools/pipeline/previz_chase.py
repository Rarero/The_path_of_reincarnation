#!/usr/bin/env python3
"""장물아비 추격 화면 프리비즈.

Godot 없이 scenes/minigame/chase_minigame.gd의 배치 상수를 그대로 재현해
480x270 화면을 그려 본다. 달리기 판정은 재현하지 않고 배치와 겹침만 본다.
상수를 바꾸면 이 파일의 값도 함께 맞춘다.

사용법: python tools/pipeline/previz_chase.py
산출: art_src/previz/chase_previz.png (장면 4개 세로 배치, 2배 확대)
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "art_src/previz/chase_previz.png"

W, H = 480, 270
BACKDROP = (13, 13, 23, 255)
INK = (230, 222, 204, 255)
INK_DIM = (153, 148, 138, 255)
LANTERN = (235, 168, 71, 255)
NIGHT = (66, 74, 122, 255)
NIGHT_DIM = (117, 117, 125, 255)
ROAD = (28, 28, 41, 255)

LANE_COUNT = 5
LANE_X0 = 144
LANE_GAP = 48
PLAYER_Y = 220
DEPTH_SCALE = 0.85
TOP_CLAMP = 26
ROAD_LEFT = 118
ROAD_RIGHT = 362
ART_CENTER = (40, 57)
FAR_SCALE = 0.52
NEAR_SCALE = 1.0
PLAYER_SCALE = 0.9
DASH_SPAN = 40
SIDE_SPAN = 96
SIDE_X = [86, 394]
MAX_HITS = 3

SIDE_PATHS = ["bg_stall_mid_a", "bg_stall_mid_b", "bg_stall_mid_c", "bg_stall_fruit"]
OBSTACLE_PATHS = ["chase_crate", "chase_jars", "chase_cart"]


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


def lane_x(lane: float) -> float:
    return LANE_X0 + lane * LANE_GAP


def depth_y(logic_y: float) -> float:
    return max(PLAYER_Y - logic_y * DEPTH_SCALE, TOP_CLAMP)


def depth_scale(screen_y: float) -> float:
    t = max(0.0, min(1.0, (screen_y - TOP_CLAMP) / (PLAYER_Y - TOP_CLAMP)))
    return FAR_SCALE + (NEAR_SCALE - FAR_SCALE) * t


def road(canvas: Image.Image, scroll: float, seed: int) -> ImageDraw.ImageDraw:
    draw = ImageDraw.Draw(canvas)
    draw.rectangle([ROAD_LEFT, TOP_CLAMP, ROAD_RIGHT, H], fill=ROAD)
    draw.line([ROAD_LEFT, TOP_CLAMP, ROAD_LEFT, H], fill=NIGHT)
    draw.line([ROAD_RIGHT, TOP_CLAMP, ROAD_RIGHT, H], fill=NIGHT)
    for lane in range(1, LANE_COUNT):
        x = LANE_X0 - LANE_GAP / 2 + lane * LANE_GAP
        y = TOP_CLAMP + scroll % DASH_SPAN
        while y < H:
            length = 10 * depth_scale(y)
            draw.rectangle([x, y, x, y + length], fill=NIGHT)
            y += DASH_SPAN
    rng = random.Random(seed)
    for i in range(6):
        name = SIDE_PATHS[rng.randrange(len(SIDE_PATHS))]
        base = i * (SIDE_SPAN / 2) + rng.uniform(-8, 8)
        y = (base + scroll * 0.7) % (SIDE_SPAN * 3) - 30
        art = load_png("assets/sprites/bg/act1/%s.png" % name)
        at = depth_scale(y)
        art = art.resize((max(1, int(art.width * at)), max(1, int(art.height * at))),
                         Image.NEAREST)
        canvas.alpha_composite(
            art, (int(SIDE_X[i % 2] - art.width / 2), int(y - art.height / 2))
        )
    return ImageDraw.Draw(canvas)


def actor(canvas: Image.Image, art: Image.Image, at, scale_at: float) -> None:
    size = (max(1, int(art.width * scale_at)), max(1, int(art.height * scale_at)))
    art = art.resize(size, Image.NEAREST)
    x = at[0] - ART_CENTER[0] * scale_at
    y = at[1] - ART_CENTER[1] * scale_at
    canvas.alpha_composite(art, (int(x), int(y)))


def obstacle(canvas: Image.Image, index: int, lane: int, logic_y: float) -> None:
    y = depth_y(logic_y)
    at = depth_scale(y)
    name = OBSTACLE_PATHS[(index * 3 + lane) % len(OBSTACLE_PATHS)]
    art = load_png("assets/sprites/props/%s.png" % name)
    art = art.resize((max(1, int(art.width * at)), max(1, int(art.height * at))), Image.NEAREST)
    canvas.alpha_composite(
        art, (int(lane_x(lane) - art.width / 2), int(y - art.height / 2))
    )


def thief(canvas: Image.Image, lane: int, gap: float) -> None:
    y = depth_y(gap)
    at = depth_scale(y)
    actor(canvas, frame("assets/sprites/enemies/fence_back_run_n.png", 1), (lane_x(lane), y), at)


def player(canvas: Image.Image, lane: float, frame_index: int, y: float = PLAYER_Y) -> None:
    art = frame("assets/sprites/player/anim/player_back_run_n.png", frame_index % 4)
    actor(canvas, art, (lane_x(lane), y), PLAYER_SCALE)


def hit_lamps(draw: ImageDraw.ImageDraw, hits: int) -> None:
    for i in range(MAX_HITS):
        at = (20 + i * 14, 20)
        circle(draw, at, 4, fill=LANTERN if i >= hits else NIGHT, outline=INK_DIM)


def meter(draw: ImageDraw.ImageDraw, box, ratio: float) -> None:
    x, y, w, h = box
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=NIGHT)
    filled = int(w * max(0.0, min(1.0, ratio)))
    if filled > 0:
        draw.rectangle([x, y, x + filled - 1, y + h - 1], fill=LANTERN)
    draw.rectangle([x, y, x + w - 1, y + h - 1], outline=INK_DIM)


def scene_intro() -> Image.Image:
    canvas = Image.new("RGBA", (W, H), BACKDROP)
    draw = road(canvas, 12, 7)
    for index, (lane, logic) in enumerate(((1, 210), (4, 150))):
        obstacle(canvas, index, lane, logic)
    thief(canvas, 3, 90)
    player(canvas, 2, 1)
    draw = ImageDraw.Draw(canvas)
    center_text(draw, "엽전 84닢을 낚아채 달아났다", 240, 9, NIGHT_DIM)
    center_text(draw, "쫓아라", 260, 18, LANTERN)
    return canvas


def scene_run() -> Image.Image:
    canvas = Image.new("RGBA", (W, H), BACKDROP)
    draw = road(canvas, 58, 7)
    for index, (lane, logic) in enumerate(((0, 200), (2, 160), (3, 96), (1, 40))):
        obstacle(canvas, index, lane, logic)
    thief(canvas, 3, 52)
    player(canvas, 2.6, 4)
    draw = ImageDraw.Draw(canvas)
    hit_lamps(draw, 1)
    text_at(draw, "잡음 1/4", (424, 22), 9, LANTERN)
    meter(draw, (120, 250, 240, 5), 0.62)
    center_text(draw, "좌우로 피하고 따라붙어라", 266, 9, INK_DIM)
    return canvas


def scene_catch() -> Image.Image:
    canvas = Image.new("RGBA", (W, H), BACKDROP)
    draw = road(canvas, 96, 7)
    for index, (lane, logic) in enumerate(((4, 190), (1, 120))):
        obstacle(canvas, index, lane, logic)
    player(canvas, 3, 2)
    draw = ImageDraw.Draw(canvas)
    at = (lane_x(3), PLAYER_Y - 24)
    for i in range(7):
        spread = (i - 3) * 11
        u = 0.5
        x = at[0] + spread * u
        y = at[1] + 34 * u - math.sin(u * math.pi) * 22
        circle(draw, (x, y), 3, fill=LANTERN)
    text_at(draw, "잡았다", (at[0], at[1] - 9), 9, LANTERN)
    hit_lamps(draw, 1)
    text_at(draw, "잡음 2/4", (424, 22), 9, LANTERN)
    meter(draw, (120, 250, 240, 5), 0.05)
    center_text(draw, "좌우로 피하고 따라붙어라", 266, 9, INK_DIM)
    return canvas


def scene_result() -> Image.Image:
    canvas = Image.new("RGBA", (W, H), BACKDROP)
    road(canvas, 130, 7)
    player(canvas, 2, 0)
    draw = ImageDraw.Draw(canvas)
    draw.rectangle([0, 86, W - 1, 181], fill=(13, 13, 23, 216))
    center_text(draw, "전부 잡았다", 108, 18, LANTERN)
    center_text(draw, "엽전 100닢 회수 (웃돈 포함)", 132, 9, LANTERN)
    center_text(draw, "쟁여둔 장물에서 떨이 유물 하나", 147, 9, LANTERN)
    return canvas


def main() -> int:
    shots = [
        ("도입", scene_intro()),
        ("추격", scene_run()),
        ("포착", scene_catch()),
        ("결과", scene_result()),
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
