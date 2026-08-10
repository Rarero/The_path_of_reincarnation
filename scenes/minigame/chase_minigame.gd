class_name ChaseMinigame
extends Minigame

## 장물아비 추격 달리기 (docs/act1/EVENTS.md 부록 A, 2026-08-07 전용 조형과 속도 상향).
##
## 진입하면 장물아비들이 소지 엽전을 낚아채 달아난다. 탑뷰 5레인 달리기로 쫓아가
## 한 마리씩 따라잡는다. 장애물에 세 번 부딪히면 남은 개체를 놓친 채 끝난다.
## 소지 엽전이 문턱에 못 미치면 장물아비가 비웃고 물러나며 방은 일반 전투로 넘어간다
## (2026-07-25 결정 유지. 0 경험값을 만들지 않는다).
##
## 화면은 밤 저잣거리 골목이다. 인물은 뒷모습 전용 조형을 쓰고 장애물은 위에서 내려다본
## 전용 조형을 쓴다 (요청서 026). 조형이 아직 없으면 옛 경로로 물러선다.
## 바닥 눈금과 좌판과 속도선이 아래로 흘러 달리는 속도를 알리고, 장물아비 등의 보따리는
## 난색으로 찍어 우선 포착 신호를 준다 (부록 A.6).
##
## 달리기 규칙은 scripts/systems/chase_run.gd, 속도와 밀도표는 ChaseTrack 리소스에 있고
## 이 씬은 표시와 입력만 맡는다.

enum Phase { INTRO, TAUNT, RUN, RESULT }

const SEED_SALT: int = 1103515245
const SEED_MASK: int = 0x7FFFFFFF
const TRACK_PATH: String = "res://resources/minigames/chase_track_act1.tres"

## 추격 전용 뒷모습 조형 (요청서 026). 폴백과 경로가 다르면 뒷모습 배치로 그린다
const PLAYER_BACK_PATH: String = "res://scenes/player/player_back_frames.tres"
const PLAYER_FALLBACK_PATH: String = "res://scenes/player/player_frames.tres"
const THIEF_BACK_PATH: String = "res://scenes/enemies/fence_back_frames.tres"
const THIEF_FALLBACK_PATH: String = "res://scenes/enemies/dokkaebi_frames.tres"
## 골목에 놓이는 장애물 조형 (위에서 내려다본 전용 조형)
const OBSTACLE_PATHS: Array[String] = [
	"res://assets/sprites/props/chase_crate.png",
	"res://assets/sprites/props/chase_jars.png",
	"res://assets/sprites/props/chase_cart.png",
]
const OBSTACLE_FALLBACK_PATHS: Array[String] = [
	"res://assets/sprites/bosses/muneolgul_crate_01.png",
	"res://assets/sprites/bosses/muneolgul_crate_02.png",
	"res://assets/sprites/bosses/muneolgul_rock_01.png",
]
## 골목 양옆에 늘어선 좌판
const SIDE_PATHS: Array[String] = [
	"res://assets/sprites/bg/act1/bg_stall_mid_a.png",
	"res://assets/sprites/bg/act1/bg_stall_mid_b.png",
	"res://assets/sprites/bg/act1/bg_stall_mid_c.png",
	"res://assets/sprites/bg/act1/bg_stall_fruit.png",
]

# --- 배치 ---

## 첫 레인의 화면 가로 위치와 레인 간격 (px)
const LANE_X0: float = 144.0
const LANE_GAP: float = 48.0
## 플레이어가 서는 화면 세로 위치
const PLAYER_Y: float = 220.0
## 논리 거리를 화면 세로로 줄이는 배율
const DEPTH_SCALE: float = 0.85
## 화면 위쪽에서 더 올라가지 않게 막는 선
const TOP_CLAMP: float = 26.0
## 골목 바닥의 좌우 끝
const ROAD_LEFT: float = 118.0
const ROAD_RIGHT: float = 362.0
## 스프라이트 캔버스(76x76) 안에서 캐릭터의 가로 중심과 발밑 위치
const ART_CENTER: Vector2 = Vector2(40.0, 57.0)
## 화면 맨 위와 맨 아래에서의 조형 배율 (멀수록 작다)
const FAR_SCALE: float = 0.52
const NEAR_SCALE: float = 1.0
## 플레이어 조형 배율
const PLAYER_SCALE: float = 0.9
## 최소 강탈액. 비율로 계산한 값이 이보다 작으면 이 값을 쓴다
const STEAL_FLOOR: int = 20

# --- 연출 ---

## 바닥 눈금 한 칸의 간격과 좌판 한 벌의 간격 (px)
const DASH_SPAN: float = 40.0
const SIDE_SPAN: float = 96.0
## 좌판이 서는 좌우 위치
const SIDE_X: Array[float] = [86.0, 394.0]
## 속도선 개수와 한 벌의 세로 간격, 흐르는 배속
const RUSH_COUNT: int = 16
const RUSH_SPAN: float = 76.0
const RUSH_MULT: float = 1.9
## 부딪혔을 때 화면이 물드는 시간과 플레이어가 밀리는 거리
const HIT_FLASH: float = 0.3
const HIT_RECOIL: float = 10.0
## 부딪혔을 때 화면이 흔들리는 폭과 잦기
const SHAKE_POWER: float = 5.0
const SHAKE_RATE: float = 46.0
## 흙먼지 한 점의 수명 (초)
const DUST_LIFE: float = 0.5
## 잡았을 때 뜨는 문구가 올라가는 시간 (초)
const POP_LIFE: float = 0.8
## 잡았을 때 튀는 엽전 수와 나는 시간
const COIN_COUNT: int = 7
const COIN_FLY_TIME: float = 0.6
## 레인을 옮길 때 몸이 따라오는 속도 (칸/초)
const LANE_FOLLOW: float = 16.0
## 레인을 옮기는 동안 몸이 기우는 각도 (라디안)
const LANE_LEAN: float = 0.18

## 도입 연출 시간 (초)
@export var intro_time: float = 1.6
## 비웃고 물러나는 연출 시간 (초)
@export var taunt_time: float = 1.8
## 결과 표시 시간 (초)
@export var result_time: float = 2.2

var _phase: int = Phase.INTRO
var _timer: float = 0.0
var _anim_time: float = 0.0
var _run: ChaseRun = null
var _stolen: int = 0
var _return_bonus: float = 1.2
var _result: Dictionary = {}

var _player_frames: SpriteFrames = null
var _thief_frames: SpriteFrames = null
var _player_back: bool = false
var _thief_back: bool = false
var _obstacle_tex: Array[Texture2D] = []
var _side_props: Array[Dictionary] = []
var _scroll: float = 0.0
var _lane_visual: float = 2.0
var _hit_flash: float = 0.0
var _hits_seen: int = 0
var _caught_seen: int = 0
var _dust: Array[Dictionary] = []
var _pops: Array[Dictionary] = []
var _coin_fx: Array[Dictionary] = []


func begin(config: Dictionary) -> void:
	var params: Dictionary = config.get("params", {})
	var coins: int = int(config.get("coins", 0))
	var threshold: int = int(params.get("min_coins_trigger", 0))
	_return_bonus = float(params.get("return_bonus_mult", 1.2))
	_load_art()
	_build_side_props(int(config.get("seed", 0)))
	set_process(true)
	set_process_input(true)
	if coins < threshold or coins < STEAL_FLOOR:
		_begin_taunt()
		return
	_begin_chase(config, params, coins)


func _load_art() -> void:
	_player_back = PLAYER_BACK_PATH != PLAYER_FALLBACK_PATH
	_player_frames = _load_frames(PLAYER_BACK_PATH if _player_back else PLAYER_FALLBACK_PATH)
	_thief_back = THIEF_BACK_PATH != THIEF_FALLBACK_PATH
	_thief_frames = _load_frames(THIEF_BACK_PATH if _thief_back else THIEF_FALLBACK_PATH)
	_obstacle_tex.clear()
	for i: int in range(OBSTACLE_PATHS.size()):
		var path: String = OBSTACLE_PATHS[i]
		if not ResourceLoader.exists(path):
			path = OBSTACLE_FALLBACK_PATHS[i]
		if ResourceLoader.exists(path):
			_obstacle_tex.append(load(path) as Texture2D)


func _load_frames(path: String) -> SpriteFrames:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as SpriteFrames


## 골목 양옆 좌판을 시드로 늘어놓는다. 아래로 흘러 달리는 속도를 알린다
func _build_side_props(seed_value: int) -> void:
	_side_props.clear()
	if SIDE_PATHS.is_empty():
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	for i: int in range(6):
		var path: String = SIDE_PATHS[rng.randi_range(0, SIDE_PATHS.size() - 1)]
		if not ResourceLoader.exists(path):
			continue
		_side_props.append(
			{
				"tex": load(path) as Texture2D,
				"x": SIDE_X[i % SIDE_X.size()],
				"base": float(i) * (SIDE_SPAN * 0.5) + rng.randf_range(-8.0, 8.0),
			}
		)


# --- 진행 ---


func _process(delta: float) -> void:
	_anim_time += delta
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_advance_fx(delta)
	match _phase:
		Phase.INTRO:
			_scroll += 120.0 * delta
			_timer -= delta
			if _timer <= 0.0:
				_phase = Phase.RUN
		Phase.TAUNT:
			_timer -= delta
			if _timer <= 0.0:
				report(_result)
		Phase.RUN:
			_scroll += _run.scroll_speed() * delta
			_lane_visual = _follow_lane(delta)
			_run.advance(delta)
			_watch_events()
			if _run.is_over():
				_finish_run()
		Phase.RESULT:
			_timer -= delta
			if _timer <= 0.0:
				report(_result)
	queue_redraw()


## 몸이 레인을 따라잡는다. 바로 순간이동하면 옮긴 티가 안 난다
func _follow_lane(delta: float) -> float:
	var target: float = float(_run.player_lane)
	return _lane_visual + (target - _lane_visual) * clampf(LANE_FOLLOW * delta, 0.0, 1.0)


## 충돌과 포착을 지켜보다 그 순간에만 연출을 낸다.
func _watch_events() -> void:
	if _run.hits > _hits_seen:
		_hits_seen = _run.hits
		_hit_flash = HIT_FLASH
		_spawn_dust(Vector2(_lane_x(_run.player_lane), PLAYER_Y))
	var caught: int = _run.caught_count()
	if caught > _caught_seen:
		_caught_seen = caught
		var at: Vector2 = Vector2(_lane_x(_run.player_lane), PLAYER_Y - 24.0)
		_pops.append({"pos": at, "t": 0.0, "text": "잡았다"})
		_spawn_coins(at)


func _spawn_dust(at: Vector2) -> void:
	for i: int in range(8):
		var angle: float = PI + float(i) * (PI / 7.0)
		_dust.append({"pos": at, "vel": Vector2.from_angle(angle) * 46.0, "t": 0.0})


func _spawn_coins(at: Vector2) -> void:
	for i: int in range(COIN_COUNT):
		var spread: float = (float(i) - float(COIN_COUNT - 1) * 0.5) * 11.0
		_coin_fx.append({"from": at, "to": at + Vector2(spread, 34.0), "t": -float(i) * 0.03})


func _advance_fx(delta: float) -> void:
	var dust: Array[Dictionary] = []
	for grain: Dictionary in _dust:
		grain["t"] = float(grain["t"]) + delta
		grain["pos"] = Vector2(grain["pos"]) + Vector2(grain["vel"]) * delta
		grain["vel"] = Vector2(grain["vel"]) * 0.90
		if float(grain["t"]) < DUST_LIFE:
			dust.append(grain)
	_dust = dust
	var pops: Array[Dictionary] = []
	for pop: Dictionary in _pops:
		pop["t"] = float(pop["t"]) + delta
		if float(pop["t"]) < POP_LIFE:
			pops.append(pop)
	_pops = pops
	var coins: Array[Dictionary] = []
	for coin: Dictionary in _coin_fx:
		coin["t"] = float(coin["t"]) + delta
		if float(coin["t"]) < COIN_FLY_TIME:
			coins.append(coin)
	_coin_fx = coins


func _input(event: InputEvent) -> void:
	if _phase != Phase.RUN:
		return
	var step: int = 0
	if event.is_action_pressed(&"move_right") or event.is_action_pressed(&"ui_right"):
		step = 1
	elif event.is_action_pressed(&"move_left") or event.is_action_pressed(&"ui_left"):
		step = -1
	if step == 0:
		return
	get_viewport().set_input_as_handled()
	_run.move(step)


## 문턱 미만. 훔칠 게 없어 비웃고 물러난다. 방은 일반 전투로 이어진다
func _begin_taunt() -> void:
	_phase = Phase.TAUNT
	_timer = taunt_time
	_result = empty_result("장물아비 소굴")
	_result["converted_to_combat"] = true
	_result["losses"] = PackedStringArray(["이런 거지를 털어 무엇하나", "장물아비가 물러났다"])


func _begin_chase(config: Dictionary, params: Dictionary, coins: int) -> void:
	var seed_value: int = (int(config.get("seed", 0)) + SEED_SALT) & SEED_MASK
	var rate: float = float(params.get("steal_on_entry_rate", 0.2))
	_stolen = maxi(int(round(float(coins) * rate)), STEAL_FLOOR)
	_stolen = mini(_stolen, coins)
	var count: int = _thief_count(params, coins)
	var each: int = int(round(float(_stolen) / float(maxi(count, 1))))
	_run = ChaseRun.new(count, each, seed_value, load(TRACK_PATH) as ChaseTrack)
	_lane_visual = float(_run.player_lane)
	_phase = Phase.INTRO
	_timer = intro_time


## 소지금이 많을수록 장물아비가 늘어난다. 부자만 노린다는 서사다 (부록 A.1)
func _thief_count(params: Dictionary, coins: int) -> int:
	var low: int = int(params.get("min_thief_count", 3))
	var high: int = int(params.get("max_thief_count", 5))
	var rich: int = maxi(int(params.get("rich_coins", 200)), 1)
	var ratio: float = clampf(float(coins) / float(rich), 0.0, 1.0)
	return clampi(low + int(round(ratio * float(high - low))), low, high)


func _finish_run() -> void:
	_phase = Phase.RESULT
	_timer = result_time
	var recovered: int = int(floor(float(_run.caught_coins()) * _return_bonus))
	var lost: int = _run.lost_coins()
	_result = empty_result("장물아비 소굴")
	_result["coins_delta"] = recovered - _stolen
	_result["won"] = _run.all_caught()
	var gains: PackedStringArray = PackedStringArray()
	var losses: PackedStringArray = PackedStringArray()
	if recovered > 0:
		gains.append("엽전 %d닢 회수 (웃돈 포함)" % recovered)
	if _run.all_caught():
		gains.append("쟁여둔 장물에서 떨이 유물 하나")
		_result["relic_chance"] = 1.0
	if lost > 0:
		losses.append("엽전 %d닢을 놓쳤다" % lost)
	if _run.failed():
		losses.append("장애물에 %d번 걸려 추격을 접었다" % _run.max_hits())
	_result["gains"] = gains
	_result["losses"] = losses


# --- 좌표 ---


## 부딪힌 직후 골목이 흔들린다. HUD는 흔들지 않는다
func _shake() -> Vector2:
	if _hit_flash <= 0.0:
		return Vector2.ZERO
	var power: float = _hit_flash / HIT_FLASH * SHAKE_POWER
	return Vector2(sin(_anim_time * SHAKE_RATE) * power, cos(_anim_time * SHAKE_RATE * 0.7) * power)


func _lane_x(lane: int) -> float:
	return LANE_X0 + float(lane) * LANE_GAP


func _lane_x_float(lane: float) -> float:
	return LANE_X0 + lane * LANE_GAP


func _depth_y(logic_y: float) -> float:
	return maxf(PLAYER_Y - logic_y * DEPTH_SCALE, TOP_CLAMP)


## 그 화면 높이에서의 조형 배율. 위로 갈수록 작아져 멀어 보인다
func _depth_scale(screen_y: float) -> float:
	var t: float = clampf((screen_y - TOP_CLAMP) / (PLAYER_Y - TOP_CLAMP), 0.0, 1.0)
	return lerpf(FAR_SCALE, NEAR_SCALE, t)


# --- 그리기 ---


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP)
	if _phase == Phase.TAUNT:
		_draw_taunt()
		return
	var shake: Vector2 = _shake()
	_draw_road(shake)
	_draw_side_props(shake)
	_draw_rush(shake)
	if _phase == Phase.RUN or _phase == Phase.INTRO:
		_draw_obstacles(shake)
		_draw_thief(shake)
	_draw_player(shake)
	_draw_fx()
	match _phase:
		Phase.INTRO:
			_draw_intro()
		Phase.RUN:
			_draw_hud()
		Phase.RESULT:
			_draw_result()
	if _hit_flash > 0.0:
		var alpha: float = _hit_flash / HIT_FLASH * 0.28
		draw_rect(Rect2(Vector2.ZERO, size), Color(NIGHT, alpha))


## 골목 바닥. 흐르는 눈금이 속도를 알린다
func _draw_road(shake: Vector2) -> void:
	var left: float = ROAD_LEFT + shake.x
	var right: float = ROAD_RIGHT + shake.x
	draw_rect(Rect2(left, TOP_CLAMP, right - left, size.y - TOP_CLAMP), Color(0.11, 0.11, 0.16))
	draw_line(Vector2(left, TOP_CLAMP), Vector2(left, size.y), Color(NIGHT, 0.8), 1.0)
	draw_line(Vector2(right, TOP_CLAMP), Vector2(right, size.y), Color(NIGHT, 0.8), 1.0)
	for lane: int in range(1, ChaseRun.LANE_COUNT):
		var x: float = LANE_X0 - LANE_GAP * 0.5 + float(lane) * LANE_GAP + shake.x
		_draw_lane_dashes(x, shake.y)


## 레인 경계의 점선. 아래로 흘러 달리는 느낌을 만든다
func _draw_lane_dashes(x: float, shake_y: float) -> void:
	var y: float = TOP_CLAMP + fposmod(_scroll, DASH_SPAN) + shake_y
	while y < size.y:
		var scale_at: float = _depth_scale(y)
		draw_rect(Rect2(x - 0.5, y, 1.0, 10.0 * scale_at), Color(NIGHT, 0.55 + scale_at * 0.25))
		y += DASH_SPAN


## 속도선. 골목 위를 스쳐 지나가는 흐린 줄기다. 눈금보다 훨씬 빠르게 흐른다
func _draw_rush(shake: Vector2) -> void:
	if _phase == Phase.TAUNT or _phase == Phase.RESULT:
		return
	var span: float = ROAD_RIGHT - ROAD_LEFT
	for i: int in range(RUSH_COUNT):
		var lane_x: float = ROAD_LEFT + fmod(float(i) * 37.0, span) + shake.x
		var base: float = float(i) * (RUSH_SPAN / float(RUSH_COUNT))
		var y: float = fposmod(base + _scroll * RUSH_MULT, RUSH_SPAN) / RUSH_SPAN * size.y
		var scale_at: float = _depth_scale(y)
		var length: float = 8.0 + 20.0 * scale_at
		draw_rect(Rect2(lane_x, y + shake.y, 1.0, length), Color(INK, 0.05 + scale_at * 0.07))


## 양옆 좌판. 아래로 흘러 내려가며 골목 벽을 이룬다
func _draw_side_props(shake: Vector2) -> void:
	for prop: Dictionary in _side_props:
		var tex: Texture2D = prop["tex"]
		var y: float = fposmod(float(prop["base"]) + _scroll * 0.7, SIDE_SPAN * 3.0) - 30.0
		if y < TOP_CLAMP - 30.0 or y > size.y + 30.0:
			continue
		var scale_at: float = _depth_scale(y)
		var half: Vector2 = Vector2(tex.get_size()) * scale_at * 0.5
		var pos: Vector2 = Vector2(float(prop["x"]), y) + shake - half
		draw_texture_rect(tex, Rect2(pos.floor(), half * 2.0), false, Color(0.7, 0.7, 0.8))


func _draw_obstacles(shake: Vector2) -> void:
	if _run == null:
		return
	for obstacle: Dictionary in _run.obstacles:
		var y: float = _depth_y(float(obstacle["y"])) + shake.y
		var x: float = _lane_x(int(obstacle["lane"])) + shake.x
		var scale_at: float = _depth_scale(y)
		var tint: Color = INK_DIM if bool(obstacle["spent"]) else Color(0.80, 0.80, 0.88)
		_draw_prop(_obstacle_for(int(obstacle.get("shape", 0))), Vector2(x, y), scale_at, tint)


## 장애물 조형 하나. 없으면 남색 사각으로 물러선다
func _draw_prop(tex: Texture2D, center: Vector2, scale_at: float, tint: Color) -> void:
	if tex == null:
		var box: Vector2 = Vector2(26.0, 10.0) * scale_at
		draw_rect(Rect2(center - box * 0.5, box), NIGHT_DIM)
		return
	var box_size: Vector2 = Vector2(tex.get_size()) * scale_at
	var pos: Vector2 = center - box_size * 0.5
	draw_texture_rect(tex, Rect2(pos.floor(), box_size), false, tint)


## 같은 장애물에는 늘 같은 조형이 붙게 생성 번호로 고른다
func _obstacle_for(shape: int) -> Texture2D:
	if _obstacle_tex.is_empty():
		return null
	return _obstacle_tex[shape % _obstacle_tex.size()]


## 표적 장물아비. 등의 보따리는 난색으로 찍어 우선 포착 신호를 준다 (부록 A.6)
func _draw_thief(shake: Vector2) -> void:
	if _run == null or _thief_frames == null:
		return
	var lane: int = _run.target_lane()
	if lane < 0:
		return
	var y: float = _depth_y(_run.gap) + shake.y
	var x: float = _lane_x(lane) + shake.x
	var scale_at: float = _depth_scale(y)
	var anim: StringName = &"run" if _thief_back else &"hop"
	_draw_actor(_frame_of(_thief_frames, anim, 12.0), Vector2(x, y), scale_at, 0.0, INK)
	if _thief_back:
		# 전용 조형은 보따리를 그려서 갖고 있다. 덧그리지 않는다
		return
	var bundle: Vector2 = Vector2(x, y - 20.0 * scale_at)
	draw_circle(bundle, 5.0 * scale_at, LANTERN)
	draw_circle(bundle, 2.0 * scale_at, INK)


func _draw_player(shake: Vector2) -> void:
	if _player_frames == null:
		return
	var lean: float = 0.0
	var x: float = _lane_x_float(_lane_visual) + shake.x
	if _run != null:
		lean = clampf(float(_run.player_lane) - _lane_visual, -1.0, 1.0) * LANE_LEAN
	var y: float = PLAYER_Y + shake.y
	if _hit_flash > 0.0:
		y += _hit_flash / HIT_FLASH * HIT_RECOIL
	var anim: StringName = &"run" if _phase != Phase.RESULT else &"idle"
	_draw_actor(_frame_of(_player_frames, anim, 14.0), Vector2(x, y), PLAYER_SCALE, lean, INK)


## 캐릭터 한 명. 발밑이 그 자리에 오게 그린다
func _draw_actor(tex: Texture2D, at: Vector2, scale_at: float, lean: float, tint: Color) -> void:
	if tex == null:
		return
	draw_set_transform(at.floor(), lean, Vector2(scale_at, scale_at))
	draw_texture(tex, -ART_CENTER, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _frame_of(frames: SpriteFrames, anim: StringName, fps: float) -> Texture2D:
	var name_value: StringName = anim if frames.has_animation(anim) else &"idle"
	var count: int = frames.get_frame_count(name_value)
	if count <= 0:
		return null
	return frames.get_frame_texture(name_value, int(_anim_time * fps) % count)


## 흙먼지, 튀는 엽전, 잡았다 문구.
func _draw_fx() -> void:
	for grain: Dictionary in _dust:
		var life: float = 1.0 - float(grain["t"]) / DUST_LIFE
		draw_circle(Vector2(grain["pos"]), 2.0 * life, Color(NIGHT_DIM, life))
	for coin: Dictionary in _coin_fx:
		var t: float = float(coin["t"])
		if t < 0.0:
			continue
		var u: float = clampf(t / COIN_FLY_TIME, 0.0, 1.0)
		var pos: Vector2 = Vector2(coin["from"]).lerp(Vector2(coin["to"]), u)
		pos -= Vector2(0.0, sin(u * PI) * 22.0)
		draw_circle(pos.floor(), 3.0, Color(LANTERN, 1.0 - u * 0.5))
	for pop: Dictionary in _pops:
		var u2: float = float(pop["t"]) / POP_LIFE
		var at: Vector2 = Vector2(pop["pos"]) - Vector2(0.0, u2 * 18.0)
		_draw_text_at(String(pop["text"]), at, FONT_SIZE, Color(LANTERN, 1.0 - u2))


func _draw_text_at(text: String, center: Vector2, font_size: int, color: Color) -> void:
	var font: Font = body_font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var pos: Vector2 = center - Vector2(width * 0.5, 0.0)
	draw_string(font, pos.floor(), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


# --- 문구 ---


func _draw_taunt() -> void:
	if _thief_frames != null:
		var anim: StringName = &"run" if _thief_back else &"hop"
		_draw_actor(_frame_of(_thief_frames, anim, 8.0), Vector2(300.0, 190.0), 1.2, 0.0, INK)
	if _player_frames != null:
		_draw_actor(_frame_of(_player_frames, &"idle", 6.0), Vector2(180.0, 190.0), 1.2, 0.0, INK)
	draw_center("장물아비가 소매를 뒤적이다 만다", 226.0, FONT_SIZE, INK)
	draw_center("이런 거지를 털어 무엇하나", 244.0, FONT_SIZE, NIGHT_DIM)


func _draw_intro() -> void:
	draw_center("엽전 %d닢을 낚아채 달아났다" % _stolen, 240.0, FONT_SIZE, NIGHT_DIM)
	draw_center("쫓아라", 260.0, FONT_SIZE_BIG, LANTERN)


func _draw_hud() -> void:
	_draw_hit_lamps()
	var right: String = "잡음 %d/%d" % [_run.caught_count(), _run.thieves.size()]
	_draw_text_at(right, Vector2(424.0, 22.0), FONT_SIZE, LANTERN)
	draw_meter(Rect2(120.0, 250.0, 240.0, 5.0), 1.0 - _run.gap_ratio(), LANTERN, NIGHT)
	draw_center("좌우로 피하고 따라붙어라", 266.0, FONT_SIZE, INK_DIM)


## 남은 충돌 여유를 등불로 보인다. 꺼진 등이 부딪힌 횟수다
func _draw_hit_lamps() -> void:
	for i: int in range(_run.max_hits()):
		var at: Vector2 = Vector2(20.0 + float(i) * 14.0, 20.0)
		var lit: bool = i >= _run.hits
		draw_circle(at, 4.0, LANTERN if lit else NIGHT)
		draw_arc(at, 4.0, 0.0, TAU, 12, INK_DIM, 1.0)


func _draw_result() -> void:
	var won: bool = bool(_result.get("won", false))
	draw_rect(Rect2(0.0, 86.0, size.x, 96.0), Color(BACKDROP, 0.85))
	draw_center("전부 잡았다" if won else "추격을 접었다", 108.0, FONT_SIZE_BIG, LANTERN if won else NIGHT_DIM)
	var line_y: float = 132.0
	for text: String in _result.get("gains", PackedStringArray()):
		draw_center(text, line_y, FONT_SIZE, LANTERN)
		line_y += 15.0
	for text: String in _result.get("losses", PackedStringArray()):
		draw_center(text, line_y, FONT_SIZE, NIGHT_DIM)
		line_y += 15.0
