class_name StallCover
extends StaticBody2D

## 파괴 가능 좌판 엄폐물 (docs/GDD.md 9장 좌판, DESIGN_ACT1 2.6 파괴 등급 1).
##
## 지형(world)이라 총알을 막는 엄폐물로 쓰이고, 위에 올라설 수도 있다.
## 부수면 엽전을 준다. 파괴 시 도깨비 어그로(GDD 9장)는 적 인지 확장이 필요해
## 후속 과제로 남긴다 (DECISIONS 2026-08-04 유보 항목).
## 원점은 바닥 중앙이다 (적, 플레이어와 같은 접지 기준).
##
## broken 시그널 (2026-08-06 G3 추가): 문얼굴 보스 1페이즈 벽면 기믹이 좌판 파괴를
## 진행도로 쓴다. 방(아레나) 스크립트가 이 시그널을 받아 보스에게 내려준다
## (call down, signal up). queue_free 이전에 올려야 방이 안전하게 받을 수 있다.

signal broken

## 파괴 보상 엽전
@export var coin_reward: int = 4

@onready var _health: Health = $Health as Health
@onready var _hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var _shape: CollisionShape2D = $Shape as CollisionShape2D
@onready var _visual: Sprite2D = $Visual as Sprite2D


func _ready() -> void:
	add_to_group(&"breakable")
	_health.died.connect(_on_broken)
	_hurtbox.hit_received.connect(_on_hit_received)


## 적이 돌진으로 부순다 (한 번에 파괴). 접근 경로를 막지 않게 한다.
func break_now() -> void:
	if not _health.is_dead():
		_health.apply_damage(_health.maximum)


## 피격 반짝임. 부술 수 있는 물건이라는 피드백이다.
func _on_hit_received(_amount: int, _source_position: Vector2) -> void:
	_visual.self_modulate = Color(1.6, 1.6, 1.6)
	var tween: Tween = create_tween()
	tween.tween_property(_visual, ^"self_modulate", Color.WHITE, 0.12)


## 파괴: 엽전 지급 후 주저앉는 연출과 함께 제거한다.
func _on_broken() -> void:
	RunState.add_coins(coin_reward)
	_shape.set_deferred("disabled", true)
	_hurtbox.set_deferred("monitorable", false)
	broken.emit()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, ^"scale", Vector2(1.25, 0.15), 0.22)
	tween.tween_property(_visual, ^"position:y", -2.0, 0.22)
	tween.tween_property(_visual, ^"modulate:a", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)
