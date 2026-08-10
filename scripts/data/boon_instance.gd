class_name BoonInstance
extends RefCounted

## 보유 중인 권능 1개의 런타임 상태 (docs/systems/BOONS.md 9.8).
##
## def(BoonDef)는 정의이고 이 인스턴스가 등급, 티어, 각인, 오버레이를 얹는다.
## 액티브는 조합으로 티어가 올라도 같은 def를 유지한다 (액티브 모듈러 구조는 적용 대기, 5장).

## 정의 (BoonDef). 결과물의 이름, 계열, 효과가 여기서 나온다
var def: BoonDef = null
## 보유 티어. 생성 시 def.tier로 초기화되며 액티브 조합에서만 def와 독립적으로 오른다
var tier: int = 1
## 등급 (BoonDef.Rarity)
var rarity: int = BoonDef.Rarity.SEUCHIM
## 대성공 덤 누적치 (6장, 규칙 48). RarityTable.bonus_cap을 넘지 않는다
var rarity_bonus: float = 0.0
## 각인 계열. -1은 없음 (특수 계열을 서브로 조합했을 때만 채워진다, 5장)
var mark_pantheon: int = -1
## 액티브 계열 모디파이어(최대 2)와 3티어 부가(최대 1). 액티브 모듈러 구조가 적용 대기라 M2에서는
## 3티어 부가(PantheonOverlay.Usage.TIER3_ADDON)만 실제로 채워진다
var overlays: Array[PantheonOverlay] = []
## def.weapon_tag_inherits가 true인 결과물이 메인 재료에서 물려받은 실효 태그. -1이면 def.weapon_tag를 쓴다
var weapon_tag_effective: int = -1


func _init(source: BoonDef = null) -> void:
	def = source
	if source != null:
		tier = source.tier


var id: StringName:
	get:
		return def.id if def != null else &""

var display_name: String:
	get:
		return def.display_name if def != null else ""

var pantheon: int:
	get:
		return int(def.pantheon) if def != null else -1


func pantheon_name() -> String:
	return def.pantheon_name() if def != null else ""


## 무기 비활성 판정에 쓰는 실효 무기 태그 (규칙 52).
func effective_weapon_tag() -> int:
	if weapon_tag_effective >= 0:
		return weapon_tag_effective
	return int(def.weapon_tag) if def != null else BoonDef.WeaponTag.NONE
