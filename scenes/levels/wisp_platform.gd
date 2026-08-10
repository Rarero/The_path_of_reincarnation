class_name WispPlatform
extends Node2D

## 도깨비불 일시 발판 (docs/DESIGN_ACT1.md 3.5).
##
## 점등 조건: 플레이어 접근, 원거리/근접 공격 적중. 점등 동안만 원웨이 발판이 선다.
## 지속 후 소등, 짧은 쿨다운 뒤 재점등 가능. 쿨다운이 끝났을 때 플레이어가
## 아직 근처면 즉시 다시 점등한다.
## 색 신호: 평시 청록, 생기 몰림 발동 중 적색 (기능은 유지. DESIGN_ACT1 3.5).
## 피격 점등은 Health+Hurtbox 재사용으로 받는다 (체력은 매번 되채워 파괴되지 않는다).

enum State { UNLIT, LIT, COOLDOWN }

## 평시 불꽃 색 (청록. 색 채널 규약: 청록은 도깨비불 신호 전용)
const COLOR_CALM: Color = Color(0.35, 0.9, 0.82)
## 생기 몰림 중 불꽃 색
const COLOR_RAGE: Color = Color(0.92, 0.32, 0.28)
## 소등 임박 깜빡임 구간 (초)
const BLINK_WINDOW: float = 0.7

## 점등 지속 시간 (초. DESIGN_ACT1 3.5 초안 3초)
@export var lit_duration: float = 3.0
## 소등 후 재점등 가능까지의 쿨다운 (초)
@export var relight_cooldown: float = 0.8

var _state: int = State.UNLIT
var _time_left: float = 0.0
var _rage_active: bool = false

@onready var _shape: CollisionShape2D = $Platform/Shape as CollisionShape2D
@onready var _detect: Area2D = $Detect as Area2D
@onready var _health: Health = $Health as Health
@onready var _hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var _glow: Sprite2D = $Glow as Sprite2D
@onready var _flame: Sprite2D = $Flame as Sprite2D
@onready var _deck: Polygon2D = $PlatformVisual as Polygon2D


func _ready() -> void:
	_detect.body_entered.connect(_on_body_entered)
	_hurtbox.hit_received.connect(_on_hit_received)
	GameEvents.rage_stage_changed.connect(_on_rage_stage_changed)
	_apply_visual()


func _process(delta: float) -> void:
	if _state == State.UNLIT:
		return
	_time_left -= delta
	if _state == State.LIT:
		if _time_left <= 0.0:
			_extinguish()
		elif _time_left <= BLINK_WINDOW:
			_apply_blink()
		return
	if _time_left <= 0.0:
		_state = State.UNLIT
		_apply_visual()
		if _player_nearby():
			light()


func is_lit() -> bool:
	return _state == State.LIT


## 점등. 이미 켜져 있으면 지속 시간만 되채운다. 쿨다운 중이면 무시한다.
func light() -> void:
	if _state == State.COOLDOWN:
		return
	_time_left = lit_duration
	if _state == State.LIT:
		return
	_state = State.LIT
	_shape.set_deferred("disabled", false)
	_apply_visual()


func _extinguish() -> void:
	_state = State.COOLDOWN
	_time_left = relight_cooldown
	_shape.set_deferred("disabled", true)
	_apply_visual()


func _player_nearby() -> bool:
	for body: Node2D in _detect.get_overlapping_bodies():
		if body.is_in_group(&"player"):
			return true
	return false


func _flame_color() -> Color:
	return COLOR_RAGE if _rage_active else COLOR_CALM


## 상태별 기본 표시. 소등 시 불씨만 흐리게 남겨 위치는 계속 읽히게 한다.
func _apply_visual() -> void:
	var color: Color = _flame_color()
	_deck.visible = _state == State.LIT
	_deck.color = Color(color, 0.85)
	_flame.modulate = color if _state == State.LIT else Color(color, 0.45)
	_glow.modulate = Color(color, 0.5 if _state == State.LIT else 0.16)
	var glow_scale: float = 1.0 if _state == State.LIT else 0.6
	_glow.scale = Vector2(glow_scale, glow_scale)


## 소등 임박 깜빡임. 발판이 곧 꺼진다는 신호다.
func _apply_blink() -> void:
	var phase: bool = int(_time_left * 10.0) % 2 == 0
	_deck.color = Color(_flame_color(), 0.85 if phase else 0.35)
	_glow.modulate = Color(_flame_color(), 0.5 if phase else 0.2)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		light()


func _on_hit_received(_amount: int, _source_position: Vector2) -> void:
	_health.refill()
	light()


func _on_rage_stage_changed(stage: int, _enemy_mult: float, _player_mult: float) -> void:
	_rage_active = stage > 0
	_apply_visual()
