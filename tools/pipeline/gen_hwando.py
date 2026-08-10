#!/usr/bin/env python3
"""환도 스프라이트와 각도 프리베이크 생성 (docs/ART_WEAPON_SPLIT.md 3.2).

무기는 AI가 아니라 스크립트로 그린다. 근거는 세 가지다.
1. 크기 규격을 정확히 지킬 수 있다. AI 생성에서 목표 19px가 13px로 나왔던 문제가
   원천 차단된다
2. 색을 art_src/palettes/act1_night_nofire.gpl에서 정확히 찍는다
3. 각도 세트를 결정적으로 만들 수 있다. 같은 형태가 각도만 달라진다

ART_STYLE 8장의 런타임 스프라이트 회전 금지는 유지된다. 회전은 이 스크립트
(빌드 타임)에서 일어나고 인게임에는 고정 프레임만 들어간다.

조형 요건 (요청서 025 C-1): 조선식 환도. 작은 타원 코등이, 완만한 곡률,
짧은 한 손 자루. 카타나의 큰 츠바와 깊은 반월 곡선, 긴 두 손 자루를 배제한다.

사용법: python tools/pipeline/gen_hwando.py
산출:
  assets/sprites/weapons/hwando_angles.png  각도 세트 가로 스트립 (76x76 x 16)
  assets/sprites/weapons/hwando_item.png    아이템 표시용 (48x48)

크기 이력: 초안 전장 18px -> 36px(2026-08-07 사용자 지시) -> 31px -> 28px
(같은 날, 날이 길다는 판단이 두 번 나와 날을 30 -> 25 -> 22로 축소).
신장 38px의 0.74배다. 디자인 변경만이며 히트박스와 판정 시간은 D8 5.2 그대로다.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
OUT_DIR = ROOT / "assets/sprites/weapons"

## act1_night_nofire.gpl에서 뽑은 색 (요청서 025 C-1)
BLADE_HI = (226, 218, 210, 255)
BLADE_MID = (138, 129, 115, 255)
BLADE_LO = (95, 93, 104, 255)
GUARD = (197, 171, 109, 255)
GUARD_LO = (129, 106, 67, 255)
HILT = (44, 41, 66, 255)
HILT_LO = (31, 28, 60, 255)
SCABBARD = (36, 33, 59, 255)
SCABBARD_HI = (68, 53, 63, 255)

## 규격. 인게임 플레이어 신장 38px 대비 비율로 잡는다.
## 2026-08-07 사용자 지시로 전장을 키웠다. 18px -> 36px로 올린 뒤 날이 길다는
## 판단이 두 번 나와 날을 30 -> 25 -> 22로 줄여 전장 28px에 안착했다.
## 신장 38px의 0.74다.
## 디자인 변경만이며 히트박스와 판정(D8 5.2)은 그대로 둔다.
## 자루는 함께 2배로 늘리지 않는다. 조선 환도의 짧은 한 손 자루를 유지해야
## 카타나(긴 두 손 자루)와 구분되기 때문이다. 자루는 4 -> 5로만 올린다
BLADE_LEN = 22.0
HILT_LEN = 5.0
## 곡률은 날 길이에 비례해 잡는다. 비례를 지켜야 완만한 곡선이라는 인상이 같다
CURVE = 2.5
## 그립이 정중앙이므로 캔버스는 (날 길이 + 여유)의 2배가 필요하다.
## 76은 몸 클립 캔버스와 같아 오버레이 계산이 단순해진다
CANVAS = 76
ANGLE_STEPS = 16


def draw_hwando(size: int, angle_deg: float) -> Image.Image:
    """자루 끝을 원점으로 두고 angle_deg 방향으로 뻗은 환도를 그린다.

    angle_deg 0은 오른쪽 수평, 양수는 반시계(화면 위쪽)다.

    각 캔버스 픽셀을 무기 축 좌표로 역변환해 칠할지 판정한다. 축을 따라가며
    찍는 방식은 대각선에서 표본이 어긋나 날이 끊기므로 쓰지 않는다. 이 방식은
    어느 각도에서도 두께가 일정하다.
    """
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = image.load()
    theta = math.radians(angle_deg)
    cos_t, sin_t = math.cos(theta), math.sin(theta)
    ## 그립(자루를 쥐는 지점)을 항상 캔버스 정중앙에 고정한다.
    ## 각도가 바뀌어도 그립 위치가 같아야 앵커 한 쌍으로 모든 각도를 얹을 수 있다.
    hand_x = size / 2.0
    hand_y = size / 2.0

    for yi in range(size):
        for xi in range(size):
            dx = xi + 0.5 - hand_x
            dy = yi + 0.5 - hand_y
            ## 축 좌표로 역회전. along은 칼끝 방향, across는 등에서 날 방향
            along = dx * cos_t - dy * sin_t
            across = -(dx * sin_t + dy * cos_t)

            color = None
            if -HILT_LEN <= along <= -0.2:
                ## 자루. 짧은 한 손 자루라 두께를 얇게 유지한다
                if abs(across) <= 1.0:
                    color = HILT if abs(across) <= 0.5 else HILT_LO
            elif -0.2 < along <= 0.9:
                ## 코등이. 작은 타원이라 축 방향으로 1px에 그친다
                if abs(across) <= 1.7:
                    color = GUARD if abs(across) <= 0.7 else GUARD_LO
            elif 0.9 < along <= 1.0 + BLADE_LEN:
                t = (along - 1.0) / BLADE_LEN
                t = max(0.0, min(1.0, t))
                ## 곡률. 끝으로 갈수록 완만하게 휘어 오른다 (카타나의 깊은 반월 배제)
                bend = CURVE * (t ** 2)
                ## 폭. 뿌리 2.4px에서 칼끝 1.2px로 좁아진다.
                ## 날을 길게 잡으면서 뿌리를 조금 넓혔다. 그대로 두면
                ## 22px 길이에 2px 폭이라 실이 늘어진 것처럼 보인다
                half = 1.2 - 0.6 * t
                offset = across - bend
                if abs(offset) <= half:
                    if t > 0.93:
                        color = BLADE_LO
                    elif offset >= 0.0:
                        color = BLADE_HI
                    else:
                        color = BLADE_MID
            if color is not None:
                px[xi, yi] = color
    return image


def make_angle_strip() -> Image.Image:
    """ANGLE_STEPS 단계의 각도 프레임을 가로 스트립으로 굽는다."""
    frames = []
    for index in range(ANGLE_STEPS):
        angle = 360.0 * index / ANGLE_STEPS
        frames.append(draw_hwando(CANVAS, angle))
    strip = Image.new("RGBA", (CANVAS * len(frames), CANVAS), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (CANVAS * index, 0))
    return strip


def draw_scabbard(size: int, angle_deg: float) -> Image.Image:
    """칼집. 날보다 조금 길고 굵으며 띠돈 고리 두 개가 붙는다."""
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = image.load()
    theta = math.radians(angle_deg)
    cos_t, sin_t = math.cos(theta), math.sin(theta)
    center = size / 2.0
    base_x = center - cos_t * (BLADE_LEN * 0.30)
    base_y = center + sin_t * (BLADE_LEN * 0.30)
    length = BLADE_LEN + 2.0

    for yi in range(size):
        for xi in range(size):
            dx = xi + 0.5 - base_x
            dy = yi + 0.5 - base_y
            along = dx * cos_t - dy * sin_t
            across = -(dx * sin_t + dy * cos_t)
            if not (0.0 <= along <= length):
                continue
            t = along / length
            bend = CURVE * (t ** 2)
            offset = across - bend
            if abs(offset) <= 1.6:
                px[xi, yi] = SCABBARD_HI if offset >= 0.8 else SCABBARD
            ## 띠돈. 등 쪽에 매다는 황동 고리 두 개
            if 1.6 < offset <= 2.6 and (3.0 <= along <= 5.0 or 10.0 <= along <= 12.0):
                px[xi, yi] = GUARD
    return image


def make_item() -> Image.Image:
    """아이템 표시용. 칼집에 꽂힌 채 띠돈으로 매달린 형태다 (요청서 025 C-3-6).

    칼과 칼집을 나란히 두는 안은 32px에서 둘이 겹쳐 한 덩어리로 뭉개졌다.
    꽂힌 형태는 실루엣이 하나라 이 밀도에서 훨씬 잘 읽히고, 띠돈으로 날이
    아래를 향해 매달리는 구조가 그대로 보인다. 그 구조가 카타나(띠에 꽂아
    날이 위를 향함)와 구분되는 가장 큰 단서다.
    """
    ## 전장 2배 변경(2026-08-07)에 맞춰 캔버스를 48로 키웠다. 32에서는 칼집이
    ## 대각선을 넘어 잘렸다
    size = 48
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = image.load()
    angle = 32.0
    theta = math.radians(angle)
    cos_t, sin_t = math.cos(theta), math.sin(theta)
    center = size / 2.0
    length = BLADE_LEN + 2.0
    ## 자루 끝에서 칼집 끝까지가 캔버스 대각선을 채우도록 뒤로 물린다
    base_x = center - cos_t * (length - HILT_LEN) / 2.0
    base_y = center + sin_t * (length - HILT_LEN) / 2.0

    for yi in range(size):
        for xi in range(size):
            dx = xi + 0.5 - base_x
            dy = yi + 0.5 - base_y
            along = dx * cos_t - dy * sin_t
            across = -(dx * sin_t + dy * cos_t)

            color = None
            if -HILT_LEN <= along <= -0.2:
                ## 자루. 칼집 밖으로 나온 부분
                if abs(across) <= 1.2:
                    color = HILT if abs(across) <= 0.6 else HILT_LO
            elif -0.2 < along <= 0.9:
                ## 코등이
                if abs(across) <= 1.9:
                    color = GUARD if abs(across) <= 0.8 else GUARD_LO
            elif 0.9 < along <= length:
                t = (along - 0.9) / (length - 0.9)
                bend = CURVE * (t ** 2)
                offset = across - bend
                if abs(offset) <= 1.8:
                    ## 흑칠 칼집. 등 쪽에 광택 한 줄
                    color = SCABBARD_HI if offset >= 0.8 else SCABBARD
                elif 1.8 < offset <= 2.8 and (3.0 <= along <= 5.0 or 10.0 <= along <= 12.0):
                    ## 띠돈. 허리에 매다는 황동 고리 두 개.
                    ## 위치는 칼집 길이에 비례해 옮겼다
                    color = GUARD
            if color is not None:
                px[xi, yi] = color
    return image


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    strip = make_angle_strip()
    strip_path = OUT_DIR / "hwando_angles.png"
    strip.save(strip_path)

    item = make_item()
    item_path = OUT_DIR / "hwando_item.png"
    item.save(item_path)

    base = draw_hwando(CANVAS, 0.0)
    box = base.getbbox()
    print("wrote %s  %s  각도 %d단계" % (strip_path.name, strip.size, ANGLE_STEPS))
    print("wrote %s  %s" % (item_path.name, item.size))
    print("환도 실측(0도): %dx%d  전장 %dpx" % (box[2] - box[0], box[3] - box[1], box[2] - box[0]))
    print("인게임 신장 38px 대비 %.2f배. 확대 없이 그대로 오버레이한다"
          % ((box[2] - box[0]) / 38.0))
    colors = {c[1][:3] for c in strip.getcolors(9999) if c[1][3] > 0}
    print("색 %d종: %s" % (len(colors), sorted(colors)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
