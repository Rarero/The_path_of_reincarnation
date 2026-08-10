class_name WeaponBase
extends Node2D

## 무기 공통 인터페이스 (docs/systems/WEAPONS.md 12장).
##
## Player는 이 인터페이스로만 무기와 통신한다 (call down, signal up 원칙,
## docs/CONVENTIONS.md). 파생은 WeaponMelee와 후속 WeaponRanged다.

## 무기를 휘둘렀다 (연출과 사운드 훅)
signal swung(step: int)

## 무기 정의. 밸런스 수치는 전부 여기서 읽는다
@export var definition: WeaponDef = null

## 생기 몰림 배율 등 외부 배수. Player가 넣는다
var damage_multiplier: float = 1.0

var facing: int = 1

var _equipped: bool = false


func _ready() -> void:
	set_equipped(false)


## 장착 여부를 바꾼다. 해제되면 표시와 판정이 모두 꺼진다.
func set_equipped(value: bool) -> void:
	_equipped = value
	visible = value
	set_physics_process(value)
	if not value:
		_on_unequipped()


func is_equipped() -> bool:
	return _equipped


func set_facing(direction: int) -> void:
	if direction == 0:
		return
	facing = direction
	scale.x = absf(scale.x) * float(direction)


## 무기 이름. HUD 표시 계약에 쓴다 (9장)
func display_name() -> String:
	if definition == null:
		return ""
	return definition.display_name


## 주 공격을 시도한다. 시작되면 true.
## on_floor는 지상 콤보와 점프 공격을 가르는 판정에 쓴다 (6장)
func try_primary_attack(_on_floor: bool) -> bool:
	return false


## 공격 동작이 진행 중이면 true. Player가 상태 유지 판단에 쓴다
func is_attacking() -> bool:
	return false


## 이번 프레임에 자동 전진할 거리 (px). 좌우 이동 입력과는 별개다 (5.2절)
func consume_advance() -> float:
	return 0.0


## 지금 재생해야 할 몸 클립 이름. 비어 있으면 Player가 기본 클립을 쓴다.
## 무기가 몸 애니메이션을 고르는 이유는 3연타의 타마다 클립이 다르기 때문이며,
## 어느 타인지 아는 것은 무기뿐이다
func body_clip() -> StringName:
	return &""


## 장착 해제 시 파생이 정리할 것 (진행 중 판정 취소 등)
func _on_unequipped() -> void:
	pass
