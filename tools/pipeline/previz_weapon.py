#!/usr/bin/env python3
"""무기 오버레이 미리보기 (docs/ART_WEAPON_SPLIT.md 3.4).

맨손 몸 클립 위에 무기 각도 프레임을 앵커대로 얹어 스트립으로 출력한다.
Godot 없이 결합 결과를 확인하는 것이 목적이며, 앵커 주석 작업의 도구다.

앵커 규격 (3.3):
  클립 이름 -> 프레임마다 [x, y, angle_index, visible]
  x y   몸 클립 캔버스(72x72) 안의 손 위치. 무기 각도 프레임의 정중앙(그립)이 여기 온다
  angle_index  hwando_angles.png의 프레임 번호. 16단계이므로 한 칸이 22.5도다
  visible      false면 그 프레임은 무기를 그리지 않는다. 타격 순간은 참격
               이펙트가 무기를 대신하므로 꺼 둔다 (2026-08-07 사용자 확정)

사용법: python tools/pipeline/previz_weapon.py <풀린 export 폴더> [클립 ...]
산출: art_src/previz/weapon_<클립>.png
"""

from __future__ import annotations

import glob
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
ANGLES = ROOT / "assets/sprites/weapons/hwando_angles.png"
OUT_DIR = ROOT / "art_src/previz"

## export 폴더 안 애니메이션 폴더를 찾는 부분 문자열
NEEDLE = {
    "idle": "standing_still_in_a_relaxed",
    "run": "running_forward_at_full_stride",
    "attack1": "a_wide_diagonal_sword_swing",
    "attack2": "a_rising_sword_swing",
    "attack3": "a_heavy_finishing_overhead",
    "air_attack": "an_airborne_downward_strike",
    "jump": "jumping_upward_off_the_ground",
    "fall": "falling_downward_through_the_air",
    "wall": "clinging_to_a_wall",
    "hurt": "recoiling_backward_from_a_hit",
}

## 앵커 초안. 프레임마다 [x, y, angle_index, visible]
## 1차값은 idle 실측(손 x36 y41)에서 출발했다. 클립별 정밀 주석은 이 도구로 보며 잡는다
ANCHORS: dict[str, list] = {
    "idle": [[36, 41, 15, True]] * 9,
    "run": [
        [36, 41, 14, True], [36, 41, 14, True], [37, 42, 13, True],
        [37, 42, 13, True], [36, 41, 14, True], [36, 41, 14, True],
        [37, 42, 13, True], [37, 42, 13, True], [36, 41, 14, True],
    ],
    ## 공격은 예비 구간만 무기를 얹고 타격 순간은 참격 이펙트가 대신한다
    "attack2": [
        [36, 42, 13, True], [36, 41, 14, True], [35, 40, 1, True],
        [35, 38, 2, False], [36, 36, 3, False], [37, 35, 4, False],
        [37, 36, 3, True], [37, 38, 2, True],
    ],
    "attack3": [
        [36, 41, 14, True], [36, 39, 3, True], [36, 36, 5, True],
        [36, 34, 6, True], [36, 34, 6, False], [36, 37, 15, False],
        [36, 40, 14, False], [36, 42, 13, True], [36, 42, 13, True],
        [36, 41, 14, True],
    ],
}

FALLBACK = [36, 41, 15, True]


def load_angles() -> list[Image.Image]:
    strip = Image.open(ANGLES).convert("RGBA")
    size = strip.height
    count = strip.width // size
    return [strip.crop((i * size, 0, (i + 1) * size, size)) for i in range(count)]


def overlay(body: Image.Image, weapon: Image.Image, anchor) -> Image.Image:
    out = body.copy()
    x, y, index, visible = anchor
    if not visible:
        return out
    half = weapon.width // 2
    out.alpha_composite(weapon, (int(x) - half, int(y) - half))
    return out


def build(clip: str, export_root: Path, angles: list[Image.Image], scale: int = 6):
    hits = [p for p in glob.glob(str(export_root / "*/animations/*/east")) if NEEDLE[clip] in p]
    if not hits:
        print("  건너뜀 %-11s (원본 없음)" % clip)
        return False
    frames = sorted(glob.glob(hits[0] + "/frame_*.png"))
    table = ANCHORS.get(clip, [])
    sheet = None
    for index, path in enumerate(frames):
        body = Image.open(path).convert("RGBA")
        anchor = table[index] if index < len(table) else FALLBACK
        merged = overlay(body, angles[anchor[2] % len(angles)], anchor)
        if sheet is None:
            sheet = Image.new("RGBA", (body.width * len(frames), body.height), (26, 24, 38, 255))
        sheet.alpha_composite(merged, (body.width * index, 0))
    big = sheet.resize((sheet.width * scale, sheet.height * scale), Image.NEAREST)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / ("weapon_%s.png" % clip)
    big.save(out)
    print("  %-11s %d프레임 -> %s" % (clip, len(frames), out.name))
    return True


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    export_root = Path(sys.argv[1])
    if not export_root.is_dir():
        print("폴더가 아니다: %s" % export_root)
        return 1
    wanted = sys.argv[2:] or list(NEEDLE)
    angles = load_angles()
    print("각도 프레임 %d장, 캔버스 %dx%d" % (len(angles), angles[0].width, angles[0].height))
    for clip in wanted:
        if clip not in NEEDLE:
            print("모르는 클립: %s" % clip)
            continue
        build(clip, export_root, angles)
    print("앵커가 없는 클립은 idle 앵커로 임시 표시된다. 보면서 ANCHORS에 채운다")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
