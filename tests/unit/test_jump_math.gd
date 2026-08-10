extends GdUnitTestSuite

## 점프 파라미터 파생 검증. 기획 수치(3.5타일)가 물리 값으로 정확히 옮겨지는지 확인한다.

const TILE_SIZE: int = 16
const JUMP_TILES: float = 3.5
const TIME_TO_PEAK: float = 0.36


func test_tiles_to_pixels() -> void:
	assert_float(JumpMath.tiles_to_pixels(JUMP_TILES, TILE_SIZE)).is_equal_approx(56.0, 0.001)


func test_jump_velocity_is_upward() -> void:
	var height: float = JumpMath.tiles_to_pixels(JUMP_TILES, TILE_SIZE)
	var velocity: float = JumpMath.jump_velocity(height, TIME_TO_PEAK)
	assert_bool(velocity < 0.0).is_true()


func test_derived_values_reproduce_target_height() -> void:
	var height: float = JumpMath.tiles_to_pixels(JUMP_TILES, TILE_SIZE)
	var velocity: float = JumpMath.jump_velocity(height, TIME_TO_PEAK)
	var gravity: float = JumpMath.rise_gravity(height, TIME_TO_PEAK)
	assert_float(JumpMath.peak_height(absf(velocity), gravity)).is_equal_approx(height, 0.01)


func test_shorter_descent_gives_stronger_gravity() -> void:
	var height: float = JumpMath.tiles_to_pixels(JUMP_TILES, TILE_SIZE)
	var rise: float = JumpMath.rise_gravity(height, 0.36)
	var fall: float = JumpMath.fall_gravity(height, 0.28)
	assert_bool(fall > rise).is_true()


func test_zero_time_is_guarded() -> void:
	assert_float(JumpMath.jump_velocity(56.0, 0.0)).is_equal_approx(0.0, 0.001)
	assert_float(JumpMath.rise_gravity(56.0, 0.0)).is_equal_approx(0.0, 0.001)
	assert_float(JumpMath.fall_gravity(56.0, 0.0)).is_equal_approx(0.0, 0.001)
	assert_float(JumpMath.peak_height(300.0, 0.0)).is_equal_approx(0.0, 0.001)
