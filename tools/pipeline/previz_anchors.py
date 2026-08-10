#!/usr/bin/env python3
"""앵커 검수용 미리보기 (docs/ART_WEAPON_SPLIT.md 3.4).

gen_weapon_anchors.py가 구운 hwando_anchors.tres를 그대로 읽어 맨손 클립 위에
환도를 얹는다. Godot을 켜지 않고 결합 결과를 본다. 인게임 WeaponSprite와 같은
식으로 계산하므로(그립이 각도 프레임 정중앙, 캔버스 76x76), 여기서 맞으면
엔진에서도 맞는다.

사용법: python tools/pipeline/previz_anchors.py [클립 ...]
산출: art_src/previz/anchor_<클립>.png
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
ANCHORS = ROOT / "resources/weapons/hwando_anchors.tres"
ANGLES = ROOT / "assets/sprites/weapons/hwando_angles.png"
BARE_DIR = ROOT / "art_src/work/body"
OUT_DIR = ROOT / "art_src/previz"

CANVAS = 76
SCALE = 5


def load_anchors() -> dict:
    text = ANCHORS.read_text(encoding="utf-8")
    table = {}
    for name, body in re.findall(r'&"(\w+)": PackedInt32Array\(([^)]*)\)', text):
        values = [int(v) for v in body.split(",") if v.strip()]
        table[name] = [values[i:i + 4] for i in range(0, len(values), 4)]
    return table


def load_angles() -> list:
    strip = Image.open(ANGLES).convert("RGBA")
    size = strip.height
    return [strip.crop((i * size, 0, (i + 1) * size, size))
            for i in range(strip.width // size)]


def build(clip: str, anchors: list, angles: list) -> bool:
    src = BARE_DIR / ("player_bare_%s_e.png" % clip)
    if not src.exists():
        print("  건너뜀 %-11s (맨손 클립 없음)" % clip)
        return False
    body = Image.open(src).convert("RGBA")
    count = body.width // CANVAS
    sheet = Image.new("RGBA", (CANVAS * count, CANVAS), (26, 24, 38, 255))
    for index in range(count):
        frame = body.crop((CANVAS * index, 0, CANVAS * (index + 1), CANVAS))
        if index < len(anchors):
            hx, hy, angle, shown = anchors[index]
            if shown:
                weapon = angles[angle % len(angles)]
                half = weapon.width // 2
                frame.alpha_composite(weapon, (hx - half, hy - half))
        sheet.alpha_composite(frame, (CANVAS * index, 0))
    big = sheet.resize((sheet.width * SCALE, sheet.height * SCALE), Image.NEAREST)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / ("anchor_%s.png" % clip)
    big.save(out)
    print("  %-11s %2d프레임 -> %s" % (clip, count, out.name))
    return True


def main() -> int:
    table = load_anchors()
    angles = load_angles()
    wanted = sys.argv[1:] or sorted(table)
    for clip in wanted:
        if clip not in table:
            print("  앵커 없음: %s" % clip)
            continue
        build(clip, table[clip], angles)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
