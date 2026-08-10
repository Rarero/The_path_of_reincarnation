extends GdUnitTestSuite

## 이벤트 확정 알고리즘 검증 (docs/act1/EVENTS.md 11장 E5~E10).
##
## 맵을 여러 시드로 생성하고 결과를 확정한 뒤 필터, 한도, 중복, 표시 확률, 실점수,
## 재현성을 고정한다. 경로 예산 검증(RUN_STRUCTURE 10장 DP와 재배정)은 아직 없으므로
## E9는 실점수가 경로 합계에 들어오는지까지만 본다.

const SAMPLE_SEEDS: int = 40
const FLAGS: Dictionary = {&"blacksmith_locked": true}


func test_e5_filters_are_respected() -> void:
	for s: int in range(SAMPLE_SEEDS):
		var map: RunMap = _resolved(s)
		for node: RunMapNode in map.event_nodes():
			if not node.has_outcome():
				continue
			var outcome: EventOutcome = _pool().find_by_id(node.outcome_id)
			assert_object(outcome).is_not_null()
			assert_bool(outcome.meets_prerequisites(FLAGS)).is_true()
			# theme_tags는 강제가 아니라 우선이지만, 태그 없는 후보가 늘 남아 있어
			# 확정 결과는 언제나 그 방 테마를 받아들일 수 있어야 한다 (EVENTS 8.4)
			assert_bool(outcome.accepts_theme(node.theme)).is_true()


func test_e6_big_value_limit_per_act() -> void:
	for s: int in range(SAMPLE_SEEDS):
		var map: RunMap = _resolved(s)
		var big: int = 0
		for node: RunMapNode in map.event_nodes():
			var outcome: EventOutcome = _pool().find_by_id(node.outcome_id)
			if outcome != null and outcome.big_value:
				big += 1
		assert_int(big).is_less_equal(EventResolver.BIG_VALUE_LIMIT_PER_ACT)


func test_e7_no_duplicate_outcome_in_one_run() -> void:
	var pool: EventPool = _pool()
	for s: int in range(SAMPLE_SEEDS):
		var map: RunMap = _resolved(s)
		var events: Array[RunMapNode] = map.event_nodes()
		# 이벤트 노드 수가 풀 크기를 넘으면 중복 금지를 놓는 폴백이 돈다 (EventResolver 폴백 사다리).
		# 그 경우는 이 규칙의 대상이 아니므로 건너뛴다
		if events.size() > pool.size():
			continue
		var seen: Dictionary = {}
		for node: RunMapNode in events:
			if not node.has_outcome():
				continue
			assert_bool(seen.has(node.outcome_id)).is_false()
			seen[node.outcome_id] = true


func test_pool_is_large_enough_for_typical_maps() -> void:
	# 풀이 이벤트 노드 수보다 작으면 중복이 생긴다. 데이터가 얼마나 모자란지 눈에 보이게 둔다
	var pool: EventPool = _pool()
	var widest: int = 0
	for s: int in range(SAMPLE_SEEDS):
		widest = maxi(widest, _resolved(s).event_nodes().size())
	assert_int(pool.size()).is_greater_equal(widest)


func test_e8_displayed_odds_match_tier() -> void:
	var tiers: Dictionary = {}
	for tier: EventNodeConfig in _pool().tiers:
		tiers[tier.odds_tier] = tier
	for s: int in range(SAMPLE_SEEDS):
		var map: RunMap = _resolved(s)
		for node: RunMapNode in map.event_nodes():
			assert_bool(node.has_odds()).is_true()
			var tier: EventNodeConfig = tiers.get(node.odds_tier, null)
			assert_object(tier).is_not_null()
			assert_float(node.positive_chance).is_equal(tier.positive_chance)
			assert_int(node.positive_percent()).is_equal(tier.positive_percent())
			assert_int(node.positive_percent() + node.negative_percent()).is_equal(100)


func test_e9_actual_score_includes_event_outcome() -> void:
	for s: int in range(SAMPLE_SEEDS):
		var map: RunMap = _resolved(s)
		var events: Array[RunMapNode] = map.event_nodes()
		if events.is_empty():
			continue
		for node: RunMapNode in events:
			# 이벤트 종류 기본 점수는 0이라 실점수가 곧 확정 결과의 점수다 (10장)
			assert_int(map.kind_score(node.kind)).is_equal(0)
			assert_int(map.node_actual_score(node.id)).is_equal(node.outcome_score)
		var path: Array[int] = _first_path(map)
		var base: int = 0
		var extra: int = 0
		for node_id: int in path:
			var node: RunMapNode = map.get_node_by_id(node_id)
			base += map.kind_score(node.kind)
			extra += node.outcome_score
		assert_int(map.path_score(path)).is_equal(base + extra)


func test_e10_same_seed_reproduces_outcomes() -> void:
	for s: int in range(SAMPLE_SEEDS):
		var a: RunMap = _resolved(s)
		var b: RunMap = _resolved(s)
		assert_str(_signature(a)).is_equal(_signature(b))
		assert_int(a.path_score(_first_path(a))).is_equal(b.path_score(_first_path(b)))


func test_every_event_node_gets_an_outcome() -> void:
	for s: int in range(SAMPLE_SEEDS):
		var map: RunMap = _resolved(s)
		for node: RunMapNode in map.event_nodes():
			assert_bool(node.has_outcome()).is_true()
			assert_bool(node.theme != &"").is_true()


func test_prerequisite_blocks_unlocked_content() -> void:
	# 대장장이를 이미 해금한 런에서는 대장장이 구출이 확정되지 않는다 (EVENTS 9.3)
	var unlocked: Dictionary = {&"blacksmith_locked": false}
	for s: int in range(SAMPLE_SEEDS):
		var map: RunMap = RunMap.new()
		map.generate(s)
		EventResolver.new(_pool()).resolve(map, unlocked)
		for node: RunMapNode in map.event_nodes():
			assert_bool(node.outcome_id == &"act1_blacksmith_rescue").is_false()


# --- 헬퍼 ---


func _pool() -> EventPool:
	return EventPool.load_act1(false)


func _resolved(map_seed: int) -> RunMap:
	var map: RunMap = RunMap.new()
	map.generate(map_seed)
	EventResolver.new(_pool()).resolve(map, FLAGS)
	return map


## 시작 노드에서 보스까지 첫 간선만 따라간 경로 (실점수 합계 검사용).
func _first_path(map: RunMap) -> Array[int]:
	var path: Array[int] = [map.start_id()]
	var current: RunMapNode = map.get_node_by_id(path[0])
	while current != null and not current.link_ids.is_empty() and not map.is_boss(current.id):
		var next_id: int = _closest_to_boss(map, current)
		if next_id < 0:
			break
		path.append(next_id)
		current = map.get_node_by_id(next_id)
	return path


## 보스에 가장 가까워지는 이웃. 자유 그래프라 방향이 없어 진행 기준을 depth로 잡는다
func _closest_to_boss(map: RunMap, node: RunMapNode) -> int:
	var best: int = -1
	var best_depth: float = node.depth
	for other_id: int in node.link_ids:
		var other: RunMapNode = map.get_node_by_id(other_id)
		if other != null and other.depth > best_depth:
			best_depth = other.depth
			best = other_id
	return best


func _signature(map: RunMap) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for node: RunMapNode in map.event_nodes():
		parts.append(
			(
				"%d:%d:%s:%s:%d"
				% [node.id, node.odds_tier, node.theme, node.outcome_id, node.outcome_score]
			)
		)
	return "|".join(parts)
