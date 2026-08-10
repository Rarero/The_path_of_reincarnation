extends GdUnitTestSuite

## 생기 몰림 타이머 규칙 검증 (docs/RUN_STRUCTURE.md 9장).


func test_inactive_before_threshold() -> void:
	var timer: RageTimer = RageTimer.new(90.0, 10.0)
	timer.advance(89.0)
	assert_bool(timer.is_active()).is_false()
	assert_int(timer.stage()).is_equal(0)
	assert_float(timer.enemy_multiplier()).is_equal_approx(1.0, 0.001)
	assert_float(timer.player_multiplier()).is_equal_approx(1.0, 0.001)


func test_activates_at_threshold() -> void:
	var timer: RageTimer = RageTimer.new(90.0, 10.0)
	var changed: bool = timer.advance(90.0)
	assert_bool(changed).is_true()
	assert_int(timer.stage()).is_equal(1)


func test_stage_increases_by_interval() -> void:
	var timer: RageTimer = RageTimer.new(90.0, 10.0)
	timer.advance(90.0)
	timer.advance(10.0)
	assert_int(timer.stage()).is_equal(2)
	timer.advance(20.0)
	assert_int(timer.stage()).is_equal(4)


func test_enemy_scales_faster_than_player() -> void:
	var timer: RageTimer = RageTimer.new(90.0, 10.0)
	timer.advance(110.0)
	assert_int(timer.stage()).is_equal(3)
	assert_float(timer.enemy_multiplier()).is_equal_approx(1.75, 0.001)
	assert_float(timer.player_multiplier()).is_equal_approx(1.30, 0.001)
	assert_bool(timer.enemy_multiplier() > timer.player_multiplier()).is_true()


func test_multipliers_are_capped() -> void:
	var timer: RageTimer = RageTimer.new(90.0, 10.0)
	timer.advance(600.0)
	assert_float(timer.enemy_multiplier()).is_equal_approx(timer.enemy_cap, 0.001)
	assert_float(timer.player_multiplier()).is_equal_approx(timer.player_cap, 0.001)


func test_reset_clears_state() -> void:
	var timer: RageTimer = RageTimer.new(90.0, 10.0)
	timer.advance(150.0)
	timer.reset()
	assert_int(timer.stage()).is_equal(0)
	assert_float(timer.elapsed()).is_equal_approx(0.0, 0.001)
	assert_float(timer.time_to_trigger()).is_equal_approx(90.0, 0.001)


func test_time_to_trigger_counts_down_then_clamps() -> void:
	var timer: RageTimer = RageTimer.new(90.0, 10.0)
	timer.advance(82.0)
	assert_float(timer.time_to_trigger()).is_equal_approx(8.0, 0.001)
	timer.advance(30.0)
	assert_float(timer.time_to_trigger()).is_equal_approx(0.0, 0.001)


func test_advance_reports_change_only_once_per_stage() -> void:
	var timer: RageTimer = RageTimer.new(90.0, 10.0)
	timer.advance(90.0)
	assert_bool(timer.advance(1.0)).is_false()
	assert_bool(timer.advance(9.0)).is_true()
