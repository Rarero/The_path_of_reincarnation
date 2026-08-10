class_name WeaponDef
extends Resource

## 무기 1종의 정의 (docs/systems/WEAPONS.md 3.2).
##
## 근접과 원거리를 별도 클래스로 쪼개지 않고 kind로 분기한다. BoonDef가 계열마다
## 분기 필드를 갖는 것과 같은 패턴이다. 저장 위치는 resources/weapons/.

enum Kind { MELEE, RANGED }

## BoonDef.WeaponTag와 같은 어휘. 무기는 자기 kind와 항상 같은 값을 쓴다 (4장)
enum WeaponTag { MELEE, RANGED }

## 획득처. drop, shop, exchange_stand, blacksmith (11장)
enum Source { DROP, SHOP, EXCHANGE_STAND, BLACKSMITH }

@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: Kind = Kind.MELEE

## 권능 무기 태그 판정에 쓰는 값. 활성 슬롯 기준으로만 본다 (4.1절)
@export var weapon_tag: WeaponTag = WeaponTag.MELEE

## 어디서 얻을 수 있는지 (11장). 시작 무기는 비어 있어도 된다
@export var sources: Array[int] = []

@export_group("근접")
## 지상 콤보 타별 수치. 환도는 3개다 (5.2절)
@export var melee_combo: Array[MeleeAttackDef] = []

## 점프 공격. 지상 콤보와 연결되지 않는 독립 1회 공격 (6장)
@export var melee_jump_attack: MeleeAttackDef = null

## 히트박스 크기 (px). 근접 무기 정체성 축 하나 (5.2절)
@export var hitbox_size: Vector2 = Vector2(34.0, 28.0)

## 히트박스를 플레이어 기준 어디에 둘지. 오프셋은 A6 스프라이트에 맞춰 확정한다
@export var hitbox_offset: Vector2 = Vector2(18.0, -12.0)

@export_group("점프 공격")
## 착지 후딜. 즉시 취소하면 점프 공격이 지상 후딜을 생략하는 최적해가 된다 (6장)
@export var jump_attack_land_recovery: float = 0.12


## 콤보 타 수. 환도는 3이다
func combo_length() -> int:
	return melee_combo.size()


## index번째 타. 범위를 벗어나면 null
func combo_step(index: int) -> MeleeAttackDef:
	if index < 0 or index >= melee_combo.size():
		return null
	return melee_combo[index]
