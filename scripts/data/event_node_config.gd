class_name EventNodeConfig
extends Resource

## 이벤트 노드 1개의 확률 등급 (docs/act1/EVENTS.md 8.2).
##
## 생성기가 이 등급으로 결과를 시드 확정한다. 노드 맵이 표시하는 확률은 여기 값을 그대로
## 쓴다. 표시와 확정이 같은 출처를 보게 해 어긋남을 막는다 (E8).
## 확률 자체가 밸런싱 수치이므로 코드 상수가 아니라 .tres에 둔다.

## 좋은 예감, 반반, 스산함 (docs/act1/EVENTS.md 2장)
enum OddsTier { GOOD_OMEN, EVEN, GRIM }

const TIER_NAMES: Dictionary = {
	OddsTier.GOOD_OMEN: "좋은 예감",
	OddsTier.EVEN: "반반",
	OddsTier.GRIM: "스산함",
}

@export var odds_tier: OddsTier = OddsTier.EVEN
## 좋음 확률. 초안 0.7 / 0.5 / 0.3 (M2 시드 시뮬레이션에서 튜닝)
@export_range(0.0, 1.0, 0.01) var positive_chance: float = 0.5
## 생성기가 이 등급을 뽑을 상대 가중치. 등급 분포도 M2 튜닝 대상이다
@export_range(0.0, 10.0, 0.1) var pick_weight: float = 1.0
@export_multiline var designer_note: String = ""


func tier_name() -> String:
	return String(TIER_NAMES.get(odds_tier, "?"))


## 표시용 좋음 확률 (정수 퍼센트). 노드 맵과 테스트 E8이 이 값을 쓴다
func positive_percent() -> int:
	return int(round(positive_chance * 100.0))


func negative_percent() -> int:
	return 100 - positive_percent()


## 노드 맵 표시 문구. 예: "좋음 70 / 나쁨 30"
func display_text() -> String:
	return "좋음 %d / 나쁨 %d" % [positive_percent(), negative_percent()]
