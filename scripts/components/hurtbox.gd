class_name Hurtbox
extends Area2D

## 피격 판정 영역. 소유자의 Health로 피해를 전달한다.
## Hitbox가 이 영역을 감지해 receive_hit을 호출한다 (call down 방향 유지).

signal hit_received(amount: int, source_position: Vector2)

@export var health_path: NodePath = ^"../Health"

var _health: Health = null


func _ready() -> void:
	if not health_path.is_empty():
		_health = get_node_or_null(health_path) as Health


## Hitbox가 호출한다. 실제로 적용된 피해량을 반환한다.
func receive_hit(amount: int, source_position: Vector2) -> int:
	if _health == null:
		return 0
	var dealt: int = _health.apply_damage(amount)
	if dealt > 0:
		hit_received.emit(dealt, source_position)
	return dealt


func health() -> Health:
	return _health
