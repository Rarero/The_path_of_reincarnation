class_name PantheonOverlay
extends Resource

## 본체 위에 얹히는 계열 변조 (docs/systems/BOONS.md 9.4).
## 액티브 모디파이어(5장)와 3티어 부가(8.5)가 이 리소스를 공유한다.
## 액티브 모듈러 구조(ACTIVE_MODIFIER 용도)는 적용 대기다. M2는 TIER3_ADDON만 쓴다.

enum Usage { ACTIVE_MODIFIER, TIER3_ADDON }

@export var id: StringName = &""
@export var display_name: String = ""
@export var pantheon: BoonDef.Pantheon
@export var usage: Usage = Usage.ACTIVE_MODIFIER
## 본체 파라미터 스케일. hook은 ACTIVE_CAST, target_key는 본체 파라미터 키를 쓴다
@export var body_scales: Array[BoonEffect] = []
## 본체에 새로 붙는 조건부 효과
@export var added_effects: Array[BoonEffect] = []
## 같은 계열이 두 번 들어올 수 있는 최대치. 3티어 부가는 조합 시점에 얹히고 다시
## 조합되지 않으므로 1이다. 액티브 모디파이어만 2를 쓴다 (현재 적용 대기)
@export_range(1, 2) var max_stack: int = 1
## 2중첩일 때 값에 더해지는 계수 (1.0 + 0.5)
@export var stack_scale: float = 0.5
@export_multiline var description: String = ""
@export_multiline var designer_note: String = ""
