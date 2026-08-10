class_name EmberDrift
extends Sprite2D

## 배경 불똥. 천천히 떠오르다 위로 나가면 아래에서 다시 올라온다.
##
## 화면 밀도의 재료는 픽셀 디테일이 아니라 레이어 겹침과 대기 효과다
## (docs/ART_STYLE.md 5장 대기 파티클).
## 배경 전용이라 물리 틱과 무관하게 _process에서 돈다 (crowd_figure.gd와 같은 규약).

## 초당 상승 픽셀
@export var rise_speed: float = 6.0
## 이 y보다 위로 올라가면 bottom_y로 되돌린다
@export var top_y: float = 210.0
## 되돌아오는 y
@export var bottom_y: float = 336.0
## 좌우 흔들림 폭 (px). 픽셀 정합을 위해 1px 단위로 반올림한다
@export var sway_pixels: float = 2.0

var _phase: float = 0.0
var _base_x: float = 0.0
var _y: float = 0.0


func _ready() -> void:
	_base_x = position.x
	_y = position.y
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(absf(position.x * 37.0 + position.y * 19.0)) + 1
	_phase = rng.randf_range(0.0, TAU)


func _process(delta: float) -> void:
	_y -= rise_speed * delta
	if _y < top_y:
		_y = bottom_y
	_phase = fmod(_phase + delta * 1.4, TAU)
	position = Vector2(_base_x + roundf(sin(_phase) * sway_pixels), roundf(_y))
