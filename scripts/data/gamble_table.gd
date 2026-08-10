class_name GambleTable
extends Resource

## 노름판의 판수와 배당표 (docs/act1/EVENTS.md 7장 B1).
##
## 배당을 코드 상수가 아니라 이 리소스(.tres)에 둔다 (docs/CONVENTIONS.md 데이터).
## 투전과 골패는 비기면 건 돈을 돌려주므로 기대값이 1.0이다.
## 썅륙은 합 7을 하우스 승으로 두어 세 베팅 모두 기대값이 같아진다 (초안 0.833).
## 내기방 종류 기본 점수가 중립 0인 근거는 기대값 중립이므로, 썅륙 배당은 밸런싱에서
## 재검토 대상이다 (docs/DECISIONS.md 2026-08-06).

## 한 방에서 할 수 있는 판 수
@export_range(1, 10, 1) var rounds: int = 3
## 최소 베팅
@export var min_bet: int = 10
## 베팅을 올리고 내리는 단위
@export var bet_step: int = 10
## 소지금 대비 한 판 최대 베팅 비율
@export_range(0.05, 1.0, 0.05) var max_bet_ratio: float = 0.5
## 투전과 골패에서 이겼을 때의 총 지급 배율 (건 돈 포함)
@export_range(1.0, 5.0, 0.1) var even_money_mult: float = 2.0
## 썅륙 소와 대의 총 지급 배율
@export_range(1.0, 5.0, 0.1) var small_big_mult: float = 2.0
## 썅륙 쌍의 총 지급 배율
@export_range(1.0, 12.0, 0.5) var pair_mult: float = 5.0
@export_multiline var designer_note: String = ""


## 소지금에서 걸 수 있는 최대 베팅. 단위에 맞춰 내림한다.
func max_bet(coins: int) -> int:
	var cap: int = int(floor(float(coins) * max_bet_ratio))
	if cap < min_bet:
		return min_bet if coins >= min_bet else 0
	return maxi(min_bet, cap - cap % maxi(bet_step, 1))


## 그 소지금으로 판을 벌일 수 있는지.
func can_play(coins: int) -> bool:
	return coins >= min_bet
