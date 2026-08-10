class_name BoonDef
extends Resource

## 권능 1종의 정의 (docs/systems/BOONS.md 9.1).
## 계열별 상세는 2026-08-06 사용자 지정 12종(8장)을 기준으로 삼는다.
## 조합(FusionRule), 등급 배율(RarityTable), 시너지(SynergyTable)는 별도 리소스다.

enum Pantheon { SANSIN, JOWANG, SEONANG, SAMSIN, DOKKAEBI, YONGWANG }
enum Layer { REGULAR, SPECIAL }  ## 상시 4종, 특수 2종
enum WeaponTag { MELEE, RANGED, NONE }  ## 근접, 원거리, 무관
enum Kind { ACTIVE, NORMAL, GONGSU, GYEOMNAERIM }  ## 티어는 tier 필드가 구분한다
enum Rarity { SEUCHIM, SILLIM, ONNAERIM }  ## 스침, 실림, 온내림
## 발동 형태 (2026-08-06 신설, 4장). 액티브형은 동시 1개만 보유한다 (8.6)
enum Activation { PASSIVE, ACTIVE }

const PANTHEON_KEYS := {
	Pantheon.SANSIN: &"sansin",
	Pantheon.JOWANG: &"jowang",
	Pantheon.SEONANG: &"seonang",
	Pantheon.SAMSIN: &"samsin",
	Pantheon.DOKKAEBI: &"dokkaebi",
	Pantheon.YONGWANG: &"yongwang",
}

const PANTHEON_NAMES := {
	Pantheon.SANSIN: "산신",
	Pantheon.JOWANG: "조왕",
	Pantheon.SEONANG: "서낭",
	Pantheon.SAMSIN: "삼신",
	Pantheon.DOKKAEBI: "도깨비 대장",
	Pantheon.YONGWANG: "용왕",
}

## 조합 태그 어휘 8종 (8.6). 이 밖의 값은 fusion_tags/fusion_accepts에 쓰지 않는다 (규칙 45)
const FUSION_TAGS: Array[StringName] = [
	&"chigi", &"ssogi", &"mom", &"beotim", &"georeum", &"beonjim", &"norim", &"myeongjul"
]

## 계열 고유 축 키 (8.1)
const AXIS_KEYS := {
	Pantheon.SANSIN: &"ground",
	Pantheon.JOWANG: &"burn",
	Pantheon.SEONANG: &"move",
	Pantheon.SAMSIN: &"life",
	Pantheon.DOKKAEBI: &"luck",
	Pantheon.YONGWANG: &"wet",
}

@export var id: StringName = &""
@export var display_name: String = ""
@export var pantheon: Pantheon = Pantheon.SANSIN
@export var layer: Layer = Layer.REGULAR
## 겹내림일 때 서브 계열. -1은 없음
@export var sub_pantheon: int = -1
@export var weapon_tag: WeaponTag = WeaponTag.NONE
## 2티어와 3티어 결과 정의는 true. 인스턴스가 메인 재료의 태그를 들고 weapon_tag는 무시된다 (규칙 32)
@export var weapon_tag_inherits: bool = false
@export var kind: Kind = Kind.NORMAL
@export_range(1, 3) var tier: int = 1
@export var act_pool: Array[int] = [1, 2, 3]
## false면 신당 풀에서 제외한다 (미완성 계열 데이터 수준 제외)
@export var implemented: bool = false
@export var m2_priority: bool = false
## 인벤토리와 신당 목록에 쓰는 16x16 아이콘 (assets/sprites/ui/boons/)
@export var icon: Texture2D = null
@export_multiline var description: String = ""
@export_multiline var designer_note: String = ""
## 능력치 강화. 권능은 최소 1개 필수 (4장)
@export var stat_effects: Array[BoonEffect] = []
## 특수 능력. 권능은 최소 1개 필수 (4장)
@export var special_effects: Array[BoonEffect] = []
## 특수 계열이 서브로 조합될 때 결과물에 얹히는 각인. 특수 계열 BoonDef에만 정의
@export var special_mark: Array[BoonEffect] = []
## 서브로 들어갈 때 내미는 성격 (8.6, FUSION_TAGS 값만 허용)
@export var fusion_tags: Array[StringName] = []
## 메인일 때 받아들이는 성격 (8.6, FUSION_TAGS 값만 허용)
@export var fusion_accepts: Array[StringName] = []
## 태그가 맞아도 막을 예외 쌍. 메인 쪽에 적는다
@export var fusion_deny_ids: Array[StringName] = []
## 발동 형태 (2026-08-06 신설, 4장)
@export var activation: Activation = Activation.PASSIVE
## 액티브형에만 쓴다
@export var active_cooldown_sec: float = 0.0
## 사용할 때마다 쿨다운이 늘어나는 폭. 0이면 고정 쿨다운 (삼신 첫국밥이 유일한 사용처)
@export var cooldown_growth_sec: float = 0.0
## 새 공격 수단 예외 명시 (4장, 규칙 57). 액티브형이거나 이 플래그가 true여야 허용된다
@export var grants_new_attack: bool = false


## 계열 문자열 키 (RelicDef.pantheon_key와 매핑).
func pantheon_key() -> StringName:
	return PANTHEON_KEYS.get(pantheon, &"")


## 계열 한글 이름.
func pantheon_name() -> String:
	return PANTHEON_NAMES.get(pantheon, "")


## 조합 가능 판정 (9.1, 규칙 43). 순수 함수. 액티브 조합은 이 판정을 쓰지 않는다 (5장).
static func fusible(main: BoonDef, sub: BoonDef) -> bool:
	if main == null or sub == null:
		return false
	if main.fusion_deny_ids.has(sub.id):
		return false
	if sub.layer == Layer.SPECIAL:
		return true
	if main.pantheon == sub.pantheon:
		return true
	for tag: StringName in main.fusion_accepts:
		if sub.fusion_tags.has(tag):
			return true
	return false
