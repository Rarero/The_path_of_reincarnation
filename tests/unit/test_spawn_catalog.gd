extends GdUnitTestSuite

## 배치 대상 목록 검증 (scripts/map/spawn_catalog.gd).
##
## docs/act1/ENEMIES.md 2장 위협 포인트 표와 EnemyStats.threat_pt가 어긋나지 않게 고정한다.

const EPSILON: float = 0.001
## docs/act1/ENEMIES.md 2장 위협 포인트 예산제 표
const DESIGN_THREAT: Dictionary = {
	&"goblin_charger": 1.0,
	&"egg_dokkaebi": 0.5,
	&"lantern_shooter": 1.5,
	&"fence_dokkaebi": 2.0,
	&"ssireum_wrestler": 4.0,
}


func test_all_design_enemies_are_listed() -> void:
	for id: StringName in DESIGN_THREAT:
		assert_bool(SpawnCatalog.has_entry(id)).is_true()
		assert_bool(SpawnCatalog.is_enemy(id)).is_true()
	assert_int(SpawnCatalog.all_enemy_ids().size()).is_equal(DESIGN_THREAT.size())


func test_threat_points_match_the_design_table() -> void:
	for id: StringName in DESIGN_THREAT:
		var gap: float = absf(SpawnCatalog.threat_pt(id) - float(DESIGN_THREAT[id]))
		assert_bool(gap < EPSILON).is_true()


## 수치의 권위는 .tres다. 구현된 개체는 리소스 값과 표가 같아야 한다
func test_threat_points_match_enemy_stats_resources() -> void:
	for id: StringName in SpawnCatalog.all_enemy_ids():
		var path: String = SpawnCatalog.stats_path(id)
		if path.is_empty():
			continue
		var stats: EnemyStats = load(path) as EnemyStats
		assert_object(stats).is_not_null()
		var gap: float = absf(stats.threat_pt - SpawnCatalog.threat_pt(id))
		assert_bool(gap < EPSILON).is_true()


func test_available_entries_point_at_existing_scenes() -> void:
	for id: StringName in SpawnCatalog.ENTRIES:
		var path: String = SpawnCatalog.scene_path(id)
		if path.is_empty():
			continue
		assert_bool(ResourceLoader.exists(path)).is_true()


func test_tags_are_known() -> void:
	for id: StringName in SpawnCatalog.ENTRIES:
		assert_bool(SpawnCatalog.KNOWN_TAGS.has(SpawnCatalog.tag_of(id))).is_true()


## 씬 경로가 빈 항목은 데이터만 있고 배치 후보에서는 빠진다.
##
## 2026-08-10: 개체 이름을 박아 두었더니 구현이 끝난 뒤에도 "미구현"으로 단정해
## 실패했다. 개체 목록이 아니라 규칙 자체를 고정한다. 지금은 전부 구현되어 있어
## 미구현 쪽 순회가 공집합이고, 새 개체를 데이터만 넣는 순간 다시 의미를 갖는다
func test_entries_without_a_scene_are_data_only() -> void:
	var available: Array[StringName] = SpawnCatalog.available_enemy_ids()
	for id: StringName in SpawnCatalog.ENTRIES:
		if not DESIGN_THREAT.has(id):
			continue
		var has_scene: bool = not SpawnCatalog.scene_path(id).is_empty()
		assert_bool(available.has(id)).is_equal(has_scene)


func test_slot_kinds_accept_the_expected_tags() -> void:
	var empty: PackedStringArray = PackedStringArray()
	var ground: PackedStringArray = SpawnSlot.accepts_for(SpawnSlot.Kind.GROUND, empty)
	assert_bool(ground.has("ground")).is_true()
	assert_bool(ground.has("high")).is_false()
	var air: PackedStringArray = SpawnSlot.accepts_for(SpawnSlot.Kind.AIR, empty)
	assert_bool(air.has("ground")).is_false()
	assert_bool(air.has("high")).is_true()
	var high: PackedStringArray = SpawnSlot.accepts_for(SpawnSlot.Kind.HIGH, empty)
	assert_bool(high.has("ground")).is_true()
	assert_bool(high.has("high")).is_true()
	var extra: PackedStringArray = SpawnSlot.accepts_for(
		SpawnSlot.Kind.GROUND, PackedStringArray(["lane"])
	)
	assert_bool(extra.has("lane")).is_true()
