class_name RunMapNode
extends RefCounted

## 노드 맵의 노드 1개 (docs/RUN_STRUCTURE.md 2장). 노드 1개 = 방 1개 = 씬 1개.
##
## 순수 데이터다. 씬 참조를 갖지 않아 단위 테스트가 가능하다 (docs/RUN_STRUCTURE.md 7장).

## 맵 안에서 유일한 노드 번호
var id: int = -1
## 지도 위 좌표 (px). 층과 행 대신 이 값이 배치와 이동 비용의 기준이다
## (2026-08-06 자유 이동 전환. 층 잠금을 없애면서 layer와 row를 폐기했다)
var pos: Vector2 = Vector2.ZERO
## 진행도 0~1. 시작 노드가 0, 보스가 1이다. 층을 대신해 난이도 점증의 기준이 된다
var depth: float = 0.0
## 노드 종류 (RunMap.Kind)
var kind: int = 0
## 이어진 이웃 노드 id 목록. 간선은 양방향이라 진입과 진출을 구분하지 않는다
var link_ids: Array[int] = []
## 방문 여부. 다시 들어갈 수 있고, 그때는 빈 방이다
var visited: bool = false

# --- 이벤트 노드 확정값 (docs/act1/EVENTS.md 9.1). 이벤트 종류가 아니면 미확정으로 남는다 ---

## 배정된 확률 등급 (EventNodeConfig.OddsTier). -1은 미확정
var odds_tier: int = -1
## 등급의 좋음 확률. 노드 맵 표시가 이 값을 그대로 쓴다 (E8)
var positive_chance: float = 0.0
## 확정된 결과 id. 비면 미확정이다. 맵에는 공개하지 않는다 (내용 비공개 원칙)
var outcome_id: StringName = &""
## 확정된 결과의 순점수. 경로 실점수 검사가 이 값을 쓴다 (E9)
var outcome_score: int = 0
## 확정된 결과의 극성 (EventOutcome.Polarity). -1은 미확정. 진입 전까지 비공개다
var outcome_polarity: int = -1
## 확정된 결과의 방 성격 (EventOutcome.RoomFlavor). -1은 미확정
var outcome_flavor: int = -1
## 확정된 결과의 발동 방식 (EventOutcome.Trigger). -1은 미확정
var outcome_trigger: int = -1
## 배정된 방 테마 (street, roof, alley). theme_tags 필터와 방 선택에 쓴다
var theme: StringName = &""


func _init(node_id: int = -1, node_pos: Vector2 = Vector2.ZERO, node_kind: int = 0) -> void:
	id = node_id
	pos = node_pos
	kind = node_kind


## 이벤트 결과가 확정됐는지.
func has_outcome() -> bool:
	return outcome_id != &""


## 확률 등급이 배정됐는지 (노드 맵이 확률을 그릴 수 있는 상태).
func has_odds() -> bool:
	return odds_tier >= 0


## 표시용 좋음 확률 (정수 퍼센트). 등급의 positive_chance와 일치해야 한다 (E8)
func positive_percent() -> int:
	return int(round(positive_chance * 100.0))


func negative_percent() -> int:
	return 100 - positive_percent()


## 노드 맵 표시 문구. 예: "좋음 70 / 나쁨 30"
func odds_text() -> String:
	return "좋음 %d / 나쁨 %d" % [positive_percent(), negative_percent()]
