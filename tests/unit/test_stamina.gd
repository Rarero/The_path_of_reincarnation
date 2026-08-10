extends GdUnitTestSuite

## 스태미나 컴포넌트 검증. 대시(완전 회피) 3~4회 보장 가설을 수치로 고정한다.

const DASH_COST: float = 30.0


func _make_stamina() -> Stamina:
	var stamina: Stamina = auto_free(Stamina.new())
	stamina.maximum = 100.0
	stamina.regen_per_second = 45.0
	stamina.regen_delay = 0.25
	add_child(stamina)
	return stamina


func test_starts_full() -> void:
	var stamina: Stamina = _make_stamina()
	assert_float(stamina.current()).is_equal_approx(100.0, 0.001)
	assert_float(stamina.ratio()).is_equal_approx(1.0, 0.001)


func test_three_consecutive_dashes_are_allowed() -> void:
	var stamina: Stamina = _make_stamina()
	assert_bool(stamina.spend(DASH_COST)).is_true()
	assert_bool(stamina.spend(DASH_COST)).is_true()
	assert_bool(stamina.spend(DASH_COST)).is_true()
	assert_float(stamina.current()).is_equal_approx(10.0, 0.001)


func test_fourth_dash_without_regen_fails() -> void:
	var stamina: Stamina = _make_stamina()
	for _i: int in range(3):
		stamina.spend(DASH_COST)
	assert_bool(stamina.spend(DASH_COST)).is_false()


func test_regen_waits_for_delay() -> void:
	var stamina: Stamina = _make_stamina()
	stamina.spend(DASH_COST)
	stamina.tick(0.2)
	assert_float(stamina.current()).is_equal_approx(70.0, 0.001)


func test_regen_after_delay() -> void:
	var stamina: Stamina = _make_stamina()
	stamina.spend(DASH_COST)
	stamina.tick(0.25)
	stamina.tick(1.0)
	assert_float(stamina.current()).is_equal_approx(100.0, 0.001)


func test_regen_does_not_exceed_maximum() -> void:
	var stamina: Stamina = _make_stamina()
	stamina.tick(5.0)
	assert_float(stamina.current()).is_equal_approx(100.0, 0.001)


func test_default_values_support_three_dashes() -> void:
	var stamina: Stamina = auto_free(Stamina.new())
	add_child(stamina)
	var dashes: int = 0
	while stamina.spend(DASH_COST):
		dashes += 1
	assert_int(dashes).is_greater_equal(3)


func test_refill_clears_delay() -> void:
	var stamina: Stamina = _make_stamina()
	stamina.spend(DASH_COST)
	stamina.refill()
	assert_float(stamina.current()).is_equal_approx(100.0, 0.001)
	assert_bool(stamina.can_spend(DASH_COST)).is_true()
