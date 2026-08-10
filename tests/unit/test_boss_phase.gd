extends GdUnitTestSuite

## 방망이 보스 페이즈 전환 검증 (docs/act1/BOSS.md 8). 체력 비율 문턱으로 전환한다.

const BOSS_SCENE: PackedScene = preload("res://scenes/bosses/dokkaebi_bangmangi.tscn")


func test_starts_in_phase_one() -> void:
	var boss: BossBase = auto_free(BOSS_SCENE.instantiate()) as BossBase
	add_child(boss)
	assert_int(boss.phase).is_equal(1)


func test_transitions_to_phase_two_below_half_health() -> void:
	var boss: BossBase = auto_free(BOSS_SCENE.instantiate()) as BossBase
	add_child(boss)
	var damage: int = boss.health.maximum / 2 + 10
	boss.health.apply_damage(damage)
	boss._check_phase()
	assert_int(boss.phase).is_equal(2)
