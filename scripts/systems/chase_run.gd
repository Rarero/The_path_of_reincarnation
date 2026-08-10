class_name ChaseRun
extends RefCounted

## 장물아비 추격 달리기의 순수 로직 (docs/act1/EVENTS.md 부록 A).
##
## 탑뷰 5레인 달리기다. 플레이어는 화면 아래에 고정되고 좌우 레인만 옮긴다. 앞서 달아나는
## 장물아비를 한 마리씩 따라잡는다. 거리가 0이 됐을 때 같은 레인이면 잡고, 어긋나면 다시
## 벌어진다. 장애물에 부딪히면 거리가 벌어지고 충돌이 쌓이며, 한도에 이르면 남은 장물아비를
## 놓친 채 끝난다.
##
## 속도와 밀도 수치는 ChaseTrack 리소스에 있다 (docs/CONVENTIONS.md 데이터). 리소스를
## 넘기지 않으면 기본값으로 하나 만들어 쓴다.
##
## 씬과 입력에서 분리한 순수 자료구조라 gdUnit4 단위 테스트가 된다. 시드를 받으므로
## 같은 시드는 같은 장애물 배치와 같은 도주 경로를 낸다.

## 레인 수
const LANE_COUNT: int = 5
## 충돌 허용 횟수의 기본값. 실제 한도는 track.max_hits다
const MAX_HITS: int = 3
## 장애물이 생기는 논리 거리 (플레이어는 0에 있다)
const SPAWN_Y: float = 240.0
## 이 아래로 내려간 장애물은 지운다
const DESPAWN_Y: float = -16.0
## 플레이어와 겹쳤다고 보는 세로 폭
const HIT_WINDOW: float = 9.0
## 한 번에 막지 않고 남겨 두는 최소 레인 수 (막다른 길을 만들지 않는다)
const MIN_FREE_LANES: int = 2

## 플레이어가 선 레인 (0~4). 가운데에서 시작한다
var player_lane: int = 2
## 장애물에 부딪힌 횟수
var hits: int = 0
## 달린 거리 (연출용)
var distance: float = 0.0
## 장물아비 목록. 각 항목은 lane, coins, caught를 가진다
var thieves: Array[Dictionary] = []
## 화면 위에서 내려오는 장애물. 각 항목은 lane, y, prev_y, spent, shape를 가진다
var obstacles: Array[Dictionary] = []
## 지금 쫓는 장물아비 번호. 전부 처리했으면 thieves.size()다
var target_index: int = 0
## 지금 표적까지 남은 거리
var gap: float = 0.0
## 속도와 밀도표
var track: ChaseTrack = null

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawn_left: float = 0.4
var _switch_left: float = 0.0
var _finished: bool = false
var _shape_counter: int = 0


func _init(
	thief_count: int, coins_each: int, seed_value: int, track_value: ChaseTrack = null
) -> void:
	track = track_value if track_value != null else ChaseTrack.new()
	_rng.seed = seed_value
	for i: int in range(maxi(thief_count, 0)):
		thieves.append({"lane": _rng.randi_range(0, LANE_COUNT - 1), "coins": coins_each})
	gap = track.start_gap
	_switch_left = track.switch_interval
	_finished = thieves.is_empty()


## 골목이 흐르는 속도 (연출이 읽는다).
func scroll_speed() -> float:
	return track.scroll_speed


## 충돌 한도.
func max_hits() -> int:
	return track.max_hits


func is_over() -> bool:
	return _finished


## 충돌 한도에 걸려 끝났는지 (남은 장물아비는 놓친 것이다).
func failed() -> bool:
	return hits >= track.max_hits


func all_caught() -> bool:
	return caught_count() == thieves.size() and not thieves.is_empty()


func caught_count() -> int:
	var count: int = 0
	for thief: Dictionary in thieves:
		if bool(thief.get("caught", false)):
			count += 1
	return count


## 되찾은 엽전 합계 (잡은 개체가 가진 것만).
func caught_coins() -> int:
	var total: int = 0
	for thief: Dictionary in thieves:
		if bool(thief.get("caught", false)):
			total += int(thief.get("coins", 0))
	return total


## 놓친 엽전 합계.
func lost_coins() -> int:
	var total: int = 0
	for thief: Dictionary in thieves:
		if not bool(thief.get("caught", false)):
			total += int(thief.get("coins", 0))
	return total


## 지금 쫓는 장물아비. 전부 처리했으면 빈 사전
func target() -> Dictionary:
	if target_index < 0 or target_index >= thieves.size():
		return {}
	return thieves[target_index]


## 표적 레인. 표적이 없으면 -1
func target_lane() -> int:
	var thief: Dictionary = target()
	return int(thief.get("lane", -1)) if not thief.is_empty() else -1


## 남은 거리의 0~1 비율 (거리 막대 표시용).
func gap_ratio() -> float:
	return clampf(gap / maxf(track.start_gap, 1.0), 0.0, 1.0)


## 레인을 옮긴다. step은 -1 또는 1이다.
func move(step: int) -> void:
	if _finished:
		return
	player_lane = clampi(player_lane + step, 0, LANE_COUNT - 1)


## 시간을 흘린다. 장애물을 내리고, 표적을 쫓고, 충돌과 포착을 판정한다.
func advance(delta: float) -> void:
	if _finished:
		return
	distance += track.scroll_speed * delta
	_move_obstacles(delta)
	# 판정을 먼저 하고 치운다. 빠른 프레임에서 지나쳐 버린 장애물도 판정에 걸려야 한다
	_check_collision()
	_despawn_obstacles()
	_spawn_left -= delta
	if _spawn_left <= 0.0:
		_spawn_row()
	if _finished:
		return
	_advance_target(delta)


func _move_obstacles(delta: float) -> void:
	var step: float = track.scroll_speed * delta
	for obstacle: Dictionary in obstacles:
		obstacle["prev_y"] = float(obstacle["y"])
		obstacle["y"] = float(obstacle["y"]) - step


func _despawn_obstacles() -> void:
	var alive: Array[Dictionary] = []
	for obstacle: Dictionary in obstacles:
		if float(obstacle["y"]) > DESPAWN_Y:
			alive.append(obstacle)
	obstacles = alive


## 한 줄에 장애물을 놓는다. 지나갈 레인은 반드시 남긴다.
func _spawn_row() -> void:
	_spawn_left = track.spawn_delay(_rng)
	var blocked: int = track.blocked_lanes(_rng, LANE_COUNT, MIN_FREE_LANES)
	var lanes: Array[int] = []
	for lane: int in range(LANE_COUNT):
		lanes.append(lane)
	for i: int in range(lanes.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: int = lanes[i]
		lanes[i] = lanes[j]
		lanes[j] = tmp
	for i: int in range(blocked):
		_shape_counter += 1
		obstacles.append(
			{
				"lane": lanes[i],
				"y": SPAWN_Y,
				"prev_y": SPAWN_Y,
				"spent": false,
				"shape": _shape_counter,
			}
		)


## 이번 프레임에 지나간 구간이 플레이어와 겹쳤는지 본다.
## 속도가 빠르면 한 프레임에 판정 폭을 건너뛸 수 있어 구간으로 검사한다
func _check_collision() -> void:
	for obstacle: Dictionary in obstacles:
		if bool(obstacle["spent"]):
			continue
		if int(obstacle["lane"]) != player_lane:
			continue
		var here: float = float(obstacle["y"])
		var before: float = float(obstacle["prev_y"])
		if before < -HIT_WINDOW or here > HIT_WINDOW:
			continue
		obstacle["spent"] = true
		hits += 1
		gap += track.hit_penalty
		if hits >= track.max_hits:
			_finished = true
		return


## 표적에 붙는다. 거리가 0이 됐을 때 레인이 같으면 잡고, 다르면 다시 벌어진다.
func _advance_target(delta: float) -> void:
	var thief: Dictionary = target()
	if thief.is_empty():
		_finished = true
		return
	_switch_left -= delta
	if _switch_left <= 0.0:
		_switch_left = track.switch_interval
		thief["lane"] = _drift_lane(int(thief["lane"]))
	gap -= track.close_speed * delta
	if gap > 0.0:
		return
	if int(thief["lane"]) == player_lane:
		thief["caught"] = true
		target_index += 1
		gap = track.start_gap
		if target_index >= thieves.size():
			_finished = true
		return
	gap = track.retry_gap


## 표적이 도망칠 다음 레인. 한 칸씩 흔들리되 플레이어가 붙은 레인은 피하려 든다.
func _drift_lane(lane: int) -> int:
	var step: int = _rng.randi_range(-1, 1)
	if lane == player_lane and _rng.randf() < track.evade_chance:
		step = 1 if lane == 0 else (-1 if lane == LANE_COUNT - 1 else _away_step())
	return clampi(lane + step, 0, LANE_COUNT - 1)


## 가운데에서 달아날 때 좌우 중 한쪽을 고른다.
func _away_step() -> int:
	return 1 if _rng.randf() < 0.5 else -1
