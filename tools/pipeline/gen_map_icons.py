"""지도 노드 기호 축소 베이크 (22x22 원본 -> 16x16).

원본은 요청서 020의 손그림 기호다 (art_src/ui_src/nodes). 22px는 지도에서 기호가
커서 서로 붙어 보여 16px로 줄인다 (2026-08-06). 원본 도안 자체는 유지한다.

축소 방식: 최근접 이웃은 가는 획을 통째로 날려 먹으므로 쓰지 않는다.
알파를 면적 평균으로 줄인 뒤 임계값으로 다시 1비트로 굳힌다. 실루엣의 무게가
보존되고 획이 끊기지 않는다.

사용법: python tools/pipeline/gen_map_icons.py
"""

from __future__ import annotations

import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC_DIR = ROOT / "art_src" / "ui_src" / "nodes"
OUT_DIR = ROOT / "assets" / "sprites" / "ui" / "nodes"

## 출력 크기 (px)
SIZE = 16
## 면적 평균 알파를 다시 1비트로 굳히는 임계값 (0~255).
## 낮추면 획이 굵어지고 높이면 가늘어진다
ALPHA_THRESHOLD = 110
INK = (24, 20, 16)


def ink_bounds(img: Image.Image) -> tuple[int, int, int, int]:
    """알파가 있는 영역의 경계. 여백을 먼저 깎아야 축소 후에도 크기가 고르다."""
    bounds = img.getbbox()
    return bounds if bounds is not None else (0, 0, img.width, img.height)


def shrink(img: Image.Image) -> Image.Image:
    cropped = img.crop(ink_bounds(img))
    side = max(cropped.width, cropped.height)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(cropped, ((side - cropped.width) // 2, (side - cropped.height) // 2))
    small = square.resize((SIZE, SIZE), Image.BOX)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    src = small.load()
    dst = out.load()
    for y in range(SIZE):
        for x in range(SIZE):
            if src[x, y][3] >= ALPHA_THRESHOLD:
                dst[x, y] = INK + (255,)
    return out


def main() -> None:
    if not SRC_DIR.is_dir():
        raise SystemExit("원본 폴더가 없다: %s" % SRC_DIR)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for path in sorted(SRC_DIR.glob("*.png")):
        target = OUT_DIR / path.name
        shrink(Image.open(path).convert("RGBA")).save(target)
        print("wrote %s" % target)


if __name__ == "__main__":
    main()
