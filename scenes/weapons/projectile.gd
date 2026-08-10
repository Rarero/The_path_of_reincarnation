class_name Projectile
extends Area2D

## 투사체. 플레이어와 적이 공용으로 쓴다.
## 소속은 launch에 넘기는 mask로 결정한다 (감지할 피격판정 레이어가 달라진다).
##
## 두 가지 궤도를 지원한다.
## - launch: 등속 직선. 총과 기존 원거리 공격이 쓴다
## - launch_arc: 중력을 받는 포물선. 등불 도깨비 투척이 쓴다 (docs/act1/ENEMIES.md 5.2)

## 지형에 닿거나 수명이 끝나 떨어진 지점. 착탄 마커가 이 신호로 폭발한다
signal impacted(at: Vector2)
## 플레이어 피격판정에 직접 맞아 소멸했다. 착탄 폭발은 일어나지 않는다
signal absorbed

@export var lifetime: float = 1.5

var _velocity: Vector2 = Vector2.RIGHT
var _damage: int = 8
var _time_left: float = 0.0
var _gravity: float = 0.0
## 플레이어가 쏜 것인가. 권능 훅(화상 부여)은 플레이어 발사체에만 건다
var _from_player: bool = false
## 이미 소멸 처리를 했는가. 같은 프레임에 두 번 신호가 나가지 않게 한다
var _consumed: bool = false


func _ready() -> void:
	_time_left = lifetime
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _gravity != 0.0:
		_velocity.y += _gravity * delta
		rotation = _velocity.angle()
	global_position += _velocity * delta
	_time_left -= delta
	if _time_left <= 0.0:
		_expire()


## 발사 직후 1회 호출한다.
## 플레이어 발사체로 표시한다. 발사 전에 부른다.
func mark_from_player() -> void:
	_from_player = true


## 등속 직선 발사.
func launch(direction: Vector2, damage: int, speed: float, mask: int) -> void:
	_velocity = direction.normalized() * speed
	_damage = damage
	_gravity = 0.0
	collision_mask = mask
	rotation = _velocity.angle()


## 포물선 발사. target에 flight_time 후 떨어지도록 초기 속도를 역산한다.
## 물리 적분(semi-implicit Euler)까지 반영한 식이라 마커와 실제 착탄이 어긋나지 않는다.
## flight_time은 패링 하한(검 1타 windup 0.10초) 이상이어야 한다
## (docs/DECISIONS.md 2026-08-07 패링 신설, D11 인계)
func launch_arc(
	target: Vector2, damage: int, flight_time: float, arc_gravity: float, mask: int
) -> void:
	var time: float = maxf(0.05, flight_time)
	var step: float = 1.0 / float(maxi(1, Engine.physics_ticks_per_second))
	var offset: Vector2 = target - global_position
	_velocity = Vector2(
		offset.x / time, (offset.y - 0.5 * arc_gravity * time * (time + step)) / time
	)
	_damage = damage
	_gravity = arc_gravity
	collision_mask = mask
	rotation = _velocity.angle()
	# 착탄까지 날아갈 시간을 확보한다. 기존 lifetime이 더 짧으면 공중에서 사라진다
	lifetime = maxf(lifetime, time + 0.5)
	_time_left = lifetime


## 남은 비행 시간 (초). 마커가 폭발 시점을 맞추는 데 쓴다
func time_left() -> float:
	return _time_left


func _on_area_entered(area: Area2D) -> void:
	var hurtbox: Hurtbox = area as Hurtbox
	if hurtbox == null or _consumed:
		return
	var dealt: int = hurtbox.receive_hit(_damage, global_position)
	# 피해가 0이면(무적 대시, 이미 죽은 대상 등) 소멸시키지 않고 통과시킨다.
	# 여기서 없애면 예고된 착탄 폭발이 사라져, 마커를 보고 비키는 회피 규칙이
	# 대시 한 번으로 무력화된다 (docs/act1/ENEMIES.md 5.2)
	if dealt <= 0:
		return
	_consumed = true
	if _from_player:
		BoonRuntime.notify_ranged_hit(hurtbox)
	absorbed.emit()
	queue_free()


func _on_body_entered(_body: Node2D) -> void:
	_expire()


## 지형에 닿거나 수명이 끝났다. 착탄 지점을 알리고 사라진다
func _expire() -> void:
	if _consumed:
		return
	_consumed = true
	impacted.emit(global_position)
	queue_free()
