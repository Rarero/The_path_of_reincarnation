"""이동 예산과 지형 틀 시드 시뮬레이션 (docs/RUN_STRUCTURE.md 11장).

scripts/map/run_map.gd의 생성 알고리즘을 그대로 옮긴 것이다. 수치를 바꿀 때마다
이 도구로 재측정한 뒤 문서 11.4와 11.6 표를 갱신한다. 둘이 어긋나면 이 파일이 아니라
run_map.gd가 기준이다. 난수 엔진이 달라 시드 하나가 같은 지도를 주지는 않는다.
통계로만 비교한다.

사용법: python tools/sim_run_budget.py [--seeds 600]
"""

from __future__ import annotations

import argparse
import collections
import heapq
import math
import random
import statistics
import sys

## --- run_map.gd와 같은 값 ---
FIELD_W, FIELD_H = 296.0, 176.0
NODE_FLOOR = 18
MIN_SEPARATION = 32.0
LINK_RADIUS = 46.0
MAX_LINKS = 4
NODE_CLEARANCE = 12.0
COST_UNIT = 9.0
SCATTER_TRIES = 20000
TRAVEL_BUDGET = 58
SHORTEST_RATIO_MIN, SHORTEST_RATIO_MAX = 0.45, 0.85
REGEN_TRIES, REGEN_MULT, REGEN_STEP, SEED_MASK = 8, 2654435761, 40503, 0x7FFFFFFF
BOSS_APPROACH_DEPTH = 0.70

SHAPES = ["광장", "갈래", "사슬", "성단", "활꼴"]
SHAPE_TARGETS = {"광장": 30, "갈래": 26, "사슬": 27, "성단": 26, "활꼴": 24}
TARGET_JITTER = 2
SHAPE_SEED_STEP = 12345
CLUSTER_COUNT = 3
CLUSTER_RY = 70.0
ARC_BULGE, ARC_HALF = 42.0, 40.0

KIND_BANDS = {
    "이벤트": (2, 5), "신당": (1, 3), "상점": (1, 3),
    "내기": (0, 2), "중간보스": (1, 3), "쉼터": (0, 2),
}
NON_COMBAT_MIN, NON_COMBAT_MAX = 8, 14
COMBAT_SHARE_MIN = 0.50
OFF_AXIS = {"신당", "상점", "내기", "쉼터", "중간보스"}
DWELL = {
    "전투": 60, "이벤트": 45, "신당": 60, "상점": 45,
    "내기": 45, "중간보스": 120, "쉼터": 30, "보스": 0,
}
INF = 1 << 30
CY = FIELD_H * 0.5


def roll_shape(seed):
    return SHAPES[random.Random((seed * REGEN_MULT + SHAPE_SEED_STEP) & SEED_MASK).randrange(
        len(SHAPES)
    )]


def shape_params(shape, rng):
    if shape == "성단":
        return {
            "centers": [
                (FIELD_W * (i + 0.5) / CLUSTER_COUNT + rng.uniform(-6.0, 6.0),
                 CY + rng.uniform(-16.0, 16.0))
                for i in range(CLUSTER_COUNT)
            ],
            "rx": rng.uniform(32.0, 40.0),
        }
    if shape == "활꼴":
        return {"sign": 1.0 if rng.random() < 0.5 else -1.0}
    if shape == "갈래":
        return {"gap": rng.uniform(22.0, 32.0)}
    if shape == "사슬":
        return {"bands": rng.randint(5, 7), "throat": rng.uniform(14.0, 20.0)}
    return {}


def shape_accepts(shape, point, params):
    if shape == "갈래":
        return abs(point[1] - CY) >= params["gap"]
    if shape == "사슬":
        bands = params["bands"]
        index = min(bands - 1, max(0, int(point[0] / FIELD_W * bands)))
        return True if index % 2 == 0 else abs(point[1] - CY) <= params["throat"]
    if shape == "성단":
        rx, ry = params["rx"], CLUSTER_RY
        return any(
            ((point[0] - c[0]) / rx) ** 2 + ((point[1] - c[1]) / ry) ** 2 <= 1.0
            for c in params["centers"]
        )
    if shape == "활꼴":
        center = CY + params["sign"] * math.sin(point[0] / FIELD_W * math.pi) * ARC_BULGE
        return abs(point[1] - center) <= ARC_HALF
    return True


def scatter(shape, rng):
    boss = (FIELD_W - 6.0, CY)
    points = [(6.0, CY), boss]
    params = shape_params(shape, rng)
    target = SHAPE_TARGETS[shape] + rng.randint(-TARGET_JITTER, TARGET_JITTER)
    tries = 0
    while len(points) < target and tries < SCATTER_TRIES:
        tries += 1
        candidate = (rng.uniform(12.0, FIELD_W - 12.0), rng.uniform(8.0, FIELD_H - 8.0))
        if not shape_accepts(shape, candidate, params):
            continue
        if all(math.dist(candidate, p) >= MIN_SEPARATION for p in points):
            points.append(candidate)
    points.pop(1)
    points.append(boss)
    return points


def roll_composition(rng, middle, node_count):
    counts = {k: b[0] for k, b in KIND_BANDS.items()}
    total = sum(counts.values())
    pool = []
    for kind, (low, high) in KIND_BANDS.items():
        pool.extend([kind] * (high - low))
    ceiling = middle - math.ceil(COMBAT_SHARE_MIN * node_count)
    goal = min(max(rng.randint(NON_COMBAT_MIN, NON_COMBAT_MAX), total), max(total, ceiling))
    rng.shuffle(pool)
    index = 0
    while total < goal and index < len(pool):
        counts[pool[index]] += 1
        total += 1
        index += 1
    counts["전투"] = max(0, middle - total)
    return counts


def cross_product(o, a, b):
    return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])


def segments_cross(a1, a2, b1, b2):
    d1 = cross_product(b1, b2, a1)
    d2 = cross_product(b1, b2, a2)
    d3 = cross_product(a1, a2, b1)
    d4 = cross_product(a1, a2, b2)
    return (d1 > 0) != (d2 > 0) and (d3 > 0) != (d4 > 0)


def point_to_segment(point, a, b):
    vx, vy = b[0] - a[0], b[1] - a[1]
    length_sq = vx * vx + vy * vy
    if length_sq < 1e-9:
        return math.dist(point, a)
    t = max(0.0, min(1.0, ((point[0] - a[0]) * vx + (point[1] - a[1]) * vy) / length_sq))
    return math.dist(point, (a[0] + vx * t, a[1] + vy * t))


def build(seed, shape):
    rng = random.Random(seed)
    points = scatter(shape, rng)
    n = len(points)
    start, boss = 0, n - 1
    links = {i: {} for i in range(n)}
    edges = []

    def add(a, b):
        cost = max(1, round(math.dist(points[a], points[b]) / COST_UNIT))
        links[a][b] = cost
        links[b][a] = cost
        edges.append((min(a, b), max(a, b)))

    def road_is_clear(a, b):
        for c in range(n):
            if c in (a, b):
                continue
            if point_to_segment(points[c], points[a], points[b]) < NODE_CLEARANCE:
                return False
        for x, y in edges:
            if x in (a, b) or y in (a, b):
                continue
            if segments_cross(points[a], points[b], points[x], points[y]):
                return False
        return True

    pairs = sorted(
        (math.dist(points[i], points[j]), i, j)
        for i in range(n) for j in range(i + 1, n)
    )
    for distance, i, j in pairs:
        if distance > LINK_RADIUS:
            break
        if len(links[i]) >= MAX_LINKS or len(links[j]) >= MAX_LINKS:
            continue
        if not road_is_clear(i, j):
            continue
        add(i, j)

    left, right = points[start][0], points[boss][0]
    span = max(1.0, right - left)
    depth = [(p[0] - left) / span for p in points]

    for distance, i, j in pairs:
        if boss not in (i, j):
            continue
        other = i if j == boss else j
        if other == start or depth[other] < BOSS_APPROACH_DEPTH:
            continue
        if other in links[boss] or not road_is_clear(other, boss):
            continue
        add(other, boss)

    def component_owner():
        owner, group = {}, 0
        for node in range(n):
            if node in owner:
                continue
            stack = [node]
            while stack:
                u = stack.pop()
                if u in owner:
                    continue
                owner[u] = group
                stack.extend(v for v in links[u] if v not in owner)
            group += 1
        return owner

    for _ in range(n):
        owner = component_owner()
        if len(set(owner.values())) <= 1:
            break
        bridge = None
        for need_clear in (True, False):
            for distance, i, j in pairs:
                if owner[i] == owner[j]:
                    continue
                if need_clear and not road_is_clear(i, j):
                    continue
                bridge = (i, j)
                break
            if bridge is not None:
                break
        if bridge is None:
            break
        add(*bridge)

    middle = [i for i in range(n) if i not in (start, boss)]
    middle.sort(key=lambda i: abs(points[i][1] - CY), reverse=True)
    counts = roll_composition(rng, len(middle), n)
    off, on = [], []
    for kind, count in counts.items():
        (off if kind in OFF_AXIS else on).extend([kind] * count)
    rng.shuffle(on)
    queue = off + on
    kinds = {start: "전투", boss: "보스"}
    for index, node in enumerate(middle):
        kinds[node] = queue[index] if index < len(queue) else "전투"
    return points, links, kinds, start, boss, depth, edges


def dijkstra(links, source, target=None):
    dist = {source: 0}
    queue = [(0, source)]
    while queue:
        cost, node = heapq.heappop(queue)
        if target is not None and node == target:
            return cost
        if cost > dist.get(node, INF):
            continue
        for nxt, step in links[node].items():
            if cost + step < dist.get(nxt, INF):
                dist[nxt] = cost + step
                heapq.heappush(queue, (cost + step, nxt))
    return dist if target is None else dist.get(target, INF)


def generate(seed):
    shape = roll_shape(seed)
    result = None
    attempt = 0
    for attempt in range(REGEN_TRIES):
        result = build((seed * REGEN_MULT + attempt * REGEN_STEP) & SEED_MASK, shape)
        if len(result[0]) < NODE_FLOOR:
            continue
        ratio = dijkstra(result[1], result[3], result[4]) / TRAVEL_BUDGET
        if SHORTEST_RATIO_MIN <= ratio <= SHORTEST_RATIO_MAX:
            return result, shape, attempt
    return result, shape, attempt


def count_crossings(points, edges):
    bad = 0
    for x in range(len(edges)):
        for y in range(x + 1, len(edges)):
            if len(set(edges[x]) | set(edges[y])) < 4:
                continue
            a, b = edges[x]
            c, d = edges[y]
            if segments_cross(points[a], points[b], points[c], points[d]):
                bad += 1
    return bad


def mean_of(values):
    values = list(values)
    return sum(values) / len(values) if values else 0.0


def measure(seeds):
    rows = collections.defaultdict(list)
    per_shape = collections.defaultdict(list)
    shape_count = collections.Counter()
    for seed in range(seeds):
        (points, links, kinds, start, boss, depth, edges), shape, attempt = generate(seed)
        n = len(points)
        shape_count[shape] += 1
        rows["재시도"].append(attempt)
        rows["노드수"].append(n)
        rows["최단"].append(dijkstra(links, start, boss) / TRAVEL_BUDGET)
        rows["보스차수"].append(len(links[boss]))
        rows["간선"].append(len(edges))
        rows["교차"].append(count_crossings(points, edges))
        combat = sum(1 for k in kinds.values() if k == "전투") / n
        rows["전투"].append(combat)
        for label in ("신당", "이벤트", "상점", "중간보스"):
            rows[label].append(sum(1 for k in kinds.values() if k == label))
        cursor, total = start, 0
        for i, kind in kinds.items():
            if kind in OFF_AXIS:
                total += dijkstra(links, cursor, i)
                cursor = i
        total += dijkstra(links, cursor, boss)
        rows["보상순회"].append(total)
        reward = [abs(points[i][1] - CY) for i, k in kinds.items() if k in OFF_AXIS]
        fight = [abs(points[i][1] - CY) for i, k in kinds.items() if k == "전투"]
        rows["축이탈차"].append(mean_of(reward) - mean_of(fight))
        rows["최소간격"].append(min(
            math.dist(points[i], points[j]) for i in range(n) for j in range(i + 1, n)
        ))
        for i in range(n):
            if i in (start, boss) or depth[i] < BOSS_APPROACH_DEPTH:
                continue
            straight = max(1, round(math.dist(points[i], points[boss]) / COST_UNIT))
            rows["우회배율"].append(dijkstra(links, i, boss) / straight)
            rows["직결"].append(1.0 if boss in links[i] else 0.0)
        per_shape[shape].append((n, rows["최단"][-1], combat))
    return rows, per_shape, shape_count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seeds", type=int, default=600)
    args = parser.parse_args()
    rows, per_shape, shape_count = measure(args.seeds)
    avg = statistics.mean
    print("시드 %d" % args.seeds)
    print("  재시도 평균 %.2f (최대 %d)" % (avg(rows["재시도"]), max(rows["재시도"])))
    print("  노드 수 %.1f (%d~%d)" % (
        avg(rows["노드수"]), min(rows["노드수"]), max(rows["노드수"])))
    print("  최단/예산 %.0f%% (%.0f~%.0f)" % (
        avg(rows["최단"]) * 100, min(rows["최단"]) * 100, max(rows["최단"]) * 100))
    print("  전투 비율 %.0f%% (%.0f~%.0f)" % (
        avg(rows["전투"]) * 100, min(rows["전투"]) * 100, max(rows["전투"]) * 100))
    print("  보상 순회 %.0f (예산 초과 %.0f%%)" % (
        avg(rows["보상순회"]),
        sum(1 for v in rows["보상순회"] if v > TRAVEL_BUDGET) / args.seeds * 100))
    for label in ("신당", "상점", "이벤트", "중간보스"):
        print("  %-4s %.1f (%d~%d)" % (
            label, avg(rows[label]), min(rows[label]), max(rows[label])))
    print("  보스 차수 %.1f   우회배율 %.2f (최악 %.1f)   직결 %.0f%%" % (
        avg(rows["보스차수"]), avg(rows["우회배율"]), max(rows["우회배율"]),
        avg(rows["직결"]) * 100))
    print("  간선 %.1f   길끼리 교차 %.2f건 (최대 %d)" % (
        avg(rows["간선"]), avg(rows["교차"]), max(rows["교차"])))
    print("  보상 축이탈 우위 %.1fpx (최소 %.1f)   실측 최소 간격 %.1fpx" % (
        avg(rows["축이탈차"]), min(rows["축이탈차"]), min(rows["최소간격"])))
    print("  지형 틀별 (표본 / 노드 수 / 최단 / 전투)")
    for shape in SHAPES:
        values = per_shape[shape]
        if not values:
            continue
        print("    %-3s %4d   %4.1f   %3.0f%%   %3.0f%%" % (
            shape, shape_count[shape], avg(v[0] for v in values),
            avg(v[1] for v in values) * 100, avg(v[2] for v in values) * 100))
    return 0


if __name__ == "__main__":
    sys.exit(main())
