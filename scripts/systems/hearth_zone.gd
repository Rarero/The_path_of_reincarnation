class_name HearthZone
extends Area2D

## 아궁이 불자리 (docs/systems/BOONS.md 8.6 조왕 액티브).
##
## 발밑에 놓이고, 그 위에 선 적에게 주기적으로 화상을 쌓는다. 지속이 끝나면 사라진다.
## 씬 파일 없이 코드로 구성한다. 노드 구성이 도형 하나와 표시 하나뿐이고 이 권능 외에
## 재사용처가 없어, .tscn을 두면 오히려 수치가 두 곳으로 갈린다.

## 화상을 다시 쌓는 주기 (초). 규격값이며 스택 수는 권능 .tres가 정한다
const REAPPLY_INTERVAL: float = 1.0
## 불자리 크기 (px). 발밑 폭이라 플레이어 판정보다 조금 넓다
const ZONE_SIZE: Vector2 = Vector2(40.0, 16.0)
## 조왕 불빛 색. 적색을 섞지 않는다 (11장 조왕 이펙트 가독성)
const FLAME_COLOR: Color = Color(1.0, 0.72, 0.26, 0.55)

var _duration: float = 3.0
var _stacks: int = 1
var _reapply_left: float = 0.0


func configure(duration: float, stacks: int) -> void:
	_duration = maxf(0.1, duration)
	_stacks = maxi(1, stacks)


func _ready() -> void:
	monitoring = true
	# 적 피격판정 레이어(5)만 본다. 플레이어는 태우지 않는다
	collision_layer = 0
	collision_mask = 1 << 4
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = ZONE_SIZE
	shape.shape = rect
	add_child(shape)
	var visual: ColorRect = ColorRect.new()
	visual.color = FLAME_COLOR
	visual.size = ZONE_SIZE
	visual.position = -ZONE_SIZE * 0.5
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)
	var tween: Tween = create_tween()
	tween.tween_property(visual, ^"modulate:a", 0.35, _duration)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	_duration -= delta
	_reapply_left -= delta
	if _reapply_left > 0.0:
		return
	_reapply_left = REAPPLY_INTERVAL
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
