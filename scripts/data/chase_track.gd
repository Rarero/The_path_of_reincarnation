class_name ChaseTrack
extends Resource

## 장물아비 추격 달리기의 속도와 밀도표 (docs/act1/EVENTS.md 부록 A.2).
##
## 달리기 수치를 코드 상수가 아니라 이 리소스(.tres)에 둔다 (docs/CONVENTIONS.md 데이터).
## 2026-08-07 상향: 너무 쉬웠다. 스크롤 속도와 장애물 밀도를 함께 올리고 표적이
## 플레이어 레인을 피해 달아나게 했다.

## 골목이 아래로 흐르는 속도 (논리 단위/초). 체감 속도를 정한다
@export_range(60.0, 500.0, 5.0) var scroll_speed: float = 240.0
## 표적과의 거리가 줄어드는 속도
@export_range(5.0, 120.0, 1.0) var close_speed: float = 30.0
## 표적을 놓쳤을 때 다시 벌어지는 거리
@export_range(5.0, 200.0, 1.0) var retry_gap: float = 40.0
## 장애물에 부딪혔을 때 벌어지는 거리
@export_range(5.0, 200.0, 1.0) var hit_penalty: float = 44.0
## 표적을 처음 쫓기 시작할 때의 거리
@export_range(20.0, 300.0, 1.0) var start_gap: float = 96.0
## 표적이 레인을 바꾸는 주기 (초). 짧을수록 따라붙기 어렵다
@export_range(0.15, 3.0, 0.05) var switch_interval: float = 0.55
## 표적이 레인을 바꿀 때 플레이어 레인을 피할 확률
@export_range(0.0, 1.0, 0.05) var evade_chance: float = 0.6
## 장애물 한 줄이 나오는 간격의 최소와 최대 (초)
@export_range(0.1, 2.0, 0.01) var spawn_min: float = 0.30
@export_range(0.1, 2.0, 0.01) var spawn_max: float = 0.52
## 한 줄에서 막는 레인 수의 최소와 최대. 지나갈 레인은 반드시 남는다
@export_range(1, 4, 1) var blocked_min: int = 2
@export_range(1, 4, 1) var blocked_max: int = 3
## 충돌 허용 횟수
@export_range(1, 9, 1) var max_hits: int = 3
@export_multiline var designer_note: String = ""


## 한 줄에서 막을 레인 수를 뽑는다. 막다른 길이 되지 않게 위쪽을 자른다.
func blocked_lanes(rng: RandomNumberGenerator, lane_count: int, min_free: int) -> int:
	var top: int = mini(blocked_max, lane_count - min_free)
	var low: int = clampi(blocked_min, 1, top)
	return rng.randi_range(low, top)


## 다음 줄까지의 간격.
func spawn_delay(rng: RandomNumberGenerator) -> float:
	return rng.randf_range(spawn_min, maxf(spawn_max, spawn_min))
