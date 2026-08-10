"""방 도달 가능성과 배치 슬롯 감사 도구.

scenes/levels/room_*.tscn의 RoomTerrain 레이아웃과 배치 노드(적, 좌판, 도깨비불,
배치 슬롯)를 파싱해 다음을 검사한다.

1. 모든 슬롯과 고정 적이 설 수 있는 표면 위에 있고, 그 표면이 스폰에서 도달 가능한가
2. 부유 슬롯(공중, 도깨비불, 아이템)이 도달 가능한 자리 근처에 있는가
3. 출구(귀문 앞 바닥)에 도달 가능한가
4. 도달 불가 고립 표면(섬)이 없는가
5. 함정이 없는가 (도달 가능한 모든 자리에서 출구로 되돌아갈 수 있는가)
6. 슬롯을 쓰는 방에 고정 적이 남아 있지 않은가

슬롯은 채워질 수도 비워질 수도 있으므로 필수 경로 판정에 넣지 않는다. 즉 슬롯이 만드는
발판(좌판, 도깨비불)을 딛지 않고도 방이 성립해야 한다. 이 도구는 지형만으로 도달 가능성을
계산한 뒤 슬롯을 검사한다.

이동 모델 (docs/PROTOTYPE.md 2장, docs/DESIGN_ACT1.md 3.1에서 파생한 보수적 근사):
- 점프 3.5타일. 상승 3타일이면 수평 여유 2타일, 2타일이면 3타일, 1타일이면 4타일
- 수평 갭(같은 높이)은 5타일까지. 낙하는 수평 드리프트 4타일
- 벽 점프: 마주보는 수직 벽 간격 4~6타일 구간에서 위로 탈출 가능
- 대시 요구 갭은 필수 경로 판정에 넣지 않는다 (선택 경로 전용 원칙)

벽 점프는 필수 경로에 넣지 않는다 (2026-08-06 결정). --no-walljump를 주면 벽 점프
보정을 끄고 순수 점프만으로 검사하므로, 전투방은 이 모드에서도 통과해야 한다.
보상 경로를 벽 점프 뒤에 둔 방이 생기면 기본 모드만 통과하면 된다.

사용법: python tools/reach_check.py [--no-walljump] [room.tscn ...]
인자가 없으면 scenes/levels/room_*.tscn 중 RoomTerrain 레이아웃을 가진 방 전부.
문제가 있으면 종료 코드 1.
"""

from __future__ import annotations

import pathlib
import re
import sys
from collections import deque

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOLID = "GSPR/\\"
MAX_DX = {0: 5, 1: 4, 2: 3, 3: 2}
DROP_DX = 4
SPAWN = (4, 21)
## 출구(귀문)는 우벽 앞. 방 폭에서 파생한다 (폭 40 -> 35~38, 폭 60 -> 55~58).

## scripts/map/spawn_slot.gd의 SpawnSlot.Kind와 값이 같아야 한다
SLOT_GROUND, SLOT_HIGH, SLOT_AIR, SLOT_LANE, SLOT_COVER, SLOT_WISP, SLOT_ITEM = range(7)
SLOT_NAMES = {
    SLOT_GROUND: "지상",
    SLOT_HIGH: "고지대",
    SLOT_AIR: "공중",
    SLOT_LANE: "굴림 레인",
    SLOT_COVER: "좌판",
    SLOT_WISP: "도깨비불",
    SLOT_ITEM: "아이템",
}
## 발밑에 설 수 있는 표면이 있어야 하는 슬롯
SURFACE_SLOTS = {SLOT_GROUND, SLOT_HIGH, SLOT_LANE, SLOT_COVER}
## 부유 슬롯이 도달 가능한 자리에서 떨어져 있어도 되는 한계 (타일)
AIR_MAX_DX = 4
AIR_MAX_RISE = 3
AIR_MAX_DROP = 4

SLOT_BLOCK_RE = re.compile(
    r'\[node name="[^"]+" type="Marker2D" parent="Slots"\]\n(.*?)(?=\n\[node |\Z)',
    re.S,
)
POSITION_RE = re.compile(r"position = Vector2\((-?\d+), (-?\d+)\)")
KIND_RE = re.compile(r"^kind = (\d+)$", re.M)


def parse_room(path: pathlib.Path):
    src = path.read_text(encoding="utf-8")
    layout_match = re.search(r'layout = "((?:[^"\\]|\\.)*)"', src, re.S)
    if not layout_match:
        return None
    layout = layout_match.group(1).replace("\\\\", "\\")
    rows = [line.replace(" ", ".") for line in layout.split("\n") if line.strip()]
    entities = {"stall": [], "wisp": [], "enemy": [], "slot": []}
    node_re = re.compile(
        r'\[node name="[^"]+" parent="([^"]+)" instance=ExtResource\("([^"]+)"\)\]\n'
        r"position = Vector2\((-?\d+), (-?\d+)\)"
    )
    id_to_path = {rid: p for p, rid in re.findall(
        r'\[ext_resource type="PackedScene" path="([^"]+)" id="([^"]+)"\]', src
    )}
    for parent, rid, x, y in node_re.findall(src):
        scene = id_to_path.get(rid, "")
        pos = (int(x), int(y))
        if "stall_cover" in scene:
            entities["stall"].append(pos)
        elif "wisp_platform" in scene:
            entities["wisp"].append(pos)
        elif parent == "Enemies" or "/enemies/" in scene or "/bosses/" in scene:
            entities["enemy"].append(pos)
    for body in SLOT_BLOCK_RE.findall(src):
        pos_match = POSITION_RE.search(body)
        if not pos_match:
            continue
        kind_match = KIND_RE.search(body)
        kind = int(kind_match.group(1)) if kind_match else SLOT_GROUND
        entities["slot"].append((kind, int(pos_match.group(1)), int(pos_match.group(2))))
    return rows, entities


def solid_at(rows, x, y):
    if 0 <= y < len(rows) and 0 <= x < len(rows[y]):
        return rows[y][x] in SOLID
    return False


def standable_cells(rows, entities):
    cells = set()
    for y in range(1, len(rows)):
        for x in range(len(rows[y])):
            sym = rows[y][x]
            if sym in SOLID and solid_at(rows, x, y - 1):
                continue
            if sym not in SOLID and sym not in "=~":
                continue
            if solid_at(rows, x, y - 1) or solid_at(rows, x, y - 2):
                continue
            cells.add((x, y))
    for sx, sy in entities["stall"]:
        top_row = sy // 16 - 2
        for x in range((sx - 24) // 16, (sx - 24) // 16 + 3):
            if not solid_at(rows, x, top_row - 1) and not solid_at(rows, x, top_row - 2):
                cells.add((x, top_row))
    for wx, wy in entities["wisp"]:
        row = wy // 16
        for x in range((wx - 16) // 16, (wx - 16) // 16 + 2):
            if not solid_at(rows, x, row - 1) and not solid_at(rows, x, row - 2):
                cells.add((x, row))
    return cells


def clear_arc(rows, x0, y0, x1, y1):
    top = min(y0, y1)
    for x in range(min(x0, x1), max(x0, x1) + 1):
        for y in range(max(0, top - 3), top):
            if solid_at(rows, x, y):
                return False
    return True


def build_edges(rows, cells, wall_jump=True):
    adj = {k: set() for k in cells}
    for (x, y) in cells:
        for (tx, ty) in cells:
            if (tx, ty) == (x, y):
                continue
            dx = abs(tx - x)
            rise = y - ty
            ok = False
            if dx <= 1 and abs(rise) <= 1:
                ok = True
            elif rise == 0 and dx <= MAX_DX[0]:
                ok = True
            elif rise < 0 and dx <= DROP_DX:
                ok = True
            elif 1 <= rise <= 3 and dx <= MAX_DX[rise]:
                ok = True
            if ok and clear_arc(rows, x, y, tx, ty):
                adj[(x, y)].add((tx, ty))
    if wall_jump:
        _add_wall_jump_edges(rows, cells, adj)
    return adj


def _add_wall_jump_edges(rows, cells, adj):
    width = max(len(r) for r in rows)
    for gap_l in range(width - 1):
        for gap_r in range(gap_l + 5, min(gap_l + 8, width)):
            run = [
                y for y in range(1, len(rows) - 1)
                if solid_at(rows, gap_l, y) and solid_at(rows, gap_r, y)
            ]
            if len(run) < 4:
                continue
            inside = [
                (cx, cy) for (cx, cy) in cells
                if gap_l < cx < gap_r and cy <= run[-1] + 4
            ]
            entry = [
                (cx, cy) for (cx, cy) in cells
                if gap_l - 1 <= cx <= gap_r + 1 and cy > run[-1]
            ]
            tops = [
                (cx, cy) for (cx, cy) in cells
                if cy == run[0] and gap_l - 2 <= cx <= gap_r + 2
            ]
            for a in entry + inside:
                for b in inside + tops:
                    if a != b:
                        adj[a].add(b)


def reachable_from(adj, starts):
    seen = set()
    queue = deque(starts)
    while queue:
        cur = queue.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in adj[cur]:
            if nxt not in seen:
                queue.append(nxt)
    return seen


def _surface_spot(cells, col, row):
    """슬롯 발밑 표면. 같은 칸이 없으면 좌우 한 칸까지 본다."""
    for c in (col, col - 1, col + 1):
        if (c, row) in cells:
            return (c, row)
    return None


def _near_reachable(seen, col, row):
    """부유 슬롯이 도달 가능한 자리 근처에 있는가."""
    for (cx, cy) in seen:
        if abs(cx - col) > AIR_MAX_DX:
            continue
        rise = cy - row
        if -AIR_MAX_DROP <= rise <= AIR_MAX_RISE:
            return True
    return False


def check_slots(entities, cells, seen):
    problems = []
    for kind, sx, sy in entities["slot"]:
        col, row = sx // 16, sy // 16
        label = "%s 슬롯 (%d,%d)" % (SLOT_NAMES.get(kind, "?"), sx, sy)
        if kind in SURFACE_SLOTS:
            spot = _surface_spot(cells, col, row)
            if spot is None:
                problems.append("%s 발밑에 표면 없음" % label)
            elif spot not in seen:
                problems.append("%s 표면이 스폰에서 도달 불가" % label)
        elif not _near_reachable(seen, col, row):
            problems.append("%s 근처에 도달 가능한 자리 없음" % label)
    if entities["slot"] and entities["enemy"]:
        problems.append(
            "슬롯을 쓰는 방에 고정 적 %d기가 남아 있음 (슬롯으로 옮길 것)"
            % len(entities["enemy"])
        )
    return problems


def audit(path: pathlib.Path, wall_jump: bool = True):
    parsed = parse_room(path)
    if parsed is None:
        return None
    rows, entities = parsed
    cells = standable_cells(rows, entities)
    adj = build_edges(rows, cells, wall_jump)
    problems = []
    width = max((len(r) for r in rows), default=0)
    door_cols = range(width - 5, width - 1)
    if SPAWN not in cells:
        return [f"스폰 {SPAWN}에 설 수 없음"]
    seen = reachable_from(adj, [SPAWN])
    for ex, ey in entities["enemy"]:
        col, row = ex // 16, ey // 16
        spot = _surface_spot(cells, col, row)
        if spot is None:
            problems.append(f"적 ({ex},{ey}) 발밑에 표면 없음")
        elif spot not in seen:
            problems.append(f"적 ({ex},{ey}) 표면이 스폰에서 도달 불가")
    problems.extend(check_slots(entities, cells, seen))
    door_nodes = [(c, 21) for c in door_cols if (c, 21) in cells]
    if not any(n in seen for n in door_nodes):
        problems.append("출구(귀문) 도달 불가")
    unreachable = sorted(k for k in cells if k not in seen)
    for y in sorted({y for (_, y) in unreachable}):
        xs = sorted(x for (x, yy) in unreachable if yy == y)
        problems.append(f"도달 불가 표면 row {y} cols {xs}")
    if door_nodes:
        rev = {k: set() for k in cells}
        for a, outs in adj.items():
            for b in outs:
                rev[b].add(a)
        can_exit = reachable_from(rev, door_nodes)
        trapped = sorted(k for k in seen if k not in can_exit)
        for y in sorted({y for (_, y) in trapped}):
            xs = sorted(x for (x, yy) in trapped if yy == y)
            problems.append(f"함정(출구 복귀 불가) row {y} cols {xs}")
    return problems


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    wall_jump = "--no-walljump" not in sys.argv[1:]
    if args:
        targets = [pathlib.Path(p) for p in args]
    else:
        targets = sorted((ROOT / "scenes" / "levels").glob("room_*.tscn"))
    failed = False
    if not wall_jump:
        print("벽 점프 보정 없이 검사한다 (필수 경로 판정)")
    for path in targets:
        parsed = parse_room(path)
        if parsed is None:
            continue  # RoomTerrain 레이아웃이 없는 방 (구 방식)
        problems = audit(path, wall_jump)
        slot_count = len(parsed[1]["slot"])
        status = "통과" if not problems else "실패"
        suffix = f" (슬롯 {slot_count})" if slot_count else ""
        print(f"[{status}] {path.name}{suffix}")
        for p in problems:
            print(f"    {p}")
            failed = True
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
