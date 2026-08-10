class_name PokerFlame
extends Area2D

## 부지깽이가 던지는 불꽃 (docs/systems/BOONS.md 8.3).
##
## 플레이어 조작과 무관하게 주기로 나간다. 조준도 발사 입력도 없으므로 무기 공격
## 속도와 무관하고 규칙 46(공격 속도 비례 금지)에 걸리지 않는다.
##
## 포물선으로 날아가며, 적에게 닿으면 화상을 붙이고 사라진다. 직접 피해는 주지 않는다.
## 피해를 주면 원거리 무기 없이도 딜이 나와 계열 역할 고정(2장)이 흔들린다.

## 던지는 속도 (px/s). 규격값이며 화상 스택 수는 권능 .tres가 정한다
const THROW_SPEED: float = 190.0
## 포물선을 만드는 중력 (px/s^2)
const ARC_GRAVITY: float = 420.0
## 초기 상승분 (px/s). 위로 살짝 띄워 포물선으로 읽히게 한다
const ARC_LIFT: float = 130.0
## 아무것도 맞히지 못했을 때 사라지기까지 (초)
const LIFETIME: float = 2.0
## 불꽃 크기 (px)
const FLAME_SIZE: Vector2 = Vector2(6.0, 6.0)
## 조왕 불빛 색. 적색을 섞지 않는다 (11장)
const FLAME_COLOR: Color = Color(1.0, 0.78, 0.3, 0.9)

var _velocity: Vector2 = Vector2.ZERO
var _time_left: float = LIFETIME
var _stacks: int = 1


func _ready() -> void:
	monitoring = true
	collision_layer = 0
	# 적 피격판정 레이어(5)
	collision_mask = 1 << 4
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = FLAME_SIZE
	shape.shape = rect
	add_child(shape)
	var visual: ColorRect = ColorRect.new()
	visual.color = FLAME_COLOR
	visual.size = FLAME_SIZE
	visual.position = -FLAME_SIZE * 0.5
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)


## 발사 직후 1회 호출한다. stacks가 0 이하면 권능 정의에서 읽는다.
func launch(direction: Vector2, stacks: int = 0) -> void:
	_velocity = direction.normalized() * THROW_SPEED + Vector2(0.0, -ARC_LIFT)
	_stacks = stacks if stacks > 0 else 1


func _physics_process(delta: float) -> void:
	_velocity.y += ARC_GRAVITY * delta
	global_position += _velocity * delta
	_time_left -= delta
	if _time_left <= 0.0:
		queue_free()
		return
	_scorch()


func _scorch() -> void:
	for area: Area2D in get_overlapping_areas():
		var hurtbox: Hurtbox = area as Hurtbox
		if hurtbox == null:
			continue
		var enemy: Node = hurtbox.get_parent()
		if enemy == null or enemy.is_in_group(&"player"):
			continue
		StatusBurn.apply(
			enemy,
			_stacks,
			BoonRuntime.burn_duration(),
			BoonRuntime.burn_stack_cap(),
			BoonRuntime.BURN_DAMAGE_PER_STACK
		)
		queue_free()
		return
