class_name LanternSwitch
extends Node2D

## 등불 점등 스위치 (문얼굴 보스 1페이즈 벽면 기믹, docs/act1/BOSS.md 3.1).
##
## 한 번 맞으면 점등되고 계속 켜진 채로 남는다 (임시 발판인 WispPlatform과 달리 퍼즐
## 스위치라 소등하지 않는다). 점등 시 lit 시그널을 올려 방(아레나) 스크립트가 보스에게
## 진행도를 전달한다 (call down, signal up, docs/CONVENTIONS.md 씬 설계).
##
## 지형이 아니라 장식이므로 몸체 충돌이 없다. WispPlatform과 같이 루트를 Node2D로 두고
## 피격만 Hurtbox로 받는다 (충돌 형상 없는 StaticBody2D는 에디터 설정 경고를 낸다).
##
## 스프라이트는 임시다. 전용 등불 에셋이 없어 도깨비불(dokkaebi_fire)과 원형 광원을
## 빌려 쓴다. 미점등에도 반드시 보여야 한다: 플레이어는 이걸 쏴야 보스 무적이 풀리는데
## 안 보이면 전투가 진행 불가가 된다. A5 아트 세션에서 전용 등불 스프라이트로 교체한다.

signal lit

## 평시(미점등) 색
const COLOR_UNLIT: Color = Color(0.4, 0.36, 0.34)
## 점등 색 (등불 발광 규칙: 주황/호박 계열만 허용, docs/ART_STYLE.md 3장)
const COLOR_LIT: Color = Color(1.0, 0.72, 0.32)

var _lit: bool = false

@onready var _health: Health = $Health as Health
@onready var _hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var _glow: Sprite2D = $Glow as Sprite2D
@onready var _flame: Sprite2D = $Flame as Sprite2D


func _ready() -> void:
	_health.died.connect(_on_triggered)
	_hurtbox.hit_received.connect(_on_hit_received)
	_apply_visual()


func is_lit() -> bool:
	return _lit


func _on_hit_received(_amount: int, _source_position: Vector2) -> void:
	pass  # Health.died가 트리거를 처리한다 (maximum 1이라 한 번 맞으면 죽는다)


func _on_triggered() -> void:
	if _lit:
		return
	_lit = true
	_hurtbox.set_deferred(&"monitorable", false)
	_apply_visual()
	lit.emit()


## 미점등은 어둡게, 점등은 호박색으로. 미점등에도 형체는 남겨 조준 대상임을 알린다.
func _apply_visual() -> void:
	_flame.modulate = COLOR_LIT if _lit else COLOR_UNLIT
	_glow.modulate = Color(COLOR_LIT, 0.55) if _lit else Color(COLOR_UNLIT, 0.25)
