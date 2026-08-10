class_name EventOutcome
extends Resource

## 이벤트 노드가 확정하는 하나의 P 또는 N 결과 (docs/act1/EVENTS.md 8.1).
##
## 점수를 코드 상수가 아니라 이 리소스(.tres)에 둔다
## (docs/RUN_STRUCTURE.md 10장 데이터 위치 결정, docs/CONVENTIONS.md 데이터 규칙).
## 노드 종류 기본 점수는 0(중립)이고, 경로 실점수 검사에는 여기 score가 들어간다 (10장 규칙 12).

enum Polarity { POSITIVE, NEGATIVE }
## 자동, 선택, 조건부, 해금 (docs/act1/EVENTS.md 3장 발동 방식 4종)
enum Trigger { AUTO, OPT_IN, CONDITIONAL, UNLOCK }
## 전투형, 플랫포밍형, 상호작용형 (docs/act1/EVENTS.md 3장 방 성격)
enum RoomFlavor { COMBAT, PLATFORMING, INTERACTION }

## 점수 절대값 하한 (docs/act1/EVENTS.md 11장 E1)
const SCORE_MIN_ABS: int = 10
## 점수 절대값 상한 (2026-07-27 축소. 옛 범위 40)
const SCORE_MAX_ABS: int = 30
## 큰 값 결과의 점수 절대값. 2026-08-05 D6에서 40 표기가 30으로 정정됐다
const BIG_VALUE_ABS: int = 30

const POLARITY_NAMES: Dictionary = {
	Polarity.POSITIVE: "긍정",
	Polarity.NEGATIVE: "부정",
}

const TRIGGER_NAMES: Dictionary = {
	Trigger.AUTO: "자동",
	Trigger.OPT_IN: "선택",
	Trigger.CONDITIONAL: "조건부",
	Trigger.UNLOCK: "해금",
}

const ROOM_FLAVOR_NAMES: Dictionary = {
	RoomFlavor.COMBAT: "전투형",
	RoomFlavor.PLATFORMING: "플랫포밍형",
	RoomFlavor.INTERACTION: "상호작용형",
}

## 예: &"act1_night_market_boom"
@export var id: StringName = &""
@export var display_name: String = ""
@export var polarity: Polarity = Polarity.POSITIVE
## 순점수. 절대값 10~30이고 부호가 극성과 일치해야 한다 (E1, E2)
@export_range(-30, 30) var score: int = 10
@export var trigger: Trigger = Trigger.AUTO
## 이벤트방 구성 성격. 템플릿이 이 성격을 수용해야 한다 (E4)
@export var room_flavor: RoomFlavor = RoomFlavor.COMBAT
## 테마 우선(비면 제약 없음): street, roof, alley. 강제가 아니라 생성기 가중치다 (8.4)
@export var theme_tags: Array[StringName] = []
## 선행 플래그. 예: &"blacksmith_locked" (9.3)
@export var prerequisites: Array[StringName] = []
## 런 내 1회. 성사 시 플래그가 갱신돼 이후 런 풀에서 빠진다 (9.3)
@export var run_once: bool = false
## 절대값 30. 막당 한도 대상이다 (E6)
@export var big_value: bool = false
@export var m2_priority: bool = false
@export var act: int = 1
## false면 런 생성기의 추첨 풀에서 제외한다. 데이터만 있고 방 전개가 아직 없는 결과다
@export var implemented: bool = false
## 결과별 파라미터. 보상 수치 등 밸런싱 값을 코드가 아니라 여기에 둔다
@export var params: Dictionary = {}
@export_multiline var designer_note: String = ""


func is_positive() -> bool:
	return polarity == Polarity.POSITIVE


## 극성 부호. 점수 부호 검사(E2)와 표시에 쓴다
func polarity_sign() -> int:
	return 1 if is_positive() else -1


## 점수 절대값이 규정 범위(10~30) 안인지 (E1).
func has_valid_score() -> bool:
	var magnitude: int = absi(score)
	return magnitude >= SCORE_MIN_ABS and magnitude <= SCORE_MAX_ABS


## 극성과 점수 부호가 맞는지 (E2). 0점은 어느 극성에도 맞지 않는다
func has_matching_sign() -> bool:
	return signi(score) == polarity_sign()


## big_value 표기와 실제 점수 절대값이 맞는지.
func has_valid_big_value() -> bool:
	return big_value == (absi(score) == BIG_VALUE_ABS)


## 이 결과가 그 테마의 방에 놓일 수 있는지. 태그가 비면 어느 테마든 받는다 (8.4).
func accepts_theme(theme: StringName) -> bool:
	return theme_tags.is_empty() or theme_tags.has(theme)


## theme_tags에 그 테마가 명시돼 있는지 (가중치 상향 대상).
func prefers_theme(theme: StringName) -> bool:
	return theme_tags.has(theme)


## 선행 조건 충족 여부. flags는 런 시작 시점의 상태 스냅샷이다 (9.3).
func meets_prerequisites(flags: Dictionary) -> bool:
	for key: StringName in prerequisites:
		if not bool(flags.get(key, false)):
			return false
	return true


func polarity_name() -> String:
	return String(POLARITY_NAMES.get(polarity, "?"))


func trigger_name() -> String:
	return String(TRIGGER_NAMES.get(trigger, "?"))


func room_flavor_name() -> String:
	return String(ROOM_FLAVOR_NAMES.get(room_flavor, "?"))
