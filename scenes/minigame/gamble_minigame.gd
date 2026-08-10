class_name GambleMinigame
extends Minigame

## 노름판 (docs/act1/EVENTS.md 7장 B1, 2026-08-07 장면 연출 추가).
##
## 흐름
## 1. 멍석이 화면을 채우고 건너편에 노름꾼이 앉는다. 구경꾼이 판을 둘러싼다
## 2. 한 판 붙을지 그냥 지나갈지 고른다
## 3. 썅륙이면 소 대 쌍 중 하나를 고르고, 이어서 걸 엽전을 정한다
## 4. 판이 실제로 굴러간다. 투전과 골패는 패를 돌린 뒤 한 장씩 뒤집고, 썅륙은 통을
##    흔들어 주사위를 굴린다. 결과 문구는 패가 다 열린 뒤에 붙는다
## 5. 승부가 나면 엽전이 딴 쪽으로 날아간다. 최대 세 판까지 이어진다
##
## 판정과 배당은 scripts/systems/gambling_games.gd와 GambleTable 리소스에 있다.
## 이 씬은 표시와 입력만 맡는다.
##
## 그리기는 전부 _draw에서 한다. 등불, 구경꾼 뒤, 노름꾼, 멍석, 패, 구경꾼 앞, HUD 순으로
## 겹쳐야 해서 자식 노드 대신 그리기 순서를 직접 잡았다 (씨름 미니게임과 같은 방식).

enum Phase { INTRO, OFFER, BET_KIND, BET_AMOUNT, REVEAL, DONE }

const TABLE_PATH: String = "res://resources/minigames/gamble_table_act1.tres"
const MAT_PATH: String = "res://assets/sprites/bg/act1/bg_gambling_mat.png"
const LANTERN_BAND_PATH: String = "res://assets/sprites/bg/act1/bg_lantern_band.png"
## 노름판 전용 노름꾼 조형 (요청서 026). 양반다리로 앉아 두 팔을 벌린 상반신이다.
## 두 경로가 다르면 앉은 배치(_draw_seated_dealer)로 그린다
const GAMBLER_FRAMES_PATH: String = "res://scenes/enemies/gambler_frames.tres"
const DEALER_FRAMES_PATH: String = "res://scenes/enemies/dokkaebi_frames.tres"

## 건너편 구경꾼 (이쪽을 본다)
const CROWD_FAR: Array[String] = [
	"res://assets/sprites/bg/act1/crowd/crowd_b.png",
	"res://assets/sprites/bg/act1/crowd/crowd_d.png",
	"res://assets/sprites/bg/act1/crowd/crowd_g.png",
	"res://assets/sprites/bg/act1/crowd/crowd_cat.png",
]
## 이쪽 구경꾼 (등을 보인다). 화면 아래 양 끝에만 둔다
const CROWD_NEAR: Array[String] = [
	"res://assets/sprites/bg/act1/crowd/crowd_back_b.png",
	"res://assets/sprites/bg/act1/crowd/crowd_back_d.png",
]

const SEED_SALT: int = 1442695040
const SEED_MASK: int = 0x7FFFFFFF

## 게임별 한 줄 규칙 안내 (대사량은 최소로 둔다, GDD 2장)
const RULE_HINTS: Dictionary = {
	GamblingGames.Game.TUJEON: "두 장 합의 끝자리로 겨룬다. 같은 숫자면 땡이다",
	GamblingGames.Game.GOLPAE: "두 장의 점을 모두 더한 끝자리가 높은 쪽이 이긴다",
	GamblingGames.Game.SSANGRYUK: "주사위 둘. 소는 2에서 6, 대는 8에서 12, 쌍은 같은 눈",
}
const OFFER_LABELS: Array[String] = ["한 판 붙는다", "그냥 지나간다"]
## 썅륙 베팅 종류 수 (소, 대, 쌍)
const BET_COUNT: int = 3

# --- 배치 ---

const CENTER_X: float = 240.0
## 뒷벽과 바닥이 갈리는 선
const FLOOR_LINE: float = 118.0
## 멍석 위아래 변의 높이와 반너비 (위가 좁은 사다리꼴로 눕혀 놓은 멍석)
const MAT_TOP_Y: float = 148.0
const MAT_BOTTOM_Y: float = 214.0
const MAT_TOP_HALF: float = 104.0
const MAT_BOTTOM_HALF: float = 148.0
## 멍석 옆에 늘어놓는 세간 (MAT_PATH 조형). 원본 48x12를 2배로 키워 좌우 끝에 둔다
const CLUTTER_SCALE: float = 2.0
const CLUTTER_POS: Array[Vector2] = [Vector2(-8.0, 96.0), Vector2(392.0, 96.0)]
## 노름꾼 발밑 (옛 옆모습 폴백용). 멍석이 하반신을 가려 앉은 것처럼 읽힌다
const DEALER_FEET_Y: float = 180.0
const DEALER_SCALE: float = 1.8
## 앉은 전용 조형은 허리에서 잘려 있다. 조형 아래끝을 멍석 윗변(148)에 살짝 걸치게 두면
## 벌린 두 팔이 멍석에 가리지 않고 건너편에 앉은 것으로 읽힌다
const SEATED_SCALE: float = 1.0
const SEATED_WAIST_Y: float = 152.0
## 스프라이트 캔버스(76x76) 안에서 캐릭터의 가로 중심과 발밑 위치
const ART_CENTER: Vector2 = Vector2(40.0, 57.0)
## 건너편 구경꾼 바닥선
const CROWD_FAR_Y: float = 120.0
## 이쪽 구경꾼 바닥선
const CROWD_NEAR_Y: float = 272.0
## 노름꾼 패가 놓이는 줄
const DEALER_ROW_Y: float = 164.0
## 내 패가 놓이는 줄
const PLAYER_ROW_Y: float = 198.0
## 판돈이 쌓이는 자리. 패와 주사위가 놓이는 가운데를 비켜 멍석 왼쪽에 둔다
const POT_POS: Vector2 = Vector2(132.0, 192.0)
## 패와 주사위가 나오는 자리 (노름꾼 손께)
const DECK_POS: Vector2 = Vector2(406.0, 156.0)

## 뒷벽과 바닥
const WALL: Color = Color(0.09, 0.09, 0.14)
const FLOOR: Color = Color(0.13, 0.12, 0.16)
## 멍석 짚색과 테두리
const STRAW: Color = Color(0.40, 0.34, 0.24)
const STRAW_DIM: Color = Color(0.31, 0.26, 0.18)
const STRAW_EDGE: Color = Color(0.20, 0.17, 0.12)

# --- 패와 주사위 ---

const CARD_SIZE: Vector2 = Vector2(18.0, 28.0)
const CARD_GAP: float = 24.0
const TILE_SIZE: Vector2 = Vector2(30.0, 16.0)
const TILE_GAP: float = 38.0
const DIE_SIZE: float = 16.0
const DIE_GAP: float = 26.0
## 패 겉면 바탕과 패 뒷면 바탕
const PAPER: Color = Color(0.86, 0.81, 0.68)
const PAPER_EDGE: Color = Color(0.20, 0.18, 0.16)
## 주사위 눈 하나의 반지름
const PIP_RADIUS: float = 1.6

# --- 진행 시각 (초) ---

## 패 한 장이 미끄러져 나가는 간격과 걸리는 시간
const DEAL_STEP: float = 0.14
const DEAL_TIME: float = 0.26
## 패를 뒤집기 시작하는 시점, 장당 간격, 한 장 뒤집는 시간
const FLIP_START: float = 0.86
const FLIP_STEP: float = 0.22
const FLIP_TIME: float = 0.20
## 투전과 골패에서 판정 문구가 뜨는 시점
const CARD_VERDICT_AT: float = 1.94
## 주사위통을 흔드는 시간, 굴러 멈추는 시점, 판정 문구가 뜨는 시점
const SHAKE_END: float = 0.45
const ROLL_END: float = 1.55
const DICE_VERDICT_AT: float = 1.82
## 주사위가 튀어오르는 높이 (px)
const DICE_HOP: float = 26.0

# --- 연출 ---

## 승부가 난 뒤 날아가는 엽전 수와 나는 시간, 포물선 높이
const COIN_COUNT: int = 9
const COIN_FLY_TIME: float = 0.75
const COIN_ARC: float = 34.0
## 판정 순간 화면이 물드는 시간 (초)
const FLASH_TIME: float = 0.24
## 판돈 더미로 그리는 엽전의 최대 개수
const POT_MAX: int = 12

## 도입 연출 시간 (초)
@export var intro_time: float = 1.6
## 판 하나를 보여주는 시간 (초). 패를 돌리고 뒤집는 시간을 포함한다
@export var reveal_time: float = 3.2

var _phase: int = Phase.INTRO
var _timer: float = 0.0
var _anim_time: float = 0.0
var _reveal_t: float = 0.0
var _verdict_shown: bool = false
var _table: GambleTable = null
var _game: int = GamblingGames.Game.TUJEON
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _coins: int = 0
var _net: int = 0
var _round: int = 0
var _bet: int = 0
var _bet_kind: int = GamblingGames.Bet.SMALL
var _cursor: int = 0
var _last: Dictionary = {}
var _played: bool = false

var _mat: Texture2D = null
var _lantern_band: Texture2D = null
var _dealer_frames: SpriteFrames = null
var _dealer_seated: bool = false
var _crowd: Array[Dictionary] = []
var _coin_fx: Array[Dictionary] = []
var _flash: float = 0.0
var _flash_color: Color = LANTERN


func begin(config: Dictionary) -> void:
	_table = load(TABLE_PATH) as GambleTable
	if _table == null:
		report(empty_result("노름판"))
		return
	var seed_value: int = int(config.get("seed", 0))
	_rng.seed = (seed_value + SEED_SALT) & SEED_MASK
	_game = GamblingGames.pick_game(_rng)
	_coins = int(config.get("coins", 0))
	_bet = _table.min_bet
	_load_art()
	_build_crowd(seed_value)
	_phase = Phase.INTRO
	_timer = intro_time
	set_process(true)
	set_process_input(true)
	queue_redraw()


func _load_art() -> void:
	if ResourceLoader.exists(MAT_PATH):
		_mat = load(MAT_PATH)
	if ResourceLoader.exists(LANTERN_BAND_PATH):
		_lantern_band = load(LANTERN_BAND_PATH)
	_dealer_seated = GAMBLER_FRAMES_PATH != DEALER_FRAMES_PATH
	var frames_path: String = GAMBLER_FRAMES_PATH if _dealer_seated else DEALER_FRAMES_PATH
	if ResourceLoader.exists(frames_path):
		_dealer_frames = load(frames_path) as SpriteFrames


## 구경꾼을 시드로 흩는다. 건너편은 이쪽을 보고, 이쪽 구경꾼은 아래 양 끝에서 등을 보인다.
func _build_crowd(seed_value: int) -> void:
	_crowd.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var far_x: Array[float] = [116.0, 160.0, 320.0, 364.0]
	for i: int in range(far_x.size()):
		_add_crowd(CROWD_FAR[i % CROWD_FAR.size()], far_x[i], CROWD_FAR_Y, rng)
	_add_crowd(CROWD_NEAR[0], 34.0, CROWD_NEAR_Y, rng)
	_add_crowd(CROWD_NEAR[1], 446.0, CROWD_NEAR_Y, rng)


func _add_crowd(path: String, x: float, feet_y: float, rng: RandomNumberGenerator) -> void:
	if not ResourceLoader.exists(path):
		return
	_crowd.append(
		{
			"tex": load(path) as Texture2D,
			"x": x,
			"y": feet_y,
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(1.8, 3.0),
		}
	)


# --- 진행 ---


func _process(delta: float) -> void:
	_anim_time += delta
	_flash = maxf(_flash - delta, 0.0)
	_advance_coins(delta)
	if _phase == Phase.INTRO:
		_timer -= delta
		if _timer <= 0.0:
			_open_offer()
	elif _phase == Phase.REVEAL:
		_reveal_t += delta
		if not _verdict_shown and _reveal_t >= _verdict_at():
			_show_verdict()
		_timer -= delta
		if _timer <= 0.0:
			_next_round()
	queue_redraw()


## 날아가는 엽전을 옮긴다. 다 난 것은 지운다
func _advance_coins(delta: float) -> void:
	if _coin_fx.is_empty():
		return
	var alive: Array[Dictionary] = []
	for coin: Dictionary in _coin_fx:
		coin["t"] = float(coin["t"]) + delta
		if float(coin["t"]) < COIN_FLY_TIME:
			alive.append(coin)
	_coin_fx = alive


func _input(event: InputEvent) -> void:
	match _phase:
		Phase.OFFER:
			_input_offer(event)
		Phase.BET_KIND:
			_input_bet_kind(event)
		Phase.BET_AMOUNT:
			_input_bet_amount(event)
		Phase.REVEAL:
			# 패가 다 열리기 전에는 넘기지 못한다. 장면을 보라고 만든 시간이다
			if _verdict_shown and _is_confirm(event):
				get_viewport().set_input_as_handled()
				_next_round()


func _is_confirm(event: InputEvent) -> bool:
	return event.is_action_pressed(&"jump") or event.is_action_pressed(&"ui_accept")


func _axis_x(event: InputEvent) -> int:
	if event.is_action_pressed(&"move_right") or event.is_action_pressed(&"ui_right"):
		return 1
	if event.is_action_pressed(&"move_left") or event.is_action_pressed(&"ui_left"):
		return -1
	return 0


func _axis_y(event: InputEvent) -> int:
	if event.is_action_pressed(&"move_down") or event.is_action_pressed(&"ui_down"):
		return 1
	if event.is_action_pressed(&"move_up") or event.is_action_pressed(&"ui_up"):
		return -1
	return 0


func _open_offer() -> void:
	_phase = Phase.OFFER
	_cursor = 0


func _input_offer(event: InputEvent) -> void:
	var step: int = _axis_y(event)
	if step != 0:
		get_viewport().set_input_as_handled()
		_cursor = (_cursor + step + OFFER_LABELS.size()) % OFFER_LABELS.size()
		return
	if not _is_confirm(event):
		return
	get_viewport().set_input_as_handled()
	if _cursor == 1:
		_finish()
		return
	_open_round()


## 다음 판을 연다. 걸 돈이 모자라거나 판수를 다 쓰면 끝낸다.
func _open_round() -> void:
	if _round >= _table.rounds or not _table.can_play(_coins):
		_finish()
		return
	_bet = clampi(_bet, _table.min_bet, maxi(_table.max_bet(_coins), _table.min_bet))
	_phase = Phase.BET_KIND if _game == GamblingGames.Game.SSANGRYUK else Phase.BET_AMOUNT
	_cursor = 0


func _input_bet_kind(event: InputEvent) -> void:
	var step: int = _axis_x(event) + _axis_y(event)
	if step != 0:
		get_viewport().set_input_as_handled()
		_bet_kind = (_bet_kind + step + BET_COUNT) % BET_COUNT
		return
	if not _is_confirm(event):
		return
	get_viewport().set_input_as_handled()
	_phase = Phase.BET_AMOUNT


func _input_bet_amount(event: InputEvent) -> void:
	var step: int = _axis_x(event)
	if step != 0:
		get_viewport().set_input_as_handled()
		var top: int = maxi(_table.max_bet(_coins), _table.min_bet)
		_bet = clampi(_bet + step * _table.bet_step, _table.min_bet, top)
		return
	if _axis_y(event) > 0:
		get_viewport().set_input_as_handled()
		_finish()
		return
	if not _is_confirm(event):
		return
	get_viewport().set_input_as_handled()
	_play_round()


func _play_round() -> void:
	_played = true
	match _game:
		GamblingGames.Game.TUJEON:
			_last = GamblingGames.play_tujeon(_bet, _table, _rng)
		GamblingGames.Game.GOLPAE:
			_last = GamblingGames.play_golpae(_bet, _table, _rng)
		_:
			_last = GamblingGames.play_ssangryuk(_bet, _bet_kind, _table, _rng)
	_phase = Phase.REVEAL
	_reveal_t = 0.0
	_verdict_shown = false
	_timer = reveal_time


## 패가 다 열린 순간. 여기서 소지금을 옮기고 엽전을 날린다
func _show_verdict() -> void:
	_verdict_shown = true
	var delta_coins: int = int(_last.get("coins_delta", 0))
	_net += delta_coins
	_coins += delta_coins
	_round += 1
	var outcome: int = int(_last.get("outcome", GamblingGames.Outcome.DEALER))
	if outcome == GamblingGames.Outcome.PUSH:
		_flash = FLASH_TIME
		_flash_color = INK_DIM
		return
	var won: bool = outcome == GamblingGames.Outcome.PLAYER
	_flash = FLASH_TIME
	_flash_color = LANTERN if won else NIGHT
	_spawn_coins(won)


## 판돈이 이긴 쪽으로 날아간다. 시드를 쓰지 않고 번호로 흩어 재현성을 지킨다
func _spawn_coins(won: bool) -> void:
	var to_y: float = 246.0 if won else 132.0
	for i: int in range(COIN_COUNT):
		var spread: float = (float(i) - float(COIN_COUNT - 1) * 0.5) * 13.0
		_coin_fx.append(
			{
				"from": POT_POS + Vector2(spread * 0.35, 0.0),
				"to": Vector2(CENTER_X + spread, to_y),
				"t": -float(i) * 0.03,
				"won": won,
			}
		)


func _next_round() -> void:
	if _round >= _table.rounds or not _table.can_play(_coins):
		_finish()
		return
	_open_round()


func _finish() -> void:
	_phase = Phase.DONE
	var result: Dictionary = empty_result("노름판")
	result["coins_delta"] = _net
	result["won"] = _net > 0
	if not _played:
		result["losses"] = PackedStringArray(["판을 마다하고 지나갔다"])
	elif _net > 0:
		result["gains"] = PackedStringArray(["엽전 %d닢을 땄다" % _net])
	elif _net < 0:
		result["losses"] = PackedStringArray(["엽전 %d닢을 잃었다" % absi(_net)])
	else:
		result["gains"] = PackedStringArray(["본전치기"])
	report(result)


## 이 게임에서 판정 문구가 뜨는 시점.
func _verdict_at() -> float:
	return DICE_VERDICT_AT if _game == GamblingGames.Game.SSANGRYUK else CARD_VERDICT_AT


# --- 그리기 ---


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP)
	_draw_room()
	_draw_lanterns()
	_draw_clutter()
	_draw_crowd(CROWD_FAR_Y)
	_draw_dealer()
	_draw_mat()
	if _phase == Phase.REVEAL:
		_draw_table_props()
	elif _phase == Phase.BET_AMOUNT or _phase == Phase.BET_KIND:
		_draw_pot(_bet)
	_draw_coins()
	_draw_crowd(CROWD_NEAR_Y)
	_draw_hud()
	if _flash > 0.0:
		var alpha: float = _flash / FLASH_TIME * 0.22
		draw_rect(Rect2(Vector2.ZERO, size), Color(_flash_color, alpha))


## 천장의 등불 띠. 아주 느리게 흔들려 판이 밤 저잣거리 안이라고 알린다
func _draw_lanterns() -> void:
	if _lantern_band == null:
		return
	var sway: float = sin(_anim_time * 0.8) * 3.0
	draw_texture(_lantern_band, Vector2(-16.0 + sway, 30.0).floor())


func _draw_crowd(feet_y: float) -> void:
	for figure: Dictionary in _crowd:
		if not is_equal_approx(float(figure["y"]), feet_y):
			continue
		var tex: Texture2D = figure["tex"]
		var bob: float = sin(_anim_time * float(figure["speed"]) + float(figure["phase"]))
		var offset: float = -1.0 if bob > 0.4 else 0.0
		var pos: Vector2 = Vector2(
			float(figure["x"]) - tex.get_width() * 0.5, feet_y - tex.get_height() + offset
		)
		draw_texture(tex, pos.floor())


## 건너편에 앉은 노름꾼. 멍석이 하반신을 가린다
func _draw_dealer() -> void:
	if _dealer_frames == null:
		return
	var tex: Texture2D = _dealer_texture()
	if tex == null:
		return
	# 말을 걸 때만 몸을 조금 흔든다
	var bob: float = 0.0
	if _phase == Phase.INTRO or _phase == Phase.OFFER:
		bob = -1.0 if sin(_anim_time * 4.0) > 0.5 else 0.0
	if _dealer_seated:
		_draw_seated_dealer(tex, bob)
		return
	draw_set_transform(
		Vector2(CENTER_X, DEALER_FEET_Y + bob), 0.0, Vector2(-DEALER_SCALE, DEALER_SCALE)
	)
	draw_texture(tex, -ART_CENTER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 앉은 전용 조형. 정면을 보고 있으므로 좌우를 뒤집지 않는다
func _draw_seated_dealer(tex: Texture2D, bob: float) -> void:
	var box_size: Vector2 = Vector2(tex.get_size()) * SEATED_SCALE
	var pos: Vector2 = Vector2(
		CENTER_X - box_size.x * 0.5, SEATED_WAIST_Y + bob - box_size.y
	)
	draw_texture_rect(tex, Rect2(pos.floor(), box_size), false)


## 판이 끝나면 이겼는지에 따라 노름꾼의 자세가 달라진다
func _dealer_texture() -> Texture2D:
	if _phase == Phase.REVEAL and _verdict_shown:
		var outcome: int = int(_last.get("outcome", GamblingGames.Outcome.DEALER))
		if outcome == GamblingGames.Outcome.PLAYER:
			return _pose_of(&"lose" if _dealer_seated else &"hurt", 4)
		if outcome == GamblingGames.Outcome.DEALER:
			return _frame_of(&"win" if _dealer_seated else &"hop", 7.0)
	return _frame_of(&"idle", 2.0 if _dealer_seated else 6.0)


func _frame_of(anim: StringName, fps: float) -> Texture2D:
	var name_value: StringName = anim if _dealer_frames.has_animation(anim) else &"idle"
	var count: int = _dealer_frames.get_frame_count(name_value)
	if count <= 0:
		return null
	return _dealer_frames.get_frame_texture(name_value, int(_anim_time * fps) % count)


func _pose_of(anim: StringName, index: int) -> Texture2D:
	var name_value: StringName = anim if _dealer_frames.has_animation(anim) else &"idle"
	var count: int = _dealer_frames.get_frame_count(name_value)
	if count <= 0:
		return null
	return _dealer_frames.get_frame_texture(name_value, clampi(index, 0, count - 1))


## 눕혀 놓은 멍석. 위가 좁은 사다리꼴이라 위에서 비스듬히 내려다보는 자리가 된다
func _draw_mat() -> void:
	var corners: PackedVector2Array = PackedVector2Array(
		[
			Vector2(CENTER_X - MAT_TOP_HALF, MAT_TOP_Y),
			Vector2(CENTER_X + MAT_TOP_HALF, MAT_TOP_Y),
			Vector2(CENTER_X + MAT_BOTTOM_HALF, MAT_BOTTOM_Y),
			Vector2(CENTER_X - MAT_BOTTOM_HALF, MAT_BOTTOM_Y),
		]
	)
	draw_colored_polygon(corners, STRAW)
	_draw_mat_weave()
	var outline: PackedVector2Array = corners.duplicate()
	outline.append(corners[0])
	draw_polyline(outline, STRAW_EDGE, 1.0)


## 짚을 엮은 결. 가로줄만 몇 개 그어도 바닥이 평평하다고 읽힌다
func _draw_mat_weave() -> void:
	for i: int in range(1, 7):
		var t: float = float(i) / 7.0
		var y: float = lerpf(MAT_TOP_Y, MAT_BOTTOM_Y, t)
		var half: float = lerpf(MAT_TOP_HALF, MAT_BOTTOM_HALF, t) - 4.0
		draw_line(Vector2(CENTER_X - half, y), Vector2(CENTER_X + half, y), STRAW_DIM, 1.0)
		# 세로 톱니를 한 줄 걸러 엇갈리게 찍어 짚을 엮은 결로 읽히게 한다
		var offset: float = 0.0 if i % 2 == 0 else 7.0
		var x: float = CENTER_X - half + offset
		while x < CENTER_X + half:
			draw_rect(Rect2(x, y - 4.0, 1.0, 4.0), STRAW_DIM)
			x += 14.0


## 뒷벽과 바닥. 인물이 허공에 뜨지 않게 서는 자리를 깔아 준다
func _draw_room() -> void:
	draw_rect(Rect2(0.0, 0.0, size.x, FLOOR_LINE), WALL)
	draw_rect(Rect2(0.0, FLOOR_LINE, size.x, size.y - FLOOR_LINE), FLOOR)
	draw_line(Vector2(0.0, FLOOR_LINE), Vector2(size.x, FLOOR_LINE), Color(NIGHT, 0.8), 1.0)


## 멍석 옆 세간. 좌우 끝에 두어 판이 살림 한가운데라고 알린다
func _draw_clutter() -> void:
	if _mat == null:
		return
	var box_size: Vector2 = Vector2(_mat.get_size()) * CLUTTER_SCALE
	for at: Vector2 in CLUTTER_POS:
		draw_texture_rect(_mat, Rect2(at, box_size), false, Color(0.8, 0.8, 0.86))


## 판돈 더미. 걸린 엽전만큼 쌓아 올린다
func _draw_pot(amount: int) -> void:
	if amount <= 0:
		return
	var step: int = maxi(_table.bet_step, 1)
	var count: int = clampi(int(ceil(float(amount) / float(step))), 1, POT_MAX)
	for i: int in range(count):
		_draw_coin(POT_POS + Vector2(0.0, -float(i) * 2.0), LANTERN)


## 엽전 하나. 가운데 구멍까지 찍어야 엽전으로 읽힌다
func _draw_coin(center: Vector2, color: Color) -> void:
	draw_circle(center, 4.0, color)
	draw_arc(center, 4.0, 0.0, TAU, 12, PAPER_EDGE, 1.0)
	draw_rect(Rect2(center - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), PAPER_EDGE)


func _draw_coins() -> void:
	for coin: Dictionary in _coin_fx:
		var t: float = float(coin["t"])
		if t < 0.0:
			continue
		var u: float = clampf(t / COIN_FLY_TIME, 0.0, 1.0)
		var from: Vector2 = coin["from"]
		var to: Vector2 = coin["to"]
		var pos: Vector2 = from.lerp(to, u) - Vector2(0.0, sin(u * PI) * COIN_ARC)
		var color: Color = LANTERN if bool(coin["won"]) else NIGHT_DIM
		_draw_coin(pos.floor(), Color(color, 1.0 - u * 0.5))


# --- 멍석 위의 패와 주사위 ---


func _draw_table_props() -> void:
	_draw_pot(_bet)
	match _game:
		GamblingGames.Game.TUJEON:
			_draw_cards()
		GamblingGames.Game.GOLPAE:
			_draw_tiles()
		_:
			_draw_dice()


## 패가 미끄러져 나오는 진행도. 0이면 아직 노름꾼 손에 있고 1이면 자리에 놓였다
func _deal_ratio(order_index: int) -> float:
	var t: float = _reveal_t - float(order_index) * DEAL_STEP
	return clampf(t / DEAL_TIME, 0.0, 1.0)


## 패를 뒤집는 중의 가로 눌림. 0에 가까울수록 옆에서 본 모습이다
func _flip_squash(order_index: int) -> float:
	var t: float = _reveal_t - (FLIP_START + float(order_index) * FLIP_STEP)
	if t <= 0.0 or t >= FLIP_TIME:
		return 1.0
	return absf(1.0 - 2.0 * t / FLIP_TIME)


func _is_face_up(order_index: int) -> bool:
	return _reveal_t >= FLIP_START + float(order_index) * FLIP_STEP + FLIP_TIME * 0.5


## 그 자리의 지금 좌표. 노름꾼 손에서 자리까지 미끄러진다
func _prop_pos(order_index: int, slot: int, row_y: float, gap: float) -> Vector2:
	var target: Vector2 = Vector2(CENTER_X + (float(slot) - 0.5) * gap, row_y)
	var u: float = _deal_ratio(order_index)
	return DECK_POS.lerp(target, u * u * (3.0 - 2.0 * u))


func _draw_cards() -> void:
	var dealer: Array = _last.get("dealer_cards", [])
	var player: Array = _last.get("player_cards", [])
	if dealer.size() < 2 or player.size() < 2:
		return
	var ttaeng_dealer: bool = int(dealer[0]) == int(dealer[1])
	var ttaeng_player: bool = int(player[0]) == int(player[1])
	for i: int in range(2):
		var pos: Vector2 = _prop_pos(i, i, DEALER_ROW_Y, CARD_GAP)
		_draw_card(pos, int(dealer[i]), _is_face_up(i), _flip_squash(i), ttaeng_dealer)
	for i: int in range(2):
		var order: int = i + 2
		var pos: Vector2 = _prop_pos(order, i, PLAYER_ROW_Y, CARD_GAP)
		_draw_card(pos, int(player[i]), _is_face_up(order), _flip_squash(order), ttaeng_player)


## 투전 한 장. 뒤집기 전에는 뒷면을 보인다
func _draw_card(center: Vector2, number: int, face_up: bool, squash: float, ttaeng: bool) -> void:
	draw_set_transform(center.floor(), 0.0, Vector2(maxf(squash, 0.05), 1.0))
	var box: Rect2 = Rect2(-CARD_SIZE * 0.5, CARD_SIZE)
	if not face_up:
		draw_rect(box, NIGHT)
		draw_rect(box.grow(-3.0), Color(NIGHT_DIM, 0.7))
		draw_rect(Rect2(-3.0, -3.0, 6.0, 6.0), LANTERN)
		draw_rect(box, PAPER_EDGE, false, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	draw_rect(box, PAPER)
	draw_rect(box, PAPER_EDGE, false, 1.0)
	# 투전은 길쭉한 종이패다. 위아래 먹줄로 방향을 잡아 준다
	draw_rect(Rect2(-6.0, -11.0, 12.0, 1.0), PAPER_EDGE)
	draw_rect(Rect2(-6.0, 10.0, 12.0, 1.0), PAPER_EDGE)
	var ink: Color = LANTERN if ttaeng else PAPER_EDGE
	_draw_text_at(str(number), Vector2(0.0, 0.0), FONT_SIZE_BIG, ink)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_tiles() -> void:
	var dealer: Array = _last.get("dealer_tiles", [])
	var player: Array = _last.get("player_tiles", [])
	if dealer.size() < 2 or player.size() < 2:
		return
	for i: int in range(2):
		var pos: Vector2 = _prop_pos(i, i, DEALER_ROW_Y, TILE_GAP)
		_draw_tile(pos, dealer[i], _is_face_up(i), _flip_squash(i))
	for i: int in range(2):
		var order: int = i + 2
		var pos: Vector2 = _prop_pos(order, i, PLAYER_ROW_Y, TILE_GAP)
		_draw_tile(pos, player[i], _is_face_up(order), _flip_squash(order))


## 골패 한 장. 두 쪽으로 갈라 점을 찍는다
func _draw_tile(center: Vector2, pips: Vector2i, face_up: bool, squash: float) -> void:
	draw_set_transform(center.floor(), 0.0, Vector2(maxf(squash, 0.05), 1.0))
	var box: Rect2 = Rect2(-TILE_SIZE * 0.5, TILE_SIZE)
	if not face_up:
		draw_rect(box, NIGHT)
		draw_rect(box.grow(-3.0), Color(NIGHT_DIM, 0.7))
		draw_rect(box, PAPER_EDGE, false, 1.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	draw_rect(box, PAPER)
	draw_rect(box, PAPER_EDGE, false, 1.0)
	draw_rect(Rect2(-0.5, -TILE_SIZE.y * 0.5 + 2.0, 1.0, TILE_SIZE.y - 4.0), PAPER_EDGE)
	_draw_pips(Vector2(-TILE_SIZE.x * 0.25, 0.0), pips.x, 4.0)
	_draw_pips(Vector2(TILE_SIZE.x * 0.25, 0.0), pips.y, 4.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_dice() -> void:
	var dice: Array = _last.get("dice", [])
	if dice.size() < 2:
		return
	for i: int in range(2):
		var state: Dictionary = _die_state(i, int(dice[i]))
		_draw_die(state["pos"], int(state["face"]), float(state["angle"]))


## 주사위 하나의 지금 상태. 통을 흔들다가 멍석으로 굴러 나와 튀다가 멈춘다
func _die_state(index: int, final_face: int) -> Dictionary:
	var rest: Vector2 = Vector2(CENTER_X + (float(index) - 0.5) * DIE_GAP, 182.0)
	if _reveal_t < SHAKE_END:
		var shake: float = sin(_anim_time * 40.0 + float(index) * 2.0) * 3.0
		return {
			"pos": DECK_POS + Vector2(shake, float(index) * 5.0),
			"face": (int(_reveal_t * 30.0) + index) % 6 + 1,
			"angle": shake * 0.05,
		}
	if _reveal_t >= ROLL_END:
		return {"pos": rest, "face": final_face, "angle": 0.0}
	var u: float = (_reveal_t - SHAKE_END) / maxf(ROLL_END - SHAKE_END, 0.01)
	var eased: float = 1.0 - pow(1.0 - u, 3.0)
	var hop: float = absf(sin(u * PI * 3.0)) * DICE_HOP * (1.0 - u)
	return {
		"pos": DECK_POS.lerp(rest, eased) - Vector2(0.0, hop),
		"face": (int(_reveal_t * 26.0) + index * 3) % 6 + 1,
		"angle": (1.0 - u) * TAU * (1.0 + float(index) * 0.4),
	}


## 주사위 한 알.
func _draw_die(center: Vector2, face: int, angle: float) -> void:
	draw_set_transform(center.floor(), angle, Vector2.ONE)
	var box: Rect2 = Rect2(Vector2(-DIE_SIZE, -DIE_SIZE) * 0.5, Vector2(DIE_SIZE, DIE_SIZE))
	draw_rect(box, PAPER)
	draw_rect(box, PAPER_EDGE, false, 1.0)
	_draw_pips(Vector2.ZERO, face, 5.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 점 배치. 눈금 하나가 spread만큼 벌어진다
func _draw_pips(center: Vector2, count: int, spread: float) -> void:
	for offset: Vector2 in _pip_offsets(count):
		draw_circle(center + offset * spread, PIP_RADIUS, PAPER_EDGE)


## 눈 수에 따른 점 자리. 값은 -1에서 1 사이의 눈금이다
func _pip_offsets(count: int) -> Array[Vector2]:
	var spots: Array[Vector2] = []
	var value: int = clampi(count, 1, 6)
	if value % 2 == 1:
		spots.append(Vector2.ZERO)
	if value >= 2:
		spots.append(Vector2(-1.0, -1.0))
		spots.append(Vector2(1.0, 1.0))
	if value >= 4:
		spots.append(Vector2(1.0, -1.0))
		spots.append(Vector2(-1.0, 1.0))
	if value >= 6:
		spots.append(Vector2(-1.0, 0.0))
		spots.append(Vector2(1.0, 0.0))
	return spots


## 그 자리에 글자를 가운데 맞춰 그린다 (draw_set_transform 안에서도 쓴다).
func _draw_text_at(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var font: Font = body_font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var pos: Vector2 = center - Vector2(width * 0.5, -float(font_size) * 0.36)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


# --- HUD ---


func _draw_hud() -> void:
	_draw_header()
	match _phase:
		Phase.INTRO:
			_draw_intro()
		Phase.OFFER:
			_draw_offer()
		Phase.BET_KIND:
			_draw_bet_kind()
		Phase.BET_AMOUNT:
			_draw_bet_amount()
		Phase.REVEAL:
			_draw_reveal()


## 화면 위의 안내 띠. 등불 그림 위라 어두운 막을 깔고 글자를 얹는다
func _draw_header() -> void:
	draw_rect(Rect2(0.0, 0.0, size.x, 34.0), Color(BACKDROP, 0.82))
	draw_center(GamblingGames.game_name(_game), 16.0, FONT_SIZE_BIG, LANTERN)
	draw_center(String(RULE_HINTS.get(_game, "")), 30.0, FONT_SIZE, INK_DIM)
	_draw_text_at("엽전 %d닢" % _coins, Vector2(52.0, 12.0), FONT_SIZE, INK)
	_draw_text_at("%d/%d판" % [_round, _table.rounds], Vector2(428.0, 12.0), FONT_SIZE, INK)


func _draw_intro() -> void:
	draw_center("노름꾼이 자리를 내준다", 232.0, FONT_SIZE, INK)
	draw_center("오늘 판은 %s일세" % GamblingGames.game_name(_game), 246.0, FONT_SIZE, LANTERN)


func _draw_offer() -> void:
	for i: int in range(OFFER_LABELS.size()):
		var picked: bool = i == _cursor
		var text: String = ("> " if picked else "  ") + OFFER_LABELS[i]
		draw_center(text, 230.0 + float(i) * 16.0, FONT_SIZE, LANTERN if picked else INK_DIM)
	draw_center("위아래로 고르고 점프로 결정", 264.0, FONT_SIZE, INK_DIM)


func _draw_bet_kind() -> void:
	draw_center("어디에 거나", 224.0, FONT_SIZE, INK)
	var labels: Array[String] = ["소 2~6 %.1f배", "대 8~12 %.1f배", "쌍 같은 눈 %.1f배"]
	var mults: Array[float] = [_table.small_big_mult, _table.small_big_mult, _table.pair_mult]
	var font: Font = body_font()
	for i: int in range(labels.size()):
		var picked: bool = i == _bet_kind
		var text: String = labels[i] % mults[i]
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x
		var box: Rect2 = Rect2(56.0 + float(i) * 124.0, 230.0, 116.0, 16.0)
		draw_rect(box, Color(NIGHT, 0.55 if picked else 0.25))
		if picked:
			draw_rect(box, LANTERN, false, 1.0)
		var pos: Vector2 = Vector2(box.position.x + box.size.x * 0.5 - width * 0.5, 242.0)
		draw_string(
			font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, INK if picked else INK_DIM
		)
	draw_center("합이 7이면 하우스가 가져간다", 256.0, FONT_SIZE, NIGHT_DIM)
	draw_center("좌우로 고르고 점프로 결정", 267.0, FONT_SIZE, INK_DIM)


func _draw_bet_amount() -> void:
	if _game == GamblingGames.Game.SSANGRYUK:
		draw_center("%s에 건다" % GamblingGames.bet_name(_bet_kind), 228.0, FONT_SIZE, INK_DIM)
	draw_center("%d닢" % _bet, 250.0, FONT_SIZE_BIG, LANTERN)
	draw_center("좌우로 조절, 점프로 건다, 아래로 자리를 뜬다", 265.0, FONT_SIZE, INK_DIM)


## 결과 문구는 패가 다 열린 뒤에만 붙는다. 그 전에는 장면만 보인다
func _draw_reveal() -> void:
	if not _verdict_shown:
		draw_center(_reveal_caption(), 246.0, FONT_SIZE, INK_DIM)
		return
	var outcome: int = int(_last.get("outcome", GamblingGames.Outcome.DEALER))
	var delta_coins: int = int(_last.get("coins_delta", 0))
	var verdict: String = "비겼다"
	var color: Color = INK_DIM
	if outcome == GamblingGames.Outcome.PLAYER:
		verdict = "이겼다"
		color = LANTERN
	elif outcome == GamblingGames.Outcome.DEALER:
		verdict = "졌다"
		color = NIGHT_DIM
	draw_center(verdict, 232.0, FONT_SIZE_BIG, color)
	draw_center("엽전 %+d닢" % delta_coins, 246.0, FONT_SIZE, color)
	draw_center(_hand_summary(), 258.0, FONT_SIZE, INK_DIM)
	draw_center("점프로 넘긴다", 268.0, FONT_SIZE, INK_DIM)


## 패를 여는 동안의 한 줄 안내.
func _reveal_caption() -> String:
	if _game == GamblingGames.Game.SSANGRYUK:
		return "주사위통을 흔든다" if _reveal_t < SHAKE_END else "주사위가 구른다"
	return "패를 돌린다" if _reveal_t < FLIP_START else "패를 뒤집는다"


## 양쪽 패를 한 줄로 요약한다.
func _hand_summary() -> String:
	var mine: String = String(_last.get("player_text", ""))
	var theirs: String = String(_last.get("dealer_text", ""))
	return "나 %s   노름꾼 %s" % [mine, theirs]
