class_name Health
extends Node

## 체력 컴포넌트. 적과 플레이어가 공용으로 쓴다.
## 피해 계산에는 배율(생기 몰림)을 곱한 결과를 넘겨받는다. 배율 계산은 호출자 책임.

signal health_changed(current: int, maximum: int)
signal damaged(amount: int)
signal died

@export var maximum: int = 100

## 치명 피해 직전 호출되는 가드. true를 반환하면 체력 1로 생존한다 (유물 군번줄 등).
## 적은 설정하지 않으므로 영향받지 않는다.
var lethal_guard: Callable = Callable()

## 피해가 적용되기 전에 값을 걸러내는 함수. 들어온 피해량을 받아 바꾼 값을 돌려준다
## (권능 받는 피해 감소 등). 적은 설정하지 않으므로 영향받지 않는다.
var damage_filter: Callable = Callable()

var _current: int = 0
var _invulnerable: bool = false


func _ready() -> void:
	_current = maximum
	health_changed.emit(_current, maximum)


## 피해를 적용한다. 실제로 깎인 양을 반환한다.
func apply_damage(amount: int) -> int:
	if amount <= 0 or _invulnerable or is_dead():
		return 0
	if damage_filter.is_valid():
		amount = int(damage_filter.call(amount))
		if amount <= 0:
			return 0
	var before: int = _current
	var after: int = before - amount
	if after <= 0 and lethal_guard.is_valid() and bool(lethal_guard.call()):
		after = 1
	_current = maxi(0, after)
	var dealt: int = before - _current
	if dealt > 0:
		damaged.emit(dealt)
		health_changed.emit(_current, maximum)
	if is_dead():
		died.emit()
	return dealt


## 회복한다. 실제로 회복된 양을 반환한다.
func heal(amount: int) -> int:
	if amount <= 0 or is_dead():
		return 0
	var before: int = _current
	_current = mini(maximum, _current + amount)
	var healed: int = _current - before
	if healed > 0:
		health_changed.emit(_current, maximum)
	return healed


## 최대 체력으로 되돌린다 (방 리셋, 테스트용).
func refill() -> void:
	_current = maximum
	health_changed.emit(_current, maximum)


## 현재 체력을 직접 지정한다 (이어하기 복원 전용). 사망 시그널은 내지 않는다.
func set_current(value: int) -> void:
	_current = clampi(value, 0, maximum)
	health_changed.emit(_current, maximum)


func current() -> int:
	return _current


func is_dead() -> bool:
	return _current <= 0


func set_invulnerable(value: bool) -> void:
	_invulnerable = value


func is_invulnerable() -> bool:
	return _invulnerable
