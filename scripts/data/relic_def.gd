class_name RelicDef
extends Resource

## 유물 1종의 정의 (docs/systems/RELICS.md 8.1).
## 밸런스 수치를 코드가 아니라 이 리소스(.tres)에 둔다 (docs/CONVENTIONS.md 데이터).

enum Grade { TTEORI, MULGEON, JINPUM }  ## 떨이, 물건, 진품
enum Axis { STAT, RULE, SYNERGY }  ## A 순수 수치, C 시스템 규칙 개조, D 권능 메타 개입
enum Era { OLD, MODERN, ANCIENT }  ## 옛시절, 현대, 고대

@export var id: StringName = &""
@export var display_name: String = ""
@export var grade: Grade = Grade.TTEORI
@export var axis: Axis = Axis.STAT
@export var era: Era = Era.OLD
## deal, modern, pantheon, terrain
@export var tags: Array[StringName] = []
## 계열 태그일 때만. 상시 계열만 허용 (sansin, jowang, seonang, samsin)
@export var pantheon_key: StringName = &""
## 등장 막. 지형 태그가 없으면 전 막 공통
@export var act_pool: Array[int] = [1, 2, 3]
## shop, treasure, secret, event, wager, drop, boss
@export var sources: Array[StringName] = []
## 같은 그룹은 동시 보유 불가
@export var exclusive_group: StringName = &""
## 런당 1개
@export var unique: bool = true
@export var m2_priority: bool = false
@export_multiline var description: String = ""
@export_multiline var designer_note: String = ""
@export var effects: Array[RelicEffect] = []
