extends GdUnitTestSuite

## 체력 컴포넌트 검증.


func _make_health(maximum: int) -> Health:
	var health: Health = auto_free(Health.new())
	health.maximum = maximum
	add_child(health)
	return health


func test_starts_full() -> void:
	var health: Health = _make_health(50)
	assert_int(health.current()).is_equal(50)
	assert_bool(health.is_dead()).is_false()


func test_damage_reduces_and_reports_dealt() -> void:
	var health: Health = _make_health(50)
	assert_int(health.apply_damage(12)).is_equal(12)
	assert_int(health.current()).is_equal(38)


func test_damage_does_not_go_below_zero() -> void:
	var health: Health = _make_health(20)
	assert_int(health.apply_damage(35)).is_equal(20)
	assert_int(health.current()).is_equal(0)
	assert_bool(health.is_dead()).is_true()


func test_invulnerable_blocks_damage() -> void:
	var health: Health = _make_health(30)
	health.set_invulnerable(true)
	assert_int(health.apply_damage(10)).is_equal(0)
	assert_int(health.current()).is_equal(30)


func test_heal_caps_at_maximum() -> void:
	var health: Health = _make_health(30)
	health.apply_damage(10)
	assert_int(health.heal(50)).is_equal(10)
	assert_int(health.current()).is_equal(30)


func test_dead_target_ignores_further_input() -> void:
	var health: Health = _make_health(10)
	health.apply_damage(10)
	assert_int(health.apply_damage(5)).is_equal(0)
	assert_int(health.heal(5)).is_equal(0)


func test_refill_restores_maximum() -> void:
	var health: Health = _make_health(40)
	health.apply_damage(25)
	health.refill()
	assert_int(health.current()).is_equal(40)


func test_lethal_guard_survives_at_one() -> void:
	var health: Health = _make_health(20)
	health.lethal_guard = func() -> bool: return true
	health.apply_damage(50)
	assert_int(health.current()).is_equal(1)
	assert_bool(health.is_dead()).is_false()


func test_lethal_guard_declined_allows_death() -> void:
	var health: Health = _make_health(20)
	health.lethal_guard = func() -> bool: return false
	health.apply_damage(50)
	assert_bool(health.is_dead()).is_true()
