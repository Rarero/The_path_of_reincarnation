#!/usr/bin/env python3
"""player_frames.tres를 클립표에서 굽는다.

이 파일은 클립 15종 x 프레임의 AtlasTexture를 나열한 800줄짜리라 손으로
고칠 물건이 아니다. 실제 정보는 아래 CLIPS 표가 전부이고 나머지는 기계적
반복이다. 검 공격 4종이 들어오면서 손편집 위험이 커져 생성으로 돌린다.

프레임 크기는 76x76 고정이고 각 클립은 가로 스트립 한 장이다.
speed는 클립 길이를 공격 정의(resources/weapons/*.tres)의 총 소요 시간에
맞춘 값이다. 어긋나면 몸이 먼저 멈추거나 판정이 먼저 끝난다.

사용법: python tools/pipeline/gen_player_frames.py
산출: scenes/player/player_frames.tres
"""

from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "scenes/player/player_frames.tres"
SRC_DIR = "res://assets/sprites/player/anim"

FRAME = 76

## (클립, 프레임 수, 순환, 속도fps)
## 공격 4종의 속도 근거:
##   attack1/2  8프레임 / 0.36초 (0.10+0.08+0.18) = 22
##   attack3   10프레임 / 0.54초 (0.14+0.10+0.30) = 18
##   air_attack 6프레임 / 0.30초 (0.08+0.10+0.12) = 20
CLIPS = [
    ("idle", 9, True, 6.0),
    ("run", 9, True, 14.0),
    ("shoot", 9, False, 20.0),
    ("reload", 9, False, 8.0),
    ("hurt", 9, False, 14.0),
    ("melee", 9, False, 15.0),
    ("jump", 3, False, 12.0),
    ("fall", 3, True, 8.0),
    ("wall", 4, True, 6.0),
    ("reload_run", 9, True, 14.0),
    ("roll", 1, False, 16.0),
    ("attack1", 8, False, 22.0),
    ("attack2", 8, False, 22.0),
    ("attack3", 10, False, 18.0),
    ("air_attack", 6, False, 20.0),
]


def main() -> int:
    steps = len(CLIPS) + sum(count for _, count, _, _ in CLIPS)
    lines = ['[gd_resource type="SpriteFrames" load_steps=%d format=3]' % (steps + 1), ""]
    for index, (clip, _count, _loop, _speed) in enumerate(CLIPS):
        lines.append('[ext_resource type="Texture2D" path="%s/player_%s_e.png" id="%d_%s"]'
                     % (SRC_DIR, clip, index + 1, clip))
    lines.append("")
    for index, (clip, count, _loop, _speed) in enumerate(CLIPS):
        for frame in range(count):
            lines.append('[sub_resource type="AtlasTexture" id="AtlasTexture_%s%d"]' % (clip, frame))
            lines.append('atlas = ExtResource("%d_%s")' % (index + 1, clip))
            lines.append("region = Rect2(%d, 0, %d, %d)" % (frame * FRAME, FRAME, FRAME))
            lines.append("")
    lines.append("[resource]")
    entries = []
    for clip, count, loop, speed in CLIPS:
        frames = ", ".join(
            '{"duration": 1.0, "texture": SubResource("AtlasTexture_%s%d")}' % (clip, frame)
            for frame in range(count)
        )
        entries.append(
            '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}'
            % (frames, "true" if loop else "false", clip, speed)
        )
    lines.append("animations = [" + ", ".join(entries) + "]")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print("wrote %s  클립 %d종" % (OUT.name, len(CLIPS)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
