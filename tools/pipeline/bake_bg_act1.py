"""1막 배경 조각 베이크: 검정 아웃라인 제거와 야간 침전.

docs/ART_STYLE.md 5장 배경 가독성 규칙이 "배경 레이어에는 검정 아웃라인을 쓰지 않는다
(아웃라인 유무 자체가 전경/배경 구분 신호)"인데, PixelLab 생성물이 아웃라인을 포함해
나오는 바람에 배경 가판대와 파괴 가능 좌판이 같은 신호를 내고 있었다. 이 스크립트가
원본에서 아웃라인을 걷어내고 배경 쪽 침전을 구워 두 레이어를 갈라놓는다.

입력: art_src/bg_src/act1/*.png (아웃라인이 살아 있는 원본)
출력: assets/sprites/bg/act1/*.png

처리
1. 아웃라인 판정: 알파가 있고 휘도가 임계 이하인 픽셀
2. 바깥 아웃라인(투명과 맞닿음)은 깎아 낸다. 실루엣이 한 겹 얇아지고 스티커 느낌이 사라진다
3. 안쪽 아웃라인(면과 면 사이 줄눈)은 이웃 색의 평균을 눌러 채운다. 검은 선이 면의 그늘이 된다
4. 채도를 낮추고 야간 청색을 섞는다. 레이어 모듈레이트와 별개로 굽는 침전이라
   조각 자체가 이미 뒤로 물러나 있다

제외 대상 (배경이 아니거나 광원이라 이 처리를 하면 안 되는 것)
- bg_gwimun_gate: 귀문은 플레이 오브젝트다 (exit_door.tscn). 아웃라인을 유지한다
- bg_lantern_band, bg_lantern_string: 광원이라 밝기를 눌러선 안 된다
- bg_moon, bg_sky_band, bg_skyline_band: 하늘 레이어라 이미 실루엣이다

사용: python tools/pipeline/bake_bg_act1.py [--dry]
"""

from __future__ import annotations

import argparse
import pathlib
import sys

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC_DIR = ROOT / "art_src" / "bg_src" / "act1"
OUT_DIR = ROOT / "assets" / "sprites" / "bg" / "act1"

## 이 휘도 이하를 아웃라인 후보로 본다 (0~255)
OUTLINE_LUMA = 42
## 안쪽 아웃라인을 이웃 평균의 몇 배로 채울지
INNER_SHADE = 0.62
## 굽는 침전: 채도 배율, 야간 청색과 혼합비
SATURATION = 0.72
NIGHT_TINT = (0.42, 0.44, 0.72)
NIGHT_MIX = 0.16


def luma(px: tuple) -> float:
    return 0.299 * px[0] + 0.587 * px[1] + 0.114 * px[2]


def deoutline(src: Image.Image) -> Image.Image:
    w, h = src.size
    px = src.load()
    flag = [[px[x, y][3] > 0 and luma(px[x, y]) <= OUTLINE_LUMA for y in range(h)]
            for x in range(w)]
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()
    for x in range(w):
        for y in range(h):
            color = px[x, y]
            if not flag[x][y]:
                dst[x, y] = color
                continue
            touches_void = False
            samples = []
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < w and 0 <= ny < h):
                    touches_void = True
                    continue
                neighbor = px[nx, ny]
                if neighbor[3] == 0:
                    touches_void = True
                elif not flag[nx][ny]:
                    samples.append(neighbor)
            if touches_void or not samples:
                continue
            avg = [sum(s[i] for s in samples) / len(samples) for i in range(3)]
            dst[x, y] = tuple(int(v * INNER_SHADE) for v in avg) + (color[3],)
    return out


def settle(src: Image.Image) -> Image.Image:
    w, h = src.size
    px = src.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()
    for x in range(w):
        for y in range(h):
            color = px[x, y]
            if color[3] == 0:
                continue
            grey = luma(color)
            rgb = []
            for i in range(3):
                value = grey + (color[i] - grey) * SATURATION
                value = value * (1.0 - NIGHT_MIX) + 255.0 * NIGHT_TINT[i] * NIGHT_MIX
                rgb.append(int(max(0, min(255, round(value)))))
            dst[x, y] = tuple(rgb) + (color[3],)
    return out


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry", action="store_true")
    args = parser.parse_args()
    if not SRC_DIR.is_dir():
        print(f"원본 폴더가 없다: {SRC_DIR}")
        return 2
    for path in sorted(SRC_DIR.glob("*.png")):
        result = settle(deoutline(Image.open(path).convert("RGBA")))
        target = OUT_DIR / path.name
        if args.dry:
            print(f"[dry] {target}")
            continue
        result.save(target)
        print(f"wrote {target}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
