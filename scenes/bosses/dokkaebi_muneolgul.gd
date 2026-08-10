extends BossBase

## 1막 정규 보스: 시장을 지키도록 세운 수문 도깨비 얼굴 대문 (docs/act1/BOSS.md 3.1)
##
## 2026-08-10 재설계 3차. 대문 자체가 보스이고 좌우 문짝에 얼굴이 하나씩 있다.
## 얼굴마다 담당 패턴이 따로 있고, 공격 중인 얼굴만 눈을 뜬다.
##
##   좌 얼굴: 지진(낙석), 소환(문에서 도깨비가 걸어 나온다)
##   우 얼굴: 증기(맵을 채우는 열기), 바람(밀어내기 + 장애물), 눈 광선(3페이즈 전용)
##
## 1페이즈는 지진과 증기를 번갈아, 2페이즈는 소환과 바람이 합류해 네 패턴이 돈다.
## 3페이즈는 두 얼굴이 동시에 움직인다. 좌 하나와 우 하나가 겹쳐 나오고 수치가 올라간다.
##
## 이를 위해 행동 상태를 얼굴별 두 갈래(_act/_step/_timer/_gap)로 나눠 돌린다. 1~2페이즈는
## 한 갈래만 돌도록 잠그고, 3페이즈에서 그 잠금을 푸는 것이 페이즈 차이의 핵심이다.
##
## 종전의 넘어지기(떨림, 전도, 엎어진 딜 창)는 폐기했다. 정면 파사드를 눌러 눕히면 얼굴이
## 뭉개져 어떤 보정으로도 읽히지 않았다 (2026-08-10 사용자 판단). 대신 우 얼굴이 달아올라
## 증기를 뿜고, 아레나 왼쪽 끝 안전지대만 남긴다. 딜 창은 패턴 사이 간격이다.
##
## 약점은 얼굴이 아니라 문 앞면 전체다 (48 x 192, 배리어보다 바깥으로 돌출).
## 얼굴 그림과 피격 판정을 분리한 2026-08-08 규칙은 그대로 유지한다.
##
## 통신은 call down, signal up. 위로 알리는 것은 BossBase의 phase_changed와 boss_defeated뿐이다.

## 문 앞 첫 상호작용에서 띄우는 경고
@export var speech_line: String = "생자가 지나갈 길은 없다. 돌아가"
@export var speech_time: float = 2.6
## 두 번째 상호작용부터 개전까지의 응시 시간 (초)
@export var awaken_time: float = 0.9
## 좌 문짝 (화난 얼굴). 문짝 한 짝이 통째로 얼굴이다
@export var left_face_texture: Texture2D = null
## 우 문짝 (온화한 얼굴)
@export var right_face_texture: Texture2D = null
## 낙석 변주
@export var rock_textures: Array[Texture2D] = []
## 바람 패턴 장애물 텍스처
@export var crate_textures: Array[Texture2D] = []

## 지진 전조 (초)
@export var quake_windup: float = 0.5
@export var quake_duration: float = 3.0
## 낙석 생성 간격 (초). 3페이즈는 berserk_rate로 나눠 더 촘촘해진다
@export var rock_interval: float = 0.3
@export var rock_damage: int = 12
@export var rock_fall_speed: float = 380.0
## 플레이어 기준 좌우 산포 폭 (px)
@export var rock_spread: float = 260.0

## 증기 1단계. 우 얼굴이 빨갛게 달아오르는 예고 (초). 3페이즈는 절반이 된다
@export var steam_windup: float = 1.3
## 증기 2단계. 뿜어내는 시간 (초)
@export var steam_duration: float = 2.2
## 증기 3단계. 걷히는 시간 (초)
@export var steam_cool: float = 0.5
@export var steam_damage: int = 20
## 증기 안에 계속 서 있을 때 피해가 다시 들어오는 간격 (초)
@export var steam_tick: float = 0.55
## 증기 띠가 흘러가는 속도 (px/s). 왼쪽으로 밀려가는 방향으로 읽힌다
@export var steam_scroll_speed: float = 26.0
## 증기가 비워두는 안전지대 폭 (px). 아레나 맨 왼쪽 끝에 남는다
@export var steam_safe_width: float = 100.0
## 3페이즈 안전지대 폭 (px). 더 좁아진다
@export var steam_safe_width_berserk: float = 62.0

## 눈 광선 (3페이즈 전용, 우 얼굴)
@export var beam_telegraph: float = 0.5
@export var beam_active: float = 0.15
@export var beam_gap: float = 0.55
@export var beam_damage: int = 16
@export var beam_length: float = 700.0
## 한 번 발동에 쏘는 발수
@export var beam_shots: int = 2
## 플레이어 발밑에서 이만큼 위를 조준한다 (px)
@export var beam_aim_height: float = 17.0

## 문이 벌어지고 닫히는 시간 (초)
@export var summon_open_time: float = 0.6
## 도깨비가 한 기씩 나오는 간격 (초)
@export var summon_step: float = 0.45
## 문틈에서 문 밖까지 걸어 나오는 시간 (초)
@export var summon_walk_time: float = 0.9
@export var summon_close_time: float = 0.6
## 한 번에 나오는 수. 3페이즈는 berserk_count_bonus만큼 더 나온다
@export var summon_count: int = 4
@export var summon_total_cap: int = 12
@export var summon_cooldown: float = 9.0

@export var wind_open_time: float = 0.6
@export var wind_duration: float = 4.5
## 플레이어 최대 이동 속도(170)와 같게 두어 걸어서는 전진이 0이 된다 (px/s).
## 대시만 바람을 뚫는다 (docs/act1/BOSS.md 3.1 바람 항목)
@export var wind_force: float = 170.0
## 3페이즈 바람 세기. 최대 속도보다 강해 걸어서는 뒤로 밀린다
@export var wind_force_berserk: float = 230.0
@export var obstacle_interval: float = 0.42
@export var obstacle_speed: float = 360.0
@export var obstacle_damage: int = 14
@export var wind_close_time: float = 0.6

## 3페이즈 배속 (작을수록 빠르다)
@export var berserk_time_scale: float = 0.75
## 3페이즈 밀도 배율. 낙석과 장애물 간격을 이 값으로 나눈다
@export var berserk_rate: float = 1.9
## 3페이즈에 한 번에 더 나오는 소환 수
@export var berserk_count_bonus: int = 2
@export var action_gap: float = 1.8
@export var action_gap_berserk: float = 1.2

const DEBRIS_SCENE: PackedScene = preload("res://scenes/bosses/muneolgul_debris.tscn")
## 소환 목록 (2026-08-10 사용자 요청: 종류를 다양하게).
##
## 접근(잡도깨비), 원거리(등불 도깨비), 지형 장애(달걀도깨비)로 역할이 겹치지 않게
## 골랐다. 씨름꾼은 중간보스급이라, 장물아비는 엽전을 훔쳐 달아나는 개체라 제외한다.
## 장물아비를 넣으면 보스전 중에 보상이 새고 도주 추격이 보스 패턴을 가린다.
##
## 방어 앵커(짐꾼)도 넣었으나 2026-08-10 라인업 제외로 함께 뺐다. 짐꾼이 재합류하면
## 여기에 되돌린다 (docs/act1/ENEMIES.md 5.6 보류 항목).
const MINION_SCENES: Array[String] = [
	"res://scenes/enemies/enemy_charger.tscn",
	"res://scenes/enemies/enemy_shooter.tscn",
	"res://scenes/enemies/enemy_egg.tscn",
]

## 서 있을 때의 약점: 문 앞면 전체. 배리어(앞면 x -152)보다 바깥으로 돌출시켜, 문에 붙기만
## 하면 근접과 사격이 반드시 닿게 한다
const STAND_HURT_POS: Vector2 = Vector2(-152.0, -96.0)
const STAND_HURT_SIZE: Vector2 = Vector2(48.0, 192.0)

## 낙석 생성 가능 범위 (보스 기준 x). 방 폭 512, 보스 x 512 기준으로 광장 전체를 덮는다
const ROCK_MIN_X: float = -490.0
const ROCK_MAX_X: float = -190.0
## 아레나 왼쪽 끝 (보스 기준 x). 증기 안전지대를 여기서부터 잰다
const ARENA_LEFT_X: float = -496.0
## 대문 앞면 (보스 기준 x). 증기는 여기까지 들어찬다
const GATE_FRONT_X: float = -152.0
## 증기가 차오르는 높이 (px). 점프로는 넘을 수 없다
const STEAM_HEIGHT: float = 104.0

## 장애물 높이 세 종. 낮으면 점프로 넘고, 중간은 점프 정점에서 스치고, 높은 것은 서서 흘린다
const OBSTACLE_LOW_Y: float = -20.0
const OBSTACLE_MID_Y: float = -42.0
const OBSTACLE_HIGH_Y: float = -66.0
const OBSTACLE_CYCLE: Array[float] = [
	OBSTACLE_LOW_Y,
	OBSTACLE_HIGH_Y,
	OBSTACLE_LOW_Y,
	OBSTACLE_MID_Y,
	OBSTACLE_LOW_Y,
	OBSTACLE_HIGH_Y,
]
## 3페이즈 주기. 낮음이 줄고 연속 점프를 강요하는 조합이 늘어난다
const OBSTACLE_CYCLE_BERSERK: Array[float] = [
	OBSTACLE_LOW_Y,
	OBSTACLE_MID_Y,
	OBSTACLE_HIGH_Y,
	OBSTACLE_MID_Y,
	OBSTACLE_LOW_Y,
	OBSTACLE_HIGH_Y,
	OBSTACLE_MID_Y,
	OBSTACLE_HIGH_Y,
]

## 얼굴별 순환표. 페이즈가 오를수록 길어진다
const LEFT_CYCLE_P1: Array[StringName] = [&"quake"]
const LEFT_CYCLE: Array[StringName] = [&"quake", &"summon"]
const RIGHT_CYCLE_P1: Array[StringName] = [&"steam"]
const RIGHT_CYCLE_P2: Array[StringName] = [&"steam", &"wind"]
const RIGHT_CYCLE_P3: Array[StringName] = [&"steam", &"wind", &"beam"]

## 문짝 반폭/반높이와 대문 전체 폭 (BodyVisual 로컬, 문은 원점 왼쪽으로 뻗는다)
const DOOR_HALF: float = 38.0
const DOOR_HALF_H: float = 96.0
const GATE_INNER_W: float = 152.0
## 활짝 열렸을 때 문짝이 돌아간 각도. 가로 축소는 이 각의 코사인으로 나온다
const DOOR_OPEN_ANGLE: float = 1.274
const DOOR_OPEN_RISE: float = 1.07
const DOOR_OPEN_SHADE: float = 0.52
const DOOR_SWING_TIME: float = 0.5
## 문틈 위치와 걸어 나오는 목표 (보스 기준 x)
const MINION_GATE_X: float = -76.0
const MINION_EXIT_X: float = -280.0

## 눈을 감은 얼굴은 어둡게 가라앉힌다
const FACE_DIM: Color = Color(0.62, 0.6, 0.66)
## 눈을 뜬 얼굴은 호박빛으로 뜬다
const FACE_AWAKE: Color = Color(1.15, 1.0, 0.85)
## 증기 예고에서 달아오른 얼굴
const FACE_HOT: Color = Color(1.9, 0.55, 0.4)
## 전조 점멸 색
const FACE_FLASH: Color = Color(2.0, 1.7, 1.5)

## 얼굴 구분. 배열 첨자로 쓴다
const LEFT: int = 0
const RIGHT: int = 1

## 개전 전 대기 상태. 상호작용 2회 또는 피격으로 풀린다
var _dormant: bool = true
## 0 대기, 1 경고 대사 후, 2 응시 연출 중
var _intro_step: int = 0
var _intro_left: float = 0.0
var _speech_left: float = 0.0

## 얼굴별 진행 상태. 첨자는 LEFT / RIGHT
var _act: Array[StringName] = [&"", &""]
var _step: Array[StringName] = [&"", &""]
var _timer: Array[float] = [0.0, 0.0]
var _gap: Array[float] = [0.0, 0.0]
var _cycle_at: Array[int] = [0, 0]
## 1~2페이즈에서 다음에 움직일 얼굴. 3페이즈에서는 쓰지 않는다
var _turn: int = LEFT

var _rock_timer: float = 0.0
var _obstacle_timer: float = 0.0
var _obstacle_step: int = 0
var _steam_tick_left: float = 0.0
## 증기 띠의 누적 스크롤 거리 (px)
var _steam_scroll: float = 0.0
var _beam_shots_left: int = 0

var _minions: Array[EnemyBase] = []
var _summon_total: int = 0
var _summon_cd: float = 0.0
var _summon_queue: int = 0
var _summon_next: float = 0.0

var _door_tween: Tween = null
## 여닫이 열림 정도 (0 닫힘, 1 활짝)
var _door_open: float = 0.0
## 문을 열어 둔 갈래 수. 3페이즈에서는 소환(좌)과 바람(우)이 겹칠 수 있어, 먼저 끝난 쪽이
## 문을 닫아 버리면 남은 쪽 연출이 깨진다. 마지막 하나가 끝날 때만 닫는다
var _door_hold: int = 0
## 지금 눈을 뜨고 있는 얼굴
var _left_awake: bool = false
var _right_awake: bool = false

@onready var gate: Node2D = $BodyVisual/Leaves as Node2D
@onready var door_left: Sprite2D = $BodyVisual/Leaves/DoorL as Sprite2D
@onready var door_right: Sprite2D = $BodyVisual/Leaves/DoorR as Sprite2D
@onready var steam_visual: Node2D = $SteamVisual as Node2D
@onready var steam_haze: Polygon2D = $SteamVisual/Haze as Polygon2D
@onready var steam_band_back: Sprite2D = $SteamVisual/BandBack as Sprite2D
@onready var steam_band_front: Sprite2D = $SteamVisual/BandFront as Sprite2D
@onready var steam_crown: CPUParticles2D = $SteamVisual/Crown as CPUParticles2D
@onready var steam_jet: CPUParticles2D = $SteamVisual/Jet as CPUParticles2D
@onready var steam_vent: CPUParticles2D = $SteamVisual/Vent as CPUParticles2D
@onready var steam_hitbox: Hitbox = $SteamHitbox as Hitbox
@onready var steam_shape: CollisionShape2D = $SteamHitbox/Shape as CollisionShape2D
@onready var speech_label: Label = $BodyVisual/SpeechLabel as Label
@onready var hint_label: Label = $BodyVisual/HintLabel as Label
@onready var hurt_shape: CollisionShape2D = $Hurtbox/Shape as CollisionShape2D
@onready var beam_hitbox: Hitbox = $BeamHitbox as Hitbox
@onready var beam_line: Line2D = $BeamTelegraph as Line2D
@onready var interact_zone: Area2D = $InteractZone as Area2D
@onready var gate_barrier: StaticBody2D = $GateBarrier as StaticBody2D


func _ready() -> void:
	super()
	speech_label.text = speech_line
	speech_label.visible = false
	hint_label.visible = false
	_apply_steam_shape()
	_stop_steam()
	if left_face_texture != null:
		door_left.texture = left_face_texture
	if right_face_texture != null:
		door_right.texture = right_face_texture
	_apply_hurt_rect(STAND_HURT_POS, STAND_HURT_SIZE)
	_set_faces(false, false)


func _tick_ai(delta: float) -> void:
	velocity.x = 0.0
	if _dormant:
		_tick_intro(delta)
		return
	_summon_cd = maxf(0.0, _summon_cd - delta)
	_prune_minions()
	_tick_side(LEFT, delta)
	_tick_side(RIGHT, delta)
	_refresh_faces()


# --- 개전 연출 ---


## 문 앞에서 위(W) 상호작용: 1회차 경고 대사, 2회차 양쪽 눈 응시 후 개전.
func _tick_intro(delta: float) -> void:
	if _speech_left > 0.0:
		_speech_left -= delta
		if _speech_left <= 0.0:
			speech_label.visible = false
	if _intro_step == 2:
		_intro_left -= delta
		if _intro_left <= 0.0:
			start_encounter()
		return
	var at_gate: bool = _player_at_gate()
	hint_label.visible = at_gate
	if not at_gate or not Input.is_action_just_pressed(&"move_up"):
		return
	if _intro_step == 0:
		_intro_step = 1
		speech_label.visible = true
		_speech_left = speech_time
		return
	_intro_step = 2
	_intro_left = awaken_time
	speech_label.visible = false
	_set_faces(true, true)
	GameEvents.screen_shake.emit(2.0, 0.3)


func _player_at_gate() -> bool:
	for body: Node2D in interact_zone.get_overlapping_bodies():
		if body.is_in_group(&"player"):
			return true
	return false


## 개전. 대기 해제는 여기가 유일한 경로다 (테스트에서도 직접 부른다).
## 첫 패턴은 좌 얼굴의 지진으로 고정한다.
func start_encounter() -> void:
	if not _dormant:
		return
	_dormant = false
	_intro_step = 2
	speech_label.visible = false
	hint_label.visible = false
	_turn = LEFT
	_cycle_at = [0, 0]
	_gap = [0.8, 0.8]
	show_boss_bar()
	GameEvents.screen_shake.emit(3.0, 0.4)


# --- 얼굴별 진행 ---


## 3페이즈는 두 얼굴이 동시에 움직인다. 그 전에는 한 얼굴만, 그것도 번갈아 움직인다.
func _can_start(side: int) -> bool:
	if phase >= 3:
		return true
	if _act[1 - side] != &"":
		return false
	return _turn == side


func _tick_side(side: int, delta: float) -> void:
	if _act[side] == &"":
		_gap[side] -= delta
		if _gap[side] <= 0.0 and _can_start(side):
			_start_next(side)
		return
	_timer[side] -= delta
	match _act[side]:
		&"quake":
			_tick_quake(side, delta)
		&"steam":
			_tick_steam(side, delta)
		&"summon":
			_tick_summon(side, delta)
		&"wind":
			_tick_wind(side, delta)
		&"beam":
			_tick_beam(side)


## 얼굴별 순환표. 페이즈가 오를수록 길어진다.
func cycle_for(side: int) -> Array[StringName]:
	if side == LEFT:
		return LEFT_CYCLE_P1 if phase < 2 else LEFT_CYCLE
	if phase < 2:
		return RIGHT_CYCLE_P1
	return RIGHT_CYCLE_P2 if phase < 3 else RIGHT_CYCLE_P3


## 다음에 나올 패턴을 소비하지 않고 본다.
func peek_next(side: int) -> StringName:
	return cycle_for(side)[_pick_index(side)]


## 다음에 나올 패턴의 순환표 위치. 조건이 서지 않는 소환(소환수가 아직 살아 있거나 총량
## 상한 도달, 재사용 대기 중)은 건너뛴다. 건너뛰지 않으면 문만 여닫고 아무도 나오지 않는
## 빈 패턴이 한 자리를 차지한다.
func _pick_index(side: int) -> int:
	var cycle: Array[StringName] = cycle_for(side)
	for i: int in range(cycle.size()):
		var at: int = (_cycle_at[side] + i) % cycle.size()
		if cycle[at] == &"summon" and not _should_summon():
			continue
		return at
	return _cycle_at[side] % cycle.size()


func _start_next(side: int) -> void:
	var at: int = _pick_index(side)
	var pick: StringName = cycle_for(side)[at]
	_cycle_at[side] = at + 1
	_act[side] = pick
	match pick:
		&"quake":
			_begin(side, &"windup", quake_windup * _scale())
		&"steam":
			_begin(side, &"heat", steam_windup * _steam_windup_scale())
		&"summon":
			_begin(side, &"open", summon_open_time)
			_hold_doors(true)
		&"wind":
			_begin(side, &"open", wind_open_time)
			_hold_doors(true)
		&"beam":
			_beam_shots_left = beam_shots
			_begin(side, &"aim", beam_telegraph)
			beam_line.visible = true


func _begin(side: int, step: StringName, duration: float) -> void:
	_step[side] = step
	_timer[side] = duration


## 패턴 사이 간격. 이 시간이 곧 딜 창이다 (docs/act1/BOSS.md 3.1 딜 창 규칙).
func gap_time() -> float:
	return action_gap_berserk if phase >= 3 else action_gap


## 패턴을 끝내고 다음 차례를 넘긴다. 3페이즈에서는 차례 개념이 없다.
##
## 넘겨받는 쪽에도 같은 간격을 다시 깐다. 기다리는 동안 그쪽은 이미 자기 _gap을 다 소모했으므로,
## 다시 깔지 않으면 앞 패턴이 끝나는 즉시 다음 패턴이 붙어 딜 창이 사라진다.
func _end_side(side: int) -> void:
	var gap: float = gap_time()
	_act[side] = &""
	_step[side] = &""
	_gap[side] = gap
	if phase < 3:
		_turn = 1 - side
		_gap[_turn] = gap


## 3페이즈 배속. 지속시간에 곱한다
func _scale() -> float:
	return berserk_time_scale if phase >= 3 else 1.0


## 3페이즈 증기 예고 단축. 피할 시간을 절반으로 줄인다
func _steam_windup_scale() -> float:
	return 0.5 if phase >= 3 else 1.0


## 3페이즈 밀도. 낙석과 장애물 간격을 이 값으로 나눈다
func _rate() -> float:
	return berserk_rate if phase >= 3 else 1.0


# --- 지진 (좌 얼굴) ---


func _tick_quake(side: int, delta: float) -> void:
	match _step[side]:
		&"windup":
			_flash_face(side)
			if _timer[side] <= 0.0:
				_begin(side, &"rain", quake_duration)
				_rock_timer = 0.0
				_hop_gate()
				GameEvents.screen_shake.emit(4.0, 0.5)
		&"rain":
			_rock_timer -= delta
			if _rock_timer <= 0.0:
				_rock_timer = rock_interval / _rate()
				_spawn_rock()
				GameEvents.screen_shake.emit(2.2, 0.3)
			if _timer[side] <= 0.0:
				_end_side(side)


## 낙석 하나. 플레이어 주변에 치우쳐 떨어져 압박이 따라온다.
func _spawn_rock() -> void:
	var player: Node2D = find_player()
	var base_x: float = (
		player.global_position.x if player != null else global_position.x + ROCK_MIN_X * 0.5
	)
	var min_x: float = global_position.x + ROCK_MIN_X
	var max_x: float = global_position.x + ROCK_MAX_X
	var gx: float = clampf(base_x + randf_range(-rock_spread, rock_spread), min_x, max_x)
	var debris: MuneolgulDebris = DEBRIS_SCENE.instantiate() as MuneolgulDebris
	var rock_texture: Texture2D = null
	if not rock_textures.is_empty():
		rock_texture = rock_textures[randi_range(0, rock_textures.size() - 1)]
	debris.setup(
		Vector2(0.0, rock_fall_speed),
		rock_damage,
		damage_multiplier,
		global_position.y,
		global_position.x - 1400.0,
		rock_texture
	)
	get_parent().add_child(debris)
	debris.global_position = Vector2(gx, global_position.y - 380.0)


## 문 전체가 살짝 뛴다 (시각 전용).
func _hop_gate() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(gate, ^"position:y", -8.0, 0.1)
	tween.tween_property(gate, ^"position:y", 0.0, 0.12)


# --- 증기 (우 얼굴. 넘어지기 대체) ---


## 안전지대는 아레나 맨 왼쪽 끝에만 남는다. 3페이즈에서는 더 좁다.
func steam_safe() -> float:
	return steam_safe_width_berserk if phase >= 3 else steam_safe_width


## 증기 판정면 (보스 로컬). 안전지대를 뺀 나머지를 대문 앞까지 채운다.
func steam_rect() -> Rect2:
	var x0: float = ARENA_LEFT_X + steam_safe()
	return Rect2(x0, -STEAM_HEIGHT, GATE_FRONT_X - x0, STEAM_HEIGHT)


func _tick_steam(side: int, delta: float) -> void:
	_scroll_steam(delta)
	match _step[side]:
		&"heat":
			_heat_face(side)
			_show_steam_telegraph()
			if _timer[side] <= 0.0:
				_begin(side, &"blast", steam_duration * _scale())
				_start_steam_blast()
		&"blast":
			_steam_tick_left -= delta
			if _steam_tick_left <= 0.0:
				_steam_tick_left = steam_tick
				steam_hitbox.deactivate()
				steam_hitbox.activate()
			if _timer[side] <= 0.0:
				_begin(side, &"cool", steam_cool)
				steam_hitbox.deactivate()
				_set_steam_emitting(false)
				var tween: Tween = create_tween()
				tween.tween_property(steam_visual, ^"modulate:a", 0.0, steam_cool)
		&"cool":
			if _timer[side] <= 0.0:
				_stop_steam()
				_end_side(side)


## 증기 띠를 흘린다. 두 겹을 서로 다른 속도로 밀어 부피감을 만든다.
## 한 겹만 쓰면 128px 타일의 반복이 그대로 보인다.
func _scroll_steam(delta: float) -> void:
	_steam_scroll += steam_scroll_speed * delta
	var span: float = 128.0
	if steam_band_front.texture != null:
		span = float(steam_band_front.texture.get_width())
	var back: Rect2 = steam_band_back.region_rect
	var front: Rect2 = steam_band_front.region_rect
	back.position.x = fmod(_steam_scroll * 0.55, span)
	front.position.x = fmod(_steam_scroll + span * 0.5, span)
	steam_band_back.region_rect = back
	steam_band_front.region_rect = front


## 예고: 얼굴이 달아오르는 동안 증기가 찰 자리를 옅게 미리 보여주고,
## 대문 앞 틈에서 김이 새기 시작한다. 어디서 나오는지를 먼저 알려 주는 신호다.
func _show_steam_telegraph() -> void:
	_apply_steam_shape()
	if steam_visual.visible:
		return
	steam_visual.visible = true
	steam_visual.modulate = Color(1.0, 0.6, 0.46, 0.0)
	steam_haze.visible = true
	steam_band_back.visible = false
	steam_band_front.visible = false
	steam_vent.emitting = true
	steam_crown.emitting = false
	steam_jet.emitting = false
	var tween: Tween = create_tween()
	# 예고 길이는 페이즈에 따라 달라진다. 고정 시간을 쓰면 3페이즈에서 예고가 다 차오르기
	# 전에 증기가 터져 경계선을 못 본 채로 맞는다
	tween.tween_property(
		steam_visual, ^"modulate:a", 0.5, steam_windup * _steam_windup_scale() * 0.8
	)


func _start_steam_blast() -> void:
	var rect: Rect2 = steam_rect()
	var shape: RectangleShape2D = steam_shape.shape as RectangleShape2D
	if shape != null:
		shape = shape.duplicate() as RectangleShape2D
		shape.size = rect.size
		steam_shape.shape = shape
	steam_shape.position = rect.position + rect.size * 0.5
	steam_hitbox.damage = steam_damage
	steam_hitbox.damage_multiplier = damage_multiplier
	steam_hitbox.activate()
	_steam_tick_left = steam_tick
	steam_haze.visible = false
	steam_band_back.visible = true
	steam_band_front.visible = true
	_set_steam_emitting(true)
	steam_visual.modulate = Color(1.0, 0.96, 0.92, 1.0)
	GameEvents.screen_shake.emit(3.4, 0.35)


func _set_steam_emitting(on: bool) -> void:
	steam_crown.emitting = on
	steam_jet.emitting = on
	steam_vent.emitting = on


## 증기를 완전히 거둔다. 페이즈 전환과 사망에서도 부른다.
func _stop_steam() -> void:
	_set_steam_emitting(false)
	steam_visual.visible = false
	steam_band_back.visible = false
	steam_band_front.visible = false
	steam_haze.visible = true


## 판정면 크기에 맞춰 안개 사각형, 띠 두 겹, 파티클 방출 구간을 한꺼번에 맞춘다.
## 3페이즈는 안전지대가 좁아져 판정면이 넓어지므로 매번 다시 계산한다.
func _apply_steam_shape() -> void:
	var r: Rect2 = steam_rect()
	steam_haze.polygon = PackedVector2Array(
		[
			r.position,
			Vector2(r.position.x + r.size.x, r.position.y),
			Vector2(r.position.x + r.size.x, r.position.y + r.size.y),
			Vector2(r.position.x, r.position.y + r.size.y),
		]
	)
	for band: Sprite2D in [steam_band_back, steam_band_front]:
		band.position = r.position
		var region: Rect2 = band.region_rect
		region.size = r.size
		band.region_rect = region
	# 윗면에서 피어오르는 퍼프. 판정면 위 가장자리를 따라 뿌린다
	steam_crown.position = Vector2(r.position.x + r.size.x * 0.5, r.position.y + 4.0)
	steam_crown.emission_rect_extents = Vector2(r.size.x * 0.5, 6.0)
	# 대문 앞 분출구. 여기서 왼쪽으로 뿜어 나간다
	steam_jet.position = Vector2(r.position.x + r.size.x - 6.0, r.position.y + r.size.y * 0.44)
	steam_vent.position = Vector2(GATE_FRONT_X + 2.0, r.position.y + r.size.y * 0.36)


# --- 소환 (좌 얼굴, 2페이즈부터) ---


## 살아 있는 소환수가 없고, 재사용 대기가 끝났고, 총량 상한이 남아 있으면 소환한다.
func _should_summon() -> bool:
	return _minions.is_empty() and _summon_cd <= 0.0 and _summon_total < summon_total_cap


## 한 번에 나오는 수. 3페이즈에는 더 나온다.
func summon_batch() -> int:
	return summon_count + (berserk_count_bonus if phase >= 3 else 0)


func _tick_summon(side: int, delta: float) -> void:
	match _step[side]:
		&"open":
			if _timer[side] <= 0.0:
				_summon_queue = summon_batch()
				_summon_next = 0.0
				_begin(side, &"out", summon_step * float(_summon_queue) + summon_walk_time)
		&"out":
			_summon_next -= delta
			if _summon_queue > 0 and _summon_next <= 0.0:
				_summon_next = summon_step
				_spawn_one_minion()
				_summon_queue -= 1
			if _timer[side] <= 0.0:
				_hold_doors(false)
				_begin(side, &"close", summon_close_time)
				_summon_cd = summon_cooldown
		&"close":
			if _timer[side] <= 0.0:
				_end_side(side)


## 한 기씩 문틈에서 걸어 나온다. 문짝보다 뒤에 그리고 서서히 드러나며 나온다.
## 종전에는 AI를 멈춘 채 위치만 보간해서 "슉 하고 날아온다"는 인상이었다
## (2026-08-10 사용자 보고). 이제 나오는 동안에도 자기 AI로 걷는다.
func _spawn_one_minion() -> void:
	if _summon_total >= summon_total_cap:
		return
	var path: String = MINION_SCENES[randi_range(0, MINION_SCENES.size() - 1)]
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return
	var minion: EnemyBase = packed.instantiate() as EnemyBase
	if minion == null:
		return
	get_parent().add_child(minion)
	minion.global_position = global_position + Vector2(MINION_GATE_X, 0.0)
	minion.z_index = -1
	minion.modulate.a = 0.0
	# 문틈은 배리어 안쪽이다. 나오는 동안만 배리어를 무시하게 해서, 중력과 바닥 충돌은
	# 그대로 두면서 문지방을 통과시킨다. 다 나오면 예외를 거둬 되돌아 들어가지 못하게 한다
	minion.add_collision_exception_with(gate_barrier)
	_minions.append(minion)
	_summon_total += 1
	var tween: Tween = create_tween()
	tween.tween_property(minion, ^"modulate:a", 1.0, summon_walk_time * 0.55)
	tween.parallel().tween_property(
		minion, ^"global_position:x", global_position.x + MINION_EXIT_X, summon_walk_time
	)
	tween.tween_callback(_release_minion.bind(minion))
	GameEvents.screen_shake.emit(1.2, 0.12)


## 다 나온 도깨비를 정상 그리기 순서로 돌려놓는다.
func _release_minion(minion: EnemyBase) -> void:
	if not is_instance_valid(minion):
		return
	minion.z_index = 0
	minion.modulate.a = 1.0
	minion.remove_collision_exception_with(gate_barrier)


func _prune_minions() -> void:
	var alive: Array[EnemyBase] = []
	for minion: EnemyBase in _minions:
		if is_instance_valid(minion) and not minion.health.is_dead():
			alive.append(minion)
	_minions = alive


# --- 바람 (우 얼굴, 2페이즈부터) ---


## 3페이즈에서는 최대 속도보다 강해져 걸으면 뒤로 밀린다.
func current_wind_force() -> float:
	return wind_force_berserk if phase >= 3 else wind_force


func _tick_wind(side: int, delta: float) -> void:
	match _step[side]:
		&"open":
			_flash_face(side)
			if _timer[side] <= 0.0:
				_begin(side, &"blow", wind_duration * _scale())
				_obstacle_timer = 0.0
				_obstacle_step = 0
				_set_player_wind(-current_wind_force())
		&"blow":
			_obstacle_timer -= delta
			if _obstacle_timer <= 0.0:
				_obstacle_timer = obstacle_interval / _rate()
				_spawn_obstacle()
			if _timer[side] <= 0.0:
				_set_player_wind(0.0)
				_hold_doors(false)
				_begin(side, &"close", wind_close_time)
		&"close":
			if _timer[side] <= 0.0:
				_end_side(side)


func _spawn_obstacle() -> void:
	var cycle: Array[float] = OBSTACLE_CYCLE_BERSERK if phase >= 3 else OBSTACLE_CYCLE
	var height: float = cycle[_obstacle_step % cycle.size()]
	_obstacle_step += 1
	var debris: MuneolgulDebris = DEBRIS_SCENE.instantiate() as MuneolgulDebris
	var crate: Texture2D = null
	if not crate_textures.is_empty():
		crate = crate_textures[randi_range(0, crate_textures.size() - 1)]
	debris.setup(
		Vector2(-obstacle_speed, 0.0),
		obstacle_damage,
		damage_multiplier,
		global_position.y + 100000.0,
		global_position.x - 900.0,
		crate
	)
	get_parent().add_child(debris)
	debris.global_position = global_position + Vector2(-140.0, height)


func _set_player_wind(force: float) -> void:
	var player: Node2D = find_player()
	if player == null:
		return
	if player.has_method(&"set_wind"):
		player.call(&"set_wind", force)


# --- 눈 광선 (우 얼굴, 3페이즈 전용) ---


func _tick_beam(side: int) -> void:
	match _step[side]:
		&"aim":
			_update_beam_telegraph(side)
			if _timer[side] <= 0.0:
				_fire_beam()
				_begin(side, &"fire", beam_active)
		&"fire":
			if _timer[side] <= 0.0:
				beam_hitbox.deactivate()
				_beam_shots_left -= 1
				if _beam_shots_left > 0:
					_begin(side, &"aim", beam_gap)
				else:
					_stop_beam()
					_end_side(side)


func _beam_origin() -> Vector2:
	return door_right.global_position + Vector2(0.0, -24.0)


## 조준선: 우 얼굴 눈 높이에서 플레이어 허트박스 중심 높이로 수평선을 긋는다.
func _update_beam_telegraph(side: int) -> void:
	var player: Node2D = find_player()
	var ty: float = -40.0
	if player != null:
		ty = player.global_position.y - beam_aim_height - global_position.y
	var origin_local: Vector2 = to_local(_beam_origin())
	beam_line.visible = true
	beam_line.points = PackedVector2Array(
		[Vector2(origin_local.x, ty), Vector2(origin_local.x - beam_length, ty)]
	)
	var pulse: bool = int(_timer[side] * 12.0) % 2 == 0
	beam_line.default_color = (
		Color(1.0, 0.3, 0.25, 0.85) if pulse else Color(1.0, 0.7, 0.6, 0.5)
	)


func _fire_beam() -> void:
	beam_line.default_color = Color(1.0, 0.95, 0.8, 0.95)
	var origin_local: Vector2 = to_local(_beam_origin())
	var ty: float = -40.0
	if beam_line.points.size() > 0:
		ty = beam_line.points[0].y
	beam_hitbox.position = Vector2(origin_local.x - beam_length * 0.5, ty)
	beam_hitbox.damage = beam_damage
	beam_hitbox.damage_multiplier = damage_multiplier
	beam_hitbox.activate()


func _stop_beam() -> void:
	beam_hitbox.deactivate()
	beam_line.visible = false


# --- 얼굴 상태 ---


## 공격 중인 얼굴만 눈을 뜬다. 대기 중이라도 곧 움직일 얼굴은 미리 뜬다 (예고).
## 3페이즈는 둘 다 상시 뜬다.
func _refresh_faces() -> void:
	if phase >= 3:
		_set_faces(true, true)
		return
	_set_faces(_act[LEFT] != &"" or _turn == LEFT, _act[RIGHT] != &"" or _turn == RIGHT)


func _set_faces(left: bool, right: bool) -> void:
	_left_awake = left
	_right_awake = right
	door_left.self_modulate = FACE_AWAKE if left else FACE_DIM
	door_right.self_modulate = FACE_AWAKE if right else FACE_DIM


## 전조 점멸. 해당 얼굴만 깜빡인다.
func _flash_face(side: int) -> void:
	var pulse: bool = int(_timer[side] * 14.0) % 2 == 0
	var face: Sprite2D = door_left if side == LEFT else door_right
	face.self_modulate = FACE_FLASH if pulse else FACE_AWAKE


## 증기 예고. 남은 시간이 줄수록 붉게 달아오른다.
func _heat_face(side: int) -> void:
	var total: float = maxf(0.01, steam_windup * _steam_windup_scale())
	var t: float = clampf(1.0 - _timer[side] / total, 0.0, 1.0)
	var face: Sprite2D = door_left if side == LEFT else door_right
	face.self_modulate = FACE_AWAKE.lerp(FACE_HOT, t)


# --- 여닫이 문 ---


## 문을 여는 갈래가 하나 늘거나 줄었다. 남은 갈래가 없을 때만 닫는다.
## 3페이즈에서 소환(좌)과 바람(우)이 겹칠 때, 먼저 끝난 쪽이 문을 닫아 버리는 것을 막는다.
func _hold_doors(open: bool) -> void:
	_door_hold = maxi(0, _door_hold + (1 if open else -1))
	_set_doors_open(_door_hold > 0)


## 열 때는 밀려 열리듯 빠르게 나갔다 잦아들고, 닫을 때는 천천히 당겨졌다가 쾅 닫힌다.
func _set_doors_open(open: bool) -> void:
	_kill_door_tween()
	_door_tween = create_tween()
	_door_tween.set_trans(Tween.TRANS_CUBIC)
	_door_tween.set_ease(Tween.EASE_OUT if open else Tween.EASE_IN)
	_door_tween.tween_method(
		_apply_door_swing, _door_open, 1.0 if open else 0.0, DOOR_SWING_TIME
	)
	if open:
		return
	_door_tween.tween_callback(_slam_doors_shut)


func _slam_doors_shut() -> void:
	GameEvents.screen_shake.emit(2.4, 0.18)


## 가로 폭은 각도의 코사인으로 줄인다. 등속으로 열리는 문의 정면 투영이 실제로 그렇다.
## 균등 축소는 문이 열리는 게 아니라 쪼그라드는 것처럼 보였다.
func _apply_door_swing(t: float) -> void:
	_door_open = t
	var s: float = cos(DOOR_OPEN_ANGLE * t)
	var rise: float = lerpf(1.0, DOOR_OPEN_RISE, t)
	var shade: float = lerpf(1.0, DOOR_OPEN_SHADE, t)
	var shade_color: Color = Color(shade, shade, shade, 1.0)
	var center_y: float = -DOOR_HALF_H * rise
	door_left.scale = Vector2(s, rise)
	door_right.scale = Vector2(s, rise)
	door_left.position = Vector2(-GATE_INNER_W + DOOR_HALF * s, center_y)
	door_right.position = Vector2(-DOOR_HALF * s, center_y)
	door_left.modulate = shade_color
	door_right.modulate = shade_color


func _kill_door_tween() -> void:
	if _door_tween != null and _door_tween.is_valid():
		_door_tween.kill()
	_door_tween = null


func _apply_hurt_rect(rect_position: Vector2, rect_size: Vector2) -> void:
	var rect: RectangleShape2D = hurt_shape.shape as RectangleShape2D
	if rect != null:
		rect.size = rect_size
	hurt_shape.position = rect_position


# --- 피격, 취소, 사망 ---


## 거체 보스: 피격 경직도 넉백도 행동 취소도 없다. 피격 표시만 남긴다.
func _on_hit_received(amount: int, source_position: Vector2) -> void:
	# 문을 때리는 것도 개전 방법이다. 상호작용 키를 못 찾아도 전투가 시작된다
	if _dormant:
		start_encounter()
	gate.modulate = Color(1.6, 1.4, 1.35)
	var tween: Tween = create_tween()
	tween.tween_property(gate, ^"modulate", Color.WHITE, 0.1)
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate() as DamageNumber
	if number == null:
		return
	number.setup(amount)
	var host: Node = get_parent()
	if host == null:
		host = self
	host.add_child(number)
	number.global_position = Vector2(hurt_shape.global_position.x, source_position.y - 16.0)


## 페이즈 전환과 방 정지가 부른다. 진행 중인 모든 판정과 연출을 물린다.
func _cancel_action() -> void:
	steam_hitbox.deactivate()
	_stop_steam()
	_stop_beam()
	_set_player_wind(0.0)
	_door_hold = 0
	_set_doors_open(false)
	_act = [&"", &""]
	_step = [&"", &""]
	_gap = [gap_time(), gap_time()]
	gate.position = Vector2.ZERO
	gate.scale = Vector2.ONE
	_apply_hurt_rect(STAND_HURT_POS, STAND_HURT_SIZE)


## 사망: 소환수를 함께 소멸시키고 모든 판정을 정리한 뒤 공통 사망으로 간다.
func _on_died() -> void:
	_set_player_wind(0.0)
	_stop_beam()
	steam_hitbox.deactivate()
	_stop_steam()
	_prune_minions()
	for minion: EnemyBase in _minions:
		minion.health.apply_damage(minion.health.maximum)
	_minions.clear()
	super()
