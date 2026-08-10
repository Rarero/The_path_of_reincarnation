class_name PantheonSynergy
extends Resource

## 계열 시너지 1항목 (docs/systems/BOONS.md 8.7, 9.7).
## 단계는 누적이 아니라 치환이다. 3단계에 도달하면 2단계 효과는 3단계 효과로 대체된다.

@export var pantheon: BoonDef.Pantheon
@export var display_name: String = ""  ## 예: 산신의 기운
@export var step2: Array[BoonEffect] = []  ## 같은 계열 2개일 때
@export var step3: Array[BoonEffect] = []  ## 3개일 때
@export var step4: Array[BoonEffect] = []  ## 4개일 때
@export_multiline var description: String = ""
