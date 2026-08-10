extends GdUnitTestSuite

## 배경 배치 규칙 검증 (scenes/levels/bg_act1.gd plan_layout, score_layout).
##
## 순수 배치 로직만 고정한다. 실제 화면 조합(접지선, 밀도 체감)은 Windows 플레이 테스트.

const BgScript: GDScript = preload("res://scenes/levels/bg_act1.gd")
const SAMPLE_SEEDS: int = 40
const STRIP_WIDTH: float = 1024.0
const MIN_GAP: float = 12.0
const SAME_MIN_DIST: float = 160.0
const AFFINITY: Dictionary = {"a|b": 2.0, "a|c": -3.0}

const ENTRIES: Array[Dictionary] = [
	{"name": "a", "width": 68.0, "max": 1},
	{"name": "b", "width": 82.0, "max": 1},
	{"name": "c", "width": 48.0, "max": 3},
	{"name": "d", "width": 111.0, "max": 1},
	{"name": "e", "width": 48.0, "max": 3},
]


func test_same_seed_reproduces_layout() -> void:
	var a: Array[Dictionary] = _plan(12345, 7)
	var b: Array[Dictionary] = _plan(12345, 7)
	assert_int(a.size()).is_equal(b.size())
	for i: int in range(a.size()):
		assert_int(int(a[i]["index"])).is_equal(int(b[i]["index"]))
		assert_float(float(a[i]["x"])).is_equal(float(b[i]["x"]))


func test_different_seeds_differ() -> void:
	assert_bool(_signature(_plan(1, 7)) == _signature(_plan(2, 7))).is_false()


func test_min_gap_and_bounds() -> void:
	for s: int in range(SAMPLE_SEEDS):
		var placements: Array[Dictionary] = _plan(s, 7)
		var prev_end: float = -MIN_GAP
		for placement: Dictionary in placements:
			var x: float = float(placement["x"])
			assert_bool(x - prev_end >= MIN_GAP - 0.001).is_true()
			prev_end = x + float(placement["width"])
		assert_bool(prev_end <= STRIP_WIDTH).is_true()


func test_count_and_max_respected() -> void:
	for s: int in range(SAMPLE_SEEDS):
		var placements: Array[Dictionary] = _plan(s, 7)
		assert_bool(placements.size() >= 1 and placements.size() <= 7).is_true()
		var counts: Dictionary = {}
		for placement: Dictionary in placements:
			var name: String = String(placement["name"])
			counts[name] = int(counts.get(name, 0)) + 1
		assert_bool(int(counts.get("a", 0)) <= 1).is_true()
		assert_bool(int(counts.get("c", 0)) <= 3).is_true()


func test_same_element_kept_apart() -> void:
	for s: int in range(SAMPLE_SEEDS):
		var placements: Array[Dictionary] = _plan(s, 7)
		for i: int in range(placements.size()):
			for j: int in range(i + 1, placements.size()):
				if String(placements[i]["name"]) != String(placements[j]["name"]):
					continue
				var dist: float = absf(float(placements[j]["x"]) - float(placements[i]["x"]))
				assert_bool(dist >= SAME_MIN_DIST).is_true()


func test_score_prefers_friendly_neighbors() -> void:
	var friendly: Array[Dictionary] = [
		{"name": "a", "x": 100.0, "width": 68.0},
		{"name": "b", "x": 180.0, "width": 82.0},
	]
	var hostile: Array[Dictionary] = [
		{"name": "a", "x": 100.0, "width": 68.0},
		{"name": "c", "x": 180.0, "width": 48.0},
	]
	var friendly_score: float = BgScript.score_layout(friendly, AFFINITY, 48.0, SAME_MIN_DIST)
	var hostile_score: float = BgScript.score_layout(hostile, AFFINITY, 48.0, SAME_MIN_DIST)
	assert_bool(friendly_score > hostile_score).is_true()
	assert_float(friendly_score).is_equal(2.0)
	assert_float(hostile_score).is_equal(-3.0)


func test_score_ignores_distant_pairs() -> void:
	var distant: Array[Dictionary] = [
		{"name": "a", "x": 100.0, "width": 68.0},
		{"name": "c", "x": 500.0, "width": 48.0},
	]
	assert_float(BgScript.score_layout(distant, AFFINITY, 48.0, SAME_MIN_DIST)).is_equal(0.0)


func test_score_penalizes_same_too_close() -> void:
	var crowded: Array[Dictionary] = [
		{"name": "c", "x": 100.0, "width": 48.0},
		{"name": "c", "x": 200.0, "width": 48.0},
	]
	var score: float = BgScript.score_layout(crowded, AFFINITY, 48.0, SAME_MIN_DIST)
	assert_bool(score <= -100.0).is_true()


# --- 헬퍼 ---


func _plan(seed_value: int, count: int) -> Array[Dictionary]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return BgScript.plan_layout(
		rng, ENTRIES, count, STRIP_WIDTH, MIN_GAP, SAME_MIN_DIST, AFFINITY, 12
	)


func _signature(placements: Array[Dictionary]) -> String:
	var parts: PackedStringArray = []
	for placement: Dictionary in placements:
		parts.append("%s:%.2f" % [String(placement["name"]), float(placement["x"])])
	return "|".join(parts)
