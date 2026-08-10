extends GdUnitTestSuite

## 자유 이동 지도 검증 (docs/RUN_STRUCTURE.md 2장, 11장).
##
## 2026-08-06 전면 개정. 층 잠금과 고정 배리어 층을 폐기했으므로 그 규칙을 검사하던
## 옛 테스트는 전부 버렸다. 지금 고정하는 것은 셋이다.
## 이동에 제약이 없을 것, 예산이 유일한 통제일 것, 구성 비율이 전투 중심일 것.

const SAMPLE_SEEDS: int = 60


func _map(value: int) -> RunMap:
	var map: RunMap = RunMap.new()
	map.generate(value)
	return map


func test_same_seed_reproduces_map() -> void:
	for value: int in [0, 7, 4242]:
		var a: RunMap = _map(value)
		var b: RunMap = _map(value)
		assert_int(a.nodes.size()).is_equal(b.nodes.size())
		for i: int in range(a.nodes.size()):
			assert_that(a.nodes[i].pos).is_equal(b.nodes[i].pos)
			assert_int(a.nodes[i].kind).is_equal(b.nodes[i].kind)
			assert_bool(a.nodes[i].link_ids == b.nodes[i].link_ids).is_true()
		assert_int(a.current_id()).is_equal(b.current_id())


func test_different_seeds_differ() -> void:
	assert_str(_signature(_map(1))).is_not_equal(_signature(_map(2)))


## 모든 간선이 양방향이다. 되돌아가기에 제약이 없다는 뜻이다
func test_every_link_is_two_way() -> void:
	for value: int in range(SAMPLE_SEEDS):
		var map: RunMap = _map(value)
		for node: RunMapNode in map.nodes:
			for other_id: int in node.link_ids:
				var other: RunMapNode = map.get_node_by_id(other_id)
				assert_bool(other.link_ids.has(node.id)).is_true()
				assert_int(map.move_cost(node.id, other_id)).is_equal(
					map.move_cost(other_id, node.id)
				)


## 이웃은 방문 여부와 예산에 관계없이 전부 고를 수 있다 (자유 이동 원칙)
func test_visited_and_unaffordable_nodes_stay_selectable() -> void:
	var map: RunMap = _map(11)
	var first: int = map.selectable_next_ids()[0]
	var origin: int = map.current_id()
	map.choose(first)
	assert_bool(map.selectable_next_ids().has(origin)).is_true()
	assert_bool(map.get_node_by_id(origin).visited).is_true()
	map.travel_spent = map.travel_budget + 100
	assert_bool(map.selectable_next_ids().has(origin)).is_true()
	assert_bool(map.choose(origin)).is_true()


func test_all_nodes_reachable_from_start() -> void:
	for value: int in range(SAMPLE_SEEDS):
		var map: RunMap = _map(value)
		assert_int(_reachable(map).size()).is_equal(map.nodes.size())


func test_boss_is_reachable_and_unique() -> void:
	for value: int in range(SAMPLE_SEEDS):
		var map: RunMap = _map(value)
		var bosses: int = 0
		for node: RunMapNode in map.nodes:
			if node.kind == RunMap.Kind.BOSS:
				bosses += 1
		assert_int(bosses).is_equal(1)
		assert_bool(map.is_boss(map.boss_id())).is_true()
		assert_bool(_reachable(map).has(map.boss_id())).is_true()


## 보스 접근 부채. 후반 노드에서 보스로 가는 길이 크게 우회하지 않는다.
##
## 2026-08-10 평면 규칙(간선 교차 금지)이 보스 직결보다 우선하게 바뀌면서 직결은
## 100퍼센트가 아니라 약 64퍼센트가 됐다 (docs/RUN_STRUCTURE.md 11.2). 그래서
## "전부 직결"이 아니라 원래 목적인 "우회가 과하지 않다"를 고정한다. 우회배율은
## 보스까지의 최단 경로 비용을 직선 거리로 나눈 값이다
func test_late_nodes_reach_boss_without_long_detours() -> void:
	for value: int in range(SAMPLE_SEEDS):
		var map: RunMap = _map(value)
		var boss: int = map.boss_id()
		var late: int = 0
		for node: RunMapNode in map.nodes:
			if node.id == map.start_id() or node.id == boss:
				continue
			if node.depth < RunMap.BOSS_APPROACH_DEPTH:
				continue
			late += 1
			var direct: float = node.pos.distance_to(map.get_node_by_id(boss).pos)
			var cost: float = map.shortest_cost_between(node.id, boss)
			assert_float(cost).is_less(direct * 4.0 + 1.0)
		assert_int(late).is_greater(0)


## 길끼리 교차하지 않는다. 지도에서 두 길이 X자로 만나는데 그 자리에 갈림길이 없으면
## 갈 수 없는 이동으로 읽힌다 (11.2 평면 그래프)
func test_roads_never_cross() -> void:
	for value: int in range(SAMPLE_SEEDS):
		assert_int(_map(value).crossing_road_count()).is_equal(0)


## 길은 다른 노드를 스치고 지나가지 않는다. 기호를 뚫고 가는 길처럼 보이면 안 된다 (11.2)
func test_roads_keep_clear_of_other_nodes() -> void:
	for value: int in range(20):
		var map: RunMap = _map(value)
		for node: RunMapNode in map.nodes:
			for other_id: int in node.link_ids:
				if other_id <= node.id:
					continue
				var a: Vector2 = node.pos
				var b: Vector2 = map.get_node_by_id(other_id).pos
				for third: RunMapNode in map.nodes:
					if third.id == node.id or third.id == other_id:
						continue
					var gap: float = _point_to_segment(third.pos, a, b)
					assert_bool(gap >= RunMap.NODE_CLEARANCE - 0.01).is_true()


## 이동 비용은 지도상 거리에 비례한다. 먼 간선이 더 싸면 안 된다
func test_cost_follows_distance() -> void:
	for value: int in range(20):
		var map: RunMap = _map(value)
		for node: RunMapNode in map.nodes:
			for other_id: int in node.link_ids:
				var other: RunMapNode = map.get_node_by_id(other_id)
				var expected: int = maxi(
					1, int(round(node.pos.distance_to(other.pos) / RunMap.COST_UNIT))
				)
				assert_int(map.move_cost(node.id, other_id)).is_equal(expected)


func test_choosing_deducts_budget() -> void:
	var map: RunMap = _map(3)
	var target: int = map.selectable_next_ids()[0]
	var cost: int = map.move_cost_from_current(target)
	var before: int = map.budget_left()
	assert_int(map.budget_after(target)).is_equal(before - cost)
	map.choose(target)
	assert_int(map.budget_left()).is_equal(before - cost)


func test_unlinked_move_is_rejected() -> void:
	var map: RunMap = _map(5)
	var far: int = -1
	for node: RunMapNode in map.nodes:
		if node.id != map.current_id() and not map.selectable_next_ids().has(node.id):
			far = node.id
			break
	assert_int(far).is_not_equal(-1)
	assert_bool(map.choose(far)).is_false()


## 노드 사이 최소 간격이 지켜진다. 지도에서 기호 테두리가 서로 닿으면 안 된다
func test_nodes_keep_minimum_separation() -> void:
	for value: int in range(SAMPLE_SEEDS):
		var map: RunMap = _map(value)
		for a: RunMapNode in map.nodes:
			for b: RunMapNode in map.nodes:
				if a.id < b.id:
					assert_bool(a.pos.distance_to(b.pos) >= RunMap.MIN_SEPARATION - 0.01).is_true()


## 최단 완주 비용이 예산 창 안에 든다. 생성기가 벗어난 지도를 다시 그린다 (11.4)
func test_shortest_run_fits_budget_window() -> void:
	var total: float = 0.0
	for value: int in range(SAMPLE_SEEDS):
		var map: RunMap = _map(value)
		var ratio: float = float(map.shortest_run_cost()) / float(map.travel_budget)
		assert_bool(ratio >= RunMap.SHORTEST_RATIO_MIN).is_true()
		assert_bool(ratio <= RunMap.SHORTEST_RATIO_MAX).is_true()
		total += ratio
	var mean: float = total / float(SAMPLE_SEEDS)
	assert_bool(mean > 0.60 and mean < 0.72).is_true()


## 좋은 노드를 전부 도는 비용은 예산을 넘는다. 넘지 않으면 선택이 사라진다
func test_visiting_every_reward_node_costs_more_than_budget() -> void:
	for value: int in range(20):
		var map: RunMap = _map(value)
		var total: int = 0
		var from_id: int = map.start_id()
		for node: RunMapNode in map.nodes:
			if RunMap.OFF_AXIS_KINDS.has(node.kind):
				total += map.shortest_cost_between(from_id, node.id)
				from_id = node.id
		total += map.shortest_cost_between(from_id, map.boss_id())
		assert_int(total).is_greater(map.travel_budget)


## 전투가 지도 노드의 절반을 넘고, 종류별 개수가 정해 둔 범위 안에 든다 (11.6)
func test_composition_stays_inside_its_bands() -> void:
	for value: int in range(SAMPLE_SEEDS):
		var map: RunMap = _map(value)
		assert_int(map.nodes.size()).is_greater_equal(RunMap.NODE_FLOOR)
		var combat: int = _count_kind(map, RunMap.Kind.COMBAT)
		var share: float = float(combat) / float(map.nodes.size())
		assert_bool(share >= RunMap.COMBAT_SHARE_MIN).is_true()
		for kind: int in RunMap.KIND_BANDS:
			var band: Vector2i = RunMap.KIND_BANDS[kind]
			var count: int = _count_kind(map, kind)
			assert_int(count).is_greater_equal(band.x)
			assert_int(count).is_less_equal(band.y)


## 시드가 다르면 지형 틀도 종류 구성도 갈린다. 한 가지 지도만 나오면 안 된다 (11.2, 11.6)
func test_maps_vary_in_shape_and_size() -> void:
	var shapes: Dictionary = {}
	var sizes: Dictionary = {}
	var shrines: Dictionary = {}
	for value: int in range(SAMPLE_SEEDS):
		var map: RunMap = _map(value)
		shapes[map.shape] = true
		sizes[map.nodes.size()] = true
		shrines[_count_kind(map, RunMap.Kind.SHRINE)] = true
	assert_int(shapes.size()).is_equal(RunMap.SHAPE_COUNT)
	assert_int(sizes.size()).is_greater_equal(4)
	assert_int(shrines.size()).is_greater_equal(2)


## 같은 시드는 지형 틀도 그대로다. 재생성이 걸려도 틀은 바뀌지 않는다
func test_shape_is_stable_for_a_seed() -> void:
	for value: int in [0, 7, 4242]:
		assert_int(_map(value).shape).is_equal(_map(value).shape)


## 좋은 노드는 본선(가로 중앙축)에서 멀리 놓인다. 들르는 데 예산이 들어야 값이 생긴다
func test_reward_nodes_sit_off_the_main_axis() -> void:
	var axis: float = RunMap.FIELD_SIZE.y * 0.5
	for value: int in range(20):
		var map: RunMap = _map(value)
		var reward: float = 0.0
		var reward_count: int = 0
		var combat: float = 0.0
		var combat_count: int = 0
		for node: RunMapNode in map.nodes:
			var offset: float = absf(node.pos.y - axis)
			if RunMap.OFF_AXIS_KINDS.has(node.kind):
				reward += offset
				reward_count += 1
			elif node.kind == RunMap.Kind.COMBAT:
				combat += offset
				combat_count += 1
		assert_bool(reward / float(reward_count) > combat / float(combat_count)).is_true()


## 방 위협 예산은 진행도를 따른다. 시작 근처가 낮고 보스 근처가 높다
func test_threat_budget_grows_with_depth() -> void:
	var map: RunMap = _map(9)
	assert_float(map.threat_budget_for(map.start_id())).is_equal_approx(RunMap.THREAT_MIN, 0.6)
	assert_float(map.threat_budget_for(map.boss_id())).is_equal_approx(RunMap.THREAT_MAX, 0.6)


## 예산을 넘겨 써도 이동은 막히지 않고 고갈 단계만 오른다
func test_depletion_is_soft() -> void:
	var map: RunMap = _map(4)
	assert_int(map.depletion_stage()).is_equal(0)
	map.travel_spent = map.travel_budget
	assert_int(map.depletion_stage()).is_equal(0)
	map.travel_spent = map.travel_budget + 5
	assert_int(map.depletion_stage()).is_equal(1)
	map.travel_spent = map.travel_budget + 20
	assert_int(map.depletion_stage()).is_equal(2)
	map.travel_spent = map.travel_budget + 40
	assert_int(map.depletion_stage()).is_equal(3)
	assert_bool(map.threat_budget_for(map.start_id()) > RunMap.THREAT_MIN).is_true()


## 저장 복원: 같은 경로를 되짚으면 예산과 방문 이력이 같아진다
func test_replay_restores_budget_and_history() -> void:
	var map: RunMap = _map(21)
	var path: Array[int] = [map.current_id()]
	for _i: int in range(6):
		var options: Array[int] = map.selectable_next_ids()
		map.choose(options[0])
		path.append(map.current_id())
	var spent: int = map.travel_spent
	var restored: RunMap = _map(21)
	restored.replay(path)
	assert_int(restored.travel_spent).is_equal(spent)
	assert_int(restored.current_id()).is_equal(map.current_id())
	for node_id: int in path:
		assert_bool(restored.get_node_by_id(node_id).visited).is_true()


# --- 도우미 ---


func _count_kind(map: RunMap, kind: int) -> int:
	var count: int = 0
	for node: RunMapNode in map.nodes:
		if node.kind == kind:
			count += 1
	return count


func _reachable(map: RunMap) -> Dictionary:
	var seen: Dictionary = {}
	var stack: Array[int] = [map.start_id()]
	while not stack.is_empty():
		var node_id: int = stack.pop_back()
		if seen.has(node_id):
			continue
		seen[node_id] = true
		for other_id: int in map.get_node_by_id(node_id).link_ids:
			if not seen.has(other_id):
				stack.append(other_id)
	return seen


func _signature(map: RunMap) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for node: RunMapNode in map.nodes:
		parts.append("%d:%d:%d" % [node.id, node.kind, int(node.pos.x)])
	return "/".join(parts)

func _point_to_segment(point: Vector2, a: Vector2, b: Vector2) -> float:
	var span: Vector2 = b - a
	var length_sq: float = span.length_squared()
	if length_sq < 0.0001:
		return point.distance_to(a)
	var t: float = clampf((point - a).dot(span) / length_sq, 0.0, 1.0)
	return point.distance_to(a + span * t)
