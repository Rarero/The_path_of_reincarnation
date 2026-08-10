"""서낭당 신목의 오색천을 나무에서 분리해 낡히고 바람에 나부끼는 프레임을 만든다.

생성물의 천은 폭이 일정한 곧은 막대라 색종이처럼 보인다(2026-08-05 사용자 지적).
천 가닥마다 개별 사연을 준다: 성한 것, 볕에 바랜 것, 중간이 끊긴 것, 올이 풀려
두 갈래로 갈라진 것. 그 뒤 매단 지점에서 멀어질수록 크게 흔들리는 전단으로
바람 순환 프레임을 굽는다.

출력
- bg_sinmok.png        : 천을 뺀 나무 (정지)
- bg_sinmok_ribbon.png : 천 레이어 가로 스트립 (FRAMES 프레임 순환)

의존성: pip install pillow
"""

from __future__ import annotations

import argparse
import colorsys
import math
import random
from collections import deque
from pathlib import Path

from PIL import Image

FRAMES = 4
## 천 끝이 흔들리는 최대 가로 폭 (px)
SWAY_MAX = 3.0
## 매단 지점에서 멀수록 크게 흔들리는 정도. 1이면 선형, 클수록 끝만 흔들린다
SWAY_FALLOFF = 1.5
## 결정적 재현용 시드
SEED = 20260805
## 천 레이어 최종 색 수 상한. 바랜 단계가 늘어나면 제한 팔레트 규칙을 벗어난다
RIBBON_COLORS = 28

# 오색천 5색대 (docs 요청서 022 B-5). 청, 자주, 황, 녹, 백
HUE_BANDS = ((200, 250), (300, 345), (18, 48), (78, 135))


def is_cloth(r: int, g: int, b: int) -> bool:
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    deg = h * 360
    if v > 0.62 and s < 0.20:
        return True
    if s < 0.18 or v < 0.18:
        return False
    return any(lo <= deg <= hi for lo, hi in HUE_BANDS)


def strands(img: Image.Image) -> list[list[tuple[int, int]]]:
    """세로로 긴 천 가닥만 골라 연결성분으로 반환한다."""
    w, h = img.size
    px = img.load()
    cloth = [[False] * w for _ in range(h)]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a >= 128 and is_cloth(r, g, b):
                cloth[y][x] = True
    seen = [[False] * w for _ in range(h)]
    out: list[list[tuple[int, int]]] = []
    for y in range(h):
        for x in range(w):
            if seen[y][x] or not cloth[y][x]:
                continue
            queue = deque([(x, y)])
            seen[y][x] = True
            cells: list[tuple[int, int]] = []
            while queue:
                cx, cy = queue.popleft()
                cells.append((cx, cy))
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = cx + dx, cy + dy
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and cloth[ny][nx]:
                        seen[ny][nx] = True
                        queue.append((nx, ny))
            xs = [p[0] for p in cells]
            ys = [p[1] for p in cells]
            bw, bh = max(xs) - min(xs) + 1, max(ys) - min(ys) + 1
            if bh < 10 or bh / max(1, bw) < 1.6 or len(cells) < 14:
                continue
            vals = [colorsys.rgb_to_hsv(*[c / 255 for c in px[p][:3]])[2] for p in cells]
            if sorted(vals)[len(vals) // 2] < 0.25:
                continue  # 어두운 가지 조각이 섞인 성분은 버린다
            out.append(cells)
    return out


def bleach(rgba: tuple[int, int, int, int], amount: float) -> tuple[int, int, int, int]:
    """볕에 바랜 천. 채도를 빼고 명도를 미색 쪽으로 민다."""
    r, g, b, a = rgba
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    s *= 1.0 - 0.55 * amount
    v = v + (0.72 - v) * 0.35 * amount
    rr, gg, bb = colorsys.hsv_to_rgb(h, max(0.0, s), min(1.0, v))
    return (round(rr * 255), round(gg * 255), round(bb * 255), a)


def weather(src: Image.Image, cells: list[tuple[int, int]], rng: random.Random) -> dict:
    """천 한 가닥에 사연을 준다. 반환값은 {(x, y): rgba}와 매단 지점 정보.

    가장자리는 항상 이어 붙은 채로 깎는다. 무작위로 픽셀을 흩뿌리면 올이 풀린
    천이 아니라 잡티로 보인다(2026-08-05 1차 시도 교정).
    """
    px = src.load()
    ys = [p[1] for p in cells]
    top, bottom = min(ys), max(ys)
    length = bottom - top + 1
    by_row: dict[int, list[int]] = {}
    for x, y in cells:
        by_row.setdefault(y, []).append(x)

    fate = rng.random()
    cut_at = bottom + 1
    if fate < 0.28:  # 중간이 끊긴 천
        cut_at = top + int(length * rng.uniform(0.42, 0.74))
    end_y = min(cut_at - 1, bottom)
    split_from = end_y + 1
    if 0.28 <= fate < 0.46 and length > 30:  # 올이 풀려 두 갈래
        split_from = top + int(length * rng.uniform(0.58, 0.78))
    worn = rng.uniform(0.45, 1.0) if fate < 0.46 else rng.uniform(0.1, 0.75)
    lean = rng.choice((-1, 1))  # 깎여 나가는 쪽

    out: dict[tuple[int, int], tuple[int, int, int, int]] = {}
    for y in sorted(by_row):
        if y > end_y:
            break
        row = sorted(by_row[y])
        t = (y - top) / max(1, length - 1)
        # 아래로 갈수록 폭이 준다 (이어 붙은 채로 한쪽씩 깎는다)
        keep = max(1, round(len(row) * (1.0 - 0.45 * t * t)))
        while len(row) > keep:
            row.pop(0 if lean < 0 else -1)
        # 끝동 4행은 실오라기 1~2올만 남긴다
        tail = end_y - y
        if tail <= 3 and len(row) > 1:
            row = row[: max(1, min(2, len(row) - tail))]
        # 좀먹은 구멍은 폭이 3 이상일 때만, 안쪽에 하나
        if len(row) >= 3 and rng.random() < 0.03 * t:
            row.pop(len(row) // 2)
        # 두 갈래로 터진 구간
        if y >= split_from and len(row) >= 3:
            row = [row[0], row[-1]]
        for x in row:
            amount = worn * (0.30 + 0.70 * t)
            out[(x, y)] = bleach(px[x, y], amount)
    return {"px": out, "top": top, "phase": rng.uniform(0.0, math.tau), "length": length}


def split_and_weather(src_path: Path, out_tree: Path, out_ribbon: Path) -> int:
    """천이 포함된 신목 조각을 나무와 천으로 나누고, 천을 낡혀 바람 프레임을 굽는다.

    bake_shrine_act1.py가 합본을 만든 뒤 이 함수를 이어 부른다.
    """
    src = Image.open(src_path).convert("RGBA")
    w, h = src.size
    rng = random.Random(SEED)

    found = strands(src)
    tree = src.copy()
    tp = tree.load()
    for cells in found:
        for x, y in cells:
            tp[x, y] = (0, 0, 0, 0)

    weathered = [weather(src, c, rng) for c in found]

    strip = Image.new("RGBA", (w * FRAMES, h), (0, 0, 0, 0))
    for f in range(FRAMES):
        frame = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        fp = frame.load()
        wind = math.sin(math.tau * f / FRAMES)
        for st in weathered:
            amp = SWAY_MAX * (0.55 + 0.45 * min(1.0, st["length"] / 120.0))
            for (x, y), c in st["px"].items():
                t = (y - st["top"]) / max(1.0, st["length"] - 1)
                shift = round(amp * math.sin(math.tau * f / FRAMES + st["phase"]) * (t**SWAY_FALLOFF))
                nx = x + shift
                if 0 <= nx < w:
                    fp[nx, y] = c
        strip.alpha_composite(frame, (f * w, 0))
        _ = wind

    strip = quantize_rgb(strip, RIBBON_COLORS)

    out_tree.parent.mkdir(parents=True, exist_ok=True)
    out_ribbon.parent.mkdir(parents=True, exist_ok=True)
    tree.save(out_tree, "PNG")
    strip.save(out_ribbon, "PNG")
    print(
        f"천 {len(found)}가닥 분리. 나무 {out_tree.name} {tree.size}, "
        f"천 {out_ribbon.name} {strip.size} ({FRAMES}프레임)"
    )
    return len(found)


def quantize_rgb(img: Image.Image, colors: int) -> Image.Image:
    """알파를 보존한 채 RGB만 제한 색으로 줄인다 (ART_STYLE 3장 제한 팔레트)."""
    alpha = img.getchannel("A")
    q = img.convert("RGB").quantize(colors=colors, dither=Image.Dither.NONE)
    out = q.convert("RGBA")
    out.putalpha(alpha)
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="서낭당 오색천 분리, 낡힘, 바람 프레임")
    ap.add_argument("--src", type=Path, required=True, help="천이 포함된 신목 합본 PNG")
    ap.add_argument("--out-tree", type=Path, required=True)
    ap.add_argument("--out-ribbon", type=Path, required=True)
    a = ap.parse_args()
    split_and_weather(a.src, a.out_tree, a.out_ribbon)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
