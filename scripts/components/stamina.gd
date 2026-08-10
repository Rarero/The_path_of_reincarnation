class_name Stamina
extends Node

## 스태미나 컴포넌트. M1에서는 대시(완전 회피)만 소모한다 (docs/PROTOTYPE.md 2장).
## 회복은 관대하게 시작한다. 초기 가설: 연속 대시 3~4회 보장.

signal stamina_changed(current: float, maximum: float)

@export var maximum: float = 100.0
## 초당 회복량
@export var regen_per_second: float = 45.0
## 소모 후 회복이 시작되기까지의 지연 (초)
@export var regen_delay: float = 0.25

var _current: float = 0.0
var _delay_left: float = 0.0


func _ready() -> void:
	_current = maximum
	stamina_changed.emit(_current, maximum)


## 소모는 Player의 물리 틱에서 일어난다. 회복도 같은 틱에서 처리해야
## 프레임레이트에 따라 체감 수치가 달라지지 않는다.
func _physics_process(delta: float) -> void:
	tick(delta)


## 회복 처리. 테스트에서 직접 호출한다.
func tick(delta: float) -> void:
	if _delay_left > 0.0:
		_delay_left = maxf(0.0, _delay_left - delta)
		return
	if is_equal_approx(_current, maximum):
		return
	var before: float = _current
	_current = minf(maximum, _current + regen_per_second * delta)
	if not is_equal_approx(before, _current):
		stamina_changed.emit(_current, maximum)


## 소모 가능한지 확인한다.
func can_spend(amount: float) -> bool:
	return _current >= amount


## 소모한다. 성공 여부를 반환한다.
func spend(amount: float) -> bool:
	if not can_spend(amount):
		return false
	_current = maxf(0.0, _current - amount)
	_delay_left = regen_delay
	stamina_changed.emit(_current, maximum)
	return true


## 전량 소모. 범의 이빨처럼 대가를 선불로 받는 권능이 쓴다 (BOONS 8.2).
func drain_all() -> void:
	if is_zero_approx(_current):
		return
	_current = 0.0
	_delay_left = maxf(_delay_left, regen_delay)
	stamina_changed.emit(_current, maximum)


## 회복을 지정 시간만큼 막는다. 기존 회복 지연 타이머를 그대로 쓴다.
func suppress_regen(duration: float) -> void:
	_delay_left = maxf(_delay_left, duration)


func refill() -> void:
	_current = maximum
	_delay_left = 0.0
	stamina_changed.emit(_current, maximum)


func current() -> float:
	return _current


func ratio() -> float:
	if maximum <= 0.0:
		return 0.0
	return _current / maximum
