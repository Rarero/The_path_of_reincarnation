extends GdUnitTestSuite

## 노름판 3종 판정 검증 (docs/act1/EVENTS.md 7장 B1).
##
## 판정과 배당은 순수 함수라 전수 또는 다수 시드로 고정할 수 있다.
## 썅륙은 36가지 눈을 전부 돌려 승률과 기대값을 확인한다.

const TABLE_PATH: String = "res://resources/minigames/gamble_table_act1.tres"
const SAMPLE_ROUNDS: int = 200


func test_tujeon_ttaeng_beats_any_kkeut() -> void:
	# 1땡(1+1)이 9끗(4+5)을 이긴다 (EVENTS 7장 B1 게임 방식)
	assert_int(GamblingGames.tujeon_rank([1, 1])).is_greater(GamblingGames.tujeon_rank([4, 5]))
	# 땡끼리는 숫자가 큰 쪽이 이긴다
	assert_int(GamblingGames.tujeon_rank([9, 9])).is_greater(GamblingGames.tujeon_rank([1, 1]))
	# 끗은 합의 끝자리다
	assert_int(GamblingGames.tujeon_rank([4, 5])).is_equal(9)
	assert_int(GamblingGames.tujeon_rank([6, 5])).is_equal(1)


func test_golpae_score_is_last_digit_of_pips() -> void:
	assert_int(GamblingGames.golpae_score([Vector2i(3, 4), Vector2i(2, 2)])).is_equal(1)
	assert_int(GamblingGames.golpae_score([Vector2i(1, 1), Vector2i(1, 2)])).is_equal(5)
	assert_int(GamblingGames.golpae_score([Vector2i(6, 6), Vector2i(6, 6)])).is_equal(4)


func test_ssangryuk_house_takes_seven() -> void:
	for a: int in range(1, 7):
		for b: int in range(1, 7):
			if a + b != GamblingGames.HOUSE_SUM:
				continue
			for bet: int in _all_bets():
				assert_bool(GamblingGames.ssangryuk_wins([a, b], bet)).is_false()


func test_ssangryuk_win_counts_are_balanced() -> void:
	var wins: Dictionary = {
		GamblingGames.Bet.SMALL: 0, GamblingGames.Bet.BIG: 0, GamblingGames.Bet.PAIR: 0
	}
	for a: int in range(1, 7):
		for b: int in range(1, 7):
			for bet: int in wins.keys():
				if GamblingGames.ssangryuk_wins([a, b], bet):
					wins[bet] += 1
	# 소와 대는 각각 15/36, 쌍은 6/36이다
	assert_int(wins[GamblingGames.Bet.SMALL]).is_equal(15)
	assert_int(wins[GamblingGames.Bet.BIG]).is_equal(15)
	assert_int(wins[GamblingGames.Bet.PAIR]).is_equal(6)


func test_ssangryuk_expected_value_is_uniform() -> void:
	var table: GambleTable = _table()
	var small: float = 15.0 / 36.0 * table.small_big_mult
	var big: float = 15.0 / 36.0 * table.small_big_mult
	var pair: float = 6.0 / 36.0 * table.pair_mult
	assert_float(small).is_equal_approx(big, 0.0001)
	assert_float(small).is_equal_approx(pair, 0.0001)


func test_payout_matches_outcome() -> void:
	var table: GambleTable = _table()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20260806
	for i: int in range(SAMPLE_ROUNDS):
		var bet: int = 10 + (i % 5) * 10
		_assert_payout(GamblingGames.play_tujeon(bet, table, rng), bet, table.even_money_mult)
		_assert_payout(GamblingGames.play_golpae(bet, table, rng), bet, table.even_money_mult)
		var kind: int = i % 3
		var pair: bool = kind == GamblingGames.Bet.PAIR
		var mult: float = table.pair_mult if pair else table.small_big_mult
		_assert_payout(GamblingGames.play_ssangryuk(bet, kind, table, rng), bet, mult)


func test_same_seed_reproduces_rounds() -> void:
	var table: GambleTable = _table()
	var a: RandomNumberGenerator = RandomNumberGenerator.new()
	var b: RandomNumberGenerator = RandomNumberGenerator.new()
	a.seed = 4242
	b.seed = 4242
	for i: int in range(20):
		var left: Dictionary = GamblingGames.play_tujeon(20, table, a)
		var right: Dictionary = GamblingGames.play_tujeon(20, table, b)
		assert_int(int(left["outcome"])).is_equal(int(right["outcome"]))
		assert_int(int(left["coins_delta"])).is_equal(int(right["coins_delta"]))


func test_table_bet_limits() -> void:
	var table: GambleTable = _table()
	assert_bool(table.can_play(table.min_bet)).is_true()
	assert_bool(table.can_play(table.min_bet - 1)).is_false()
	assert_int(table.max_bet(1000)).is_less_equal(500)
	assert_int(table.max_bet(1000)).is_greater_equal(table.min_bet)
	assert_int(table.rounds).is_equal(3)


## 썅륙 베팅 3종.
func _all_bets() -> Array[int]:
	return [GamblingGames.Bet.SMALL, GamblingGames.Bet.BIG, GamblingGames.Bet.PAIR]


func _table() -> GambleTable:
	return load(TABLE_PATH) as GambleTable


## 이기면 배율만큼, 비기면 0, 지면 건 돈만큼 잃는다.
func _assert_payout(result: Dictionary, bet: int, multiplier: float) -> void:
	var delta_coins: int = int(result["coins_delta"])
	match int(result["outcome"]):
		GamblingGames.Outcome.PLAYER:
			assert_int(delta_coins).is_equal(int(floor(float(bet) * multiplier)) - bet)
		GamblingGames.Outcome.PUSH:
			assert_int(delta_coins).is_equal(0)
		_:
			assert_int(delta_coins).is_equal(-bet)
