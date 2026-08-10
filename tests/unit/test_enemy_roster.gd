extends GdUnitTestSuite

## 1막 라인업의 배선 검증 (docs/act1/ENEMIES.md 4장 라인업, 9장 파일 규격).
## 2026-08-10: 짐꾼 도깨비를 라인업에서 뺐다 (조형과 패턴 재설계 후 재합류). 현재 5종.
##
## 개체 하나를 붙일 때 손대야 하는 곳이 넷이다. SpawnCatalog 항목, EnemyStats .tres,
## 씬, 그리고 배치 로스터다. 넷 중 하나만 빠져도 게임 안에서는 조용히 안 나온다.
## 실제로 2026-08-09까지 4종이 카탈로그에만 이름이 있고 씬과 스탯이 비어 있어
## 배치 후보에서 통째로 빠져 있었다. 그 상태가 다시 생기지 않게 여기서 고정한다.

## docs/act1/ENEMIES.md 2장 위협 포인트 표 (현재 5종)
const DESIGN_ENEMIES: Dictionary = {
	&"goblin_charger": 1.0,
	&"lantern_shooter": 1.5,
	&"fence_dokkaebi": 2.0,
	&"ssireum_wrestler": 4.0,
	&"egg_dokkaebi": 0.5,
}

const EPSILON: float = 0.001


## 라인업 전부가 실제로 배치 가능한 상태여야 한다 (씬과 스탯이 모두 있다).
func test_all_six_enemies_are_placeable() -> void:
	var available: Array[StringName] = SpawnCatalog.available_enemy_ids()
	for id: StringName in DESIGN_ENEMIES:
		assert_bool(SpawnCatalog.is_enemy(id)).is_true()
		assert_bool(available.has(id)).is_true()
	assert_int(available.size()).is_equal(DESIGN_ENEMIES.size())


## 카탈로그가 가리키는 경로가 실제로 존재해야 한다.
func test_scene_and_stats_paths_exist() -> void:
	for id: StringName in DESIGN_ENEMIES:
		assert_bool(ResourceLoader.exists(SpawnCatalog.scene_path(id))).is_true()
		assert_bool(ResourceLoader.exists(SpawnCatalog.stats_path(id))).is_true()


## 위협 pt는 카탈로그와 EnemyStats 양쪽에 있다. 두 값이 갈라지면 예산제가 틀어진다.
func test_threat_points_match_between_catalog_and_stats() -> void:
	for id: StringName in DESIGN_ENEMIES:
		var design: float = float(DESIGN_ENEMIES[id])
		assert_float(SpawnCatalog.threat_pt(id)).is_equal_approx(design, EPSILON)
		var stats: EnemyStats = load(SpawnCatalog.stats_path(id)) as EnemyStats
		assert_object(stats).is_not_null()
		assert_float(stats.threat_pt).is_equal_approx(design, EPSILON)


## 모든 공격 패턴이 반응 임계(14f / 0.23초)를 넘어야 한다.
## docs/act1/ENEMIES.md 1장 반응 가능성 우선 원칙이고 D11 결정 2가 다시 확인한 규칙이다.
func test_every_pattern_is_reactable() -> void:
	for id: StringName in DESIGN_ENEMIES:
		var stats: EnemyStats = load(SpawnCatalog.stats_path(id)) as EnemyStats
		for pattern: AttackPattern in stats.patterns_by_range():
			assert_bool(pattern.is_reactable()).override_failure_message(
				"%s 의 %s 예비가 %d프레임이라 반응 임계 미만이다"
				% [String(id), pattern.display_name, pattern.windup_frames]
			).is_true()


## 배치 로스터에 나오는 id는 전부 카탈로그에 있어야 한다.
## 오타 하나면 그 개체가 조용히 안 나온다.
func test_roster_ids_exist_in_catalog() -> void:
	for pattern_name: String in RoomPopulator.PATTERNS:
		var spec: Dictionary = RoomPopulator.PATTERNS[pattern_name]
		for id: StringName in spec["roster"] as Dictionary:
			assert_bool(SpawnCatalog.has_entry(id)).override_failure_message(
				"%s 로스터의 %s 가 카탈로그에 없다" % [pattern_name, String(id)]
			).is_true()
		for id: StringName in spec["caps"] as Dictionary:
			assert_bool(SpawnCatalog.has_entry(id)).is_true()


## 라인업 전부가 적어도 한 방 패턴에는 등장해야 한다. 구현해 놓고 배치에서 빠뜨리는 것을 막는다.
func test_every_enemy_appears_in_some_room_pattern() -> void:
	var placed: Dictionary = {}
	for pattern_name: String in RoomPopulator.PATTERNS:
		var spec: Dictionary = RoomPopulator.PATTERNS[pattern_name]
		for id: StringName in spec["roster"] as Dictionary:
			placed[id] = true
	for id: StringName in DESIGN_ENEMIES:
		assert_bool(placed.has(id)).override_failure_message(
			"%s 가 어느 방 패턴 로스터에도 없다" % String(id)
		).is_true()

