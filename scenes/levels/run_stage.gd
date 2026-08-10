extends Node2D

## M2 런 스테이지: 노드 맵 기반 진행 루프 (docs/RUN_STRUCTURE.md 3장 진행 흐름).
##
## 방 클리어 -> 우측 귀문 뿅 -> 진입 -> 지도 펼침 -> 다음 노드 선택 -> 그 방 로드.
## 방을 한 번에 하나씩 RoomHost에 로드하고, 노드 종류를 방 씬에 매핑한다.
## 현재 존재하는 방이 적어 없는 종류는 임시 방(choice_stub, 전투방)으로 대체한다.
##
## M1 stage.gd(고정 6방 루트)는 조작감 검증용으로 그대로 유지한다. 이 씬은 별개다.
## 맵 데이터(RunMap)는 씬과 분리한 순수 자료구조라 단위 테스트가 된다.

## 방 폭을 읽지 못했을 때 쓰는 기본 가로 크기 (docs/ROOM_SPEC.md 1장 표준 방)
const DEFAULT_ROOM_WIDTH: int = 960
## 보이지 않는 경계를 방 바깥으로 밀어 두는 여유 (px)
const BOUND_MARGIN: float = 4.0
## 방 우측 끝에서 귀문까지의 안쪽 여백 (px)
const EXIT_DOOR_INSET: float = 44.0
## 이벤트방 추첨용 교란값. 전투방 추첨과 다른 난수열을 쓰게 한다
const EVENT_SALT: int = 522133279
## 미니게임 시드 교란값. 방 배치 난수열과 갈라놓는다
const MINIGAME_SALT: int = 1900123901
## 유물 추첨 시드 교란값
const RELIC_SALT: int = 715639201
const SEED_MASK: int = 0x7FFFFFFF

## 이벤트 결과 id와 미니게임 씬의 대응 (docs/act1/EVENTS.md 3장 발동 방식).
## 여기 없는 결과는 미니게임 없이 방 안 전개만으로 처리한다
const MINIGAME_BY_OUTCOME: Dictionary = {
	&"act1_ssireum_challenge": &"ssireum",
	&"act1_fence_den": &"chase",
}
## 내기방 노드가 여는 미니게임 (별도 노드 종류, EVENTS 7장)
const GAMBLE_OUTCOME_ID: StringName = &"gamble"
## 디버그로 미니게임을 열 때 채워 주는 최소 노잣돈. 돈이 없으면 노름과 추격이 곧바로 끝난다
const DEBUG_MIN_COINS: int = 120
## 런 종료(보스 격파) 뒤 음악을 내리는 시간 (초). 종료 화면은 무음이다 (2026-08-10 S1)
const RUN_END_FADE: float = 1.0
## 사망 시 음악을 끊는 시간 (초). 정적으로 떨어뜨렸다가 허브 곡으로 넘어간다
const DEATH_FADE: float = 0.6

## 전투 노드용 방 후보
@export var combat_rooms: Array[PackedScene] = []
## 이벤트 노드용 방 후보 (플랫포밍 방을 이벤트 내용으로 재사용)
@export var event_rooms: Array[PackedScene] = []
## 신당, 상점, 내기, 쉼터 노드용 임시 방
@export var choice_room: PackedScene
## 쉼터 노드용 방. 회복과 강화 중 택 1을 준다
@export var rest_room: PackedScene
## 몸주 신당(첫 신당) 방. 골목 사당 (요청서 022 C-1)
@export var shrine_mongju_room: PackedScene
## 권능 신당(이후 신당) 방. 돌무더기 서낭당 (요청서 022 C-2)
@export var shrine_boon_room: PackedScene
## 내기방 노드용 방 (노름판, docs/act1/EVENTS.md 7장)
@export var gamble_room: PackedScene
## 상점 방. 아직 만들지 않았다. 비어 있으면 신당으로 대체하고 경고를 남긴다
@export var shop_room: PackedScene
## 중간보스 노드용 임시 방
@export var midboss_room: PackedScene
## 정규 보스 전용 아레나 (docs/act1/BOSS.md 8장). combat_rooms에는 포함하지 않는다
## (RUN_STRUCTURE 6장). 시드 랜덤 지정 구조는 그대로 두되, 2026-08-10 사용자 확정으로
## 지금은 문얼굴 대문 광장 하나만 넣는다. 방망이(시장 중앙 광장)는 아직 구현이 끝나지
## 않아 런에 나오면 안 된다. 구현이 끝나면 씬에서 room_boss_jungang_gwangjang.tscn을
## 이 배열에 다시 넣기만 하면 되고 코드는 손댈 필요가 없다.
@export var regular_boss_rooms: Array[PackedScene] = []
## 고정 시드 (randomize_seed가 false일 때 사용)
@export var map_seed: int = 0
## 시작 시 시드를 무작위로 뽑을지 여부
@export var randomize_seed: bool = true
## 사망이나 완주 후 허브 반송까지의 지연 (초)
@export var restart_delay: float = 1.2
## 보스 완주 시 지급하는 여의주 조각 (유지 재화, docs/GDD.md 4장)
@export var boss_yeouiju_reward: int = 1
## 이 y보다 아래로 떨어지면 낙사로 처리한다 (px)
@export var fall_limit_y: float = 640.0
## 낙사 시 잃는 체력
@export var fall_damage: int = 10
## 카메라 세로 상한 (px)
@export var camera_limit_top: int = -8
## 카메라 세로 하한 (px)
@export var camera_limit_bottom: int = 352
## 씨름 연타 대결 (이벤트 결과 act1_ssireum_challenge)
@export var ssireum_minigame: PackedScene
## 노름판 (내기방 노드)
@export var gamble_minigame: PackedScene
## 장물아비 추격 달리기 (이벤트 결과 act1_fence_den)
@export var chase_minigame: PackedScene

var _run_map: RunMap = null
var _room: Room = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## 시작 노드부터 현재까지 지나온 노드 id 순서. 중단 저장의 지도 복원에 쓴다
var _path: Array[int] = []
## 이번 런에서 이미 쓴 전투방 템플릿 인덱스 (docs/RUN_STRUCTURE.md 6장 한 런 2회 금지)
var _used_combat: Array[int] = []
## 1막 이벤트 결과 풀 (docs/act1/EVENTS.md 8.4)
var _event_pool: EventPool = null
## 런 시작 시점의 선행 조건 스냅샷. 저장에 남겨 이어하기에서 같은 확정을 재현한다 (9.3)
var _event_flags: Dictionary = {}
## 지금 도는 미니게임의 결과 id (결과 신호에 실어 보낸다)
var _pending_outcome: StringName = &""
## 디버그 방 강제 지정. 값이 있으면 다음 한 번의 방 로드에만 이 씬을 쓴다 (검증 전용).
var _debug_room: PackedScene = null

@onready var player: Player = $Player as Player
@onready var background: BgAct1 = $BgAct1 as BgAct1
@onready var room_host: Node2D = $RoomHost as Node2D
@onready var exit_door: ExitDoor = $ExitDoor as ExitDoor
@onready var node_map: NodeMap = $Ui/NodeMap as NodeMap
@onready var minigame_host: MinigameHost = $MinigameHost as MinigameHost
@onready var event_popup: EventResultPopup = $Ui/EventResultPopup as EventResultPopup
@onready var test_end_screen: TestEndScreen = $TestEndScreen as TestEndScreen
@onready var bound_left: CollisionShape2D = $Bounds/Left as CollisionShape2D
@onready var bound_right: CollisionShape2D = $Bounds/Right as CollisionShape2D


func _ready() -> void:
	exit_door.entered.connect(_on_door_entered)
	node_map.node_chosen.connect(_on_node_chosen)
	minigame_host.finished.connect(_on_minigame_finished)
	GameEvents.player_died.connect(_on_player_died)
	_apply_weapon_state()
	DevMode.set_hints(
		PackedStringArray(
			[
				"` 개발자 모드 끄기",
				"P 스테이지 클리어",
				"1 씨름  2 노름  3 추격",
				"5~8 유물 지급",
				"9 문얼굴  0 방망이",
			]
		)
	)
	if SaveGame.is_resuming():
		_resume_from_save(SaveGame.consume_resume())
	else:
		_start_new_run()
	_load_current_room()


## 런의 플레이어는 허브와 별개 인스턴스라 무기를 다시 붙여야 한다.
## player._ready가 빈손(WeaponKind.NONE)으로 시작하므로 이 호출이 없으면
## 인게임에 공격 수단이 없다 (2026-08-10 수정). 조건은 허브와 같다.
func _apply_weapon_state() -> void:
	if GameState.chasa_intro_done:
		player.apply_start_weapon()
	else:
		player.unequip_melee_weapon()


## 새 런 시작. 지도를 새로 생성하고 경로를 시작 노드로 초기화한다.
func _start_new_run() -> void:
	RunState.begin_run()
	var use_seed: int = map_seed
	if randomize_seed:
		_rng.randomize()
		use_seed = int(_rng.randi())
	else:
		_rng.seed = map_seed
	_run_map = RunMap.new()
	_run_map.generate(use_seed)
	_event_flags = EventPool.run_flags()
	_resolve_events()
	_path = [_run_map.current_id()]
	_used_combat = _reserved_combat_indices()


## 중단 저장에서 재개. 런 상태는 타이틀 이어하기에서 이미 복원됐고, 여기서는 지도만 되살린다.
func _resume_from_save(data: Dictionary) -> void:
	RunState.resume_run()
	var use_seed: int = int(data.get("map_seed", 0))
	_rng.seed = use_seed
	_run_map = RunMap.new()
	_run_map.generate(use_seed)
	_event_flags = EventPool.normalize_flags(data.get("event_flags", {}))
	var saved_health: int = int(data.get("health", 0))
	if saved_health > 0:
		player.health.set_current(saved_health)
	_resolve_events()
	_path = []
	for id_value: Variant in data.get("path", []):
		_path.append(int(id_value))
	_replay_path()
	_rebuild_used_combat()


## 이벤트 노드의 P/N 결과를 시드로 확정한다 (docs/act1/EVENTS.md 9.1).
## 맵 시드와 플래그 스냅샷만으로 정해지므로 이어하기에서 같은 결과가 나온다 (E10).
func _resolve_events() -> void:
	_event_pool = EventPool.load_act1(true)
	EventResolver.new(_event_pool).resolve(_run_map, _event_flags)


## 저장된 경로대로 지도의 현재 노드를 앞으로 이동시킨다.
func _replay_path() -> void:
	if _path.is_empty():
		_path = [_run_map.current_id()]
		return
	for i: int in range(1, _path.size()):
		_run_map.choose(_path[i])


## 현재 방 시작 상태를 파일에 저장한다 (방 진입마다 호출).
func _autosave() -> void:
	if _run_map == null:
		return
	var data: Dictionary = RunState.to_save()
	data["version"] = SaveGame.SAVE_VERSION
	data["map_seed"] = _run_map.seed_value
	data["path"] = _path.duplicate()
	data["event_flags"] = EventPool.flags_to_save(_event_flags)
	# 체력이 방 사이로 이어지므로 저장해야 이어하기가 회복 수단이 되지 않는다
	data["health"] = player.health.current()
	SaveGame.write(data)


func _process(_delta: float) -> void:
	if player.is_dead() or player.global_position.y <= fall_limit_y:
		return
	_recover_from_fall()


## 디버그 (검증용, 디버그 빌드 한정).
## 1~3은 미니게임을 그 자리에서 연다. 해당 노드를 밟을 때까지 기다리지 않고 체감을 본다.
## 5~8은 상점과 보물방이 아직 없어 진품 유물을 키로 지급한다.
## 9와 0은 보스 아레나를 그 자리에서 연다. 보스 노드는 L10 하나뿐이라 정식 경로로는
## 검증에 한 런이 통째로 든다 (docs/act1/BOSS.md 9장 확인 목록).
func _unhandled_input(event: InputEvent) -> void:
	if not DevMode.enabled:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_P:
			_debug_clear_room()
		KEY_1:
			_debug_open(&"act1_ssireum_challenge", ssireum_minigame)
		KEY_2:
			_debug_open(GAMBLE_OUTCOME_ID, gamble_minigame)
		KEY_3:
			_debug_open(&"act1_fence_den", chase_minigame)
		KEY_5:
			RunState.grant_relic_by_id(&"relic_pat")
		KEY_6:
			RunState.grant_relic_by_id(&"relic_dogtag")
		KEY_7:
			RunState.grant_relic_by_id(&"relic_notdaeya")
		KEY_8:
			RunState.grant_relic_by_id(&"relic_lantern_wick")
		KEY_9:
			_debug_load_boss(0)
		KEY_0:
			_debug_load_boss(1)


## 개발자 모드: 현재 방을 즉시 클리어한다. 전투방은 적을 지우고 귀문을 연다.
## 보스방이면 정식 클리어 경로를 그대로 타서 런 완주 처리가 된다.
## 미니게임이 열려 있으면 무시한다 (그쪽은 자체 종료 경로가 있다).
func _debug_clear_room() -> void:
	if _room == null or minigame_host.is_open():
		return
	_room.force_clear()


## 디버그: 보스 아레나를 현재 노드 자리에서 곧바로 연다 (풀 인덱스).
## 강제 지정은 이 한 번의 로드에만 걸리고 저장에는 남지 않는다. 다음 방부터는 정식 경로다.
## 풀에 문얼굴만 있는 동안 1번(0 키)은 조용히 아무 일도 하지 않는다.
func _debug_load_boss(index: int) -> void:
	if index < 0 or index >= regular_boss_rooms.size():
		return
	if regular_boss_rooms[index] == null or minigame_host.is_open():
		return
	_debug_room = regular_boss_rooms[index]
	_load_current_room()


## 디버그: 현재 노드 자리에서 미니게임을 연다. 결과 처리는 정식 경로와 같다.
## 노잣돈이 없으면 노름판과 추격이 곧바로 끝나므로 최소 소지금을 채워 준다.
func _debug_open(outcome_id: StringName, scene: PackedScene) -> void:
	if scene == null or minigame_host.is_open():
		return
	if RunState.coins < DEBUG_MIN_COINS:
		RunState.add_coins(DEBUG_MIN_COINS - RunState.coins)
	var node: RunMapNode = _run_map.current_node()
	if node == null:
		return
	var config: Dictionary = _minigame_config(node)
	if outcome_id == &"act1_fence_den" and config["params"].is_empty():
		config["params"] = _debug_chase_params()
	_pending_outcome = outcome_id
	AudioDirector.play_bgm(AudioDirector.Track.EVENT)
	GameEvents.event_started.emit(outcome_id)
	minigame_host.open(scene, config)


## 디버그로 열 때 쓰는 추격 파라미터. 결과 .tres의 params와 같은 초안값이다.
func _debug_chase_params() -> Dictionary:
	return {
		"min_coins_trigger": 0,
		"steal_on_entry_rate": 0.2,
		"return_bonus_mult": 1.2,
		"min_thief_count": 3,
		"max_thief_count": 5,
		"rich_coins": 200,
	}


## 현재 노드에 대응하는 방을 로드하고 플레이어를 배치한다.
func _load_current_room() -> void:
	for child: Node in room_host.get_children():
		child.queue_free()
	var node: RunMapNode = _run_map.current_node()
	var scene: PackedScene = _scene_for_kind(node.kind)
	var track: int = _bgm_for_kind(node.kind)
	if _debug_room != null:
		scene = _debug_room
		track = AudioDirector.Track.BOSS
		_debug_room = null
	if scene == null:
		push_error("노드 종류에 대응하는 방 씬이 없다: %d" % node.kind)
		return
	_room = scene.instantiate() as Room
	# 방은 자기 층을 모른다. 트리에 붙기 전에 층 예산과 배치 시드를 넣어야
	# Room._ready의 슬롯 채우기가 예산제로 돈다 (docs/ROOM_SPEC.md 3장)
	_room.configure(_room_context(node))
	room_host.add_child(_room)
	_room.position = Vector2.ZERO
	if not _room.cleared.is_connected(_on_room_cleared):
		_room.cleared.connect(_on_room_cleared)
	exit_door.reset_door()
	var bg_seed: int = RoomRoster.background_seed(_run_map.seed_value, node.id)
	background.rebuild(bg_seed, BgAct1.preset_from_name(_room.bg_preset))
	_apply_room_bounds()
	_place_player()
	_update_camera_limits()
	AudioDirector.set_music_ducked(false)
	AudioDirector.play_bgm(track)
	_autosave()
	_start_node_event(node)


## 이 노드가 이벤트나 내기를 여는 자리면 시작한다 (docs/act1/EVENTS.md 3장, 7장).
## 미니게임이 있는 결과는 오버레이를 띄우고, 없는 결과는 즉시 효과로 처리한다.
## 미니게임이 도는 동안 트리는 멈추므로 방 전투는 끝난 뒤에 시작된다.
func _start_node_event(node: RunMapNode) -> void:
	if node.kind == RunMap.Kind.GAMBLE:
		_open_minigame(node, GAMBLE_OUTCOME_ID, gamble_minigame)
		return
	if node.kind != RunMap.Kind.EVENT or not node.has_outcome():
		return
	var kind: StringName = MINIGAME_BY_OUTCOME.get(node.outcome_id, &"")
	if kind != &"":
		_open_minigame(node, node.outcome_id, _minigame_scene(kind))
		return
	_apply_immediate_outcome(node)


func _open_minigame(node: RunMapNode, outcome_id: StringName, scene: PackedScene) -> void:
	if scene == null:
		return
	_pending_outcome = outcome_id
	GameEvents.event_started.emit(outcome_id)
	minigame_host.open(scene, _minigame_config(node))


## 미니게임이 없는 결과. params의 즉시 효과만 적용하고 결과 팝업을 띄운다.
## 방 안 전개가 필요한 결과(좌판 밀도, 등불 소등 등)는 후속 세션에서 붙인다.
func _apply_immediate_outcome(node: RunMapNode) -> void:
	if _event_pool == null:
		return
	var outcome: EventOutcome = _event_pool.find_by_id(node.outcome_id)
	if outcome == null:
		return
	var result: Dictionary = Minigame.empty_result(outcome.display_name)
	var reward: int = int(outcome.params.get("coin_reward", 0))
	var cost: int = int(outcome.params.get("coin_cost", 0))
	result["coins_delta"] = reward - cost
	result["won"] = outcome.is_positive()
	if reward > 0:
		result["gains"] = PackedStringArray(["엽전 %d닢" % reward])
	if cost > 0:
		result["losses"] = PackedStringArray(["엽전 %d닢" % cost])
	_pending_outcome = outcome.id
	GameEvents.event_started.emit(outcome.id)
	_on_minigame_finished(result)


func _minigame_scene(kind: StringName) -> PackedScene:
	match kind:
		&"ssireum":
			return ssireum_minigame
		&"chase":
			return chase_minigame
	return null


## 미니게임 시작 조건. 시드는 지도 시드와 노드 id에서만 파생해 이어하기에서 재현된다.
func _minigame_config(node: RunMapNode) -> Dictionary:
	var base: int = RoomRoster.placement_seed(_run_map.seed_value, node.id)
	var outcome: EventOutcome = null
	if _event_pool != null and node.has_outcome():
		outcome = _event_pool.find_by_id(node.outcome_id)
	return {
		"seed": (base + MINIGAME_SALT) & SEED_MASK,
		"coins": RunState.coins,
		"params": outcome.params if outcome != null else {},
	}


## 미니게임 결과를 런 상태에 반영하고 결과 팝업을 띄운다 (EVENTS 10.2 결과 피드백).
func _on_minigame_finished(result: Dictionary) -> void:
	var coins_delta: int = int(result.get("coins_delta", 0))
	if coins_delta != 0:
		RunState.add_coins(coins_delta)
	var damage: int = int(result.get("damage", 0))
	if damage > 0:
		player.health.apply_damage(damage)
	_grant_result_relic(result)
	event_popup.show_result(result)
	GameEvents.event_resolved.emit(_pending_outcome, result)
	_pending_outcome = &""
	_autosave()


## 결과가 유물 추첨을 요구하면 떨이 등급에서 하나 뽑는다 (EVENTS 부록 A.4).
## 추첨 시드도 노드에서 파생해 이어하기에서 같은 결과가 나온다.
func _grant_result_relic(result: Dictionary) -> void:
	var chance: float = float(result.get("relic_chance", 0.0))
	if chance <= 0.0:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var base: int = RoomRoster.placement_seed(_run_map.seed_value, _run_map.current_id())
	rng.seed = (base + RELIC_SALT) & SEED_MASK
	if rng.randf() > chance:
		return
	RunState.grant_random_relic(RelicDef.Grade.TTEORI, &"event")


## 방에 넘길 맥락. 진행도와 위협 예산과 고갈 단계와 배치 시드가 여기서 방으로 들어간다.
## 배경 시드와 배치 시드는 상수가 달라 서로를 흔들지 않는다 (scripts/map/room_roster.gd).
##
## 2026-08-10: 자유 이동 전환(2026-08-06)으로 RunMapNode의 layer가 폐기됐는데 이 함수만
## 옛 필드를 계속 봐서 방 로드가 죽었다. 예산은 RunMap.threat_budget_for(진행도 기반)로 옮긴다.
func _room_context(node: RunMapNode) -> Dictionary:
	return {
		"depth": node.depth,
		"budget": _run_map.threat_budget_for(node.id),
		"depletion": _run_map.depletion_stage(),
		"seed": RoomRoster.placement_seed(_run_map.seed_value, node.id),
		"empty": _is_revisit(node.id),
	}


## 이미 지났던 노드인가. 되짚어 온 방은 비어 있어야 한다
## (docs/RUN_STRUCTURE.md 11.5, docs/act1/ENEMIES.md 6장).
##
## node.visited 를 쓰면 안 된다. _on_node_chosen 이 _run_map.choose()(그 안에서 방문
## 표시)를 먼저 부르고 방을 나중에 싣기 때문에 진입 시점에는 늘 true다. _path 는 이번
## 진입까지 포함하므로 두 번 이상 나오면 되짚어 온 것이다.
func _is_revisit(node_id: int) -> bool:
	return _path.count(node_id) > 1


## 노드 종류에 대응하는 배경음악 (2026-08-10 S1, docs/DECISIONS.md).
## 전용 곡이 없는 자리는 인접 곡이 맡는다: 중간보스와 상점과 쉼터는 스테이지 곡,
## 내기방은 이벤트 곡이다. 생기 몰림은 곡을 바꾸지 않고 그 방의 곡을 그대로 쓴다
func _bgm_for_kind(kind: int) -> int:
	match kind:
		RunMap.Kind.BOSS:
			return AudioDirector.Track.BOSS
		RunMap.Kind.SHRINE:
			return AudioDirector.Track.SHRINE
		RunMap.Kind.EVENT, RunMap.Kind.GAMBLE:
			return AudioDirector.Track.EVENT
	return AudioDirector.Track.STAGE


func _scene_for_kind(kind: int) -> PackedScene:
	match kind:
		RunMap.Kind.COMBAT:
			return _combat_scene()
		RunMap.Kind.EVENT:
			var event_scene: PackedScene = _pick_from(event_rooms, EVENT_SALT)
			return event_scene if event_scene != null else _combat_scene()
		RunMap.Kind.MIDBOSS:
			return midboss_room if midboss_room != null else _combat_scene()
		RunMap.Kind.BOSS:
			return _boss_scene()
		RunMap.Kind.SHRINE:
			return _shrine_scene()
		RunMap.Kind.REST:
			return rest_room if rest_room != null else choice_room
		RunMap.Kind.GAMBLE:
			return gamble_room if gamble_room != null else choice_room
		RunMap.Kind.SHOP:
			# 상점 방은 아직 없다. 지도에 상점이 평균 1.8개 뜨는데 전부 신당이 열리므로
			# 1막 정체성인 엽전 경제가 런에서 돌지 않는다. 조용히 넘어가지 않게 남긴다
			# (docs/PROGRESS.md 미해결 항목, 2026-08-10 전체 검토에서 재확인)
			if shop_room != null:
				return shop_room
			push_warning("상점 방 씬이 없다: 신당으로 대체한다 (엽전 경제 미구현)")
			return _shrine_scene()
	push_warning("노드 종류 %d 에 대응하는 방이 없다: 기본 방으로 대체한다" % kind)
	return choice_room


## 전투방을 고른다. 이번 런에서 이미 쓴 템플릿은 후보에서 뺀다.
func _combat_scene() -> PackedScene:
	var index: int = _consume_combat_index(_run_map.current_id())
	return combat_rooms[index] if index >= 0 else null


func _consume_combat_index(node_id: int) -> int:
	var index: int = RoomRoster.pick(
		_run_map.seed_value, node_id, combat_rooms.size(), _used_combat
	)
	if index >= 0 and not _used_combat.has(index):
		_used_combat.append(index)
	return index


## 정규 보스 풀에서 1종을 시드로 고른다 (BOSS.md 1장, 5장. 중간보스와 같은 방식).
## 보스 노드는 런당 1개뿐이라 used를 넘기지 않는다: 매번 전체 풀에서 고르되, 지도 시드와
## 노드 id로만 파생하므로 같은 런은 항상 같은 결과가 나오고(재현성), 진입 전까지는 이 값이
## 어디에도 노출되지 않는다(비공개).
##
## 2026-08-10 현재 풀에는 문얼굴 하나뿐이라 결과도 항상 문얼굴이다. 선택 로직을 없애지
## 않은 이유는 방망이 구현이 끝나면 씬의 배열에 한 줄 넣는 것만으로 되돌아가야 하기 때문이다.
func _boss_scene() -> PackedScene:
	if regular_boss_rooms.is_empty():
		return _combat_scene()
	var node_id: int = _run_map.current_id()
	var index: int = RoomRoster.pick(_run_map.seed_value, node_id, regular_boss_rooms.size(), [])
	return regular_boss_rooms[index] if index >= 0 else null


## 중간보스가 빌려 쓰는 전투방 템플릿은 전투 풀에서 미리 뺀다 (RUN_STRUCTURE 6장).
## 정규 보스는 2026-08-06부터 전용 아레나(regular_boss_rooms)를 쓰므로 combat_rooms를
## 빌리지 않는다.
func _reserved_combat_indices() -> Array[int]:
	var reserved: Array[int] = []
	for index: int in range(combat_rooms.size()):
		if combat_rooms[index] == midboss_room:
			reserved.append(index)
	return reserved


## 이어하기: 지나온 경로를 다시 훑어 이미 쓴 전투방 템플릿을 복원한다.
## 현재 노드는 뒤이어 _load_current_room이 처리하므로 마지막 항목은 건너뛴다.
func _rebuild_used_combat() -> void:
	_used_combat = _reserved_combat_indices()
	for i: int in range(_path.size() - 1):
		var node: RunMapNode = _run_map.get_node_by_id(_path[i])
		if node != null and node.kind == RunMap.Kind.COMBAT:
			_consume_combat_index(_path[i])


## 신당 방을 고른다. 몸주가 없으면 첫 신당이므로 골목 사당, 있으면 돌무더기 서낭당이다.
## 판정 기준은 RunState.roll_shrine의 분기(boons.has_active())와 같아야 방과 내용이 어긋나지 않는다.
func _shrine_scene() -> PackedScene:
	var scene: PackedScene = (
		shrine_mongju_room if not RunState.boons.has_active() else shrine_boon_room
	)
	return scene if scene != null else choice_room


## 후보 풀에서 하나를 결정적으로 고른다. 지도 시드와 노드 id에서 파생하므로
## 중단 저장 이어하기에서 같은 방이 다시 나온다.
func _pick_from(pool: Array[PackedScene], salt: int) -> PackedScene:
	if pool.is_empty():
		return null
	var base: int = RoomRoster.placement_seed(_run_map.seed_value, _run_map.current_id())
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = (base + salt) & SEED_MASK
	return pool[rng.randi_range(0, pool.size() - 1)]


func _place_player() -> void:
	if _room == null:
		return
	# 방 사이에는 체력을 이어간다. 회복은 쉼터와 아이템 같은 명시적 수단만 준다
	player.respawn(_room.spawn_point.global_position, false)


## 방 폭에 맞춰 보이지 않는 경계와 귀문을 옮긴다 (docs/ROOM_SPEC.md 1~2장).
## 표준 방은 960이고 신당 같은 소형 방은 480이다.
func _apply_room_bounds() -> void:
	var width: float = float(_current_room_width())
	bound_left.position.x = -BOUND_MARGIN
	bound_right.position.x = width + BOUND_MARGIN
	exit_door.position.x = width - EXIT_DOOR_INSET


func _current_room_width() -> int:
	return _room.room_width if _room != null else DEFAULT_ROOM_WIDTH


func _update_camera_limits() -> void:
	var camera: Camera2D = player.get_node_or_null(^"Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = 0
	camera.limit_right = _current_room_width()
	camera.limit_top = camera_limit_top
	camera.limit_bottom = camera_limit_bottom
	camera.reset_smoothing()


func _recover_from_fall() -> void:
	if _room == null:
		return
	player.global_position = _room.spawn_point.global_position
	player.velocity = Vector2.ZERO
	player.health.apply_damage(fall_damage)


func _on_room_cleared(_elapsed: float) -> void:
	if _run_map.is_boss(_run_map.current_id()):
		_finish_run()
		return
	exit_door.appear()


func _on_door_entered() -> void:
	get_tree().paused = true
	AudioDirector.set_music_ducked(true)
	node_map.open(_run_map)


func _on_node_chosen(node_id: int) -> void:
	get_tree().paused = false
	node_map.close()
	_run_map.choose(node_id)
	_path.append(node_id)
	_load_current_room()


## 보스를 잡고 완주했다. 여의주 조각을 은행에 넣고(유지) 나머지는 리셋(소멸)한다.
## 2막이 없어 이어질 곳이 없으므로 임시 테스트 종료 화면을 띄운다 (2026-08-08).
## 2막이 붙으면 test_end_screen 호출을 지우고 다음 막 진입으로 바꾼다.
func _finish_run() -> void:
	AudioDirector.stop_bgm(RUN_END_FADE)
	GameState.add_yeouiju(boss_yeouiju_reward)
	SaveGame.clear()
	await get_tree().create_timer(restart_delay).timeout
	RunState.reset_run()
	test_end_screen.open()


## 사망은 소멸: 유물, 권능, 노잣돈을 비운다. 여의주와 해금은 GameState라 남는다.
func _on_player_died() -> void:
	AudioDirector.stop_bgm(DEATH_FADE)
	SaveGame.clear()
	await get_tree().create_timer(restart_delay).timeout
	RunState.reset_run()
	SceneRouter.goto_hub()
