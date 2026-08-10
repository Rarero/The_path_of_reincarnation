class_name Hitbox
extends Area2D

## 공격 판정 영역. 활성화된 동안 겹친 Hurtbox에 피해를 준다.
## 한 번의 활성화에서 같은 대상을 여러 번 때리지 않는다.
## 생기 몰림 배율은 damage_multiplier로 외부에서 주입한다 (docs/RUN_STRUCTURE.md 9장).

signal hit_landed(target: Hurtbox, amount: int)

@export var damage: int = 10
## 활성 유지 시간 (초). 0 이하면 수동으로 deactivate를 호출해야 한다
@export var active_duration: float = 0.12

var damage_multiplier: float = 1.0

var _active: bool = false
var _time_left: float = 0.0
var _already_hit: Array[Hurtbox] = []


func _ready() -> void:
	monitoring = false
	set_physics_process(false)


## Area2D의 겹침은 물리 틱마다 갱신된다. 렌더 프레임에서 검사하면
## 프레임레이트에 따라 짧은 판정 창이 통째로 건너뛰어진다.
func _physics_process(delta: float) -> void:
	_scan()
	if active_duration <= 0.0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		deactivate()


## 판정을 켠다. 이전 활성화의 타격 기록은 초기화된다.
##
## monitoring은 반드시 set_deferred로 바꾼다. 물리 질의를 처리하는 중에 직접 대입하면
## Godot이 "Can't change this state while flushing queries"로 변경을 버린다. 낙석과
## 바람 장애물은 보스의 _physics_process 안에서 생성되어 곧바로 activate를 부르므로
## 정확히 이 경우에 걸렸고, 판정이 영영 켜지지 않아 피해가 0이었다
## (2026-08-10 사용자 보고: 돌과 날아오는 장애물에 피격 판정이 없다).
func activate() -> void:
	_active = true
	_time_left = active_duration
	_already_hit.clear()
	set_deferred(&"monitoring", true)
	set_physics_process(true)


func deactivate() -> void:
	_active = false
	_time_left = 0.0
	set_deferred(&"monitoring", false)
	set_physics_process(false)


func is_active() -> bool:
	return _active


func final_damage() -> int:
	return int(round(float(damage) * damage_multiplier))


## 피해가 0으로 막힌 겹침은 타격 기록에 남기지 않는다. 남기면 무적 시간에 처음 닿은
## 낙석이 무적이 풀린 뒤에도 계속 겹쳐 있으면서 끝까지 피해를 주지 못한다
## (2026-08-08 사용자 보고: 낙하하는 돌과 날아오는 물체에 피해가 없는 경우가 잦음).
func _scan() -> void:
	if not _active:
		return
	for area: Area2D in get_overlapping_areas():
		var hurtbox: Hurtbox = area as Hurtbox
		if hurtbox == null or _already_hit.has(hurtbox):
			continue
		var dealt: int = hurtbox.receive_hit(final_damage(), global_position)
		if dealt <= 0:
			continue
		_already_hit.append(hurtbox)
		hit_landed.emit(hurtbox, dealt)
