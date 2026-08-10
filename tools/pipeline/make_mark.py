# -*- coding: utf-8 -*-
"""상호작용 표식(느낌표) 아이콘 굽기.

라벨 글자로 찍던 것을 그림으로 바꾼다. 허브 배경이 어둡고 등불 색이 섞여 있어
글자 느낌표는 배경에 묻혔다 (사용자 지적). 등불과 같은 호박색에 어두운 외곽선을
둘러 어디에 놓아도 떠 보이게 한다.

4프레임으로 1픽셀씩 오르내려 시선을 끈다. 정적 표식은 눈에 안 들어온다.

산출물: assets/sprites/ui/mark_alert.png (4프레임), mark_alert_frames.tres
실행: python tools/pipeline/make_mark.py
"""

from __future__ import annotations

import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/sprites/ui"

CELL_W, CELL_H = 9, 18

PALETTE = {
    ".": None,
    "O": (26, 20, 24),        # 외곽선
    "A": (240, 176, 62),      # 호박색 본체
    "H": (255, 226, 148),     # 밝은 면
    "a": (188, 118, 36),      # 그늘
    "g": (250, 200, 110),     # 바깥 번짐 (반투명)
}
## 외곽선 바깥에 한 겹 두르는 번짐의 알파. 배경과 섞여 빛무리처럼 보인다
GLOW_ALPHA = 64

MARK = [
    ".........",
    "..OOOOO..",
    "..OAHAO..",
    "..OAHAO..",
    "..OAHAO..",
    "..OAHAO..",
    "..OAHAO..",
    "..OaaaO..",
    "..OOOOO..",
    ".........",
    "..OOOOO..",
    "..OAHAO..",
    "..OaaaO..",
    "..OOOOO..",
    ".........",
    ".........",
    ".........",
    ".........",
]


def _grid(rows: list[str], dy: int) -> Image.Image:
    image = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    pixels = image.load()
    solid: list[tuple[int, int]] = []
    for y, row in enumerate(rows):
        target = y + dy
        if not 0 <= target < CELL_H:
            continue
        for x, key in enumerate(row):
            color = PALETTE.get(key)
            if color is None:
                continue
            pixels[x, target] = (*color, 255)
            solid.append((x, target))
    # 외곽선 바깥 한 겹에 옅은 호박빛을 둘러 어두운 나무 위에서도 떠 보이게 한다
    filled = set(solid)
    for x, y in solid:
        for dx, dy2 in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = x + dx, y + dy2
            if 0 <= nx < CELL_W and 0 <= ny < CELL_H and (nx, ny) not in filled:
                if pixels[nx, ny][3] == 0:
                    pixels[nx, ny] = (*PALETTE["g"], GLOW_ALPHA)
    return image


FRAMES_TRES = """[gd_resource type="SpriteFrames" load_steps=6 format=3]

[ext_resource type="Texture2D" path="res://assets/sprites/ui/mark_alert.png" id="1_mark"]

[sub_resource type="AtlasTexture" id="AtlasTexture_mark0"]
atlas = ExtResource("1_mark")
region = Rect2(0, 0, 9, 18)

[sub_resource type="AtlasTexture" id="AtlasTexture_mark1"]
atlas = ExtResource("1_mark")
region = Rect2(9, 0, 9, 18)

[sub_resource type="AtlasTexture" id="AtlasTexture_mark2"]
atlas = ExtResource("1_mark")
region = Rect2(18, 0, 9, 18)

[sub_resource type="AtlasTexture" id="AtlasTexture_mark3"]
atlas = ExtResource("1_mark")
region = Rect2(27, 0, 9, 18)

[resource]
animations = [{
"frames": [{
"duration": 1.0,
"texture": SubResource("AtlasTexture_mark0")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_mark1")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_mark2")
}, {
"duration": 1.0,
"texture": SubResource("AtlasTexture_mark3")
}],
"loop": true,
"name": &"bob",
"speed": 4.0
}]
"""


def main() -> int:
    # 위로 1픽셀 떴다가 내려온다. 값을 0 1 2 1로 두면 오르내림이 고르다
    offsets = [0, 1, 2, 1]
    sheet = Image.new("RGBA", (CELL_W * len(offsets), CELL_H), (0, 0, 0, 0))
    for index, dy in enumerate(offsets):
        sheet.alpha_composite(_grid(MARK, dy), (index * CELL_W, 0))
    OUT.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT / "mark_alert.png")
    (OUT / "mark_alert_frames.tres").write_text(FRAMES_TRES, encoding="utf-8")
    print("mark_alert.png  %dx%d  %d프레임" % (sheet.width, sheet.height, len(offsets)))
    print("mark_alert_frames.tres 완료")
    return 0


if __name__ == "__main__":
    sys.exit(main())
