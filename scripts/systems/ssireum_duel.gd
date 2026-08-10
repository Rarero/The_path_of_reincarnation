class_name SsireumDuel
extends RefCounted

## 씨름 연타 대결의 순수 로직 (docs/act1/EVENTS.md 5장 N5).
##
## 두 개의 게이지로 돌아간다.
## - 씨름 게이지: -1(패)에서 +1(승). 상대가 매 프레임 자기 쪽으로 민다
## - 연타 게이지: 지금 뜬 방향을 몇 번 더 눌러야 하는지. 맞게 누를 때마다 줄어든다
##
## 방향(A S D W 또는 방향키)이 하나 뜨면 연타 게이지가 다 줄 때까지 그 방향을 연타한다.
## 다 줄면 다음 방향이 뜬다. 같은 방향이 다시 나올 수 있다. 제한 시간은 없고, 압박은
## 상대가 씨름 게이지를 계속 미는 것으로만 준다.
## 맞게 누를 때마다 씨름 게이지가 오르고 틀리면 내려간다.
##
## 씬과 입력에서 분리한 순수 자료구조라 gdUnit4 단위 테스트가 된다. 시드를 받으므로
## 같은 시드는 같은 방향 순서를 낸다.

## 프롬프트 방향. 표시 글자는 A S D W이고 방향키로도 받는다
enum Direction { LEFT, DOWN, RIGHT, UP }

const DIRECTION_KEYS: Dictionary = {
	Direction.LEFT: "A",
	Direction.DOWN: "S",
	Direction.RIGHT: "D",
	Direction.UP: "W",
}

## 방향별 입력 액션. 방향키는 Godot 기본 ui_ 액션이 받는다
const DIRECTION_ACTIONS: Dictionary = {
	Direction.LEFT: [&"move_left", &"ui_left"],
	Direction.DOWN: [&"move_down", &"ui_down"],
	Direction.RIGHT: [&"move_right", &"ui_right"],
	Direction.UP: [&"move_up", &"ui_up"],
}

## 승패가 갈리는 씨름 게이지 절대값
const WIN_GAUGE: float = 1.0
## 대결 제한 시간 (초). 연타 속도와 미는 힘이 팽팽하면 승부가 나지 않으므로 상한을 둔다.
## 넘기면 그 시점에 앞선 쪽이 이긴다. 연타 하나하나에 거는 제한 시간이 아니다
const TIME_LIMIT: float = 20.0

## -1(패배)에서 +1(승리) 사이. 0에서 시작한다
var gauge: float = 0.0
## 지금 연타해야 하는 방향 (Direction)
var prompt: int = Direction.LEFT
## 이 방향을 앞으로 몇 번 더 눌러야 하는지
var mash_left: int = 1
## 맞게 누른 횟수 누계
var hits: int = 0
## 틀리게 누른 횟수 누계
var misses: int = 0
## 넘긴 방향 수 (연타를 끝까지 채운 횟수)
var cleared: int = 0
## 대결이 시작된 뒤 흐른 시간 (초)
var elapsed: float = 0.0

var _opponent: SsireumOpponent = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _finished: bool = false


func _init(duel_opponent: SsireumOpponent, seed_value: int) -> void:
	_opponent = duel_opponent
	_rng.seed = seed_value
	roll_prompt()


## 표시 글자 (A S D W).
static func key_label(direction: int) -> String:
	return String(DIRECTION_KEYS.get(direction, "?"))


## 그 입력이 이 방향에 해당하는지. WASD와 방향키를 모두 받는다.
static func matches(direction: int, event: InputEvent) -> bool:
	for action: StringName in DIRECTION_ACTIONS.get(direction, []):
		if InputMap.has_action(action) and event.is_action_pressed(action):
			return true
	return false


## 입력이 네 방향 중 어느 하나라도 눌린 것인지 (틀린 방향 판정에 쓴다).
static func direction_of(event: InputEvent) -> int:
	for direction: int in DIRECTION_ACTIONS:
		if matches(direction, event):
			return direction
	return -1


func opponent() -> SsireumOpponent:
	return _opponent


func is_over() -> bool:
	return _finished


func player_won() -> bool:
	return _finished and gauge >= WIN_GAUGE


## 씨름 게이지 막대에 그릴 0~1 값. 0.5가 팽팽한 상태다
func progress() -> float:
	return clampf((gauge + WIN_GAUGE) * 0.5, 0.0, 1.0)


## 연타 게이지에 그릴 0~1 값. 1에서 시작해 연타할수록 줄고 0이 되면 다음 방향이 뜬다
func mash_ratio() -> float:
	var total: int = mash_total()
	if total <= 0:
		return 0.0
	return clampf(float(mash_left) / float(total), 0.0, 1.0)


## 방향 하나를 넘기는 데 필요한 연타 수.
func mash_total() -> int:
	return maxi(_opponent.mash_per_prompt, 1) if _opponent != null else 1


## 남은 대결 시간 (초).
func time_left() -> float:
	return maxf(TIME_LIMIT - elapsed, 0.0)


## 시간을 흘린다. 상대가 씨름 게이지를 민다. 연타 하나하나에는 제한 시간이 없다.
## 제한 시간을 넘기면 그 시점에 앞선 쪽이 이긴다.
func advance(delta: float) -> void:
	if _finished or _opponent == null:
		return
	elapsed += delta
	gauge -= _opponent.push_speed * delta
	if elapsed >= TIME_LIMIT:
		gauge = WIN_GAUGE if gauge >= 0.0 else -WIN_GAUGE
		_finished = true
		return
	_check_end()


## 방향을 눌렀다. 맞으면 true.
## 맞으면 씨름 게이지가 오르고 연타 게이지가 한 칸 준다. 다 줄면 다음 방향으로 넘어간다.
func press(direction: int) -> bool:
	if _finished:
		return false
	if direction != prompt:
		misses += 1
		gauge -= _opponent.miss_penalty
		_check_end()
		return false
	hits += 1
	gauge += _opponent.gain_per_hit
	mash_left -= 1
	if mash_left <= 0:
		cleared += 1
		roll_prompt()
	_check_end()
	return true


## 다음 방향을 뽑고 연타 게이지를 되채운다. 직전과 같은 방향이 다시 나올 수 있다.
func roll_prompt() -> void:
	prompt = _rng.randi_range(0, DIRECTION_KEYS.size() - 1)
	mash_left = mash_total()


func _check_end() -> void:
	if absf(gauge) >= WIN_GAUGE:
		gauge = clampf(gauge, -WIN_GAUGE, WIN_GAUGE)
		_finished = true
