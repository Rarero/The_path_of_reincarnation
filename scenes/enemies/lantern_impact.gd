class_name LanternImpact
extends Node2D

## 등불알 착탄 마커와 불꽃 지대 (docs/act1/ENEMIES.md 5.2 등불알 투척).
##
## 등불 도깨비가 예비동작에 들어갈 때 착탄 예정 지점에 생성한다. 마커는 남은 시간을
## 원호로 채워 보여 주고, 투사체가 예정 지점 근처에 떨어지면 그 자리에서 몇 초간
## 타오르는 범위 불꽃이 된다 (2026-08-08 사용자 지시: 순간 폭발에서 지속 지대로 변경).
##
## 지속 지대라 한 번 켜지면 판정을 주기적으로 다시 켠다. Hitbox가 한 번의 활성에서
## 같은 대상을 두 번 때리지 않으므로, 재활성이 없으면 서 있어도 1회만 맞는다.
##
## 두 가지 안전지대가 이 규칙에서 나온다 (5.2 지형 활용 학습).
## - 마커 밖으로 이동하면 불꽃에 닿지 않는다
## - 엄폐물이 포물선을 막으면 착탄이 예정 지점에서 멀어져 불꽃 자체가 생기지 않는다
##
## 마커와 불꽃 색은 난색으로 고정한다. 청록은 도깨비불 발판 전용 색 채널이라 회피 표식에
## 쓰면 발판으로 오독된다 (docs/DESIGN_ACT1.md 2장 색 신호).

## 예정 지점에서 이 배수 안에 떨어져야 불이 붙는다. 밖이면 엄폐물에 막힌 것으로 본다
const BLOCKED_RATIO: float = 1.5
## 채움이 끝난 뒤 착탄 신호를 더 기다리는 시간 (초).
## 물리 적분 오차로 실제 착탄이 예상보다 한두 프레임 늦을 수 있어 그 폭을 흡수한다.
## 이 여유가 없으면 마커가 먼저 사라져 불꽃이 조용히 사라지는 경우가 생긴다
const IMPACT_GRACE: float = 0.30

## 마커 반지름 (px). 불꽃 판정과 같은 크기라 표시가 곧 위험 범위다
@export var radius: float = 22.0
## 불꽃이 타오르는 시간 (초). 이 값이 공격 쿨다운보다 길면 지대가 겹쳐 쌓인다
@export var burn_time: float = 2.0
## 판정을 다시 켜는 간격 (초). 지대 안에 머무는 동안 이 간격으로 다시 맞는다
@export var tick_interval: float = 0.40
## 채움에 걸리는 시간 (초). 등불 도깨비가 setup으로 실제 값을 넣는다
@export var fill_time: float = 1.0

var _damage: int = 4
var _damage_multiplier: float = 1.0
var _fill_left: float = 0.0
var _grace_left: float = 0.0
var _burn_left: float = 0.0
var _tick_left: float = 0.0
var _burning: bool = false
var _done: bool = false

@onready var _blast: Hitbox = $Blast as Hitbox
@onready var _blast_shape: CollisionShape2D = $Blast/Shape as CollisionShape2D


func _ready() -> void:
	_fill_left = fill_time
	_grace_left = IMPACT_GRACE
	_apply_radius()
	_blast.deactivate()


func _process(delta: float) -> void:
	if _burning:
		_tick_burn(delta)
		return
	if _done:
		queue_free()
		return
	if _fill_left > 0.0:
		_fill_left = maxf(0.0, _fill_left - delta)
		queue_redraw()
		return
	# 채움이 끝났다. 착탄 신호를 짧게 더 기다린 뒤 없으면 조용히 사라진다
	_grace_left = maxf(0.0, _grace_left - delta)
	if _grace_left <= 0.0:
		queue_free()


## 불꽃 지대 진행. 주기마다 판정을 다시 켜 머무는 동안 반복 피해를 준다
func _tick_burn(delta: float) -> void:
	_burn_left = maxf(0.0, _burn_left - delta)
	_tick_left = maxf(0.0, _tick_left - delta)
	if _tick_left <= 0.0 and _burn_left > 0.0:
		_tick_left = tick_interval
		_fire_tick()
	queue_redraw()
	if _burn_left <= 0.0:
		queue_free()


## 등불 도깨비가 생성 직후 호출한다. 예상 착탄 시각에 채움이 끝나도록 맞춘다
func setup(damage: int, multiplier: float, expected_wait: float) -> void:
	_damage = damage
	_damage_multiplier = multiplier
	fill_time = maxf(0.05, expected_wait)
	_fill_left = fill_time


## 투사체가 지형에 닿았다. 예정 지점 근처면 불이 붙고, 멀면 막힌 것으로 보고 취소한다
func on_projectile_impacted(at: Vector2) -> void:
	if _done or _burning:
		return
	_done = true
	if global_position.distance_to(at) > radius * BLOCKED_RATIO:
		queue_free()
		return
	_burning = true
	_burn_left = burn_time
	# 첫 판정은 착탄 즉시 준다. 지대에 서 있었으면 바로 맞는 것이 자연스럽다
	_tick_left = tick_interval
	_fire_tick()
	queue_redraw()


## 투사체가 플레이어에게 직접 맞았다. 불꽃 없이 마커만 지운다.
## 명중한 공격은 바닥에 떨어지지 않았으므로 지대가 생기지 않는다
func on_projectile_absorbed() -> void:
	if _done or _burning:
		return
	_done = true
	queue_free()


## 판정을 한 번 켠다. Hitbox가 tick_interval보다 짧게 스스로 꺼지므로 주기마다 다시 켠다
func _fire_tick() -> void:
	_blast.damage = _damage
	_blast.damage_multiplier = _damage_multiplier
	_blast.active_duration = minf(0.12, tick_interval * 0.5)
	_blast.activate()


func _apply_radius() -> void:
	var circle: CircleShape2D = _blast_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = radius


func _draw() -> void:
	if _burning:
		_draw_flame()
		return
	# 바깥 테두리는 위험 범위, 안쪽 원호는 남은 시간이다
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.7, 0.35, 0.85), 1.0)
	var progress: float = 1.0 - _fill_left / maxf(0.05, fill_time)
	var sweep: float = TAU * progress
	var inner: Color = Color(1.0, 0.85, 0.5, 0.7)
	draw_arc(Vector2.ZERO, radius * 0.62, -PI * 0.5, -PI * 0.5 + sweep, 28, inner, 2.0)


## 타오르는 지대. 남은 시간에 따라 옅어지고, 판정 주기에 맞춰 밝기가 흔들린다.
## 흔들림이 판정 주기와 같아 "지금 다시 맞는다"는 것이 눈으로 읽힌다
func _draw_flame() -> void:
	var life: float = 0.0 if burn_time <= 0.0 else _burn_left / burn_time
	var pulse: float = 0.0
	if tick_interval > 0.0:
		pulse = _tick_left / tick_interval
	var heat: float = 0.30 + 0.22 * pulse
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.55, 0.22, heat * life))
	draw_circle(Vector2.ZERO, radius * 0.6, Color(1.0, 0.82, 0.45, 0.35 * life))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(1.0, 0.75, 0.4, 0.9 * life), 1.0)
