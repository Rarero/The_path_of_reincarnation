#!/usr/bin/env python3
"""환도 참격과 패링 성공 이펙트 생성 (요청서 025 C-3).

이 5종은 AI 생성이 아니라 절차 생성이다. 근거는 세 가지다.
1. 대상이 기하 도형(초승달 호, 쐐기, 방사 스파크)이라 생성 모델의 강점이 없다
2. 색을 art_src/palettes/act1_night_nofire.gpl에서 정확히 찍어야 한다.
   생성물은 중간 계조와 반투명 가장자리를 만들어 매번 후처리가 필요하다
3. 기존 fx(bullet_tracer, muzzle_flash_8, slash_arc_24)가 이미 같은 성격의
   초소형 플랫 에셋이다. 같은 방식으로 맞춘다

글로우와 헤일로를 굽지 않는다 (ART_STYLE 6장). 적색과 청록을 쓰지 않는다
(DESIGN_ACT1 2.4 색 채널 규약).

사용법: python tools/pipeline/gen_sword_fx.py
산출: assets/sprites/fx/fx_slash_{down,up,heavy,air}.png (가로 스트립)
     assets/sprites/fx/fx_parry_flash.png (가로 스트립)
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
OUT_DIR = ROOT / "assets/sprites/fx"

## act1_night_nofire.gpl에서 뽑은 색. 참격은 무채, 패링은 금빛으로 갈린다 (요청서 025 C-3-5)
SILVER_CORE = (226, 218, 210, 255)
SILVER_EDGE = (138, 129, 115, 255)
SILVER_DIM = (95, 93, 104, 255)
GOLD_BRIGHT = (249, 225, 162, 255)
GOLD_MID = (197, 171, 109, 255)
GOLD_DEEP = (129, 106, 67, 255)


def bezier(p0, p1, p2, t):
    inv = 1.0 - t
    x = inv * inv * p0[0] + 2 * inv * t * p1[0] + t * t * p2[0]
    y = inv * inv * p0[1] + 2 * inv * t * p1[1] + t * t * p2[1]
    return x, y


def stamp(pixels, size, cx, cy, radius, color):
    """정수 격자에 원판을 찍는다. 안티에일리어싱 없음."""
    width, height = size
    r2 = radius * radius
    left = int(math.floor(cx - radius))
    right = int(math.ceil(cx + radius))
    top = int(math.floor(cy - radius))
    bottom = int(math.ceil(cy + radius))
    for y in range(max(0, top), min(height, bottom + 1)):
        for x in range(max(0, left), min(width, right + 1)):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r2:
                pixels[x, y] = color


def arc_frame(size, p0, p1, p2, thick_max, taper, core, edge, core_ratio):
    """베지어를 따라 두께가 변하는 호를 그린다. 가장자리를 먼저 깔고 코어를 덮는다."""
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    pixels = image.load()
    steps = 220
    for pass_index, (color, scale) in enumerate(((edge, 1.0), (core, core_ratio))):
        if scale <= 0.0:
            continue
        for step in range(steps + 1):
            t = step / steps
            x, y = bezier(p0, p1, p2, t)
            ## 가운데가 가장 두껍고 양 끝으로 갈수록 가늘어진다
            profile = math.sin(math.pi * t) ** 0.7 if taper == "middle" else (1.0 - t)
            radius = thick_max * profile * scale * 0.5
            if radius < 0.5:
                continue
            stamp(pixels, size, x, y, radius, color)
    return image


def strip(frames):
    width = frames[0].width
    height = frames[0].height
    sheet = Image.new("RGBA", (width * len(frames), height), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (width * index, 0))
    return sheet


def slash(size, p0, p1, p2, thick, count, taper="middle"):
    """나타남에서 옅어짐. 마지막 프레임은 알파가 아니라 색으로 흐린다 (디더링 금지)."""
    frames = []
    steps = ((1.0, 0.62), (0.74, 0.42), (0.48, 0.0), (0.30, 0.0))[:count]
    for index, (scale, core_ratio) in enumerate(steps):
        edge = SILVER_EDGE if index < count - 1 else SILVER_DIM
        frames.append(arc_frame(size, p0, p1, p2, thick * scale, taper,
                                SILVER_CORE, edge, core_ratio))
    return strip(frames)


def parry_flash():
    """즉발 금빛 스파크. 첫 프레임이 최대 크기다 (D8 7.2 즉발성 요구)."""
    size = (32, 32)
    center = 16.0
    lengths = (13.0, 10.0, 6.0, 3.0)
    frames = []
    for index, length in enumerate(lengths):
        image = Image.new("RGBA", size, (0, 0, 0, 0))
        pixels = image.load()
        for ray in range(6):
            angle = math.radians(15 + ray * 60)
            dx = math.cos(angle)
            dy = math.sin(angle)
            span = int(length * 2)
            for step in range(span + 1):
                distance = length * step / span
                x = center + dx * distance
                y = center + dy * distance
                ratio = distance / length
                if ratio < 0.45:
                    color = GOLD_BRIGHT
                elif ratio < 0.8:
                    color = GOLD_MID
                else:
                    color = GOLD_DEEP
                radius = 1.4 if ratio < 0.35 else 0.9
                stamp(pixels, size, x, y, radius, color)
        if index < 2:
            core = 2.4 if index == 0 else 1.6
            stamp(pixels, size, center, center, core, SILVER_CORE)
        frames.append(image)
    return strip(frames)


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    jobs = (
        ## 1타. 우상에서 좌하로 긋는 초승달
        ("fx_slash_down", 48, slash((48, 40), (43, 5), (41, 31), (7, 36), 6.0, 3)),
        ## 2타. 좌하에서 우상으로 올려치는 초승달
        ("fx_slash_up", 48, slash((48, 40), (43, 35), (41, 9), (7, 4), 6.0, 3)),
        ## 3타 마무리. 위에서 아래로 내리치는 크고 두꺼운 호
        ("fx_slash_heavy", 56, slash((56, 48), (29, 3), (53, 24), (27, 45), 8.0, 4)),
        ## 점프 공격. 아래로 내리꽂는 쐐기
        ("fx_slash_air", 40, slash((40, 48), (20, 4), (25, 25), (19, 45), 8.0, 3, "taper")),
        ## 패링 성공
        ("fx_parry_flash", 32, parry_flash()),
    )
    for name, frame_width, sheet in jobs:
        path = OUT_DIR / ("%s.png" % name)
        sheet.save(path)
        print("wrote %-16s %-9s 프레임 %dx%d x%d  색 %d"
              % (path.name, "%dx%d" % sheet.size, frame_width, sheet.height,
                 sheet.width // frame_width, len(sheet.getcolors(4096) or [])))
    print("색 채널 점검: 적색과 청록 미사용. 참격은 무채, 패링만 금빛")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
