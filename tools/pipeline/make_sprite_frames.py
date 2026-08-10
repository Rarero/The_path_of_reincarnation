"""셀 시트들로 Godot SpriteFrames(.tres)를 만든다.

사용:
  python3 tools/pipeline/make_sprite_frames.py <출력.tres> <접두사> \
      idle:6:loop hop:10:loop attack:8:once hurt:8:once
"""

import sys
from PIL import Image

CELL = 76
BASE = "res://assets/sprites/enemies/"


def main() -> None:
    out_path, prefix = sys.argv[1], sys.argv[2]
    specs = []
    for token in sys.argv[3:]:
        name, speed, mode = token.split(":")
        specs.append((name, float(speed), mode == "loop"))

    ext_lines, anim_blocks, sub_blocks = [], [], []
    for idx, (name, speed, loop) in enumerate(specs):
        png = "%s_%s_e.png" % (prefix, name)
        img = Image.open("assets/sprites/enemies/" + png)
        count = img.width // CELL
        ext_id = "%d_%s" % (idx + 1, name)
        ext_lines.append(
            '[ext_resource type="Texture2D" path="%s%s" id="%s"]' % (BASE, png, ext_id)
        )
        frames = []
        for f in range(count):
            sub_id = "AtlasTexture_%s%d" % (name, f)
            sub_blocks.append(
                '[sub_resource type="AtlasTexture" id="%s"]\n'
                'atlas = ExtResource("%s")\n'
                "region = Rect2(%d, 0, %d, %d)\n" % (sub_id, ext_id, f * CELL, CELL, CELL)
            )
            frames.append(
                '{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sub_id
            )
        anim_blocks.append(
            '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
            % (", ".join(frames), "true" if loop else "false", name, speed)
        )

    steps = len(ext_lines) + len(sub_blocks) + 1
    body = "[gd_resource type=\"SpriteFrames\" load_steps=%d format=3]\n\n" % steps
    body += "\n".join(ext_lines) + "\n\n"
    body += "\n".join(sub_blocks) + "\n"
    body += "[resource]\nanimations = [" + ", ".join(anim_blocks) + "]\n"
    with open(out_path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(body)
    print(out_path, "애니", len(specs), "서브리소스", len(sub_blocks))


if __name__ == "__main__":
    main()
