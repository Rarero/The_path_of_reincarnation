class_name RunMap
extends RefCounted

## 런 지도 (docs/RUN_STRUCTURE.md 2장, 11장 이동 예산).
##
## 2026-08-06 자유 이동 전환. 층으로 잠긴 단방향 그래프를 버리고, 지도에 흩뿌린 노드를
## 근접 연결한 양방향 그래프로 만든다. 이동 제약은 하나도 두지 않는다. 앞으로도 뒤로도
## 몇 번이든 갈 수 있고, 강제로 지나야 하는 노드도 없다. 유일한 통제는 이동 예산이다.
##
## 이동 비용은 두 노드 사이 지도상 거리에 비례한다. 지도에서 선이 길면 비싸다는 규칙이
## 눈으로 읽히므로 별도 설명이 필요 없다.
##
## 씬과 분리한 순수 자료구조라 gdUnit4 단위 테스트가 된다.

## 노드 종류. docs/RUN_STRUCTURE.md 3장 배정표
enum Kind { COMBAT, EVENT, SHRINE, MIDBOSS, SHOP, GAMBLE, REST, BOSS }

## 노드를 흩뿌리는 영역 (px). 노드 맵 UI의 종이 안쪽 영역과 같다
const FIELD_SIZE: Vector2 = Vector2(296.0, 176.0)
## 지도 한 장의 최소 노드 수. 이보다 적게 들어가면 시드를 파생해 다시 그린다.
## 목표 수는 지형 틀마다 다르다 (SHAPE_TARGETS). 2026-08-09 고정 30에서 틀별 가변으로
const NODE_FLOOR: int = 18
## 노드끼리의 최소 간격 (px). 지도 기호(16px)와 테두리(반경 11)가 서로 닿지 않을 거리다.
## 2026-08-06 26에서 32로. 이 값이 틀별 목표 노드 수의 상한을 정한다 (시드 600개 확인)
const MIN_SEPARATION: float = 32.0
## 이 거리 안의 노드끼리 간선을 잇는다 (px)
const LINK_RADIUS: float = 46.0
## 노드 하나가 가질 수 있는 간선 수 상한
const MAX_LINKS: int = 4
## 길이 다른 노드를 이만큼 가까이 스치면 놓지 않는다 (px).
## 노드 기호의 테두리 반경이 11이라, 그보다 좁게 지나가면 길이 노드를 뚫고 가는 것처럼 보인다
const NODE_CLEARANCE: float = 12.0
## 이 진행도 이상인 노드는 보스와 직접 잇는다 (보스 접근 부채, docs/RUN_STRUCTURE.md 11.2).
## 종전에는 보스가 평균 1.7개 노드와만 이어져 후반 노드의 21퍼센트만 보스와 직결이었고,
## 나머지는 평균 1.55배(최악 13.2배)를 돌아가야 했다. 이 부채로 후반 노드는 전부 직결된다
const BOSS_APPROACH_DEPTH: float = 0.70
## 이동 비용 환산 단위 (px당). 비용 = round(거리 / COST_UNIT), 최소 1
const COST_UNIT: float = 9.0
## 노드 흩뿌리기 시도 상한 (결정적 종료 보장).
## 2026-08-09 4000에서 20000으로. 지형 틀이 영역을 깎으면 후보의 상당수가 기각되므로
## 시도가 모자라면 좁은 틀만 노드 수가 미달한다
const SCATTER_TRIES: int = 20000

## 지형 틀. 흩뿌릴 수 있는 영역의 모양이다 (docs/RUN_STRUCTURE.md 11.2).
## 광장은 종전과 같은 균질 배치이고, 나머지 넷이 그래프 모양 자체를 바꾼다
enum Shape { PLAZA, SPLIT, CHAIN, CLUSTER, ARC }

const SHAPE_COUNT: int = 5
const SHAPE_NAMES: Dictionary = {
	Shape.PLAZA: "광장",
	Shape.SPLIT: "갈래",
	Shape.CHAIN: "사슬",
	Shape.CLUSTER: "성단",
	Shape.ARC: "활꼴",
}
## 틀별 목표 노드 수. 영역이 좁은 틀일수록 적다. 여기에 -2~+2를 더해 흔든다
const SHAPE_TARGETS: Dictionary = {
	Shape.PLAZA: 30,
	Shape.SPLIT: 26,
	Shape.CHAIN: 27,
	Shape.CLUSTER: 26,
	Shape.ARC: 24,
}
const TARGET_JITTER: int = 2
## 틀은 원본 시드로 뽑는다. 재생성으로 흩뿌리기를 다시 해도 틀은 그대로다
const SHAPE_SEED_STEP: int = 12345
## 성단: 뭉치 수와 세로 반지름 (px). 가로 반지름은 32~40에서 뽑는다.
## 세로로 긴 타원 셋이라 뭉치 사이에 세로 빈 띠가 남는다. 원으로 하면 서로 겹쳐 뭉치로 안 읽힌다
const CLUSTER_COUNT: int = 3
const CLUSTER_RY: float = 70.0
## 활꼴: 띠 중심이 위아래로 휘는 폭과 띠의 반두께 (px)
const ARC_BULGE: float = 42.0
const ARC_HALF: float = 40.0

## 1막 이동 예산 (docs/RUN_STRUCTURE.md 11.4). 최단 완주가 예산의 평균 66퍼센트다
const TRAVEL_BUDGET: int = 58
## 최단 완주 비용이 예산에서 차지해야 하는 비율 창.
## 아래면 곁길이 너무 헐거워지고, 위면 시작부터 예산이 모자란다
## 2026-08-09 0.55~0.76에서 넓혔다. 어떤 런은 빡빡하고 어떤 런은 헐거워도 좋다는 판정
const SHORTEST_RATIO_MIN: float = 0.45
const SHORTEST_RATIO_MAX: float = 0.85
## 창을 벗어나면 시드를 파생해 다시 생성한다. 결정적이라 재현성은 유지된다
const REGEN_TRIES: int = 8
const REGEN_MULT: int = 2654435761
const REGEN_STEP: int = 40503
const SEED_MASK: int = 0x7FFFFFFF

## 종류별 노드 수의 범위 (시작 전투와 보스 제외). x가 하한, y가 상한이다.
## 2026-08-09 고정 개수에서 범위로. 매 런 노선 선택이 달라지게 하려는 것이다.
## 전투는 여기 없다. 남는 자리를 전부 가져간다
const KIND_BANDS: Dictionary = {
	Kind.EVENT: Vector2i(2, 5),
	Kind.SHRINE: Vector2i(1, 3),
	Kind.SHOP: Vector2i(1, 3),
	Kind.GAMBLE: Vector2i(0, 2),
	Kind.MIDBOSS: Vector2i(1, 3),
	Kind.REST: Vector2i(0, 2),
}
## 비전투 노드 수의 목표 범위. 아래 전투 하한에 걸리면 그쪽이 이긴다
const NON_COMBAT_MIN: int = 8
const NON_COMBAT_MAX: int = 14
## 전투가 지도에서 차지해야 하는 최소 비율. 이 선만 지키면 나머지는 흔든다
const COMBAT_SHARE_MIN: float = 0.50
## 본선에서 떨어뜨려 놓는 종류. 들르려면 예산을 써야 값이 생긴다
const OFF_AXIS_KINDS: Array = [Kind.SHRINE, Kind.SHOP, Kind.GAMBLE, Kind.REST, Kind.MIDBOSS]

## 시작 노드 근처의 방 위협 예산 (pt, docs/act1/ENEMIES.md 2장)
const THREAT_MIN: float = 3.0
## 보스 근처의 방 위협 예산
const THREAT_MAX: float = 10.0

## 종류 표시 이름 (지도 범례와 로그용)
const KIND_NAMES: Dictionary = {
	Kind.COMBAT: "전투",
	Kind.EVENT: "이벤트",
	Kind.SHRINE: "신당",
	Kind.MIDBOSS: "중간보스",
	Kind.SHOP: "상점",
	Kind.GAMBLE: "내기",
	Kind.REST: "쉼터",
	Kind.BOSS: "보스",
}

## 종류 기본 순점수 (docs/RUN_STRUCTURE.md 10장). 생성기 내부 검증용이며 UI에 쓰지 않는다
const KIND_SCORES: Dictionary = {
	Kind.COMBAT: -20,
	Kind.EVENT: 0,
	Kind.SHRINE: 40,
	Kind.MIDBOSS: -40,
	Kind.SHOP: 30,
	Kind.GAMBLE: 0,
	Kind.REST: 40,
	Kind.BOSS: 0,
}

## 생성에 쓴 시드. 같은 시드는 같은 지도를 재현한다
var seed_value: int = 0
## 이번 지도의 지형 틀 (Shape). 재생성해도 바뀌지 않는다
var shape: int = Shape.PLAZA
## 전체 노드 목록
var nodes: Array[RunMapNode] = []
## 이번 런의 이동 예산과 쓴 양
var travel_budget: int = TRAVEL_BUDGET
var travel_spent: int = 0

var _by_id: Dictionary = {}
## 간선 비용표. _links[a][b] = 비용 (양방향이라 두 방향 모두 들어 있다)
var _links: Dictionary = {}
## 놓인 간선 목록 (a < b). 교차 판정에 쓴다
var _edges: Array[Vector2i] = []
var _current_id: int = -1
var _start_id: int = -1
var _boss_id: int = -1
## 실제로 밟은 간선. 키는 _link_key(a, b), 값은 true. 지도에 지나온 길을 그리는 데 쓴다
var _walked: Dictionary = {}


## 1막 지도를 생성한다.
## 최단 완주 비용이 예산 창을 벗어나면 시드를 파생해 다시 그린다. 흩뿌리기가 성긴 자리를
## 만들면 시작부터 예산이 모자란 지도가 나오는데, 그것만 걸러 내는 장치다
func generate(map_seed: int) -> void:
	seed_value = map_seed
	shape = _roll_shape(map_seed)
	for attempt: int in range(REGEN_TRIES):
		_build((map_seed * REGEN_MULT + attempt * REGEN_STEP) & SEED_MASK)
		if nodes.size() < NODE_FLOOR:
			continue
		var ratio: float = float(shortest_run_cost()) / float(travel_budget)
		if ratio >= SHORTEST_RATIO_MIN and ratio <= SHORTEST_RATIO_MAX:
			return


## 지도 한 장을 그린다 (재시도 단위).
func _build(map_seed: int) -> void:
	nodes.clear()
	_by_id.clear()
	_links.clear()
	_edges.clear()
	_walked.clear()
	travel_budget = TRAVEL_BUDGET
	travel_spent = 0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = map_seed
	var points: Array[Vector2] = _scatter(rng)
	for index: int in range(points.size()):
		var node: RunMapNode = RunMapNode.new(index, points[index], Kind.COMBAT)
		nodes.append(node)
		_by_id[index] = node
		_links[index] = {}
	_start_id = 0
	_boss_id = nodes.size() - 1
	_link_nodes()
	_assign_depth()
	_link_boss_approach()
	_ensure_connected()
	_assign_kinds(rng)
	_current_id = _start_id
	_mark_visited(_current_id)


# --- 조회 ---


func current_id() -> int:
	return _current_id


func current_node() -> RunMapNode:
	return _by_id.get(_current_id, null)


func start_id() -> int:
	return _start_id


func boss_id() -> int:
	return _boss_id


## 서로 가로지르는 길이 몇 쌍인가. 평면 그래프이므로 항상 0이어야 한다 (11.2).
## 단위 테스트와 생성기 디버깅용이다
func crossing_road_count() -> int:
	var count: int = 0
	for i: int in range(_edges.size()):
		for j: int in range(i + 1, _edges.size()):
			var one: Vector2i = _edges[i]
			var two: Vector2i = _edges[j]
			if one.x == two.x or one.x == two.y or one.y == two.x or one.y == two.y:
				continue
			var crossed: bool = _segments_cross(
				_by_id[one.x].pos, _by_id[one.y].pos, _by_id[two.x].pos, _by_id[two.y].pos
			)
			if crossed:
				count += 1
	return count


## 이 간선을 실제로 밟았는가. 지도에서 지나온 길을 굵게 그리는 데 쓴다 (2026-08-10)
func is_walked(a: int, b: int) -> bool:
	return _walked.has(_link_key(a, b))


## 간선 키. 방향이 없으므로 작은 id를 앞에 둔다
func _link_key(a: int, b: int) -> int:
	return mini(a, b) * 1024 + maxi(a, b)


func get_node_by_id(node_id: int) -> RunMapNode:
	return _by_id.get(node_id, null)


func is_boss(node_id: int) -> bool:
	return node_id == _boss_id


func is_current(node_id: int) -> bool:
	return node_id == _current_id


func kind_name(kind: int) -> String:
	return String(KIND_NAMES.get(kind, "?"))


func kind_score(kind: int) -> int:
	return int(KIND_SCORES.get(kind, 0))


## 이벤트 종류 노드 목록 (EventResolver가 결과를 확정하는 대상).
func event_nodes() -> Array[RunMapNode]:
	var found: Array[RunMapNode] = []
	for node: RunMapNode in nodes:
		if node.kind == Kind.EVENT:
			found.append(node)
	return found


## 노드의 실점수 = 종류 기본 점수 + 확정된 이벤트 결과 점수 (docs/RUN_STRUCTURE.md 10장).
## 이벤트 기본 점수는 0이라 이벤트 노드는 확정 결과 점수가 그대로 실점수가 된다
func node_actual_score(node_id: int) -> int:
	var node: RunMapNode = _by_id.get(node_id, null)
	if node == null:
		return 0
	return kind_score(node.kind) + node.outcome_score


## 경로 위 노드의 실점수 합계. 생성기 내부 검증용이며 UI에 노출하지 않는다
func path_score(path: Array) -> int:
	var total: int = 0
	for node_id: Variant in path:
		total += node_actual_score(int(node_id))
	return total


## 갈 수 있는 이웃. 이동 제약이 없으므로 방문 여부와 예산에 관계없이 전부 돌려준다.
## 예산이 모자란 이동도 막지 않는다. 대가는 고갈 페널티가 받는다 (11.7)
func selectable_next_ids() -> Array[int]:
	var ids: Array[int] = []
	var node: RunMapNode = current_node()
	if node == null:
		return ids
	for other_id: int in node.link_ids:
		ids.append(other_id)
	ids.sort()
	return ids


func is_selectable(node_id: int) -> bool:
	return selectable_next_ids().has(node_id)


## 두 노드 사이 이동 비용. 이어져 있지 않으면 -1
func move_cost(from_id: int, to_id: int) -> int:
	var table: Dictionary = _links.get(from_id, {})
	return int(table.get(to_id, -1))


## 현재 노드에서의 이동 비용
func move_cost_from_current(to_id: int) -> int:
	return move_cost(_current_id, to_id)


func budget_left() -> int:
	return travel_budget - travel_spent


## 시작에서 보스까지의 최단 이동 비용. 예산 창 검사와 테스트가 쓴다
func shortest_run_cost() -> int:
	return shortest_cost_between(_start_id, _boss_id)


## 두 노드 사이 최단 이동 비용. 노드 수가 작아 단순 선택 다익스트라로 충분하다
func shortest_cost_between(from_id: int, to_id: int) -> int:
	var big: int = 1 << 30
	var dist: Dictionary = {from_id: 0}
	var done: Dictionary = {}
	while true:
		var best: int = -1
		var best_cost: int = big
		for key: Variant in dist:
			var node_id: int = int(key)
			if not done.has(node_id) and int(dist[node_id]) < best_cost:
				best_cost = int(dist[node_id])
				best = node_id
		if best < 0:
			return big
		if best == to_id:
			return best_cost
		done[best] = true
		for other_id: int in _by_id[best].link_ids:
			var next_cost: int = best_cost + move_cost(best, other_id)
			if next_cost < int(dist.get(other_id, big)):
				dist[other_id] = next_cost
	# 반환은 모두 while 안에서 일어나므로 이 줄은 실제로는 실행되지 않는다.
	# 다만 GDScript 분석기가 while true를 무한 루프로 보지 않아,
	# 종결 반환이 없으면 Not all code paths return a value 오류가 난다
	return big


## 이동 후 남을 예산 (노드 맵 미리보기용)
func budget_after(to_id: int) -> int:
	var cost: int = move_cost_from_current(to_id)
	return budget_left() if cost < 0 else budget_left() - cost


## 예산을 다 썼는지. 이동이 막히지는 않는다
func is_depleted() -> bool:
	return budget_left() <= 0


## 생기 고갈 단계 (docs/RUN_STRUCTURE.md 11.7). 0이면 정상
func depletion_stage() -> int:
	var over: int = -budget_left()
	if over <= 0:
		return 0
	if over <= 10:
		return 1
	if over <= 25:
		return 2
	return 3


## 이 방의 위협 포인트 예산. 층 대신 진행도로 정한다.
## 시작 근처는 3pt, 보스 근처는 10pt다. 초반에 지도 오른쪽으로 질러가면 그만큼 위험하다
func threat_budget_for(node_id: int) -> float:
	var node: RunMapNode = _by_id.get(node_id, null)
	if node == null:
		return THREAT_MIN
	var raw: float = lerpf(THREAT_MIN, THREAT_MAX, clampf(node.depth, 0.0, 1.0))
	raw += float(depletion_stage())
	return roundf(raw * 2.0) / 2.0


## 이웃으로 이동한다. 비용을 차감하고 true를 반환한다.
## 예산이 모자라도 이동은 성립한다 (자유 이동 원칙). 마이너스는 고갈 단계로 처리한다
func choose(node_id: int) -> bool:
	var cost: int = move_cost_from_current(node_id)
	if cost < 0:
		return false
	travel_spent += cost
	_walked[_link_key(_current_id, node_id)] = true
	_current_id = node_id
	_mark_visited(node_id)
	return true


## 저장 복원용. 지나온 경로를 그대로 다시 밟아 예산과 방문 이력을 되살린다
func replay(path: Array) -> void:
	if path.is_empty():
		return
	_current_id = int(path[0])
	travel_spent = 0
	_walked.clear()
	for node: RunMapNode in nodes:
		node.visited = false
	_mark_visited(_current_id)
	for i: int in range(1, path.size()):
		choose(int(path[i]))


# --- 생성 내부 ---


## 지형 틀을 뽑는다. 재생성과 무관하게 원본 시드로만 정해 한 시드는 늘 같은 틀이다.
func _roll_shape(map_seed: int) -> int:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = (map_seed * REGEN_MULT + SHAPE_SEED_STEP) & SEED_MASK
	return rng.randi_range(0, SHAPE_COUNT - 1)


## 틀마다 필요한 난수 매개변수를 미리 뽑아 둔다. 같은 틀도 시드마다 형태가 달라진다.
func _shape_params(rng: RandomNumberGenerator) -> Dictionary:
	match shape:
		Shape.CLUSTER:
			var centers: Array[Vector2] = []
			for i: int in range(CLUSTER_COUNT):
				var t: float = (float(i) + 0.5) / float(CLUSTER_COUNT)
				centers.append(
					Vector2(
						FIELD_SIZE.x * t + rng.randf_range(-6.0, 6.0),
						FIELD_SIZE.y * 0.5 + rng.randf_range(-16.0, 16.0)
					)
				)
			return {"centers": centers, "rx": rng.randf_range(32.0, 40.0)}
		Shape.ARC:
			return {"sign": 1.0 if rng.randf() < 0.5 else -1.0}
		Shape.SPLIT:
			return {"gap": rng.randf_range(22.0, 32.0)}
		Shape.CHAIN:
			return {"bands": rng.randi_range(5, 7), "throat": rng.randf_range(14.0, 20.0)}
		_:
			return {}


## 이 자리에 노드를 놓아도 되는가. 틀이 깎아 낸 영역 밖이면 기각한다.
func _shape_accepts(point: Vector2, params: Dictionary) -> bool:
	var axis: float = FIELD_SIZE.y * 0.5
	match shape:
		Shape.SPLIT:
			# 가운데 가로 띠를 비워 위아래 두 갈래로 가른다. 둘은 시작과 보스에서만 만난다
			return absf(point.y - axis) >= float(params["gap"])
		Shape.CHAIN:
			# 넓은 방과 좁은 통로가 번갈아 온다. 통로에는 노드가 한둘만 들어가 병목이 된다
			var bands: int = int(params["bands"])
			var index: int = clampi(int(point.x / FIELD_SIZE.x * float(bands)), 0, bands - 1)
			return index % 2 == 0 or absf(point.y - axis) <= float(params["throat"])
		Shape.CLUSTER:
			# 뭉치 서넛만 남기고 사이를 비운다. 뭉치 사이는 긴 간선 하나로 건너간다
			return _inside_cluster(point, params)
		Shape.ARC:
			# 띠가 위나 아래로 한 번 휜다. 지도 전체가 활처럼 굽는다
			var t: float = point.x / FIELD_SIZE.x
			var center: float = axis + float(params["sign"]) * sin(t * PI) * ARC_BULGE
			return absf(point.y - center) <= ARC_HALF
		_:
			return true


## 성단 틀 판정. 세로로 긴 타원 뭉치 하나라도 안에 들어오면 놓을 수 있다.
func _inside_cluster(point: Vector2, params: Dictionary) -> bool:
	var rx: float = float(params["rx"])
	for center: Vector2 in params["centers"]:
		var dx: float = (point.x - center.x) / rx
		var dy: float = (point.y - center.y) / CLUSTER_RY
		if dx * dx + dy * dy <= 1.0:
			return true
	return false


## 최소 간격을 지키며 노드를 흩뿌린다. 시작은 왼쪽 끝, 보스는 오른쪽 끝에 고정한다.
## 시작과 보스를 먼저 넣어 둬야 다른 노드가 그 둘과도 간격을 지킨다.
## (2026-08-06 수정. 보스를 마지막에 덧붙이던 탓에 보스 옆에 노드가 달라붙었다)
##
## 2026-08-09 지형 틀 도입. 후보를 틀로 한 번 거른 뒤 간격을 본다
func _scatter(rng: RandomNumberGenerator) -> Array[Vector2]:
	var boss_point: Vector2 = Vector2(FIELD_SIZE.x - 6.0, FIELD_SIZE.y * 0.5)
	var points: Array[Vector2] = [Vector2(6.0, FIELD_SIZE.y * 0.5), boss_point]
	var params: Dictionary = _shape_params(rng)
	var target: int = int(SHAPE_TARGETS[shape]) + rng.randi_range(-TARGET_JITTER, TARGET_JITTER)
	var tries: int = 0
	while points.size() < target and tries < SCATTER_TRIES:
		tries += 1
		var candidate: Vector2 = Vector2(
			rng.randf_range(12.0, FIELD_SIZE.x - 12.0), rng.randf_range(8.0, FIELD_SIZE.y - 8.0)
		)
		if not _shape_accepts(candidate, params):
			continue
		var ok: bool = true
		for existing: Vector2 in points:
			if existing.distance_to(candidate) < MIN_SEPARATION:
				ok = false
				break
		if ok:
			points.append(candidate)
	# 보스는 마지막 id여야 한다 (boss_id = 마지막 인덱스 규약)
	points.remove_at(1)
	points.append(boss_point)
	return points


## 가까운 노드끼리 잇는다. 간선은 양방향이고 비용은 거리에 비례한다.
## 가까운 노드끼리 잇는다. 간선은 양방향이고 비용은 거리에 비례한다.
##
## 2026-08-10 평면 그래프로 바꿨다. 종전에는 노드마다 가까운 넷을 그냥 집어서 길끼리
## 교차했다. 지도에서 두 길이 X자로 만나는데 그 자리에 갈림길이 없는 것은 이치에 맞지
## 않고, 실제로 갈 수 없는 이동으로 읽힌다. 짧은 후보부터 넣되 이미 놓인 길과 교차하거나
## 다른 노드를 스치는 후보는 버린다 (docs/RUN_STRUCTURE.md 11.2)
func _link_nodes() -> void:
	for pair: Vector3 in _candidate_pairs():
		var distance: float = pair.z
		if distance > LINK_RADIUS:
			break
		var a: int = int(pair.x)
		var b: int = int(pair.y)
		if _by_id[a].link_ids.size() >= MAX_LINKS or _by_id[b].link_ids.size() >= MAX_LINKS:
			continue
		if not _road_is_clear(a, b):
			continue
		_add_link(a, b, distance)


## 모든 노드 쌍을 거리 오름차순으로. x, y가 노드 id(x < y)이고 z가 거리다.
## 노드가 32개 이하라 쌍은 최대 496개다. 짧은 후보부터 넣는 것이 평면 그래프의 핵심이다
func _candidate_pairs() -> Array[Vector3]:
	var pairs: Array[Vector3] = []
	for i: int in range(nodes.size()):
		for j: int in range(i + 1, nodes.size()):
			pairs.append(Vector3(float(i), float(j), nodes[i].pos.distance_to(nodes[j].pos)))
	pairs.sort_custom(func(one: Vector3, two: Vector3) -> bool: return one.z < two.z)
	return pairs


## 이 길을 놓아도 되는가. 다른 노드를 스치지 않고 이미 놓인 길과 교차하지 않아야 한다.
func _road_is_clear(a: int, b: int) -> bool:
	var from_point: Vector2 = _by_id[a].pos
	var to_point: Vector2 = _by_id[b].pos
	for node: RunMapNode in nodes:
		if node.id == a or node.id == b:
			continue
		if _point_to_segment(node.pos, from_point, to_point) < NODE_CLEARANCE:
			return false
	for edge: Vector2i in _edges:
		if edge.x == a or edge.x == b or edge.y == a or edge.y == b:
			continue
		if _segments_cross(from_point, to_point, _by_id[edge.x].pos, _by_id[edge.y].pos):
			return false
	return true


## 점과 선분 사이 거리.
func _point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var span: Vector2 = b - a
	var length_sq: float = span.length_squared()
	if length_sq < 0.0001:
		return point.distance_to(a)
	var t: float = clampf((point - a).dot(span) / length_sq, 0.0, 1.0)
	return point.distance_to(a + span * t)


## 두 선분이 서로를 가로지르는가. 끝점을 공유하는 경우는 교차로 보지 않는다.
func _segments_cross(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
	var d1: float = _cross(b1, b2, a1)
	var d2: float = _cross(b1, b2, a2)
	var d3: float = _cross(a1, a2, b1)
	var d4: float = _cross(a1, a2, b2)
	return (d1 > 0.0) != (d2 > 0.0) and (d3 > 0.0) != (d4 > 0.0)


## 벡터 외적 (o에서 본 a와 b의 방향 판정).
func _cross(o: Vector2, a: Vector2, b: Vector2) -> float:
	return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)


## 간선 하나를 잇는다. force는 끊긴 덩어리를 붙일 때만 쓴다 (연결성이 상한보다 우선).
##
## 상한을 양쪽 모두 검사한다. 거는 쪽 개수만 세면 여러 이웃에게 "가장 가까운 노드"로
## 지목된 인기 노드가 MAX_LINKS를 넘긴다 (docs/RUN_STRUCTURE.md 11.2 최대 4개)
func _add_link(a: int, b: int, distance: float, force: bool = false) -> void:
	var node_first: RunMapNode = _by_id[a]
	var node_second: RunMapNode = _by_id[b]
	var is_new: bool = not node_first.link_ids.has(b)
	if is_new and not force:
		if node_first.link_ids.size() >= MAX_LINKS or node_second.link_ids.size() >= MAX_LINKS:
			return
	var cost: int = maxi(1, int(round(distance / COST_UNIT)))
	_links[a][b] = cost
	_links[b][a] = cost
	var node_a: RunMapNode = _by_id[a]
	var node_b: RunMapNode = _by_id[b]
	if not node_a.link_ids.has(b):
		node_a.link_ids.append(b)
	if not node_b.link_ids.has(a):
		node_b.link_ids.append(a)
	if is_new:
		_edges.append(Vector2i(mini(a, b), maxi(a, b)))


## 끊긴 덩어리를 잇는다. 교차하지 않는 가장 짧은 다리부터 놓고, 그런 다리가 하나도
## 없으면 그때만 교차를 허용한다 (연결성이 평면성보다 우선한다).
func _ensure_connected() -> void:
	var pairs: Array[Vector3] = _candidate_pairs()
	for _round: int in range(nodes.size()):
		var owner: Dictionary = _component_owner()
		if _component_count(owner) <= 1:
			return
		var bridge: Vector3 = _find_bridge(pairs, owner, true)
		if bridge.z < 0.0:
			bridge = _find_bridge(pairs, owner, false)
		if bridge.z < 0.0:
			return
		_add_link(int(bridge.x), int(bridge.y), bridge.z, true)


## 덩어리 번호표. 같은 값이면 이미 이어져 있다는 뜻이다.
func _component_owner() -> Dictionary:
	var owner: Dictionary = {}
	var group: int = 0
	for node: RunMapNode in nodes:
		if owner.has(node.id):
			continue
		var stack: Array[int] = [node.id]
		while not stack.is_empty():
			var current: int = stack.pop_back()
			if owner.has(current):
				continue
			owner[current] = group
			for other_id: int in _by_id[current].link_ids:
				if not owner.has(other_id):
					stack.append(other_id)
		group += 1
	return owner


func _component_count(owner: Dictionary) -> int:
	var groups: Dictionary = {}
	for node_id: int in owner:
		groups[owner[node_id]] = true
	return groups.size()


## 서로 다른 덩어리를 잇는 가장 짧은 후보. 없으면 z가 -1이다.
func _find_bridge(pairs: Array[Vector3], owner: Dictionary, need_clear: bool) -> Vector3:
	for pair: Vector3 in pairs:
		var a: int = int(pair.x)
		var b: int = int(pair.y)
		if owner[a] == owner[b]:
			continue
		if need_clear and not _road_is_clear(a, b):
			continue
		return pair
	return Vector3(0.0, 0.0, -1.0)


## 진행도. 시작에서 보스까지의 가로 위치 비율이다
func _assign_depth() -> void:
	var left: float = _by_id[_start_id].pos.x
	var right: float = _by_id[_boss_id].pos.x
	var span: float = maxf(1.0, right - left)
	for node: RunMapNode in nodes:
		node.depth = clampf((node.pos.x - left) / span, 0.0, 1.0)


## 보스 접근 부채. 진행도가 BOSS_APPROACH_DEPTH 이상인 노드를 모두 보스와 직접 잇는다.
##
## 근접 연결만으로는 보스가 이웃 한둘하고만 이어진다. 보스 코앞에 서 있어도 지도를 크게
## 우회해야 들어갈 수 있어서, 마지막 구간에서만 이동이 사실상 강제됐다. 자유 이동 원칙에
## 어긋나므로 간선 상한을 무시하고(force) 잇는다. 다만 길끼리 교차하면 안 되므로
## 짧은 것부터 넣고 교차하는 것은 버린다. 보스 차수는 평균 4.5개가 된다 (2026-08-10)
func _link_boss_approach() -> void:
	for pair: Vector3 in _candidate_pairs():
		var a: int = int(pair.x)
		var b: int = int(pair.y)
		if a != _boss_id and b != _boss_id:
			continue
		var other: int = b if a == _boss_id else a
		if other == _start_id or _by_id[other].depth < BOSS_APPROACH_DEPTH:
			continue
		if _by_id[other].link_ids.has(_boss_id):
			continue
		if not _road_is_clear(other, _boss_id):
			continue
		_add_link(other, _boss_id, pair.z, true)


## 종류를 배정한다. 좋은 노드일수록 본선(가로 중앙축)에서 먼 자리에 둔다.
## 강제로 지나게 하지 않고, 들르는 데 예산이 들게 해서 선택을 만든다
func _assign_kinds(rng: RandomNumberGenerator) -> void:
	_by_id[_start_id].kind = Kind.COMBAT
	_by_id[_boss_id].kind = Kind.BOSS
	var middle: Array = []
	for node: RunMapNode in nodes:
		if node.id != _start_id and node.id != _boss_id:
			middle.append(node.id)
	var axis: float = FIELD_SIZE.y * 0.5
	middle.sort_custom(
		func(a: int, b: int) -> bool:
			return absf(_by_id[a].pos.y - axis) > absf(_by_id[b].pos.y - axis)
	)
	var counts: Dictionary = _roll_composition(rng, middle.size(), nodes.size())
	var off_axis: Array[int] = []
	var on_axis: Array[int] = []
	for kind: int in counts:
		for _i: int in range(int(counts[kind])):
			if OFF_AXIS_KINDS.has(kind):
				off_axis.append(kind)
			else:
				on_axis.append(kind)
	_shuffle(on_axis, rng)
	var queue: Array[int] = off_axis + on_axis
	for index: int in range(middle.size()):
		var node: RunMapNode = _by_id[middle[index]]
		node.kind = queue[index] if index < queue.size() else Kind.COMBAT


## 이번 지도의 종류별 개수를 뽑는다 (docs/RUN_STRUCTURE.md 11.6).
##
## 각 종류의 하한부터 깔고, 비전투 목표 수에 닿을 때까지 상한이 남은 종류에 하나씩 얹는다.
## 전투는 남는 자리를 전부 가져간다. 전투 하한(COMBAT_SHARE_MIN)이 목표 수보다 세서,
## 노드가 적은 틀에서는 목표를 깎는다
func _roll_composition(
	rng: RandomNumberGenerator, middle_count: int, node_count: int
) -> Dictionary:
	var counts: Dictionary = {}
	var total: int = 0
	var pool: Array[int] = []
	for kind: int in KIND_BANDS:
		var band: Vector2i = KIND_BANDS[kind]
		counts[kind] = band.x
		total += band.x
		for _i: int in range(band.y - band.x):
			pool.append(kind)
	var ceiling: int = middle_count - ceili(COMBAT_SHARE_MIN * float(node_count))
	var goal: int = clampi(
		rng.randi_range(NON_COMBAT_MIN, NON_COMBAT_MAX), total, maxi(total, ceiling)
	)
	_shuffle(pool, rng)
	var index: int = 0
	while total < goal and index < pool.size():
		counts[pool[index]] += 1
		total += 1
		index += 1
	counts[Kind.COMBAT] = maxi(0, middle_count - total)
	return counts


func _shuffle(list: Array[int], rng: RandomNumberGenerator) -> void:
	for i: int in range(list.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = list[i]
		list[i] = list[j]
		list[j] = tmp


func _mark_visited(node_id: int) -> void:
	var node: RunMapNode = _by_id.get(node_id, null)
	if node != null:
		node.visited = true
