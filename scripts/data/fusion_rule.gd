class_name FusionRule
extends Resource

## 조합 결과 결정 규칙 (docs/systems/BOONS.md 9.3). 계열 쌍과 티어로 결과를 찾는다.

@export var main_pantheon: BoonDef.Pantheon  ## 항상 상시 계열이다
## 특수 계열이어도 result_id는 상시 계열 결과다. 각인은 서브 BoonDef의 special_mark를
## 런타임에 얹는다
@export var sub_pantheon: BoonDef.Pantheon
## 액티브 조합과 권능 조합을 가른다
@export var is_active_fusion: bool = false
## 메인 재료 티어. 결과는 main_tier + 1
@export_range(1, 2) var main_tier: int = 1
## 서브 재료 티어. 액티브 조합은 main_tier 이상을 요구한다 (규칙 31)
@export_range(1, 2) var sub_tier: int = 1
## 결과 BoonDef의 id. 2티어는 계열 쌍마다 고유 id, 3티어는 메인 계열 본체 id다.
## 액티브 조합(is_active_fusion)에서는 본체 id를 유지하므로 비워 둔다 (5장)
@export var result_id: StringName = &""
## 3티어 조합에서 서브 계열이 얹는 부가 오버레이의 id. 서브가 메인과 같은 계열이면
## 비운다 (본체 강화로 처리, 규칙 49)
@export var addon_id: StringName = &""
## 액티브 조합에서 서브 계열이 얹는 계열 모디파이어의 id. 액티브 모듈러 구조가 적용
## 대기라 M2에서는 항상 비운다 (5장)
@export var modifier_id: StringName = &""
## 0.95 (2티어와 3티어 공통)
@export_range(0.0, 1.0) var success_chance: float = 0.95
## 0.05. 실패 항목은 없다 (2026-07-27 조합 실패 폐지). 두 확률의 합이 1.0이다
@export_range(0.0, 1.0) var great_chance: float = 0.05
