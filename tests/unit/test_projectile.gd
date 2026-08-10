extends GdUnitTestSuite

## 투사체 궤도 검증 (scenes/weapons/projectile.gd).
##
## 포물선 투척은 착탄 마커가 위험 범위를 미리 알려 주는 것이 본체라
## 실제 착탄이 마커와 어긋나면 예고가 거짓이 된다. 그 정합을 여기서 고정한다
## (docs/act1/ENEMIES.md 5.2, docs/DECISIONS.md 2026-08-06 D11).

const BOLT_SCENE: String = "res://scenes/weapons/lantern_bolt.tscn"
const SHOOTER_SCENE: String = "res://scenes/enemies/enemy_shooter.tscn"
const HWANDO: String = "res://resources/weapons/hwando.tres"
const STEP: float = 1.0 / 60.0


func _new_bolt() -> Projectile:
	var packed: PackedScene = load(BOLT_SCENE) as PackedScene
	var bolt: Projectile = auto_free(packed.instantiate()) as Projectile
	add_child(bolt)
	# 엔진 틱과 수동 틱이 겹치면 시간이 두 배로 흐른다. 테스트는 수동 틱만 쓴다
	bolt.set_physics_process(false)
	return bolt


func _tick(bolt: Projectile, seconds: float) -> void:
	var ticks: int = int(round(seconds / STEP))
	for _i: int in range(ticks):
		bolt._physics_process(STEP)


## 지정한 비행 시간 뒤 목표 지점에 도달한다. 물리 적분 오차까지 보정된 식이다
func test_arc_lands_on_the_target_after_the_flight_time() -> void:
	var bolt: Projectile = _new_bolt()
	bolt.global_position = Vector2.ZERO
	var target: Vector2 = Vector2(180.0, 40.0)
	bolt.launch_arc(target, 8, 0.9, 800.0, 9)
	_tick(bolt, 0.9)
	assert_bool(bolt.global_position.distance_to(target) < 2.0).is_true()


## 위로 던지는 경우에도 같다. 등불 도깨비가 지붕에서 아래로 던지는 반대 상황이다
func test_arc_lands_on_an_upward_target() -> void:
	var bolt: Projectile = _new_bolt()
	bolt.global_position = Vector2.ZERO
	var target: Vector2 = Vector2(-120.0, -60.0)
	bolt.launch_arc(target, 8, 0.9, 800.0, 9)
	_tick(bolt, 0.9)
	assert_bool(bolt.global_position.distance_to(target) < 2.0).is_true()


## 포물선은 직선보다 위로 솟는다. 중간 지점이 시작과 끝을 이은 선보다 높아야 한다
func test_arc_rises_above_the_straight_line() -> void:
	var bolt: Projectile = _new_bolt()
	bolt.global_position = Vector2.ZERO
	var target: Vector2 = Vector2(200.0, 0.0)
	bolt.launch_arc(target, 8, 0.9, 800.0, 9)
	_tick(bolt, 0.45)
	# y는 아래로 갈수록 커진다. 중간 지점이 시작선보다 확실히 위여야 한다
	assert_bool(bolt.global_position.y < -40.0).is_true()


## 등속 직선 발사는 중력을 받지 않는다 (총과 기존 원거리 공격의 경로)
func test_straight_launch_keeps_its_height() -> void:
	var bolt: Projectile = _new_bolt()
	bolt.global_position = Vector2.ZERO
	bolt.launch(Vector2.RIGHT, 8, 200.0, 9)
	_tick(bolt, 0.5)
	assert_float(bolt.global_position.y).is_equal_approx(0.0, 0.001)
	assert_float(bolt.global_position.x).is_equal_approx(100.0, 0.5)


## 패링이 성립하려면 발사체 비행 시간이 검 1타 windup 이상이어야 한다
## (docs/DECISIONS.md 2026-08-07 패링 신설, D11 인계 항목)
func test_lantern_flight_time_clears_the_parry_floor() -> void:
	var packed: PackedScene = load(SHOOTER_SCENE) as PackedScene
	var enemy: Node = auto_free(packed.instantiate())
	add_child(enemy)
	enemy.set_physics_process(false)
	var sword: WeaponDef = load(HWANDO) as WeaponDef
	assert_object(sword).is_not_null()
	var parry_floor: float = sword.combo_step(0).windup
	var flight: float = float(enemy.get(&"flight_time"))
	assert_bool(flight >= parry_floor).is_true()
