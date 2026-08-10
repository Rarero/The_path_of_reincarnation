#!/usr/bin/env python3
"""씨름꾼 스프라이트 인게임 굽기 (요청서 023 1번).

PixelLab Characters v3 산출물(92x92, 8방향 Idle)에서 옆모습을 뽑아
기존 캐릭터 규격(76x76 캔버스, 가로 중심 40, 발밑 57)에 맞춰 다시 놓는다.
그 규격이 scenes/minigame/ssireum_minigame.gd의 ART_CENTER와 같아서
스프라이트만 갈아끼우면 코드를 건드리지 않아도 된다.

사용법: python tools/pipeline/bake_wrestler.py <풀린 zip 폴더>
산출: assets/sprites/enemies/wrestler_idle_e.png
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
OUT = ROOT / "assets/sprites/enemies/wrestler_idle_e.png"

## 기존 캐릭터 스프라이트와 같은 캔버스와 기준점 (dokkaebi_frames.tres, player_frames.tres)
CANVAS: int = 76
## 캔버스 안에서 캐릭터의 가로 중심과 발밑
ANCHOR = (40, 57)
## 알파 이진화 문턱. 반투명 가장자리를 없앤다 (ART_STYLE 후처리 규칙)
ALPHA_CUT: int = 128


def binarize(image: Image.Image) -> Image.Image:
    red, green, blue, alpha = image.split()
    alpha = alpha.point(lambda value: 255 if value >= ALPHA_CUT else 0)
    return Image.merge("RGBA", (red, green, blue, alpha))


def place(source: Image.Image) -> Image.Image:
    box = source.getbbox()
    if box is None:
        raise SystemExit("빈 이미지다")
    left, top, right, bottom = box
    center_x = (left + right) / 2.0
    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    offset = (int(round(ANCHOR[0] - center_x)), ANCHOR[1] - bottom)
    canvas.alpha_composite(source, offset)
    return canvas


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    src_dir = Path(sys.argv[1])
    east = src_dir / "Idle/rotations/east.png"
    if not east.exists():
        print("east.png를 찾지 못했다: %s" % east)
        return 1
    baked = place(binarize(Image.open(east).convert("RGBA")))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    baked.save(OUT)
    print("wrote %s %s bbox=%s" % (OUT, baked.size, baked.getbbox()))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
