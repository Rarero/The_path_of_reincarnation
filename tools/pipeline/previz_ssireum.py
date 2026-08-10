#!/usr/bin/env python3
"""씨름 이벤트 화면 프리비즈.

Godot 없이 scenes/minigame/ssireum_minigame.gd의 배치 상수를 그대로 재현해
480x270 화면을 그려 본다. 판정은 재현하지 않고 배치와 겹침만 본다.
상수를 바꾸면 이 파일의 값도 함께 맞춘다.

사용법: python tools/pipeline/previz_ssireum.py
산출: art_src/previz/ssireum_previz.png (3단계 가로 배치, 2배 확대)
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "art_src/previz/ssireum_previz.png"

W, H = 480, 270
BACKDROP = (13, 13, 23, 255)
INK = (230, 222, 204, 255)
INK_DIM = (153, 148, 138, 255)
LANTERN = (235, 168, 71, 255)
NIGHT = (66, 74, 122, 255)
NIGHT_DIM = (117, 117, 125, 255)

RING_SCALE = 4
RING_TOP_LEFT = (18, 118)
FLOOR_Y = 186
CENTER_X = 240
GRIP_HALF = 19
PUSH_SWAY = 44
WAIT_X = 92
ART_CENTER = (40, 57)
ACTOR_SCALE = 1.5
BIG_SCALE = 2.0
RESULT_PUSH = 54
RESULT_HOLD = 14
CROWD_FAR_Y = 128
CROWD_NEAR_Y = 270
GAUGE_BOX = (96, 20, 288, 10)
MASH_BOX = (168, 246, 144, 7)

CROWD_FAR = [
    "crowd_a", "crowd_b", "crowd_c", "crowd_cheer_a", "crowd_e", "crowd_cheer_b",
    "crowd_f", "crowd_g", "crowd_child", "crowd_h", "crowd_cat",
]
CROWD_NEAR = ["crowd_back_a", "crowd_back_b", "crowd_back_c", "crowd_back_d", "crowd_back_e"]


def load_png(rel: str) -> Image.Image:
    return Image.open(ROOT / rel).convert("RGBA")


def frame(sheet: str, index: int) -> Image.Image:
    im = load_png(sheet)
    return im.crop((76 * index, 0, 76 * (index + 1), 76))


def font() -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(ROOT / "assets/fonts/galmuri9.ttf"), 9)


def font_big() -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(ROOT / "assets/fonts/galmuri9.ttf"), 18)


def center_text(draw: ImageDraw.ImageDraw, text: str, y: int, fnt, color) -> None:
    width = draw.textlength(text, font=fnt)
    draw.text((W / 2 - width / 2, y - fnt.size), text, font=fnt, fill=color)


def meter(draw: ImageDraw.ImageDraw, box, ratio: float, fill, back) -> None:
    x, y, w, h = box
    draw.rectangle([x, y, x + w - 1, y + h - 1], fill=back)
    filled = int(w * max(0.0, min(1.0, ratio)))
    if filled > 0:
        draw.rectangle([x, y, x + filled - 1, y + h - 1], fill=fill)
    draw.rectangle([x, y, x + w - 1, y + h - 1], outline=INK_DIM)


def draw_actor(canvas: Image.Image, sprite: Image.Image, center_x: float, flip: bool,
               scale_mul: float = ACTOR_SCALE) -> None:
    art = sprite
    if flip:
        art = art.transpose(Image.FLIP_LEFT_RIGHT)
    if scale_mul != 1.0:
        size = (int(art.width * scale_mul), int(art.height * scale_mul))
        art = art.resize(size, Image.NEAREST)
    cx = ART_CENTER[0] * scale_mul
    cy = ART_CENTER[1] * scale_mul
    canvas.alpha_composite(art, (int(center_x - cx), int(FLOOR_Y - cy)))


def crowd_plan(seed: int):
    rng = random.Random(seed)
    plan = []
    for i in range(11):
        x = 40 + i * 40 + rng.uniform(-6, 6)
        plan.append((CROWD_FAR[i % len(CROWD_FAR)], x, CROWD_FAR_Y))
    for i in range(3):
        plan.append((CROWD_NEAR[i % len(CROWD_NEAR)], 24 + i * 34, CROWD_NEAR_Y))
    for i in range(3):
        plan.append((CROWD_NEAR[(i + 2) % len(CROWD_NEAR)], 392 + i * 34, CROWD_NEAR_Y))
    return plan


def draw_crowd(canvas: Image.Image, plan, feet_y: int) -> None:
    for name, x, y in plan:
        if y != feet_y:
            continue
        art = load_png("assets/sprites/bg/act1/crowd/%s.png" % name)
        canvas.alpha_composite(art, (int(x - art.width / 2), int(y - art.height)))


def base_scene(seed: int) -> tuple[Image.Image, ImageDraw.ImageDraw, list]:
    canvas = Image.new("RGBA", (W, H), BACKDROP)
    plan = crowd_plan(seed)
    draw_crowd(canvas, plan, CROWD_FAR_Y)
    ring = load_png("assets/sprites/bg/act1/bg_ssireum_ring.png")
    ring = ring.resize((ring.width * RING_SCALE, ring.height * RING_SCALE), Image.NEAREST)
    canvas.alpha_composite(ring, RING_TOP_LEFT)
    return canvas, ImageDraw.Draw(canvas), plan


def satba(draw: ImageDraw.ImageDraw, player_x: float, dokkaebi_x: float) -> None:
    left = int(min(player_x, dokkaebi_x) + 4)
    right = int(max(player_x, dokkaebi_x) - 4)
    y = FLOOR_Y - 26
    draw.rectangle([left, y, right, y + 2], fill=LANTERN)
    draw.rectangle([left, y + 3, right, y + 4], fill=NIGHT)


def scene_offer(seed: int, big: bool) -> Image.Image:
    canvas, draw, plan = base_scene(seed)
    draw_actor(canvas, frame("assets/sprites/player/anim/player_idle_e.png", 0), WAIT_X, False)
    draw_actor(canvas, frame("assets/sprites/enemies/dokkaebi_hop_e.png", 2), CENTER_X, True,
               BIG_SCALE if big else ACTOR_SCALE)
    draw_crowd(canvas, plan, CROWD_NEAR_Y)
    draw = ImageDraw.Draw(canvas)
    who = "황소만 한 장정" if big else "억센 장정"
    center_text(draw, "%s이 씨름을 건다" % who, 214, font(), INK)
    center_text(draw, "> 씨름판에 들어간다", 232, font(), LANTERN)
    center_text(draw, "  지나간다", 247, font(), INK_DIM)
    center_text(draw, "위아래로 고르고 점프로 결정", 265, font(), INK_DIM)
    return canvas


def scene_duel(seed: int, progress: float, big: bool) -> Image.Image:
    canvas, draw, plan = base_scene(seed)
    sway = (progress - 0.5) * PUSH_SWAY
    player_x = CENTER_X - GRIP_HALF + sway
    dokkaebi_x = CENTER_X + GRIP_HALF + sway
    satba(draw, player_x, dokkaebi_x)
    draw_actor(canvas, frame("assets/sprites/player/anim/player_idle_e.png", 2), player_x, False)
    draw_actor(canvas, frame("assets/sprites/enemies/dokkaebi_idle_e.png", 4), dokkaebi_x, True,
               BIG_SCALE if big else ACTOR_SCALE)
    draw_crowd(canvas, plan, CROWD_NEAR_Y)
    draw = ImageDraw.Draw(canvas)
    meter(draw, GAUGE_BOX, progress, LANTERN, NIGHT)
    knot = int(GAUGE_BOX[0] + GAUGE_BOX[2] * progress)
    draw.rectangle([knot - 1, GAUGE_BOX[1] - 3, knot, GAUGE_BOX[1] + GAUGE_BOX[3] + 2], fill=INK)
    center_text(draw, "12번 맞음   1번 헛손질", 44, font(), INK_DIM)
    center_text(draw, "A", 240, font_big(), INK)
    meter(draw, MASH_BOX, 0.6, LANTERN, NIGHT)
    center_text(draw, "노란 게이지가 다 줄 때까지 연타하라", 265, font(), INK_DIM)
    return canvas


def scene_result(seed: int, won: bool) -> Image.Image:
    canvas, draw, plan = base_scene(seed)
    player_x = CENTER_X - (RESULT_HOLD if won else RESULT_PUSH)
    dokkaebi_x = CENTER_X + (RESULT_PUSH if won else RESULT_HOLD)
    player_sheet, player_frame = ("player_jump_e", 1) if won else ("player_hurt_e", 4)
    dokkaebi_sheet, dokkaebi_frame = ("dokkaebi_hurt_e", 7) if won else ("dokkaebi_hop_e", 4)
    draw_actor(canvas, frame("assets/sprites/player/anim/%s.png" % player_sheet, player_frame),
               player_x, False)
    draw_actor(canvas, frame("assets/sprites/enemies/%s.png" % dokkaebi_sheet, dokkaebi_frame),
               dokkaebi_x, True)
    draw_crowd(canvas, plan, CROWD_NEAR_Y)
    draw = ImageDraw.Draw(canvas)
    center_text(draw, "이겼다" if won else "졌다", 234, font_big(), LANTERN if won else NIGHT_DIM)
    if won:
        center_text(draw, "엽전 36닢", 252, font(), LANTERN)
        center_text(draw, "정체는 헌 절굿공이였다", 265, font(), LANTERN)
    else:
        center_text(draw, "체력 12", 252, font(), NIGHT_DIM)
        center_text(draw, "판을 내주고 길을 비켰다", 265, font(), NIGHT_DIM)
    return canvas


def main() -> int:
    shots = [
        ("선택", scene_offer(7, False)),
        ("대결", scene_duel(7, 0.68, False)),
        ("승리", scene_result(7, True)),
        ("패배", scene_result(7, False)),
        ("큰 도깨비", scene_offer(21, True)),
    ]
    gap = 6
    sheet = Image.new("RGBA", (W, (H + gap) * len(shots) - gap), (0, 0, 0, 255))
    for i, (_label, shot) in enumerate(shots):
        sheet.alpha_composite(shot, (0, i * (H + gap)))
    sheet = sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print("wrote %s (%dx%d)" % (OUT, sheet.width, sheet.height))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
