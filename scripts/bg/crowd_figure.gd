class_name CrowdFigure
extends Sprite2D

## 배경 인파의 미세 동작. 프레임 시트 없이 1px 흔들림과 간헐 반전으로 살아 있게 한다.
## 배경 전용이라 물리 틱과 무관하게 _process에서 돈다 (docs/ART_STYLE.md 5장 군상 분리 제작).

## 흔들림 주기 (초). 개체별로 약간의 편차가 더해진다
@export var bob_interval: float = 0.55
## 주기마다 좌우를 뒤집을 확률
@export var flip_chance: float = 0.12

var _timer: float = 0.0
var _base_y: float = 0.0
var _up: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_base_y = position.y
	_rng.seed = int(absf(global_position.x * 31.0 + global_position.y * 17.0))
	_timer = _rng.randf_range(0.0, bob_interval)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = bob_interval + _rng.randf_range(-0.15, 0.2)
	_up = not _up
	position.y = _base_y - (1.0 if _up else 0.0)
	if _rng.randf() < flip_chance:
		flip_h = not flip_h
