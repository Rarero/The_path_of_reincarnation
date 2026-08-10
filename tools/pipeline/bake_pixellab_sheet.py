"""PixelLab 캐릭터 프레임을 프로젝트 규격 시트로 굽는다.

프로젝트 규격 (assets/sprites/enemies/dokkaebi_*.png 기준):
  - 셀 76x76 을 가로로 이어 붙인 한 장
  - 캐릭터 발바닥이 셀 안에서 y=57, 가로는 가운데 정렬
  - AnimatedSprite2D 가 AtlasTexture 로 셀을 잘라 쓴다

사용:
  python3 tools/pipeline/bake_pixellab_sheet.py <입력시트.png> <프레임수> <출력접두사>
"""

import sys
from PIL import Image

CELL = 76
FOOT_Y = 57


def load_frames(path: str, count: int) -> list:
    sheet = Image.open(path).convert("RGBA")
    fw = sheet.width // count
    raw = [sheet.crop((i * fw, 0, (i + 1) * fw, sheet.height)) for i in range(count)]
    box = None
    for frame in raw:
        b = frame.getbbox()
        if b is None:
            continue
        box = b if box is None else (
            min(box[0], b[0]), min(box[1], b[1]), max(box[2], b[2]), max(box[3], b[3])
        )
    return [f.crop(box) for f in raw], box


def to_cells(frames: list) -> Image.Image:
    w, h = frames[0].size
    out = Image.new("RGBA", (CELL * len(frames), CELL), (0, 0, 0, 0))
    x0 = (CELL - w) // 2
    y0 = FOOT_Y - h
    for i, f in enumerate(frames):
        out.paste(f, (i * CELL + x0, y0), f)
    return out


def bob(frame: Image.Image, count: int, amplitude: int) -> list:
    """정지 포즈 한 장으로 숨쉬는 루프를 만든다. 위아래 1~2px 만 움직인다."""
    steps = [0, -amplitude, 0, amplitude][:count]
    out = []
    for dy in steps:
        c = Image.new("RGBA", frame.size, (0, 0, 0, 0))
        c.paste(frame, (0, dy), frame)
        out.append(c)
    return out


def main() -> None:
    src, count, prefix = sys.argv[1], int(sys.argv[2]), sys.argv[3]
    frames, box = load_frames(src, count)
    print("공통 bbox", box, "프레임", frames[0].size)
    idle = frames[0]
    walk = frames[1:] if len(frames) > 1 else frames
    to_cells(bob(idle, 4, 1)).save(prefix + "_idle_e.png")
    to_cells(walk).save(prefix + "_hop_e.png")
    to_cells([idle]).save(prefix + "_attack_e.png")
    to_cells([idle]).save(prefix + "_hurt_e.png")
    print("idle 4, hop %d, attack 1, hurt 1" % len(walk))


if __name__ == "__main__":
    main()
