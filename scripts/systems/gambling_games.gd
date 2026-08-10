class_name GamblingGames
extends RefCounted

## 노름판 3종의 판정과 배당 (docs/act1/EVENTS.md 7장 B1).
##
## 투전(끗과 땡), 골패(점 합 끝자리), 썅륙(주사위 소 대 쌍)의 승패와 지급 배율만 계산한다.
## 씬과 입력에서 분리한 순수 함수 모음이라 gdUnit4 단위 테스트가 된다.
## 배당 수치는 코드가 아니라 GambleTable 리소스에 있다.
##
## 기대값: 투전과 골패는 비기면 환급이라 1.0이다. 썅륙은 합 7을 하우스 승으로 두어
## 소, 대, 쌍 세 베팅이 모두 같은 기대값을 갖는다 (초안 배당에서 0.833).

## 투전, 골패, 썅륙
enum Game { TUJEON, GOLPAE, SSANGRYUK }
## 플레이어 승, 딜러 승, 무승부(건 돈 환급)
enum Outcome { PLAYER, DEALER, PUSH }
## 썅륙 베팅. 소는 합 2~6, 대는 합 8~12, 쌍은 두 눈이 같음
enum Bet { SMALL, BIG, PAIR }

const GAME_NAMES: Dictionary = {
	Game.TUJEON: "투전",
	Game.GOLPAE: "골패",
	Game.SSANGRYUK: "썅륙",
}

const BET_NAMES: Dictionary = {
	Bet.SMALL: "소",
	Bet.BIG: "대",
	Bet.PAIR: "쌍",
}

## 투전 패의 숫자 범위와 같은 숫자의 장수 (1~10이 각 4장, 40장)
const TUJEON_MAX: int = 10
const TUJEON_COPIES: int = 4
## 땡의 서열 기준값. 어떤 끗보다도 크게 만든다 (1땡 > 9끗)
const TTAENG_BASE: int = 100
## 골패 한 쪽의 점 개수 범위
const GOLPAE_PIPS: int = 6
## 썅륙에서 하우스가 이기는 주사위 합
const HOUSE_SUM: int = 7


## 게임 이름.
static func game_name(game: int) -> String:
	return String(GAME_NAMES.get(game, "?"))


## 썅륙 베팅 이름.
static func bet_name(bet: int) -> String:
	return String(BET_NAMES.get(bet, "?"))


## 이 방에서 열릴 게임을 시드로 고른다 (방마다 1종, 7장 공통 규칙).
static func pick_game(rng: RandomNumberGenerator) -> int:
	return rng.randi_range(0, GAME_NAMES.size() - 1)


## 투전 한 판. 각자 2장을 받아 땡과 끗으로 겨룬다.
static func play_tujeon(bet: int, table: GambleTable, rng: RandomNumberGenerator) -> Dictionary:
	var deck: Array[int] = _tujeon_deck(rng)
	var player: Array[int] = [deck[0], deck[1]]
	var dealer: Array[int] = [deck[2], deck[3]]
	var player_rank: int = tujeon_rank(player)
	var dealer_rank: int = tujeon_rank(dealer)
	var outcome: int = _compare(player_rank, dealer_rank)
	var result: Dictionary = _payout(Game.TUJEON, outcome, bet, table.even_money_mult)
	result["player_cards"] = player
	result["dealer_cards"] = dealer
	result["player_text"] = _tujeon_text(player)
	result["dealer_text"] = _tujeon_text(dealer)
	return result


## 골패 한 판. 각자 2장을 받아 점 합의 끝자리로 겨룬다.
static func play_golpae(bet: int, table: GambleTable, rng: RandomNumberGenerator) -> Dictionary:
	var deck: Array = _golpae_deck(rng)
	var player: Array = [deck[0], deck[1]]
	var dealer: Array = [deck[2], deck[3]]
	var player_rank: int = golpae_score(player)
	var dealer_rank: int = golpae_score(dealer)
	var outcome: int = _compare(player_rank, dealer_rank)
	var result: Dictionary = _payout(Game.GOLPAE, outcome, bet, table.even_money_mult)
	result["player_tiles"] = player
	result["dealer_tiles"] = dealer
	result["player_text"] = _golpae_text(player, player_rank)
	result["dealer_text"] = _golpae_text(dealer, dealer_rank)
	return result


## 썅륙 한 판. 주사위 2개를 던져 미리 고른 베팅과 맞춰본다.
static func play_ssangryuk(
	bet: int, bet_kind: int, table: GambleTable, rng: RandomNumberGenerator
) -> Dictionary:
	var dice: Array[int] = [rng.randi_range(1, 6), rng.randi_range(1, 6)]
	var multiplier: float = table.pair_mult if bet_kind == Bet.PAIR else table.small_big_mult
	var won: bool = ssangryuk_wins(dice, bet_kind)
	var outcome: int = Outcome.PLAYER if won else Outcome.DEALER
	var result: Dictionary = _payout(Game.SSANGRYUK, outcome, bet, multiplier)
	result["dice"] = dice
	result["sum"] = dice[0] + dice[1]
	result["bet_kind"] = bet_kind
	result["player_text"] = "%s에 걸었다" % bet_name(bet_kind)
	result["dealer_text"] = _ssangryuk_text(dice)
	return result


## 그 주사위 눈에서 그 베팅이 이기는지. 합 7은 무조건 하우스 승이다.
static func ssangryuk_wins(dice: Array, bet_kind: int) -> bool:
	var total: int = int(dice[0]) + int(dice[1])
	if total == HOUSE_SUM:
		return false
	match bet_kind:
		Bet.PAIR:
			return int(dice[0]) == int(dice[1])
		Bet.SMALL:
			return total < HOUSE_SUM
		Bet.BIG:
			return total > HOUSE_SUM
	return false


## 투전 패의 서열. 같은 숫자면 땡이라 어떤 끗보다도 높다 (1땡이 9끗을 이긴다).
static func tujeon_rank(cards: Array) -> int:
	if int(cards[0]) == int(cards[1]):
		return TTAENG_BASE + int(cards[0])
	return (int(cards[0]) + int(cards[1])) % 10


static func _tujeon_text(cards: Array) -> String:
	if int(cards[0]) == int(cards[1]):
		return "%d %d  %d땡" % [int(cards[0]), int(cards[1]), int(cards[0])]
	var score: int = (int(cards[0]) + int(cards[1])) % 10
	return "%d %d  %d끗" % [int(cards[0]), int(cards[1]), score]


## 골패 2장의 점 합 끝자리.
static func golpae_score(tiles: Array) -> int:
	var total: int = 0
	for tile: Variant in tiles:
		total += int(tile.x) + int(tile.y)
	return total % 10


static func _golpae_text(tiles: Array, score: int) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for tile: Variant in tiles:
		parts.append("%d-%d" % [int(tile.x), int(tile.y)])
	return "%s  %d점" % [" ".join(parts), score]


static func _ssangryuk_text(dice: Array) -> String:
	var total: int = int(dice[0]) + int(dice[1])
	var label: String = "대" if total > HOUSE_SUM else "소"
	if total == HOUSE_SUM:
		label = "하우스"
	elif int(dice[0]) == int(dice[1]):
		label = "쌍"
	return "%d %d  합 %d  %s" % [int(dice[0]), int(dice[1]), total, label]


## 서열 비교. 같으면 무승부다
static func _compare(player_rank: int, dealer_rank: int) -> int:
	if player_rank > dealer_rank:
		return Outcome.PLAYER
	if player_rank < dealer_rank:
		return Outcome.DEALER
	return Outcome.PUSH


## 지급 계산. multiplier는 건 돈을 포함한 총 지급 배율이다.
## 이기면 배율만큼 받고, 비기면 건 돈을 돌려받고, 지면 건 돈을 잃는다
static func _payout(game: int, outcome: int, bet: int, multiplier: float) -> Dictionary:
	var paid: int = 0
	match outcome:
		Outcome.PLAYER:
			paid = int(floor(float(bet) * multiplier))
		Outcome.PUSH:
			paid = bet
	return {
		"game": game,
		"outcome": outcome,
		"bet": bet,
		"multiplier": multiplier,
		"coins_delta": paid - bet,
	}


## 투전 덱 40장을 섞어 돌려준다 (1~10이 각 4장).
static func _tujeon_deck(rng: RandomNumberGenerator) -> Array[int]:
	var deck: Array[int] = []
	for number: int in range(1, TUJEON_MAX + 1):
		for _copy: int in range(TUJEON_COPIES):
			deck.append(number)
	_shuffle_int(deck, rng)
	return deck


## 골패 덱. 두 쪽 점 조합 21종을 한 장씩 두고 섞는다
static func _golpae_deck(rng: RandomNumberGenerator) -> Array:
	var deck: Array = []
	for a: int in range(1, GOLPAE_PIPS + 1):
		for b: int in range(a, GOLPAE_PIPS + 1):
			deck.append(Vector2i(a, b))
	_shuffle_any(deck, rng)
	return deck


static func _shuffle_int(deck: Array[int], rng: RandomNumberGenerator) -> void:
	for i: int in range(deck.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = deck[i]
		deck[i] = deck[j]
		deck[j] = tmp


static func _shuffle_any(deck: Array, rng: RandomNumberGenerator) -> void:
	for i: int in range(deck.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = deck[i]
		deck[i] = deck[j]
		deck[j] = tmp
