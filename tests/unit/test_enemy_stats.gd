extends GdUnitTestSuite

## EnemyStats 스키마 검증 (scripts/data/enemy_stats.gd).
##
## D11(2026-08-06)에서 넣은 attack_damage, stagger_level, attack_patterns가
## 문서 규격대로 동작하는지 고정한다 (docs/act1/ENEMIES.md 2장, 9장).

const EPSILON: float = 0.0001
const GOBLIN: String = "res://resources/enemies/goblin_charger.tres"
const LANTERN: String = "res://resources/enemies/lantern_shooter.tres"


## 접촉 피해와 공격 피해는 별개 필드다 (ENEMIES.md 2장)
func test_contact_and_attack_damage_are_separate_fields() -> void:
	var stats: EnemyStats = EnemyStats.new()
	stats.contact_damage = 8
	stats.attack_damage = 14
	assert_int(stats.contact_damage).is_equal(8)
	assert_int(stats.attack_damage).is_equal(14)


## 경직 등급이 강할수록 경직 시간과 넉백이 줄어든다 (ENEMIES.md 3장)
func test_stagger_level_scales_down_hitstun_and_knockback() -> void:
	var stats: EnemyStats = EnemyStats.new()
	stats.stagger_level = EnemyStats.Stagger.WEAK
	assert_float(stats.stagger_time_scale()).is_equal_approx(1.0, EPSILON)
	assert_float(stats.stagger_knockback_scale()).is_equal_approx(1.0, EPSILON)
	stats.stagger_level = EnemyStats.Stagger.MEDIUM
	var medium_time: float = stats.stagger_time_scale()
	stats.stagger_level = EnemyStats.Stagger.STRONG
	var strong_time: float = stats.stagger_time_scale()
	assert_bool(medium_time < 1.0).is_true()
	assert_bool(strong_time < medium_time).is_true()
	assert_bool(strong_time > 0.0).is_true()


## 패턴은 사거리가 짧은 것부터 정렬된다. 개체가 밀착 패턴을 먼저 검사한다
func test_patterns_sort_by_range_ascending() -> void:
	var near: AttackPattern = AttackPattern.new()
	near.range_px = 20.0
	var far: AttackPattern = AttackPattern.new()
	far.range_px = 40.0
	var stats: EnemyStats = EnemyStats.new()
	stats.attack_patterns = [far, near]
	var sorted: Array[AttackPattern] = stats.patterns_by_range()
	assert_int(sorted.size()).is_equal(2)
	assert_float(sorted[0].range_px).is_equal_approx(20.0, EPSILON)
	assert_float(sorted[1].range_px).is_equal_approx(40.0, EPSILON)


## null 항목은 정렬 결과에서 걸러진다. 에디터에서 빈 슬롯을 남겨도 터지지 않아야 한다
func test_null_patterns_are_filtered_out() -> void:
	var only: AttackPattern = AttackPattern.new()
	only.range_px = 30.0
	var stats: EnemyStats = EnemyStats.new()
	stats.attack_patterns = [null, only, null]
	assert_int(stats.patterns_by_range().size()).is_equal(1)


## 잡도깨비는 근접 패턴 2종을 갖는다 (ENEMIES.md 5.1 근접 휘두르기, 연속 할퀴기)
func test_goblin_resource_carries_two_melee_patterns() -> void:
	var stats: EnemyStats = load(GOBLIN) as EnemyStats
	assert_object(stats).is_not_null()
	assert_int(stats.attack_patterns.size()).is_equal(2)
	for pattern: AttackPattern in stats.attack_patterns:
		assert_object(pattern).is_not_null()


## 근접 패턴의 사거리는 stats.attack_range 안에 들어야 한다.
## 밖이면 근접 진입 게이트를 통과하지 못해 영원히 선택되지 않는다
func test_goblin_pattern_ranges_fit_inside_attack_range() -> void:
	var stats: EnemyStats = load(GOBLIN) as EnemyStats
	for pattern: AttackPattern in stats.attack_patterns:
		assert_bool(pattern.range_px <= stats.attack_range).is_true()


## 등불 도깨비는 투척 패턴 1종을 갖는다 (ENEMIES.md 5.2 등불알 투척)
func test_lantern_resource_carries_the_throw_pattern() -> void:
	var stats: EnemyStats = load(LANTERN) as EnemyStats
	assert_object(stats).is_not_null()
	assert_int(stats.attack_patterns.size()).is_equal(1)
	assert_int(stats.attack_patterns[0].windup_frames).is_equal(24)
