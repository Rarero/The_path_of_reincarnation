class_name RageTimer
extends RefCounted

## 생기 몰림(데스매치) 타이머 (순수 로직, 단위 테스트 대상).
##
## 규칙은 docs/RUN_STRUCTURE.md 9장.
## - 전투 중에만 시간이 흐른다 (advance 호출 주체가 전투 상태를 판단한다)
## - 발동 시간을 넘기면 일정 간격마다 단계가 올라간다
## - 단계마다 적과 플레이어 공격력 배율이 오른다. 적이 더 가파르고 양쪽 모두 상한이 있다
## - 플레이어 배율은 전투를 끝내기 위한 장치이므로 상한이 낮다 (버티기 악용 차단)

## 발동까지의 전투 시간 (초)
var threshold: float = 90.0
## 발동 이후 단계 상승 간격 (초)
var step_interval: float = 10.0
## 단계당 적 공격력 증가분
var enemy_step: float = 0.25
## 단계당 플레이어 공격력 증가분
var player_step: float = 0.10
## 적 공격력 배율 상한
var enemy_cap: float = 2.5
## 플레이어 공격력 배율 상한
var player_cap: float = 1.5

var _elapsed: float = 0.0
var _stage: int = 0


func _init(threshold_seconds: float = 90.0, interval_seconds: float = 10.0) -> void:
	threshold = threshold_seconds
	step_interval = interval_seconds


## 전투 시간을 진행시킨다. 단계가 올라간 프레임에서만 true를 반환한다.
func advance(delta: float) -> bool:
	_elapsed += delta
	var next_stage: int = _stage_for(_elapsed)
	if next_stage == _stage:
		return false
	_stage = next_stage
	return true


## 방 진입이나 전투 종료 시 초기화한다.
func reset() -> void:
	_elapsed = 0.0
	_stage = 0


## 누적 전투 시간 (초)
func elapsed() -> float:
	return _elapsed


## 현재 단계. 0은 미발동
func stage() -> int:
	return _stage


## 발동 여부
func is_active() -> bool:
	return _stage > 0


## 발동까지 남은 시간 (초). 발동 후에는 0
func time_to_trigger() -> float:
	return maxf(0.0, threshold - _elapsed)


## 적 공격력 배율
func enemy_multiplier() -> float:
	return minf(enemy_cap, 1.0 + enemy_step * float(_stage))


## 플레이어 공격력 배율
func player_multiplier() -> float:
	return minf(player_cap, 1.0 + player_step * float(_stage))


func _stage_for(seconds: float) -> int:
	if seconds < threshold:
		return 0
	if step_interval <= 0.0:
		return 1
	return 1 + int((seconds - threshold) / step_interval)
