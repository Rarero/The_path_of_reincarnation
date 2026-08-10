class_name ExitDoor
extends Node2D

## 방 출구 귀문 (도깨비 문). 방을 클리어하면 우측에 도깨비스럽게 뿅 하고 나타난다.
##
## docs/DECISIONS.md 2026-07-30 공통 문 연출: 방 출구를 단일 귀문으로 통일하고, 문에
## 들어가면 지도(노드 선택 화면)가 열린다. 세계관 당위는 도깨비 다리 설화(밤마다 새로
## 짓는 시장)라 같은 문이 매번 다른 곳으로 이어진다.
##
## 통신: call down, signal up. 진입 감지는 entered로 알린다 (docs/CONVENTIONS.md).

## 플레이어가 문에 들어왔다
signal entered

## 도깨비불 청록 (scenes/weapons/projectile_fire.tscn과 통일)
const TEAL: Color = Color(0.353, 0.863, 0.784)
## 등장 팝 시간 (초)
const POP_TIME: float = 0.35

var _open: bool = false

@onready var sprite: Sprite2D = $Sprite as Sprite2D
@onready var glow: Sprite2D = $Glow as Sprite2D
@onready var area: Area2D = $Area as Area2D
@onready var puff: CPUParticles2D = $Puff as CPUParticles2D


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	reset_door()


## 방 클리어 시 호출한다. 스케일 팝 + 청록 섬광 + 연기로 등장하고 진입 판정을 켠다.
func appear() -> void:
	if _open:
		return
	_open = true
	visible = true
	_play_poof()


## 다음 방으로 넘어갈 때 문을 숨기고 진입 판정을 끈다 (재사용).
func reset_door() -> void:
	_open = false
	visible = false
	area.monitoring = false
	scale = Vector2(0.2, 0.2)
	glow.visible = false


func _play_poof() -> void:
	scale = Vector2(0.2, 0.2)
	rotation = 0.14
	var pop: Tween = create_tween()
	pop.set_trans(Tween.TRANS_BACK)
	pop.set_ease(Tween.EASE_OUT)
	pop.tween_property(self, "scale", Vector2.ONE, POP_TIME)
	pop.parallel().tween_property(self, "rotation", 0.0, POP_TIME)
	glow.visible = true
	glow.scale = Vector2(0.3, 0.3)
	glow.modulate = Color(TEAL, 0.9)
	var flash: Tween = create_tween()
	flash.tween_property(glow, "scale", Vector2(1.6, 1.6), 0.3)
	flash.parallel().tween_property(glow, "modulate:a", 0.0, 0.4)
	if puff != null:
		puff.restart()
		puff.emitting = true
	await pop.finished
	if _open:
		area.monitoring = true


func _on_body_entered(body: Node2D) -> void:
	if not _open:
		return
	if not body.is_in_group(&"player"):
		return
	entered.emit()
