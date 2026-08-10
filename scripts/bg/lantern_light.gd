class_name LanternLight
extends PointLight2D

## 배경 광원의 느린 흔들림 (docs/DESIGN_ACT1.md 2.5 조명 규칙).
##
## 밝기와 가로 위치를 낮은 진폭으로 흔들어 정지 화면을 살린다.
## 픽셀 정합을 위해 위치 흔들림은 1px 단위로 반올림한다.
## 배경 전용이라 물리 틱과 무관하게 _process에서 돈다 (crowd_figure.gd와 같은 규약).

## 밝기 흔들림 비율. 기준 에너지 대비 진폭이다
@export var energy_amount: float = 0.18
## 흔들림 한 주기 (초). 개체마다 편차가 더해진다
@export var period: float = 2.6
## 가로 흔들림 폭 (px). 0이면 위치를 흔들지 않는다
@export var sway_pixels: float = 1.0

var _base_energy: float = 1.0
var _base_position: Vector2 = Vector2.ZERO
var _phase: float = 0.0
var _speed: float = 1.0


func _ready() -> void:
	_base_energy = energy
	_base_position = position
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(absf(position.x * 61.0 + position.y * 29.0)) + 1
	_phase = rng.randf_range(0.0, TAU)
	_speed = TAU / maxf(period, 0.1) * rng.randf_range(0.85, 1.15)


func _process(delta: float) -> void:
	_phase = fmod(_phase + _speed * delta, TAU)
	energy = _base_energy * (1.0 + energy_amount * sin(_phase))
	if sway_pixels <= 0.0:
		return
	var sway: float = roundf(sin(_phase * 0.5) * sway_pixels)
	position = _base_position + Vector2(sway, 0.0)


## 선택 확정 응답 연출 (art_src/requests/022 E-2-3). 기준 밝기를 target_energy로
## 올렸다가 원래 값으로 되돌린다. _process가 매 프레임 energy를 _base_energy에서
## 다시 계산하므로 energy가 아니라 _base_energy를 트윈해야 흔들림 계산과 겹쳐도
## 값이 덮어써지지 않는다.
func pulse(target_energy: float, total_duration: float = 0.6) -> void:
	var start_energy: float = _base_energy
	var up_time: float = total_duration * 0.4
	var down_time: float = total_duration - up_time
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"_base_energy", target_energy, up_time)
	tween.tween_property(self, ^"_base_energy", start_energy, down_time)
