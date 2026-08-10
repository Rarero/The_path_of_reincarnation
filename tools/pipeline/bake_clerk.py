# -*- coding: utf-8 -*-
"""접수 관원(접수청 서기) 스프라이트 굽기.

원본은 art_src/generated/pixellab/chars/char_clerk_v4.zip이다. 48픽셀 캔버스,
사이드스크롤러, 정면으로 뽑은 전신 서 있는 자세이며 인물이 32x46으로 나온다.
축소 없이 그대로 쓴다. 씬에서 scale을 주면 픽셀이 고르지 않게 깨진다.

배치는 차사와 같다. 카운터 앞 바닥에 서고 발치가 월드 160(바닥선)에 닿는다.
창구 안에 넣는 안은 폐기했다 (2026-08-09 사용자 지시). 창 개구부가 폭 25뿐이라
어떤 원본을 써도 몸이 잘려 보였다.

PixelLab은 정지 스틸만 준다. 동작은 여기서 픽셀 이동으로 만든다. 늙고 지친
서기라 전부 느리게 돌린다. 놀람만 조금 빠르다 (사용자 지침).

산출물
- assets/sprites/npc/clerk_work_s.png      4프레임. 숨과 끄덕임
- assets/sprites/npc/clerk_stamp_s.png     4프레임. 장부를 고쳐 든다
- assets/sprites/npc/clerk_spaceout_s.png  4프레임. 고개가 떨어졌다 든다
- assets/sprites/npc/clerk_startled_s.png  2프레임. 놀라 고개를 든다
- assets/sprites/npc/clerk_frames.tres     SpriteFrames

실행: python tools/pipeline/bake_clerk.py
"""

from __future__ import annotations

import pathlib
import sys
import zipfile

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC_ZIP = ROOT / "art_src/generated/pixellab/chars/char_clerk_v4.zip"
WORK = ROOT / "art_src/work/clerk"
NPC_OUT = ROOT / "assets/sprites/npc"

## 인게임 칸. 원본 인물 크기 그대로다
CELL_W, CELL_H = 32, 46

## 갓 끝부터 턱 아래까지. 끄덕임은 이 구간만 움직인다
HEAD_BAND = (0, 26)
## 장부를 든 팔 구간
ARMS_BAND = (26, 40)
BODY_BAND = (0, CELL_H)


def _trim(image: Image.Image) -> Image.Image:
    box = np.argwhere(np.array(image)[:, :, 3] > 0)
    return image.crop(
        (box[:, 1].min(), box[:, 0].min(), box[:, 1].max() + 1, box[:, 0].max() + 1)
    )


def _shift(image: Image.Image, band: tuple[int, int], dy: int) -> Image.Image:
    if dy == 0:
        return image.copy()
    top, bottom = band
    out = image.copy()
    strip = image.crop((0, top, CELL_W, bottom))
    out.paste((0, 0, 0, 0), (0, top, CELL_W, bottom))
    out.alpha_composite(strip, (0, max(0, top + dy)))
    return out


def _strip(frames: list[Image.Image], name: str) -> None:
    sheet = Image.new("RGBA", (CELL_W * len(frames), CELL_H), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * CELL_W, 0))
    NPC_OUT.mkdir(parents=True, exist_ok=True)
    sheet.save(NPC_OUT / name)
    print("%s  %dx%d  %d프레임" % (name, sheet.width, sheet.height, len(frames)))


FRAMES = [
    ("work", "clerk_work_s.png", [0, 1, 2, 3], 3.0, True),
    ("work_scroll", "clerk_stamp_s.png", [0, 1, 2, 3], 2.4, True),
    ("spaceout", "clerk_spaceout_s.png", [0, 1, 2, 3], 2.0, True),
    ("startled", "clerk_startled_s.png", [0, 1], 4.0, False),
]


def _write_frames() -> None:
    textures: list[str] = []
    for _name, source, _indices, _fps, _loop in FRAMES:
        if source not in textures:
            textures.append(source)
    subs: list[str] = []
    anims: list[str] = []
    for name, source, indices, fps, loop in FRAMES:
        ext_id = "%d_%s" % (textures.index(source) + 1, pathlib.Path(source).stem)
        refs: list[str] = []
        for order, index in enumerate(indices):
            sub_id = "AtlasTexture_%s%d" % (name, order)
            subs.append(
                '[sub_resource type="AtlasTexture" id="%s"]\n'
                'atlas = ExtResource("%s")\n'
                "region = Rect2(%d, 0, %d, %d)\n"
                % (sub_id, ext_id, index * CELL_W, CELL_W, CELL_H)
            )
            refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sub_id)
        anims.append(
            '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
            % (",".join(refs), "true" if loop else "false", name, fps)
        )
    lines = [
        '[gd_resource type="SpriteFrames" load_steps=%d format=3]\n'
        % (1 + len(textures) + len(subs))
    ]
    for source in textures:
        lines.append(
            '[ext_resource type="Texture2D" path="res://assets/sprites/npc/%s" id="%d_%s"]'
            % (source, textures.index(source) + 1, pathlib.Path(source).stem)
        )
    lines.append("")
    lines.extend(subs)
    lines.append("[resource]")
    lines.append("animations = [%s]" % ",".join(anims))
    (NPC_OUT / "clerk_frames.tres").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("clerk_frames.tres  클립 %d종" % len(FRAMES))


def main() -> int:
    if not SRC_ZIP.exists():
        print("원본 없음: %s" % SRC_ZIP)
        return 1
    WORK.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(SRC_ZIP) as archive:
        archive.extractall(WORK)

    south = WORK / "Idle/rotations/south.png"
    if not south.exists():
        print("정면 스틸 없음: %s" % south)
        return 1
    base = _trim(Image.open(south).convert("RGBA"))
    if base.size != (CELL_W, CELL_H):
        print("인물 크기가 %s다. CELL 값을 맞춰야 한다" % (base.size,))
        return 1

    _strip(
        [base, _shift(base, HEAD_BAND, 1), base, _shift(base, BODY_BAND, 1)],
        "clerk_work_s.png",
    )
    _strip(
        [base, _shift(base, ARMS_BAND, -1), _shift(base, ARMS_BAND, -1), base],
        "clerk_stamp_s.png",
    )
    _strip(
        [
            _shift(base, HEAD_BAND, 1),
            _shift(base, HEAD_BAND, 2),
            _shift(base, HEAD_BAND, 3),
            _shift(base, HEAD_BAND, 2),
        ],
        "clerk_spaceout_s.png",
    )
    _strip([_shift(base, HEAD_BAND, -1), _shift(base, BODY_BAND, -2)], "clerk_startled_s.png")
    _write_frames()
    return 0


if __name__ == "__main__":
    sys.exit(main())
