extends GdUnitTestSuite

## 씨름 연타 대결 검증 (docs/act1/EVENTS.md 5장 N5).
##
## 게이지 이동과 승패 조건, 프롬프트 재현성을 고정한다. 입력 처리는 씬 몫이라 여기서는
## press와 advance만 부른다.

const OPPONENT_PATHS: Array[String] = [
	"res://resources/minigames/ssireum/ssireum_scrawny.tres",
	"res://resources/minigames/ssireum/ssireum_stout.tres",
	"res://resources/minigames/ssireum/ssireum_bull.tres",
]


func test_opponents_are_loadable_and_sane() -> void:
	var big_count: int = 0
	for path: String in OPPONENT_PATHS:
		var opponent: SsireumOpponent = load(path) as SsireumOpponent
		assert_object(opponent).is_not_null()
		assert_bool(opponent.id != &"").is_true()
		assert_float(opponent.push_speed).is_greater(0.0)
		# 한 방향을 오래 두드리게 한다. 너무 적으면 연타가 아니라 반응 게임이 된다
		assert_int(opponent.mash_per_prompt).is_between(8, 20)
		# 감소를 무시했을 때의 최소 타수. 한 판이 20타 아래로 끝나지 않게 한다
		assert_int(int(1.0 / opponent.gain_per_hit)).is_greater_equal(12)
		assert_int(opponent.win_coins).is_greater(0)
		if opponent.is_big:
			big_count += 1
	# 큰 도깨비는 낮은 확률로 나오는 상급 상대 1종이다
	assert_int(big_count).is_equal(1)


func test_big_opponent_is_rarer_and_richer() -> void:
	var normal: SsireumOpponent = load(OPPONENT_PATHS[1]) as SsireumOpponent
	var big: SsireumOpponent = load(OPPONENT_PATHS[2]) as SsireumOpponent
	assert_float(big.weight).is_less(normal.weight)
	assert_float(big.push_speed).is_greater(normal.push_speed)
	assert_int(big.win_coins).is_greater(normal.win_coins)


func test_correct_press_pushes_gauge_up() -> void:
	var duel: SsireumDuel = _duel(0)
	var before: float = duel.gauge
	assert_bool(duel.press(duel.prompt)).is_true()
	assert_float(duel.gauge).is_greater(before)
	assert_int(duel.hits).is_equal(1)


func test_prompt_holds_until_mash_gauge_empties() -> void:
	var duel: SsireumDuel = _duel(3)
	var total: int = duel.mash_total()
	assert_int(total).is_greater(1)
	var direction: int = duel.prompt
	# 게이지가 다 줄기 전에는 같은 방향을 계속 연타한다
	for i: int in range(total - 1):
		assert_bool(duel.press(direction)).is_true()
		assert_int(duel.prompt).is_equal(direction)
		assert_int(duel.mash_left).is_equal(total - i - 1)
		assert_float(duel.mash_ratio()).is_greater(0.0)
	# 마지막 한 번으로 게이지를 비우면 다음 방향으로 넘어가고 게이지가 되찬다
	assert_bool(duel.press(direction)).is_true()
	assert_int(duel.cleared).is_equal(1)
	assert_int(duel.mash_left).is_equal(total)
	assert_float(duel.mash_ratio()).is_equal_approx(1.0, 0.0001)


func test_wrong_press_does_not_consume_mash_gauge() -> void:
	var duel: SsireumDuel = _duel(3)
	var before: int = duel.mash_left
	var wrong: int = (duel.prompt + 1) % 4
	assert_bool(duel.press(wrong)).is_false()
	assert_int(duel.mash_left).is_equal(before)


func test_prompt_may_repeat() -> void:
	# 같은 방향이 연달아 나올 수 있다 (사용자 요청 2026-08-06)
	var duel: SsireumDuel = _duel(1)
	var repeated: bool = false
	var previous: int = duel.prompt
	for i: int in range(200):
		duel.roll_prompt()
		if duel.prompt == previous:
			repeated = true
			break
		previous = duel.prompt
	assert_bool(repeated).is_true()


func test_wrong_press_pushes_gauge_down() -> void:
	var duel: SsireumDuel = _duel(0)
	var before: float = duel.gauge
	var wrong: int = (duel.prompt + 1) % 4
	assert_bool(duel.press(wrong)).is_false()
	assert_float(duel.gauge).is_less(before)
	assert_int(duel.misses).is_equal(1)


func test_mashing_correctly_wins() -> void:
	var duel: SsireumDuel = _duel(7)
	for i: int in range(400):
		if duel.is_over():
			break
		duel.press(duel.prompt)
	assert_bool(duel.is_over()).is_true()
	assert_bool(duel.player_won()).is_true()


func test_doing_nothing_loses() -> void:
	var duel: SsireumDuel = _duel(7)
	for i: int in range(2000):
		if duel.is_over():
			break
		duel.advance(0.05)
	assert_bool(duel.is_over()).is_true()
	assert_bool(duel.player_won()).is_false()


func test_same_seed_reproduces_prompts() -> void:
	var a: SsireumDuel = _duel(1234)
	var b: SsireumDuel = _duel(1234)
	for i: int in range(40):
		assert_int(a.prompt).is_equal(b.prompt)
		a.roll_prompt()
		b.roll_prompt()


func test_progress_stays_in_range() -> void:
	var duel: SsireumDuel = _duel(5)
	for i: int in range(400):
		duel.advance(0.05)
		assert_float(duel.progress()).is_between(0.0, 1.0)
		assert_float(duel.mash_ratio()).is_between(0.0, 1.0)
		if duel.is_over():
			break


## 초당 7회 연타면 표준 상대를 이기고 초당 4회면 진다 (2026-08-06 2차 재조정).
## 1차 수치는 너무 쉽게 이겨서 되미는 양을 낮추고 미는 힘을 올렸다
func test_mash_rate_decides_the_duel() -> void:
	assert_bool(_wins_at(7.0)).is_true()
	assert_bool(_wins_at(4.0)).is_false()


## 연타 속도와 미는 힘이 팽팽하면 제한 시간에 걸려 승부가 난다. 무한히 늘어지지 않는다
func test_time_limit_ends_a_stalemate() -> void:
	var opponent: SsireumOpponent = load(OPPONENT_PATHS[1]) as SsireumOpponent
	var equilibrium: float = opponent.push_speed / opponent.gain_per_hit
	var duel: SsireumDuel = _run_at(equilibrium)
	assert_bool(duel.is_over()).is_true()
	assert_float(duel.elapsed).is_greater_equal(SsireumDuel.TIME_LIMIT - 0.2)


## 초당 그 횟수로 연타했을 때 이기는지.
func _wins_at(presses_per_sec: float) -> bool:
	return _run_at(presses_per_sec).player_won()


## 초당 그 횟수로 연타하며 대결을 끝까지 돌린다 (0.05초 간격으로 시간을 흘린다).
func _run_at(presses_per_sec: float) -> SsireumDuel:
	var duel: SsireumDuel = _duel(31)
	var step: float = 0.05
	var carry: float = 0.0
	for i: int in range(2000):
		if duel.is_over():
			break
		duel.advance(step)
		carry += presses_per_sec * step
		while carry >= 1.0 and not duel.is_over():
			carry -= 1.0
			duel.press(duel.prompt)
	return duel


func _duel(seed_value: int) -> SsireumDuel:
	var opponent: SsireumOpponent = load(OPPONENT_PATHS[1]) as SsireumOpponent
	return SsireumDuel.new(opponent, seed_value)
