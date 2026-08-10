extends GdUnitTestSuite

## 슬롯 기반 랜덤 배치 규칙 검증 (scripts/map/room_populator.gd).
##
## 시드 재현성, 위협 포인트 예산, 조합 하드 금지, 슬롯 허용 태그를 고정한다.
## 실제 스폰과 웨이브 진행은 Godot 에디터 플레이 테스트로 검증한다.

const SEEDS: int = 60
const EPSILON: float = 0.001
const ALL_IDS: Array = [
	&"goblin_charger",
	&"lantern_shooter",
	&"fence_dokkaebi",
	&"ssireum_wrestler",
	&"egg_dokkaebi",
]


func _slot(index: int, kind: int, x: float, y: float) -> Dictionary:
	return {
		"index": index,
		"kind": kind,
		"accepts": SpawnSlot.accepts_for(kind, PackedStringArray()),
		"position": Vector2(x, y),
	}


## 표준 전투방을 흉내낸 슬롯 묶음 (지상 6, 고지대 3, 레인 3, 좌판 2)
func _sample_slots() -> Array:
	var slots: Array = []
	for i: int in range(6):
		slots.append(_slot(slots.size(), SpawnSlot.Kind.GROUND, 128.0 + i * 112.0, 336.0))
	for i: int in range(3):
		slots.append(_slot(slots.size(), SpawnSlot.Kind.HIGH, 176.0 + i * 224.0, 288.0))
	for i: int in range(3):
		slots.append(_slot(slots.size(), SpawnSlot.Kind.LANE, 208.0 + i * 176.0, 320.0))
	for i: int in range(2):
		slots.append(_slot(slots.size(), SpawnSlot.Kind.COVER, 304.0 + i * 288.0, 336.0))
	return slots


func _context(pattern: String, budget: float, waves: int, value: int) -> Dictionary:
	return {
		"pattern": pattern,
		"budget": budget,
		"wave_count": waves,
		"seed": value,
		"available_ids": ALL_IDS,
	}


func _signature(plan: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for wave: Array in plan["waves"]:
		for item: Dictionary in wave:
			parts.append("%d:%s" % [int(item["slot"]), String(item["id"])])
		parts.append("|")
	for item: Dictionary in plan["props"]:
		parts.append("p%d:%s" % [int(item["slot"]), String(item["id"])])
	return "/".join(parts)


func _wave_sum(wave: Array) -> float:
	var total: float = 0.0
	for item: Dictionary in wave:
		total += SpawnCatalog.threat_pt(item["id"])
	return total


func _count_in(wave: Array, id: StringName) -> int:
	var count: int = 0
	for item: Dictionary in wave:
		if item["id"] == id:
			count += 1
	return count


func test_same_seed_reproduces_placement() -> void:
	for value: int in [0, 7, 4242, 999983]:
		var a: Dictionary = RoomPopulator.plan(_sample_slots(), _context("alley", 10.0, 2, value))
		var b: Dictionary = RoomPopulator.plan(_sample_slots(), _context("alley", 10.0, 2, value))
		assert_str(_signature(a)).is_equal(_signature(b))


func test_different_seeds_produce_different_placements() -> void:
	var base: String = _signature(
		RoomPopulator.plan(_sample_slots(), _context("street", 10.0, 2, 0))
	)
	var differs: bool = false
	for value: int in range(1, SEEDS):
		var other: String = _signature(
			RoomPopulator.plan(_sample_slots(), _context("street", 10.0, 2, value))
		)
		if other != base:
			differs = true
			break
	assert_bool(differs).is_true()


func test_layer_budget_is_never_exceeded() -> void:
	for pattern: String in RoomPopulator.PATTERNS:
		for budget: float in [3.0, 6.0, 10.0]:
			var waves: int = 2 if budget > 6.0 else 1
			for value: int in range(SEEDS):
				var plan: Dictionary = RoomPopulator.plan(
					_sample_slots(), _context(pattern, budget, waves, value)
				)
				var total: float = 0.0
				for wave: Array in plan["waves"]:
					total += _wave_sum(wave)
				assert_bool(total <= budget + EPSILON).is_true()


func test_two_wave_room_caps_each_wave_at_sixty_percent() -> void:
	var cap: float = 10.0 * RoomPopulator.WAVE_SHARE
	for value: int in range(SEEDS):
		var plan: Dictionary = RoomPopulator.plan(
			_sample_slots(), _context("street", 10.0, 2, value)
		)
		assert_int(plan["waves"].size()).is_equal(2)
		for wave: Array in plan["waves"]:
			assert_bool(_wave_sum(wave) <= cap + EPSILON).is_true()


func test_no_two_ssireum_in_the_same_wave() -> void:
	for value: int in range(SEEDS):
		var plan: Dictionary = RoomPopulator.plan(
			_sample_slots(), _context("street", 10.0, 2, value)
		)
		for wave: Array in plan["waves"]:
			assert_int(_count_in(wave, &"ssireum_wrestler")).is_less_equal(1)


func test_fence_is_capped_at_one_per_room() -> void:
	for pattern: String in ["alley", "warehouse"]:
		for value: int in range(SEEDS):
			var plan: Dictionary = RoomPopulator.plan(
				_sample_slots(), _context(pattern, 10.0, 2, value)
			)
			var total: int = 0
			for wave: Array in plan["waves"]:
				total += _count_in(wave, &"fence_dokkaebi")
			assert_int(total).is_less_equal(1)


func test_eggs_are_never_dense() -> void:
	var slots: Array = _sample_slots()
	for value: int in range(SEEDS):
		var plan: Dictionary = RoomPopulator.plan(slots, _context("alley", 10.0, 2, value))
		for wave: Array in plan["waves"]:
			var positions: Array[Vector2] = []
			for item: Dictionary in wave:
				if item["id"] == &"egg_dokkaebi":
					positions.append(slots[int(item["slot"])]["position"])
			assert_int(positions.size()).is_less_equal(RoomPopulator.MAX_EGG_PER_WAVE)
			for i: int in range(positions.size()):
				for j: int in range(i + 1, positions.size()):
					var gap: float = positions[i].distance_to(positions[j])
					assert_bool(gap >= RoomPopulator.EGG_MIN_DISTANCE).is_true()


func test_platform_pattern_excludes_melee_and_grab() -> void:
	var banned: Array = [&"goblin_charger", &"ssireum_wrestler", &"fence_dokkaebi"]
	for value: int in range(SEEDS):
		var plan: Dictionary = RoomPopulator.plan(
			_sample_slots(), _context("platform", 10.0, 2, value)
		)
		for wave: Array in plan["waves"]:
			for item: Dictionary in wave:
				assert_bool(banned.has(item["id"])).is_false()


func test_placements_always_match_slot_tags() -> void:
	var slots: Array = _sample_slots()
	for pattern: String in RoomPopulator.PATTERNS:
		for value: int in range(SEEDS):
			var plan: Dictionary = RoomPopulator.plan(
				slots, _context(pattern, 10.0, 2, value)
			)
			for wave: Array in plan["waves"]:
				for item: Dictionary in wave:
					var accepts: PackedStringArray = slots[int(item["slot"])]["accepts"]
					assert_bool(accepts.has(SpawnCatalog.tag_of(item["id"]))).is_true()


func test_ground_slot_never_takes_lantern() -> void:
	var slots: Array = [_slot(0, SpawnSlot.Kind.GROUND, 200.0, 336.0)]
	for value: int in range(SEEDS):
		var plan: Dictionary = RoomPopulator.plan(slots, _context("street", 10.0, 1, value))
		for wave: Array in plan["waves"]:
			assert_int(_count_in(wave, &"lantern_shooter")).is_equal(0)


func test_air_slot_never_takes_melee() -> void:
	var slots: Array = [
		_slot(0, SpawnSlot.Kind.AIR, 200.0, 200.0),
		_slot(1, SpawnSlot.Kind.AIR, 400.0, 200.0),
	]
	for value: int in range(SEEDS):
		var plan: Dictionary = RoomPopulator.plan(slots, _context("street", 10.0, 1, value))
		for wave: Array in plan["waves"]:
			assert_int(_count_in(wave, &"goblin_charger")).is_equal(0)
			assert_int(_count_in(wave, &"ssireum_wrestler")).is_equal(0)


func test_slots_are_allowed_to_stay_empty() -> void:
	var slots: Array = _sample_slots()
	var enemy_slots: int = 12
	var min_filled: int = enemy_slots
	for value: int in range(SEEDS):
		var plan: Dictionary = RoomPopulator.plan(slots, _context("alley", 10.0, 2, value))
		var filled: int = 0
		for wave: Array in plan["waves"]:
			filled += wave.size()
		min_filled = mini(min_filled, filled)
	assert_int(min_filled).is_less(enemy_slots)


func test_props_only_land_on_prop_slots() -> void:
	var slots: Array = _sample_slots()
	for value: int in range(SEEDS):
		var plan: Dictionary = RoomPopulator.plan(slots, _context("street", 10.0, 2, value))
		for item: Dictionary in plan["props"]:
			var accepts: PackedStringArray = slots[int(item["slot"])]["accepts"]
			assert_bool(accepts.has(SpawnCatalog.tag_of(item["id"]))).is_true()
			assert_bool(SpawnCatalog.is_enemy(item["id"])).is_false()


func test_unavailable_entries_are_skipped_by_default() -> void:
	var context: Dictionary = _context("alley", 10.0, 2, 31)
	context.erase("available_ids")
	var plan: Dictionary = RoomPopulator.plan(_sample_slots(), context)
	for wave: Array in plan["waves"]:
		for item: Dictionary in wave:
			assert_bool(SpawnCatalog.is_available(item["id"])).is_true()
