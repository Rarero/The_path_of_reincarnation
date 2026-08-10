#!/usr/bin/env python3
"""인게임 플레이어 클립에서 소총만 지운다 (docs/ART_WEAPON_SPLIT.md 5.1).

이 스크립트의 존재 이유가 규격 그 자체다. 플레이어 몸은 AI로 다시 그리지
않는다. 2026-08-07 Create from Reference로 몸을 재생성했다가 인물이 바뀌었고
(몸 폭 26px -> 15px, 머리 폭 18px -> 14px, 42색 중 4색만 일치), 사용자가
"캐릭터는 기존 플레이어 캐릭터를 그대로 사용한다"를 최우선 규칙으로 다시
확인했다. 그래서 몸의 원본은 assets/sprites/player/anim/의 현행 픽셀이고,
이 스크립트는 거기서 소총 픽셀만 걷어낸다. 나머지는 한 픽셀도 건드리지 않는다.

손은 다시 그리지 않는다. 소총을 쥐던 손 모양을 그대로 두고 그 자리에 환도를
오버레이한다. 파지 자세가 이미 맞아 있으므로 주먹으로 고칠 이유가 없다.

판정 방식. 단순 색 판정은 실패한다. 총열 회색(134 126 121 등)이 몸의 음영
회색과 겹치고, 목재 갈색 일부는 살색과 색상 거리가 가깝다. 그래서 세 가지를
겹쳐 쓴다.

1. 씨앗. 몸에 한 번도 안 쓰이는 총 전용 색 7종(RIFLE_ONLY)과, 허리 띠 안에서
   몸 실루엣 바깥으로 나간 x 구간(LEFT_CUT 이하, RIGHT_CUT 이상)
2. 확장. 씨앗에서 1칸만 넓힌다. 셔츠 흰색과 살색은 넘지 않는다. 1칸을 넘기면
   바지 덩어리로 새어 몸을 갉아먹는다는 것이 실험에서 확인됐다
3. 정리. 총이 몸 앞을 지나며 판 구멍은 세로로 더 가까운 쪽 픽셀로 메운다.
   위에서만 메우면 셔츠 흰색이 바지까지 흘러내린다. 그 다음 마스크 자리에
   외곽선을 복구하고, 몸과 떨어진 조각(총열 끝)을 전부 버린다

사용법: python tools/pipeline/strip_rifle.py [클립 ...]
산출: art_src/work/body/player_bare_<클립>_e.png
     검수 통과 뒤에 assets/sprites/player/anim/으로 옮긴다
"""

from __future__ import annotations

import sys
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent.parent
SRC_DIR = ROOT / "assets/sprites/player/anim"
OUT_DIR = ROOT / "art_src/work/body"

CANVAS = 76
OUTLINE = (0, 0, 0, 255)

## 인게임 idle f0의 총 픽셀과 몸 픽셀을 색별로 대조해 뽑았다.
## 이 7색은 몸 어디에도 쓰이지 않으므로 오검출 없이 씨앗으로 쓸 수 있다
RIFLE_ONLY = {
    (78, 64, 61), (100, 80, 74), (134, 126, 121),
    (68, 54, 52), (125, 99, 88), (149, 122, 111), (60, 46, 43),
}

## 클립별 판정 범위. band는 총이 지나는 y 구간, body_x는 구멍을 메울 몸통 좌우,
## left/right_cut은 band 안에서 몸 실루엣 밖으로 나간 것으로 보는 x 경계다
CLIPS: dict[str, dict] = {
    "idle": {"band": (41, 54), "body_x": (30, 46), "left_cut": 28, "right_cut": 47},
    "run": {"band": (41, 55), "body_x": (29, 46), "left_cut": 27, "right_cut": 47},
    "jump": {"band": (38, 54), "body_x": (29, 46), "left_cut": 27, "right_cut": 47},
    "fall": {"band": (38, 54), "body_x": (29, 46), "left_cut": 27, "right_cut": 47},
    "wall": {"band": (38, 56), "body_x": (29, 46), "left_cut": 27, "right_cut": 47},
    "hurt": {"band": (40, 55), "body_x": (29, 46), "left_cut": 27, "right_cut": 47},
    ## melee는 총검 찌르기라 총이 크게 움직인다. 띠와 경계를 넓게 잡는다.
    ## 이 클립이 검 공격 4종의 몸 원본이다 (tools/pipeline/derive_attacks.py)
    "melee": {"band": (36, 58), "body_x": (28, 47), "left_cut": 26, "right_cut": 48},
}


def build_mask(frame: Image.Image, spec: dict) -> set:
    px = frame.load()
    lo, hi = spec["band"]
    seeds = set()
    for y in range(lo, hi):
        for x in range(CANVAS):
            pixel = px[x, y]
            if pixel[3] == 0:
                continue
            if (pixel[:3] in RIFLE_ONLY
                    or x >= spec["right_cut"] or x <= spec["left_cut"]):
                seeds.add((x, y))
    if not seeds:
        return set()
    grown = set()
    for x, y in seeds:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < CANVAS and lo <= ny < hi):
                    continue
                pixel = px[nx, ny]
                if pixel[3] == 0 or (nx, ny) in seeds:
                    continue
                ## 셔츠 흰색과 살색은 넘지 않는다. 총열 회색은 통과시킨다
                if min(pixel[:3]) >= 150 or max(pixel[:3]) > 150:
                    continue
                grown.add((nx, ny))
    return seeds | grown


def fill_holes(image: Image.Image, mask: set, body_x: tuple) -> None:
    px = image.load()
    for x, y in sorted(mask):
        if not (body_x[0] <= x <= body_x[1]):
            continue
        up = down = None
        for distance in range(1, 8):
            if up is None and y - distance >= 0 \
                    and (x, y - distance) not in mask and px[x, y - distance][3] > 0:
                up = distance
            if down is None and y + distance < CANVAS \
                    and (x, y + distance) not in mask and px[x, y + distance][3] > 0:
                down = distance
        if up is None and down is None:
            continue
        take_up = down is None or (up is not None and up <= down)
        px[x, y] = px[x, y - up] if take_up else px[x, y + down]


def restore_outline(image: Image.Image, mask: set) -> None:
    px = image.load()
    for x, y in sorted(mask):
        if px[x, y][3]:
            continue
        neighbours = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
        solid = [(nx, ny) for nx, ny in neighbours
                 if 0 <= nx < CANVAS and 0 <= ny < CANVAS and px[nx, ny][3] > 0]
        if solid and any(max(px[nx, ny][:3]) > 60 for nx, ny in solid):
            px[x, y] = OUTLINE


def keep_largest(image: Image.Image) -> int:
    px = image.load()
    seen = [[False] * CANVAS for _ in range(CANVAS)]
    parts = []
    for y in range(CANVAS):
        for x in range(CANVAS):
            if px[x, y][3] == 0 or seen[y][x]:
                continue
            queue = deque([(x, y)])
            seen[y][x] = True
            part = []
            while queue:
                cx, cy = queue.popleft()
                part.append((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < CANVAS and 0 <= ny < CANVAS \
                                and not seen[ny][nx] and px[nx, ny][3] > 0:
                            seen[ny][nx] = True
                            queue.append((nx, ny))
            parts.append(part)
    if not parts:
        return 0
    parts.sort(key=len, reverse=True)
    dropped = 0
    for part in parts[1:]:
        for x, y in part:
            px[x, y] = (0, 0, 0, 0)
            dropped += 1
    return dropped


def strip_frame(frame: Image.Image, spec: dict) -> tuple:
    mask = build_mask(frame, spec)
    out = frame.copy()
    if not mask:
        return out, 0
    px = out.load()
    for x, y in mask:
        px[x, y] = (0, 0, 0, 0)
    fill_holes(out, mask, spec["body_x"])
    restore_outline(out, mask)
    dropped = keep_largest(out)
    return out, len(mask) + dropped


def process(clip: str) -> bool:
    src = SRC_DIR / ("player_%s_e.png" % clip)
    if not src.exists():
        print("  원본 없음: %s" % src.name)
        return False
    spec = CLIPS[clip]
    strip = Image.open(src).convert("RGBA")
    count = strip.width // CANVAS
    result = Image.new("RGBA", strip.size, (0, 0, 0, 0))
    removed = []
    for index in range(count):
        frame = strip.crop((CANVAS * index, 0, CANVAS * (index + 1), CANVAS))
        out, n = strip_frame(frame, spec)
        result.alpha_composite(out, (CANVAS * index, 0))
        removed.append(n)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_path = OUT_DIR / ("player_bare_%s_e.png" % clip)
    result.save(out_path)
    print("  %-5s %d프레임 -> %s  프레임별 제거 %s"
          % (clip, count, out_path.name, " ".join(str(n) for n in removed)))
    return True


def main() -> int:
    wanted = sys.argv[1:] or list(CLIPS)
    unknown = [name for name in wanted if name not in CLIPS]
    if unknown:
        print("모르는 클립: %s" % ", ".join(unknown))
        return 1
    print("소총 제거. 몸 픽셀은 건드리지 않는다")
    for clip in wanted:
        process(clip)
    print("결과를 눈으로 확인한 뒤 CLIPS의 band와 cut을 다듬는다")
    print("채택 전에는 assets/sprites/player/anim/으로 옮기지 않는다")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
