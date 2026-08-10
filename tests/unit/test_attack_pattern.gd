extends GdUnitTestSuite

## AttackPattern 프레임 환산과 반응 임계 검증 (scripts/data/attack_pattern.gd).
##
## docs/act1/ENEMIES.md 5장 공격 패턴 표가 프레임 표기이고 코드는 초로 돈다.
## 환산이 어긋나면 문서와 실제 타이밍이 조용히 갈라지므로 여기서 고정한다.

const EPSILON: float = 0.0001

## docs/act1/ENEMIES.md 5장 표의 예비동작 프레임. 구현된 패턴 리소스와 대조한다
const DESIGN_WINDUP_FRAMES: Dictionary = {
	"res://resources/enemies/patterns/goblin_swing.tres": 16,
	"res://resources/enemies/patterns/goblin_claw.tres": 15,
	"res://resources/enemies/patterns/lantern_throw.tres": 24,
}


func test_frames_convert_to_seconds_at_60fps() -> void:
	var pattern: AttackPattern = AttackPattern.new()
	pattern.windup_frames = 30
	pattern.active_frames = 6
	pattern.recovery_frames = 12
	pattern.cooldown_frames = 90
	assert_float(pattern.windup()).is_equal_approx(0.5, EPSILON)
	assert_float(pattern.active()).is_equal_approx(0.1, EPSILON)
	assert_float(pattern.recovery()).is_equal_approx(0.2, EPSILON)
	assert_float(pattern.cooldown()).is_equal_approx(1.5, EPSILON)


## 반복 판정은 판정 길이와 그 사이 빈 구간을 합친 길이를 갖는다
func test_repeated_hits_extend_the_active_window() -> void:
	var pattern: AttackPattern = AttackPattern.new()
	pattern.active_frames = 4
	pattern.hit_count = 2
	pattern.hit_interval_frames = 3
	# 4f + 3f + 4f = 11f
	assert_float(pattern.active_total()).is_equal_approx(11.0 / 60.0, EPSILON)


func test_single_hit_has_no_interval_padding() -> void:
	var pattern: AttackPattern = AttackPattern.new()
	pattern.active_frames = 5
	pattern.hit_count = 1
	pattern.hit_interval_frames = 9
	assert_float(pattern.active_total()).is_equal_approx(5.0 / 60.0, EPSILON)


func test_total_time_sums_all_phases() -> void:
	var pattern: AttackPattern = AttackPattern.new()
	pattern.windup_frames = 16
	pattern.active_frames = 5
	pattern.recovery_frames = 20
	pattern.hit_count = 1
	assert_float(pattern.total_time()).is_equal_approx(41.0 / 60.0, EPSILON)


## 반응 회피 임계는 14프레임이다 (docs/DECISIONS.md 2026-08-04 예고 신호 표준)
func test_reaction_threshold_boundary() -> void:
	var pattern: AttackPattern = AttackPattern.new()
	pattern.windup_frames = AttackPattern.REACTION_THRESHOLD_FRAMES - 1
	assert_bool(pattern.is_reactable()).is_false()
	pattern.windup_frames = AttackPattern.REACTION_THRESHOLD_FRAMES
	assert_bool(pattern.is_reactable()).is_true()


## 구현된 패턴 리소스는 전부 반응 임계를 지켜야 한다.
## D11에서 임계 미달 3종을 올린 결정이 코드에서 되돌려지지 않게 고정한다
func test_shipped_patterns_respect_the_reaction_threshold() -> void:
	for path: String in DESIGN_WINDUP_FRAMES:
		var pattern: AttackPattern = load(path) as AttackPattern
		assert_object(pattern).is_not_null()
		assert_bool(pattern.is_reactable()).is_true()


## 리소스의 예비 프레임이 ENEMIES.md 5장 표와 같아야 한다
func test_shipped_patterns_match_the_design_table() -> void:
	for path: String in DESIGN_WINDUP_FRAMES:
		var pattern: AttackPattern = load(path) as AttackPattern
		assert_object(pattern).is_not_null()
		assert_int(pattern.windup_frames).is_equal(int(DESIGN_WINDUP_FRAMES[path]))


## 반복 판정 패턴은 판정 사이 빈 구간이 있어야 한다.
## 0이면 Hitbox가 같은 대상을 두 번 때리지 못해 2회 판정이 1회가 된다
func test_multi_hit_patterns_declare_an_interval() -> void:
	for path: String in DESIGN_WINDUP_FRAMES:
		var pattern: AttackPattern = load(path) as AttackPattern
		if pattern.hit_count <= 1:
			continue
		assert_int(pattern.hit_interval_frames).is_greater(0)
