#!/usr/bin/env python3
"""무기 오버레이 앵커를 인게임 좌표계로 굽는다 (docs/ART_WEAPON_SPLIT.md 3.3).

앵커는 손 위치다. 손을 눈으로 찍지 않고 계산으로 얻는다. 근거는 이렇다.
소총을 쥔 클립에서 소총 픽셀만 지운 것이 맨손 클립이므로(strip_rifle.py),
두 장의 차이가 곧 "소총이 있던 자리"다. 그 자리의 가장 몸쪽 끝이 손잡이를
쥐던 지점, 즉 손이다. 사람이 프레임마다 찍는 것보다 정확하고 재현된다.

파지 자세를 그대로 두고 그 자리에 환도를 얹는다는 2026-08-07 결정이
이 계산을 성립시킨다. 손을 다시 그렸다면 쓸 수 없는 방법이다.

각도와 표시 여부는 계산으로 나오지 않으므로 아래 표에 적는다. 타격 순간은
무기를 끄고 참격 이펙트가 대신한다(ART_WEAPON_SPLIT 6장 확인 1).

각도 규약: hwando_angles.png의 index i는 22.5 x i 도이며 0이 오른쪽 수평,
증가 방향이 반시계(화면 위쪽)다. gen_hwando.py와 같은 규약이다.

입력: art_src/work/sword/rifle_ref/player_<클립>_e.png  (소총 파지 원본 스냅샷)
      art_src/work/body/player_bare_<클립>_e.png        (맨손 클립)
산출: resources/weapons/hwando_anchors.tres
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
REF_DIR = ROOT / "art_src/work/sword/rifle_ref"
BARE_DIR = ROOT / "art_src/work/body"
OUT = ROOT / "resources/weapons/hwando_anchors.tres"

CANVAS = 76
ANGLE_STEPS = 16

## derive_attacks.py의 SEQUENCES와 같은 값이어야 한다. 공격 클립의 프레임이
## melee 원본 어느 프레임에서 왔는지가 손 위치를 결정한다
SEQUENCES: dict[str, list] = {
    "attack1": [2, 3, 4, 5, 6, 7, 8, 0],
    "attack2": [3, 4, 5, 6, 7, 8, 0, 1],
    "attack3": [0, 1, 2, 3, 4, 5, 6, 7, 8, 0],
    "air_attack": [4, 5, 6, 7, 8, 0],
}

BASE_CLIPS = ["idle", "run", "jump", "fall", "wall", "hurt", "melee"]

## 프레임별 [각도 index, 표시 여부]. 표시가 0인 구간은 참격 이펙트가 대신한다
POSE: dict[str, list] = {
    "idle": [[15, 1]] * 9,
    "run": [[15, 1], [15, 1], [14, 1], [14, 1], [15, 1],
            [15, 1], [14, 1], [14, 1], [15, 1]],
    "jump": [[15, 1], [15, 1], [14, 1]],
    "fall": [[14, 1], [14, 1], [14, 1]],
    ## 벽 매달림은 칼끝이 바닥을 파고들지 않게 수평에 가깝게 든다
    "wall": [[14, 1], [14, 1], [14, 1], [14, 1]],
    "hurt": [[15, 1], [0, 1], [1, 1], [1, 1], [0, 1],
             [15, 1], [15, 1], [15, 1], [15, 1]],
    "melee": [[15, 0]] * 9,
    "attack1": [[3, 1], [2, 1], [0, 0], [15, 0], [0, 1],
                [15, 1], [15, 1], [15, 1]],
    "attack2": [[13, 1], [12, 1], [14, 0], [1, 0], [2, 1],
                [1, 1], [15, 1], [15, 1]],
    "attack3": [[15, 1], [1, 1], [3, 1], [5, 1], [6, 1],
                [4, 0], [1, 0], [14, 1], [14, 1], [15, 1]],
    "air_attack": [[5, 1], [2, 0], [14, 0], [13, 1], [13, 1], [14, 1]],
}

FALLBACK = (36, 41)


def grips(clip: str) -> list:
    ref = REF_DIR / ("player_%s_e.png" % clip)
    bare = BARE_DIR / ("player_bare_%s_e.png" % clip)
    if not ref.exists() or not bare.exists():
        return []
    a = Image.open(ref).convert("RGBA")
    b = Image.open(bare).convert("RGBA")
    count = min(a.width, b.width) // CANVAS
    out = []
    for index in range(count):
        pa = a.crop((CANVAS * index, 0, CANVAS * (index + 1), CANVAS)).load()
        pb = b.crop((CANVAS * index, 0, CANVAS * (index + 1), CANVAS)).load()
        removed = [(x, y) for y in range(CANVAS) for x in range(CANVAS)
                   if pa[x, y] != pb[x, y]]
        if not removed:
            out.append(FALLBACK)
            continue
        ## 손은 소총이 있던 자리의 몸쪽 끝이다. 총열은 앞으로 길게 뻗으므로
        ## x 하위 사분위가 개머리판과 손잡이 구간이고 그 중앙이 손에 해당한다
        xs = sorted(x for x, _ in removed)
        cut = xs[len(xs) // 4]
        ys = sorted(y for x, y in removed if x <= cut + 2)
        out.append((cut, ys[len(ys) // 2]))
    return out


def main() -> int:
    table: dict[str, list] = {}
    base: dict[str, list] = {}
    for clip in BASE_CLIPS:
        found = grips(clip)
        if not found:
            print("  건너뜀 %-11s (원본 짝 없음)" % clip)
            continue
        base[clip] = found
        table[clip] = found
    for name, sequence in SEQUENCES.items():
        if "melee" not in base:
            continue
        table[name] = [base["melee"][pick] for pick in sequence]

    lines = []
    for clip in sorted(table):
        pose = POSE.get(clip)
        if pose is None:
            print("  자세표 없음: %s" % clip)
            continue
        hands = table[clip]
        if len(pose) != len(hands):
            print("  프레임 수 불일치 %-11s 자세 %d 손 %d" % (clip, len(pose), len(hands)))
            continue
        flat = []
        for (hx, hy), (angle, shown) in zip(hands, pose):
            flat += [hx, hy, angle % ANGLE_STEPS, shown]
        values = ", ".join(str(v) for v in flat)
        lines.append('&"%s": PackedInt32Array(%s)' % (clip, values))
        print("  %-11s %2d프레임  손 %s" % (clip, len(hands), hands[0]))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    text = (
        '[gd_resource type="Resource" script_class="WeaponAnchorSet" '
        'load_steps=2 format=3]\n\n'
        '[ext_resource type="Script" '
        'path="res://scripts/data/weapon_anchor_set.gd" id="1_anchors"]\n\n'
        "[resource]\n"
        'script = ExtResource("1_anchors")\n'
        + "canvas = %d\n" % CANVAS
        + "angle_steps = %d\n" % ANGLE_STEPS
        + "clips = {\n"
        + ",\n".join(lines)
        + "\n}\n"
    )
    OUT.write_text(text, encoding="utf-8")
    print("wrote %s  클립 %d종" % (OUT.name, len(lines)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
