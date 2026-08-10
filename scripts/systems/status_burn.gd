class_name StatusBurn
extends Node

## 화상 상태 (docs/systems/BOONS.md 8.1 계열 고유 상태, 규칙 51).
##
## 적 개체가 소유한다. 어느 권능이 붙였는지와 무관하게 대상당 인스턴스는 하나이며,
## 스택만 쌓인다. 스택 상한과 지속 시간은 플레이어 쪽 값(권능 보유 상태)을 부여
## 시점에 넘겨받아 갱신한다. 적이 그 값을 참조하는 구조다 (9장).
##
## 틱마다 스택 수에 비례한 피해를 준다. 피해는 Health로 직접 넣는다. Hurtbox를 거치면
## 적의 피격 경직과 넉백이 매 틱 발생해 적이 영구히 굳는다.

## 스택이 바뀌었다. current, cap (HUD 표식용)
signal stacks_changed(current: int, cap: int)

## 화상 피해가 들어가는 주기 (초)
const TICK_INTERVAL: float = 1.0

var _stacks: int = 0
var _cap: int = 1
var _damage_per_stack: float = 1.0
var _time_left: float = 0.0
var _tick_left: float = TICK_INTERVAL
var _health: Health = null


## 대상에게 화상을 건다. 이미 붙어 있으면 스택을 더하고 지속을 갱신한다.
## 대상에 Health가 없으면 아무것도 하지 않는다.
static func apply(
	target: Node, stacks: int, duration: float, cap: int, damage_per_stack: float
) -> StatusBurn:
	if target == null or stacks <= 0:
		return null
	var health: Health = target.get_node_or_null(^"Health") as Health
	if health == null or health.is_dead():
		return null
	var burn: StatusBurn = target.get_node_or_null(^"StatusBurn") as StatusBurn
	if burn == null:
		burn = StatusBurn.new()
		burn.name = "StatusBurn"
		target.add_child(burn)
		burn._health = health
	burn._add(stacks, duration, cap, damage_per_stack)
	return burn


## 대상의 현재 화상 스택. 없으면 0 (잿불류 상한 조건 판정용).
static func stacks_on(target: Node) -> int:
	if target == null:
		return 0
	var burn: StatusBurn = target.get_node_or_null(^"StatusBurn") as StatusBurn
	return burn._stacks if burn != null else 0


func _process(delta: float) -> void:
	if _health == null or _health.is_dead():
		queue_free()
		return
	_time_left -= delta
	_tick_left -= delta
	if _tick_left <= 0.0:
		_tick_left += TICK_INTERVAL
		_burn_once()
	if _time_left <= 0.0:
		_clear()


func stacks() -> int:
	return _stacks


func cap() -> int:
	return _cap


func _add(stacks_added: int, duration: float, new_cap: int, damage_per_stack: float) -> void:
	_cap = maxi(1, new_cap)
	_damage_per_stack = damage_per_stack
	_stacks = mini(_cap, _stacks + stacks_added)
	# 지속은 갱신이다. 누적하면 오래 때린 적이 영구히 타므로 큰 쪽으로 덮어쓴다
	_time_left = maxf(_time_left, duration)
	stacks_changed.emit(_stacks, _cap)


func _burn_once() -> void:
	if _stacks <= 0 or _health == null:
		return
	var amount: int = int(round(float(_stacks) * _damage_per_stack))
	if amount <= 0:
		return
	_health.apply_damage(amount)


func _clear() -> void:
	_stacks = 0
	stacks_changed.emit(0, _cap)
	queue_free()
