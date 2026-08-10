class_name SpiritMote
extends Sprite2D

## 신당의 부유 티끌. 신기(神氣)의 인상을 만든다.
##
## 불똥(EmberDrift)과 구분되는 점이 셋이다. 색이 난색이 아니라 창백한 한색이고,
## 상승이 훨씬 느리며, 제 주기로 밝아졌다 사라진다. 나타났다 없어지는 것이
## 신비한 인상의 핵심이라 알파 호흡을 뺀 티끌은 그냥 먼지로 보인다.
##
## 도깨비불과의 분리: 청록을 쓰지 않고 1px에 저알파라 발판으로 오독되지 않는다
## (docs/DESIGN_ACT1.md 2.4 색 채널 규약).
## 배경 전용이라 물리 틱과 무관하게 _process에서 돈다 (crowd_figure.gd와 같은 규약).

## 초당 상승 픽셀. 불똥보다 훨씬 느리다
@export var rise_speed: float = 2.2
## 이 y보다 위로 올라가면 bottom_y로 되돌린다
@export var top_y: float = 150.0
## 되돌아오는 y
@export var bottom_y: float = 336.0
## 좌우 흔들림 폭 (px). 픽셀 정합을 위해 1px 단위로 반올림한다
@export var sway_pixels: float = 3.0
## 밝아졌다 사라지는 한 주기 (초)
@export var fade_period: float = 4.5

var _phase: float = 0.0
var _fade_phase: float = 0.0
var _base_x: float = 0.0
var _base_alpha: float = 1.0
var _y: float = 0.0


func _ready() -> void:
	_base_x = position.x
	_y = position.y
	_base_alpha = modulate.a
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(absf(position.x * 53.0 + position.y * 23.0)) + 1
	_phase = rng.randf_range(0.0, TAU)
	_fade_phase = rng.randf_range(0.0, TAU)


func _process(delta: float) -> void:
	_y -= rise_speed * delta
	if _y < top_y:
		_y = bottom_y
	_phase = fmod(_phase + delta * 0.7, TAU)
	_fade_phase = fmod(_fade_phase + delta * TAU / maxf(fade_period, 0.1), TAU)
	position = Vector2(_base_x + roundf(sin(_phase) * sway_pixels), roundf(_y))
	modulate.a = _base_alpha * maxf(0.0, 0.5 + 0.5 * sin(_fade_phase))
