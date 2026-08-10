class_name SsireumMinigame
extends Minigame

## 씨름 연타 대결 (docs/act1/EVENTS.md 5장 N5, 2026-08-06 연출 추가).
##
## 흐름 (사용자 지정 2026-08-06)
## 1. 씨름판이 화면을 채우고 한가운데 도깨비가 선다. 귀신과 도깨비 관중이 판을 둘러싼다
## 2. 씨름판에 들어갈지 지나갈지 고른다
## 3. 들어가면 플레이어가 판에 올라 도깨비와 샅바를 잡는다
## 4. 3 2 1 시작
## 5. 샅바를 잡은 채 좌우로 밀린다. 밀리는 방향은 씨름 게이지를 따라간다
## 6. 이기면 플레이어가, 지면 도깨비가 승리 포즈를 잡고 보상 또는 벌칙이 붙는다
##
## 조작: 방향(A S D W 또는 방향키) 하나가 뜨면 아래 노란 연타 게이지가 다 줄 때까지
## 그 방향을 연타한다. 다 줄면 다음 방향이 뜬다. 같은 방향이 다시 나올 수 있다.
## 판정 규칙은 scripts/systems/ssireum_duel.gd에 있고 이 씬은 표시와 입력만 맡는다.
##
## 그리기는 전부 _draw에서 한다. 관중 뒤, 씨름판, 선수, 관중 앞, HUD 순으로 겹쳐야 해서
## 자식 노드 대신 그리기 순서를 직접 잡았다.

enum Phase { SHOW, OFFER, SETUP, COUNT, DUEL, RESULT }

## 상대 풀 (docs/CONVENTIONS.md 데이터. 수치는 전부 .tres에 있다)
const OPPONENT_PATHS: Array[String] = [
	"res://resources/minigames/ssireum/ssireum_scrawny.tres",
	"res://resources/minigames/ssireum/ssireum_stout.tres",
	"res://resources/minigames/ssireum/ssireum_bull.tres",
]
const PLAYER_FRAMES_PATH: String = "res://scenes/player/player_frames.tres"
## 상대가 자기 조형을 지정하지 않았을 때 쓰는 임시 조형.
## 씨름꾼(dokkaebi_wrestler)은 아직 스프라이트가 없어 잡도깨비로 대신한다
## (docs/act1/ENEMIES.md 5.4, art_src/requests/018_act1_enemy_mobs.md 4번)
const FALLBACK_FRAMES_PATH: String = "res://scenes/enemies/dokkaebi_frames.tres"
const RING_PATH: String = "res://assets/sprites/bg/act1/bg_ssireum_ring.png"

## 판 건너편 관중 (이쪽을 본다). 귀신, 도깨비, 아이, 고양이
const CROWD_FAR: Array[String] = [
	"res://assets/sprites/bg/act1/crowd/crowd_a.png",
	"res://assets/sprites/bg/act1/crowd/crowd_b.png",
	"res://assets/sprites/bg/act1/crowd/crowd_c.png",
	"res://assets/sprites/bg/act1/crowd/crowd_cheer_a.png",
	"res://assets/sprites/bg/act1/crowd/crowd_e.png",
	"res://assets/sprites/bg/act1/crowd/crowd_cheer_b.png",
	"res://assets/sprites/bg/act1/crowd/crowd_f.png",
	"res://assets/sprites/bg/act1/crowd/crowd_g.png",
	"res://assets/sprites/bg/act1/crowd/crowd_child.png",
	"res://assets/sprites/bg/act1/crowd/crowd_h.png",
	"res://assets/sprites/bg/act1/crowd/crowd_cat.png",
]
## 이쪽 관중 (등을 보인다). 화면 아래 양 끝에만 둔다
const CROWD_NEAR: Array[String] = [
	"res://assets/sprites/bg/act1/crowd/crowd_back_a.png",
	"res://assets/sprites/bg/act1/crowd/crowd_back_b.png",
	"res://assets/sprites/bg/act1/crowd/crowd_back_c.png",
	"res://assets/sprites/bg/act1/crowd/crowd_back_d.png",
	"res://assets/sprites/bg/act1/crowd/crowd_back_e.png",
]

## 대결 시드를 방 시드와 갈라놓는 교란값
const SEED_SALT: int = 1013904223
const SEED_MASK: int = 0x7FFFFFFF

## 씨름판 배율 (원본 111x25 -> 444x100). 정수배라 픽셀이 뭉개지지 않는다.
## 화면 폭 480 중 444를 채워 판이 화면을 한가득 차지한다
const RING_SCALE: float = 4.0
## 씨름판 왼쪽 위 모서리
const RING_TOP_LEFT: Vector2 = Vector2(18.0, 118.0)
## 선수가 서는 바닥선 (판의 평평한 윗면 앞쪽)
const FLOOR_Y: float = 186.0
## 판 한가운데 가로 좌표
const CENTER_X: float = 240.0
## 두 선수 사이 반거리
const GRIP_HALF: float = 19.0
## 씨름 게이지에 따라 두 선수가 함께 밀리는 최대 폭
const PUSH_SWAY: float = 44.0
## 플레이어가 판 밖에서 기다리는 자리
const WAIT_X: float = 92.0

## 스프라이트 캔버스(76x76) 안에서 캐릭터의 가로 중심과 발밑 위치
const ART_CENTER: Vector2 = Vector2(40.0, 57.0)
## 선수를 키우는 배율. 판 위의 둘이 화면의 주인공으로 읽혀야 한다
const ACTOR_SCALE: float = 1.5
## 큰 도깨비를 한 번 더 키우는 배율. 한눈에 크다고 읽혀야 한다
const BIG_SCALE: float = 2.0
## 승부가 난 뒤 진 쪽이 판 가장자리로 밀려나는 거리
const RESULT_PUSH: float = 54.0
## 승부가 난 뒤 이긴 쪽이 가운데에서 비켜서는 거리
const RESULT_HOLD: float = 14.0

## 건너편 관중이 서는 바닥선. 판보다 뒤라 발밑이 판에 가린다
const CROWD_FAR_Y: float = 128.0
## 이쪽 관중이 서는 바닥선. 화면 아래 양 끝에만 둔다
const CROWD_NEAR_Y: float = 270.0

## 씨름 게이지 막대 (줄다리기)
const GAUGE_BOX: Rect2 = Rect2(96, 20, 288, 10)
## 연타 게이지 막대. 노란색으로 채우고 연타할수록 줄어든다
const MASH_BOX: Rect2 = Rect2(168, 246, 144, 7)
## 맞거나 틀렸을 때 번쩍이는 시간 (초)
const FLASH_TIME: float = 0.12
## 남은 대결 시간을 알리기 시작하는 시점 (초)
const WARN_TIME: float = 8.0
const OFFER_LABELS: Array[String] = ["씨름판에 들어간다", "지나간다"]

## 씨름판이 눈에 들어오는 시간 (초). 대사량은 최소로 둔다 (Dead Cells 상한, GDD 2장)
@export var show_time: float = 1.2
## 판에 올라 샅바를 잡는 시간 (초)
@export var setup_time: float = 0.9
## 구호 한 마디의 길이 (초). 3 2 1 시작 네 마디다
@export var count_step: float = 0.6
## 결과 표시 시간 (초)
@export var result_time: float = 2.2

var _phase: int = Phase.SHOW
var _timer: float = 0.0
var _anim_time: float = 0.0
var _cursor: int = 0
var _duel: SsireumDuel = null
var _opponent: SsireumOpponent = null
var _flash: float = 0.0
var _flash_good: bool = false
var _result: Dictionary = {}
var _player_frames: SpriteFrames = null
var _dokkaebi_frames: SpriteFrames = null
var _ring: Texture2D = null
var _crowd: Array[Dictionary] = []


func begin(config: Dictionary) -> void:
	var seed_value: int = int(config.get("seed", 0))
	_opponent = _pick_opponent(seed_value)
	if _opponent == null:
		report(empty_result("씨름 상대가 없다"))
		return
	_duel = SsireumDuel.new(_opponent, (seed_value + SEED_SALT) & SEED_MASK)
	_load_art()
	_build_crowd(seed_value)
	_phase = Phase.SHOW
	_timer = show_time
	set_process(true)
	set_process_input(true)
	queue_redraw()


func _process(delta: float) -> void:
	_anim_time += delta
	_flash = maxf(_flash - delta, 0.0)
	match _phase:
		Phase.SHOW:
			_advance_timer(delta, Phase.OFFER)
		Phase.SETUP:
			_advance_timer(delta, Phase.COUNT, count_step * 4.0)
		Phase.COUNT:
			_advance_timer(delta, Phase.DUEL)
		Phase.DUEL:
			_duel.advance(delta)
			if _duel.is_over():
				_finish_duel()
		Phase.RESULT:
			_timer -= delta
			if _timer <= 0.0:
				report(_result)
	queue_redraw()


## 단계 타이머를 흘리고 다 되면 다음 단계로 넘긴다.
func _advance_timer(delta: float, next_phase: int, next_timer: float = 0.0) -> void:
	_timer -= delta
	if _timer > 0.0:
		return
	_phase = next_phase
	_timer = next_timer


func _input(event: InputEvent) -> void:
	if _phase == Phase.OFFER:
		_input_offer(event)
		return
	if _phase != Phase.DUEL:
		return
	var direction: int = SsireumDuel.direction_of(event)
	if direction < 0:
		return
	get_viewport().set_input_as_handled()
	_flash_good = _duel.press(direction)
	_flash = FLASH_TIME


func _input_offer(event: InputEvent) -> void:
	var step: int = 0
	if event.is_action_pressed(&"move_down") or event.is_action_pressed(&"ui_down"):
		step = 1
	elif event.is_action_pressed(&"move_up") or event.is_action_pressed(&"ui_up"):
		step = -1
	if step != 0:
		get_viewport().set_input_as_handled()
		_cursor = (_cursor + step + OFFER_LABELS.size()) % OFFER_LABELS.size()
		return
	if not (event.is_action_pressed(&"jump") or event.is_action_pressed(&"ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if _cursor == 1:
		_skip()
		return
	_phase = Phase.SETUP
	_timer = setup_time


## 판에 오르지 않고 지나간다. 얻는 것도 잃는 것도 없다
func _skip() -> void:
	_phase = Phase.RESULT
	_timer = 0.0
	var result: Dictionary = empty_result("도깨비 씨름")
	result["losses"] = PackedStringArray(["씨름판을 지나쳤다"])
	report(result)


func _load_art() -> void:
	_player_frames = load(PLAYER_FRAMES_PATH) as SpriteFrames
	_dokkaebi_frames = _load_frames(_opponent.frames_path)
	if ResourceLoader.exists(RING_PATH):
		_ring = load(RING_PATH)


## 상대 조형을 읽는다. 지정이 없거나 읽지 못하면 임시 조형으로 물러선다.
func _load_frames(path: String) -> SpriteFrames:
	if not path.is_empty() and ResourceLoader.exists(path):
		var frames: SpriteFrames = load(path) as SpriteFrames
		if frames != null:
			return frames
	return load(FALLBACK_FRAMES_PATH) as SpriteFrames


## 관중을 시드로 흩는다. 건너편은 이쪽을 보고, 이쪽 관중은 화면 아래 양 끝에서 등을 보인다.
func _build_crowd(seed_value: int) -> void:
	_crowd.clear()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for i: int in range(11):
		var x: float = 40.0 + float(i) * 40.0 + rng.randf_range(-6.0, 6.0)
		_add_crowd(CROWD_FAR[i % CROWD_FAR.size()], x, CROWD_FAR_Y, rng)
	for i: int in range(3):
		_add_crowd(CROWD_NEAR[i % CROWD_NEAR.size()], 24.0 + float(i) * 34.0, CROWD_NEAR_Y, rng)
	for i: int in range(3):
		var path: String = CROWD_NEAR[(i + 2) % CROWD_NEAR.size()]
		_add_crowd(path, 392.0 + float(i) * 34.0, CROWD_NEAR_Y, rng)


func _add_crowd(path: String, x: float, feet_y: float, rng: RandomNumberGenerator) -> void:
	if not ResourceLoader.exists(path):
		return
	_crowd.append(
		{
			"tex": load(path) as Texture2D,
			"x": x,
			"y": feet_y,
			"phase": rng.randf_range(0.0, TAU),
			"speed": rng.randf_range(2.2, 3.4),
		}
	)


## 가중치로 상대를 뽑는다. 큰 도깨비의 가중치가 낮아 드물게 나온다.
func _pick_opponent(seed_value: int) -> SsireumOpponent:
	var pool: Array[SsireumOpponent] = []
	var total: float = 0.0
	for path: String in OPPONENT_PATHS:
		var opponent: SsireumOpponent = load(path) as SsireumOpponent
		if opponent == null:
			push_warning("씨름 상대를 읽지 못했다: %s" % path)
			continue
		pool.append(opponent)
		total += maxf(opponent.weight, 0.0)
	if pool.is_empty():
		return null
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var roll: float = rng.randf() * total
	for opponent: SsireumOpponent in pool:
		roll -= maxf(opponent.weight, 0.0)
		if roll <= 0.0:
			return opponent
	return pool[pool.size() - 1]


func _finish_duel() -> void:
	_phase = Phase.RESULT
	_timer = result_time
	_result = empty_result("도깨비 씨름")
	if _duel.player_won():
		_result["won"] = true
		_result["coins_delta"] = _opponent.win_coins
		_result["relic_chance"] = _opponent.win_relic_chance
		_result["gains"] = PackedStringArray(
			["엽전 %d닢" % _opponent.win_coins, "정체는 %s였다" % _opponent.true_form]
		)
	else:
		_result["damage"] = _opponent.lose_damage
		_result["losses"] = PackedStringArray(
			["체력 %d" % _opponent.lose_damage, "판을 내주고 길을 비켰다"]
		)


# --- 그리기 ---


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP)
	_draw_crowd(CROWD_FAR_Y)
	_draw_ring()
	_draw_actors()
	_draw_crowd(CROWD_NEAR_Y)
	_draw_hud()


func _draw_ring() -> void:
	if _ring == null:
		var fallback: Rect2 = Rect2(RING_TOP_LEFT, Vector2(444.0, 100.0))
		draw_rect(fallback, Color(NIGHT, 0.6))
		return
	var box: Rect2 = Rect2(RING_TOP_LEFT, Vector2(_ring.get_size()) * RING_SCALE)
	draw_texture_rect(_ring, box, false)


## 관중. 응원하듯 천천히 아래위로 흔들린다
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


## 단계별로 두 선수의 자리와 기울임을 잡는다.
## 대결 중에는 씨름 게이지를 따라 둘이 함께 밀리고, 승부가 나면 진 쪽이 밀려난다.
func _draw_actors() -> void:
	var player_x: float = CENTER_X - GRIP_HALF
	var dokkaebi_x: float = CENTER_X + GRIP_HALF
	var lean: float = 0.0
	match _phase:
		Phase.SHOW, Phase.OFFER:
			player_x = WAIT_X
			dokkaebi_x = CENTER_X
		Phase.SETUP:
			player_x = lerpf(WAIT_X, CENTER_X - GRIP_HALF, _setup_ratio())
			dokkaebi_x = CENTER_X + GRIP_HALF * _setup_ratio()
		Phase.DUEL:
			var sway: float = (_duel.progress() - 0.5) * PUSH_SWAY
			player_x += sway
			dokkaebi_x += sway
			lean = 0.16
		Phase.RESULT:
			var won: bool = bool(_result.get("won", false))
			player_x = CENTER_X - (RESULT_HOLD if won else RESULT_PUSH)
			dokkaebi_x = CENTER_X + (RESULT_PUSH if won else RESULT_HOLD)
	if _gripping():
		_draw_satba(player_x, dokkaebi_x)
	_draw_actor(_player_texture(), player_x, false, lean)
	_draw_actor(_dokkaebi_texture(), dokkaebi_x, true, -lean)


## 샅바. 두 선수 허리춤을 잇는다. 색 채널을 지켜 등불 호박과 남색을 쓴다 (적색 금지)
func _draw_satba(player_x: float, dokkaebi_x: float) -> void:
	var left: float = minf(player_x, dokkaebi_x) + 4.0
	var right: float = maxf(player_x, dokkaebi_x) - 4.0
	var y: float = FLOOR_Y - 26.0
	draw_rect(Rect2(left, y, right - left, 3.0), LANTERN)
	draw_rect(Rect2(left, y + 3.0, right - left, 2.0), NIGHT)


## 캐릭터 한 명. 발밑이 판 바닥선에 오고 가로 중심이 center_x에 오게 그린다.
## 기울임은 발밑을 축으로 돈다. 큰 도깨비는 배율을 키운다.
func _draw_actor(tex: Texture2D, center_x: float, flip: bool, lean: float) -> void:
	if tex == null:
		return
	var scale_mul: float = ACTOR_SCALE
	if flip and _opponent.is_big:
		scale_mul = BIG_SCALE
	var flip_sign: float = -1.0 if flip else 1.0
	draw_set_transform(
		Vector2(center_x, FLOOR_Y), lean * flip_sign, Vector2(flip_sign * scale_mul, scale_mul)
	)
	draw_texture(tex, -ART_CENTER)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _setup_ratio() -> float:
	return clampf(1.0 - _timer / maxf(setup_time, 0.01), 0.0, 1.0)


## 샅바를 잡고 있는 단계인지.
func _gripping() -> bool:
	return _phase == Phase.COUNT or _phase == Phase.DUEL


func _player_texture() -> Texture2D:
	if _player_frames == null:
		return null
	if _phase == Phase.SETUP:
		return _frame_of(_player_frames, &"run", 12.0)
	if _phase == Phase.RESULT:
		# 이기면 두 팔을 든 도약 자세, 지면 웅크린 자세로 멈춘다
		var won: bool = bool(_result.get("won", false))
		if won:
			return _pose_of(_player_frames, &"jump", 1)
		return _pose_of(_player_frames, &"hurt", 4)
	if _phase == Phase.DUEL:
		return _frame_of(_player_frames, &"idle", 10.0)
	return _frame_of(_player_frames, &"idle", 6.0)


func _dokkaebi_texture() -> Texture2D:
	if _dokkaebi_frames == null:
		return null
	if _phase == Phase.RESULT:
		# 이기면 도깨비가 나뒹굴고, 지면 폴짝거리며 이겼다고 뽐낸다
		var won: bool = bool(_result.get("won", false))
		if won:
			return _pose_of(_dokkaebi_frames, &"hurt", 7)
		return _frame_of(_dokkaebi_frames, &"hop", 8.0)
	if _phase == Phase.DUEL:
		return _frame_of(_dokkaebi_frames, &"idle", 10.0)
	return _frame_of(_dokkaebi_frames, &"hop", 6.0)


## 그 애니메이션의 지금 프레임. 없는 이름이면 idle로 물러선다
func _frame_of(frames: SpriteFrames, anim: StringName, fps: float) -> Texture2D:
	var name_value: StringName = anim if frames.has_animation(anim) else &"idle"
	var count: int = frames.get_frame_count(name_value)
	if count <= 0:
		return null
	return frames.get_frame_texture(name_value, int(_anim_time * fps) % count)


## 그 애니메이션의 지정 프레임 하나. 승리와 패배 포즈처럼 멈춘 그림에 쓴다.
func _pose_of(frames: SpriteFrames, anim: StringName, index: int) -> Texture2D:
	var name_value: StringName = anim if frames.has_animation(anim) else &"idle"
	var count: int = frames.get_frame_count(name_value)
	if count <= 0:
		return null
	return frames.get_frame_texture(name_value, clampi(index, 0, count - 1))


# --- HUD ---


func _draw_hud() -> void:
	match _phase:
		Phase.SHOW:
			_draw_intro_text()
		Phase.OFFER:
			_draw_offer()
		Phase.COUNT:
			_draw_count()
		Phase.DUEL:
			_draw_duel_hud()
		Phase.RESULT:
			_draw_result()


func _draw_intro_text() -> void:
	var who: String = _opponent.display_name
	if _opponent.is_big:
		who = "%s  (큰 도깨비)" % who
	draw_center("판이 열렸다", 232.0, FONT_SIZE, INK_DIM)
	draw_center(who, 250.0, FONT_SIZE, LANTERN if not _opponent.is_big else NIGHT_DIM)


func _draw_offer() -> void:
	draw_center("%s이 씨름을 건다" % _opponent.display_name, 214.0, FONT_SIZE, INK)
	for i: int in range(OFFER_LABELS.size()):
		var picked: bool = i == _cursor
		var text: String = ("> " if picked else "  ") + OFFER_LABELS[i]
		draw_center(text, 232.0 + float(i) * 15.0, FONT_SIZE, LANTERN if picked else INK_DIM)
	draw_center("위아래로 고르고 점프로 결정", 265.0, FONT_SIZE, INK_DIM)


## 3 2 1 시작. 한 마디씩 커졌다 사라진다
func _draw_count() -> void:
	var step: int = 3 - int(_timer / maxf(count_step, 0.01))
	var words: Array[String] = ["3", "2", "1", "시작"]
	var word: String = words[clampi(step, 0, words.size() - 1)]
	# 판 위쪽에 띄운다. 샅바를 잡은 두 선수를 가리지 않는다
	draw_center(word, 110.0, FONT_SIZE_BIG, LANTERN)


func _draw_duel_hud() -> void:
	_draw_gauge()
	_draw_prompt()
	draw_center("노란 게이지가 다 줄 때까지 연타하라", 265.0, FONT_SIZE, INK_DIM)


## 줄다리기 막대. 매듭이 오른쪽 끝에 닿으면 이기고 왼쪽 끝에 닿으면 진다.
func _draw_gauge() -> void:
	draw_meter(GAUGE_BOX, _duel.progress(), LANTERN, NIGHT)
	var knot_x: float = GAUGE_BOX.position.x + GAUGE_BOX.size.x * _duel.progress()
	draw_rect(Rect2(knot_x - 1.0, GAUGE_BOX.position.y - 3.0, 2.0, GAUGE_BOX.size.y + 6.0), INK)
	var tally: String = "%d번 맞음   %d번 헛손질" % [_duel.hits, _duel.misses]
	draw_center(tally, 44.0, FONT_SIZE, INK_DIM)
	# 제한 시간은 늘어짐 방지 장치라 막판에만 알린다. 일찍 보이면 없던 압박이 생긴다
	if _duel.time_left() < WARN_TIME:
		draw_center("남은 시간 %d" % int(ceil(_duel.time_left())), 58.0, FONT_SIZE, NIGHT_DIM)


## 지금 눌러야 하는 방향과 노란 연타 게이지.
## 게이지가 다 줄면 다음 방향이 뜬다 (같은 방향이 다시 나올 수 있다).
func _draw_prompt() -> void:
	var color: Color = INK
	if _flash > 0.0:
		color = LANTERN if _flash_good else NIGHT_DIM
	draw_center(SsireumDuel.key_label(_duel.prompt), 240.0, FONT_SIZE_BIG, color)
	draw_meter(MASH_BOX, _duel.mash_ratio(), LANTERN, NIGHT)


func _draw_result() -> void:
	var won: bool = bool(_result.get("won", false))
	draw_center("이겼다" if won else "졌다", 234.0, FONT_SIZE_BIG, LANTERN if won else NIGHT_DIM)
	var line_y: float = 252.0
	for text: String in _result.get("gains", PackedStringArray()):
		draw_center(text, line_y, FONT_SIZE, LANTERN)
		line_y += 13.0
	for text: String in _result.get("losses", PackedStringArray()):
		draw_center(text, line_y, FONT_SIZE, NIGHT_DIM)
		line_y += 13.0
