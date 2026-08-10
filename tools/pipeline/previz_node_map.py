"""노드 맵 길 표시 미리보기 (scenes/ui/node_map.gd 대조용).

Godot 없이 길(간선) 표시안을 눈으로 확인하려고 만든 것이다. 배치 계산과 그리기 순서를
node_map.gd와 같게 맞춘다. 수치를 바꾸면 양쪽을 함께 고쳐야 한다.

사용법: python tools/pipeline/previz_node_map.py [--seed 0] [--scale 3]
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import sim_run_budget as S  # noqa: E402

## --- node_map.gd와 같은 값 ---
SCREEN = (480, 270)
PAPER_POS = (20, 15)
PAPER_SIZE = (440, 240)
FIELD = (90, 47, 296, 176)
ICON_HALF = 8
RING_RADIUS = 11.0
MIN_SEP = 32.0
LUMA_OK = 0.66
AVOID_MAX = 34

INK = (46, 36, 28)
INK_SOFT = (107, 89, 69)
PARCH = (237, 230, 209)

## --- 길 표시안 ---
ROAD_BED = (238, 231, 212)
ROAD_BED_WIDTH = 3
ROAD_INK = (70, 54, 38)
ROAD_OPEN_INK = (30, 24, 17)
## 이미 밟은 길 (걸어서 다져진 길)
ROAD_WALKED_INK = (60, 44, 30)
ROAD_SAG = 2.5
ROAD_WAVE = 2.2
ROAD_WAVE_MIN, ROAD_WAVE_MAX = 1.5, 2.5
ROAD_STEP = 2.0
ROAD_DASH, ROAD_GAP = 3.0, 3.0
NODE_CLEARANCE = 12.0
## 십리점: 이동 비용 1마다 점 하나 (COST_UNIT = 9px)
DOT_STEP = 9.0
SELECT_HALO = (198, 182, 150)
SELECT_HALO_RADIUS = 13.5
SELECT_HALO_ALPHA = 140

ICONS = {
    "전투": "danger.png", "중간보스": "peril.png", "이벤트": "unknown.png",
    "내기": "unknown.png", "상점": "boon.png", "쉼터": "boon.png",
    "신당": "mystery.png", "보스": "boss.png",
}


def hash_signed(n):
    h = math.sin(n * 12.9898 + 78.233) * 43758.5453
    return (h - math.floor(h)) * 2.0 - 1.0


def in_field(p):
    return FIELD[0] <= p[0] <= FIELD[0] + FIELD[2] and FIELD[1] <= p[1] <= FIELD[1] + FIELD[3]


def min_luma(paper, p):
    w, h = paper.size
    darkest = 1.0
    for ox in (-11, -5, 0, 5, 11):
        for oy in (-12, -6, 0, 6, 12):
            u = (p[0] + ox - PAPER_POS[0]) / PAPER_SIZE[0]
            v = (p[1] + oy - PAPER_POS[1]) / PAPER_SIZE[1]
            if not (0.0 <= u <= 1.0 and 0.0 <= v <= 1.0):
                continue
            px = paper.getpixel((
                int(min(max(u * (w - 1), 0), w - 1)), int(min(max(v * (h - 1), 0), h - 1))
            ))
            darkest = min(darkest, sum(px[:3]) / 3.0 / 255.0)
    return darkest


def relocate(paper, p):
    if in_field(p) and min_luma(paper, p) >= LUMA_OK:
        return p
    cx = PAPER_POS[0] + PAPER_SIZE[0] * 0.5
    best, best_score, radius = p, -1.0, 4
    while radius <= AVOID_MAX:
        for deg in range(0, 360, 15):
            a = math.radians(deg)
            c = (p[0] + math.cos(a) * radius, p[1] + math.sin(a) * radius)
            if not in_field(c):
                continue
            luma = min_luma(paper, c)
            if luma >= LUMA_OK:
                score = luma - abs(c[0] - cx) / 4000.0
                if score > best_score:
                    best_score, best = score, c
        if best_score >= 0.0:
            return best
        radius += 3
    return p


def separate(pos):
    ids = list(pos)
    for _ in range(24):
        moved = False
        for i in range(len(ids)):
            for j in range(i + 1, len(ids)):
                a, b = ids[i], ids[j]
                dx, dy = pos[b][0] - pos[a][0], pos[b][1] - pos[a][1]
                dist = math.hypot(dx, dy) or 1.0
                if dist >= MIN_SEP:
                    continue
                px, py = dx / dist * (MIN_SEP - dist) * 0.5, dy / dist * (MIN_SEP - dist) * 0.5
                na = (pos[a][0] - px, pos[a][1] - py)
                nb = (pos[b][0] + px, pos[b][1] + py)
                if in_field(na):
                    pos[a] = na
                if in_field(nb):
                    pos[b] = nb
                moved = True
        if not moved:
            return


def curve_points(a, b, edge_id):
    mx, my = (a[0] + b[0]) * 0.5, (a[1] + b[1]) * 0.5
    dx, dy = b[0] - a[0], b[1] - a[1]
    length = math.hypot(dx, dy)
    if length < 1.0:
        return [a, b], 0.0
    nx, ny = -dy / length, dx / length
    sag = hash_signed(edge_id * 3) * ROAD_SAG
    cx, cy = mx + nx * sag, my + ny * sag
    waves = ROAD_WAVE_MIN + (ROAD_WAVE_MAX - ROAD_WAVE_MIN) * (hash_signed(edge_id * 7) + 1) * 0.5
    phase = hash_signed(edge_id * 11) * math.pi
    steps = max(8, int(length / ROAD_STEP))
    out = []
    for i in range(steps + 1):
        t = i / steps
        one = 1.0 - t
        bx = one * one * a[0] + 2 * one * t * cx + t * t * b[0]
        by = one * one * a[1] + 2 * one * t * cy + t * t * b[1]
        w = math.sin(t * math.tau * waves + phase) * math.sin(t * math.pi) * ROAD_WAVE
        out.append((bx + nx * w, by + ny * w))
    return out, length


def dash_segments(points):
    dashes, current, drawing, run = [], [points[0]], True, 0.0
    for i in range(1, len(points)):
        run += math.dist(points[i - 1], points[i])
        limit = ROAD_DASH if drawing else ROAD_GAP
        if drawing:
            current.append(points[i])
        if run < limit:
            continue
        run = 0.0
        if drawing:
            if len(current) >= 2:
                dashes.append(current)
            current = []
        else:
            current = [points[i]]
        drawing = not drawing
    if drawing and len(current) >= 2:
        dashes.append(current)
    return dashes


def seg_cross(p1, p2, p3, p4):
    def cr(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    d1, d2 = cr(p3, p4, p1), cr(p3, p4, p2)
    d3, d4 = cr(p1, p2, p3), cr(p1, p2, p4)
    return (d1 > 0) != (d2 > 0) and (d3 > 0) != (d4 > 0)


def point_seg(p, a, b):
    vx, vy = b[0] - a[0], b[1] - a[1]
    L2 = vx * vx + vy * vy
    if L2 < 1e-9:
        return math.dist(p, a)
    t = max(0.0, min(1.0, ((p[0] - a[0]) * vx + (p[1] - a[1]) * vy) / L2))
    return math.dist(p, (a[0] + vx * t, a[1] + vy * t))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--scale", type=int, default=3)
    ap.add_argument("--out", default="art_src/previz/node_map_roads.png")
    ap.add_argument("--steps", type=int, default=4)
    ap.add_argument("--focus", action="store_true")
    args = ap.parse_args()

    paper = Image.open(ROOT / "assets/sprites/ui/map_paper.png").convert("RGBA")
    (points, links, kinds, start, boss, depth, _e), shape, _a = S.generate(args.seed)

    pos = {}
    for i, p in enumerate(points):
        pos[i] = relocate(paper, (FIELD[0] + p[0], FIELD[1] + p[1]))
    separate(pos)

    # 현재 위치는 시작에서 두 걸음 옮겨 둔 상태로 가정한다 (갈 수 있는 길을 보이려고)
    current = start
    visited = {start}
    walked = set()
    for _ in range(args.steps):
        fresh = [k for k in sorted(links[current]) if k not in visited and k != boss]
        if not fresh:
            break
        step = fresh[len(fresh) // 2]
        walked.add((min(current, step), max(current, step)))
        current = step
        visited.add(step)
    openable = set(links[current])

    canvas = Image.new("RGBA", SCREEN, (26, 22, 18, 255))
    canvas.alpha_composite(paper.resize(PAPER_SIZE, Image.NEAREST), PAPER_POS)
    d = ImageDraw.Draw(canvas)

    edges = sorted({(min(a, b), max(a, b)) for a in links for b in links[a]})
    roads = []
    for a, b in edges:
        pts, length = curve_points(pos[a], pos[b], a * 97 + b)
        roads.append({
            "pts": pts, "dashes": dash_segments(pts), "length": length,
            "walked": (a, b) in walked, "open": a == current or b == current,
        })

    def stroke(dashes, color, width):
        for dash in dashes:
            d.line(dash, fill=color + (255,), width=width, joint="curve")

    for r in roads:
        if r["walked"] and not r["open"]:
            d.line(r["pts"], fill=ROAD_BED + (255,), width=ROAD_BED_WIDTH, joint="curve")
        else:
            stroke(r["dashes"], ROAD_BED, ROAD_BED_WIDTH)
    for r in roads:
        if r["open"]:
            continue
        if r["walked"]:
            d.line(r["pts"], fill=ROAD_WALKED_INK + (255,), width=1, joint="curve")
        else:
            stroke(r["dashes"], ROAD_INK, 1)
    for r in roads:
        if not r["open"]:
            continue
        stroke(r["dashes"], ROAD_OPEN_INK, 2)
        count = max(1, int(round(r["length"] / DOT_STEP)))
        for k in range(1, count):
            idx = int(k / count * (len(r["pts"]) - 1))
            x, y = r["pts"][idx]
            d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=PARCH + (255,))
            d.ellipse([x - 1, y - 1, x + 1, y + 1], fill=ROAD_OPEN_INK + (255,))

    crossings = 0
    for x in range(len(edges)):
        for y in range(x + 1, len(edges)):
            e1, e2 = edges[x], edges[y]
            if len(set(e1) | set(e2)) < 4:
                continue
            if seg_cross(pos[e1[0]], pos[e1[1]], pos[e2[0]], pos[e2[1]]):
                crossings += 1

    icon_cache = {}
    for i, kind in kinds.items():
        name = ICONS[kind]
        if name not in icon_cache:
            icon_cache[name] = Image.open(ROOT / "assets/sprites/ui/nodes" / name).convert("RGBA")
        icon = icon_cache[name]
        x, y = pos[i]
        if i != current and i in openable:
            halo = Image.new("RGBA", SCREEN, (0, 0, 0, 0))
            ImageDraw.Draw(halo).ellipse(
                [x - SELECT_HALO_RADIUS, y - SELECT_HALO_RADIUS,
                 x + SELECT_HALO_RADIUS, y + SELECT_HALO_RADIUS],
                fill=SELECT_HALO + (SELECT_HALO_ALPHA,))
            canvas.alpha_composite(halo)
        canvas.alpha_composite(icon, (int(x) - ICON_HALF, int(y) - ICON_HALF))
        if i == current:
            d.ellipse([x - RING_RADIUS, y - RING_RADIUS, x + RING_RADIUS, y + RING_RADIUS],
                      outline=INK + (255,), width=2)
        elif i in openable:
            for deg in range(0, 360, 30):
                d.arc([x - RING_RADIUS, y - RING_RADIUS, x + RING_RADIUS, y + RING_RADIUS],
                      deg, deg + 15, fill=INK + (255,), width=2)
        elif i in visited:
            d.ellipse([x - RING_RADIUS, y - RING_RADIUS, x + RING_RADIUS, y + RING_RADIUS],
                      outline=INK_SOFT + (255,), width=1)

    d.text((24, 254), "%s  seed %d  node %d  edge %d  cross %d"
           % (shape, args.seed, len(points), len(edges), crossings), fill=PARCH + (255,))
    out = ROOT / args.out
    if args.focus:
        cx, cy = pos[current]
        box = (int(cx) - 60, int(cy) - 40, int(cx) + 60, int(cy) + 40)
        canvas.crop(box).resize((120 * 6, 80 * 6), Image.NEAREST).save(out)
    else:
        canvas.resize((SCREEN[0] * args.scale, SCREEN[1] * args.scale), Image.NEAREST).save(out)
    print("saved", out, "edges", len(edges), "current", current, pos[current])


if __name__ == "__main__":
    main()
