extends Node2D

## 시작 허브: 저승 초입 접수청 (hub).
##
## 회귀 지점이자 준비 공간. player.tscn과 block.tscn을 재사용한다.
## NPC와 서비스는 플레이스홀더이며 GameState 해금으로 표시를 제어한다.
## 상호작용은 대상 근처에서 move_up(위). docs/DESIGN_HUB.md.
##
## 시작 흐름 (5장, D12 확정): 첫 런은 차사 대화를 마치고 접수 관원에게 지도를
## 받아야 상행문이 열린다. 두 대상이 스폰에서 상행문까지의 편도 동선 위에
## 순서대로 있어 되돌아가는 이동이 없다. 두 번째 런부터는 조건이 없다.

const HUB_WIDTH: int = 1440
const CAMERA_TOP: int = -8
const CAMERA_BOTTOM: int = 180
const INTERACT_RANGE: float = 30.0
## 상호작용 대상 머리 위 프롬프트 기본 위치. 대상이 prompt_offset을 주면 그것을 쓴다.
## 라벨 폭이 96이고 가운데 정렬이라 절반인 48을 왼쪽으로 밀어야 대상 위 정중앙에 온다
const PROMPT_OFFSET: Vector2 = Vector2(-48.0, -64.0)
const MESSAGE_TIME: float = 2.5
const CROWD_BASE: int = 2
## 첫 런 진입 직후 차사 호출 토스트까지의 지연 (초)
const CALL_DELAY: float = 0.8

var _interactables: Array[Dictionary] = []
var _active: Dictionary = {}
var _message_token: int = 0
var _last_idle_index: int = -1
## 접수 관원 반복 설명 순서. 허브에 머무는 동안만 유지하면 되므로 저장하지 않는다
var _clerk_explain_index: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var player: Player = $Player as Player
@onready var spawn_point: Marker2D = $SpawnPoint as Marker2D
@onready var crowd_root: Node2D = $Crowd as Node2D
@onready var prompt_label: Label = %PromptLabel
@onready var message_label: Label = %MessageLabel
@onready var dialogue: DialogueBox = %DialogueBox
@onready var reward_popup: EventResultPopup = %RewardPopup


func _ready() -> void:
	AudioDirector.play_bgm(AudioDirector.Track.HUB)
	_rng.randomize()
	_build_interactable_config()
	_place_player()
	_apply_unlocks()
	GameState.unlock_changed.connect(_on_unlock_changed)
	prompt_label.visible = false
	message_label.text = ""
	dialogue.finished.connect(_on_dialogue_finished)
	dialogue.effect_fired.connect(_on_dialogue_effect)
	var saja: NpcActor = get_node_or_null(^"Interactables/NpcChasa/Anim") as NpcActor
	if saja != null:
		saja.spoke.connect(_show_message)
	_apply_weapon_state()
	DevMode.set_hints(
		PackedStringArray(
			[
				"` 개발자 모드 끄기",
				"1~4 해금 토글",
				"0 진행 초기화",
			]
		)
	)
	_update_marks()
	_maybe_call_from_chasa()


func _process(_delta: float) -> void:
	_update_prompt()


## 허브의 무기 상태는 다음 런의 시작 구성이다 (5.4절). 첫 대화 전에는
## 무기가 없고, 받은 뒤에는 저장된 시작 무기가 그대로 장착돼 있다.
## 총은 대장장이 해금 이후에만 고를 수 있다 (WEAPONS 11.3절)
func _apply_weapon_state() -> void:
	if GameState.chasa_intro_done:
		player.apply_start_weapon()
	else:
		player.unequip_melee_weapon()


func _unhandled_input(event: InputEvent) -> void:
	# 대화 중에는 대화 상자가 입력을 먼저 소비한다(process_mode ALWAYS + 소비 처리).
	# 여기까지 온 move_up은 상호작용으로 본다
	if not dialogue.is_active() and event.is_action_pressed(&"move_up"):
		_try_interact()
	_handle_debug(event)


func _build_interactable_config() -> void:
	_interactables = [
		{
			"name": "NpcChasa",
			"unlock": "",
			"prompt": "위: 차사 아무개",
			"message": "",
			"action": "chasa",
		},
		{
			"name": "NpcClerk",
			"unlock": "",
			"prompt": "위: 접수 관원",
			"message": "",
			"action": "clerk",
		},
		{
			"name": "NpcSapsal",
			"unlock": "npc_sapsal",
			"prompt": "위: 삽살개",
			"message": "삽살개가 반긴다. 편의 기능은 준비 중. (미구현)",
			"action": "message",
		},
		{
			"name": "NpcBlacksmith",
			"unlock": "npc_blacksmith",
			"prompt": "위: 대장장이 도깨비",
			"message": "",
			"action": "smith",
		},
		{
			"name": "StationWeaponSwap",
			"unlock": "station_weapon_swap",
			"prompt": "위: 무기 교체대",
			"message": "무기 교체대. 시작 무기 선택은 준비 중. (미구현)",
			"action": "message",
		},
		{
			"name": "StationBoonGacha",
			"unlock": "station_boon_gacha",
			"prompt": "위: 신당(권능 가챠)",
			"message": "신당. 권능 가챠는 준비 중. (미구현)",
			"action": "message",
		},
		{
			"name": "GateAct1",
			"unlock": "",
			"prompt": "위: 1막으로 출발",
			"message": "",
			"action": "stage",
		},
	]


func _place_player() -> void:
	player.respawn(spawn_point.global_position)
	var camera: Camera2D = player.get_node_or_null(^"Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = 0
	camera.limit_right = HUB_WIDTH
	camera.limit_top = CAMERA_TOP
	camera.limit_bottom = CAMERA_BOTTOM
	camera.reset_smoothing()


func _apply_unlocks() -> void:
	for item: Dictionary in _interactables:
		var key: String = str(item.get("unlock", ""))
		if key.is_empty():
			continue
		var node: Node2D = _node_for(item)
		if node != null:
			node.visible = GameState.is_unlocked(key)
	_update_crowd()


func _update_crowd() -> void:
	var shown: int = CROWD_BASE + GameState.unlocked_count() * 2
	var children: Array[Node] = crowd_root.get_children()
	for i: int in range(children.size()):
		var wisp: Node2D = children[i] as Node2D
		if wisp != null:
			wisp.visible = i < shown


## 조건이 남은 대상 머리 위에만 표식을 띄운다 (5.3절 게이팅 UX).
func _update_marks() -> void:
	_set_mark("NpcChasa", not GameState.chasa_intro_done)
	_set_mark("NpcClerk", not GameState.map_received)


## 표식은 글자가 아니라 그림이다. 어두운 배경에서 글자 느낌표가 묻혔다.
## 오르내리는 4프레임이라 켜 두기만 하면 알아서 움직인다
func _set_mark(node_name: String, shown: bool) -> void:
	var mark: CanvasItem = get_node_or_null(
		NodePath("Interactables/" + node_name + "/Mark")
	) as CanvasItem
	if mark == null:
		return
	mark.visible = shown


## 첫 런 진입 직후 차사가 먼저 부른다. 대화 상자가 아니라 토스트라 조작권을
## 뺏지 않으며, 오프닝 마지막이 차사의 끊긴 말이라 서사적으로도 이어진다.
func _maybe_call_from_chasa() -> void:
	if GameState.chasa_intro_done:
		return
	await get_tree().create_timer(CALL_DELAY).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return
	if GameState.chasa_intro_done or dialogue.is_active():
		return
	_show_message(HubLines.CHASA_CALL)


func _update_prompt() -> void:
	if dialogue.is_active():
		prompt_label.visible = false
		return
	var nearest: Dictionary = _nearest_interactable()
	_active = nearest
	if nearest.is_empty():
		prompt_label.visible = false
		return
	var node: Node2D = _node_for(nearest)
	if node == null:
		prompt_label.visible = false
		return
	prompt_label.text = _prompt_text(nearest)
	# 접수 관원처럼 창구 안에 있는 대상은 기본 위치가 카운터에 가려진다. 대상별로
	# 위치를 덮어쓸 수 있게 둔다
	var offset: Vector2 = nearest.get("prompt_offset", PROMPT_OFFSET)
	prompt_label.global_position = node.global_position + offset
	prompt_label.visible = true


## 상행문 프롬프트는 감추지 않는다. 잠긴 동안 표기만 바꾼다. 감추면 그곳이
## 출구라는 사실조차 전달되지 않는다 (5.3절).
func _prompt_text(item: Dictionary) -> String:
	var base: String = str(item.get("prompt", ""))
	if str(item.get("action", "")) == "stage" and not GameState.can_depart():
		return "위: 상행문 (잠김)"
	return base


func _nearest_interactable() -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = INTERACT_RANGE
	for item: Dictionary in _interactables:
		var node: Node2D = _node_for(item)
		if node == null or not node.visible:
			continue
		var distance: float = player.global_position.distance_to(node.global_position)
		if distance <= best_distance:
			best_distance = distance
			best = item
	return best


func _try_interact() -> void:
	if _active.is_empty():
		return
	match str(_active.get("action", "message")):
		"stage":
			_try_depart()
		"chasa":
			_talk_to_chasa()
		"clerk":
			_talk_to_clerk()
		"smith":
			_talk_to_smith()
		_:
			_interact_stub()


## 상행문. 첫 런은 두 조건을 만족해야 열린다. 막히면 씬 전환 없이 토스트만 띄운다.
func _try_depart() -> void:
	if not GameState.can_depart():
		_show_message(GameState.depart_block_reason())
		return
	GameState.advance_run_count()
	SceneRouter.goto_run()


## 차사. 첫 대화가 남았으면 게이팅 대화, 끝났으면 사건 반응 > 진행도 해금 >
## 상시 순환 순서로 하나를 낸다 (5.6절).
func _talk_to_chasa() -> void:
	_startle("NpcChasa")
	if not GameState.chasa_intro_done:
		dialogue.open(HubLines.CHASA_INTRO)
		return
	dialogue.open(_pick_chasa_line())


## 접수 관원. 지도를 아직 안 줬으면 지급 대화, 줬으면 설명을 낸다.
## 설명은 반복 가능하며 "다시 말을 거는 것"을 곧 설명 요청으로 본다 (5.5절).
## 이동 규칙과 기호 설명을 번갈아 낸다. 한 대화에 다 담으면 5.2절 분량 상한
## (6줄)을 넘고, 한 번에 쏟아부으면 읽히지도 않는다
func _talk_to_clerk() -> void:
	_startle("NpcClerk")
	if not GameState.map_received:
		dialogue.open(HubLines.CLERK_MAP)
		return
	var entries: Array = HubLines.CLERK_EXPLAIN
	dialogue.open(entries[_clerk_explain_index % entries.size()])
	_clerk_explain_index += 1


## 대장장이 도깨비. 총을 아직 안 풀었으면 해금 대화, 풀었으면 시작 무기 교체 대화다
## (docs/systems/WEAPONS.md 11.2, 11.3절).
func _talk_to_smith() -> void:
	_startle("NpcBlacksmith")
	if not GameState.gun_unlocked:
		dialogue.open(HubLines.SMITH_GUN)
		return
	dialogue.open(HubLines.SMITH_SWAP)


func _pick_chasa_line() -> Dictionary:
	for entry: Dictionary in HubLines.CHASA_EVENTS:
		var id: String = String(entry.get("id", ""))
		var flag: String = String(entry.get("flag", ""))
		if GameState.has_seen_line(id):
			continue
		if not GameState.is_unlocked(flag):
			continue
		return HubLines.single(id, HubLines.CHASA, String(entry.get("text", "")))
	for entry: Dictionary in HubLines.CHASA_MILESTONES:
		var id: String = String(entry.get("id", ""))
		if GameState.has_seen_line(id):
			continue
		if GameState.run_count < int(entry.get("runs", 0)):
			continue
		return HubLines.single(id, HubLines.CHASA, String(entry.get("text", "")))
	return HubLines.single("chasa_idle", HubLines.CHASA, _next_idle_line())


## 직전에 나온 것은 연속으로 다시 나오지 않는다 (5.6절).
func _next_idle_line() -> String:
	var count: int = HubLines.CHASA_IDLE.size()
	if count <= 1:
		return String(HubLines.CHASA_IDLE[0])
	var index: int = _last_idle_index
	while index == _last_idle_index:
		index = _rng.randi_range(0, count - 1)
	_last_idle_index = index
	return String(HubLines.CHASA_IDLE[index])


func _startle(node_name: String) -> void:
	var actor: NpcActor = get_node_or_null(
		NodePath("Interactables/" + node_name + "/Anim")
	) as NpcActor
	if actor != null:
		actor.react_startled_silent()


func _interact_stub() -> void:
	_show_message(str(_active.get("message", "")))


func _on_dialogue_effect(effect: String) -> void:
	match effect:
		"grant_sword":
			_grant_sword()
		"grant_map":
			_grant_map()
		"unlock_gun":
			_unlock_gun()
		"swap_weapon":
			_swap_start_weapon()


## 환도 지급 (5.4절). 획득 표시는 EventResultPopup 규격을 재사용한다.
## 지급 순간 허브에서도 슬롯 0에 실제로 장착된다. 허브 전투 입력이 전면 허용이라
## 받은 자리에서 바로 휘둘러 보는 것이 곧 획득 피드백이 된다.
func _grant_sword() -> void:
	player.equip_melee_weapon()
	reward_popup.show_result(
		{
			"title": "환도",
			"gains": PackedStringArray(["환도(검)"]),
			"losses": PackedStringArray(),
		}
	)


func _grant_map() -> void:
	reward_popup.show_result(
		{
			"title": "1막 약도",
			"gains": PackedStringArray(["도깨비 시장 약도"]),
			"losses": PackedStringArray(),
		}
	)


## 총 해금 (WEAPONS 11.2절). 해금만 하고 손에 들리지는 않는다.
## 무엇을 들고 나갈지는 다시 말을 걸어 고른다
func _unlock_gun() -> void:
	GameState.unlock_gun()
	reward_popup.show_result(
		{
			"title": "총",
			"gains": PackedStringArray(["총 (시작 무기 선택 해금)"]),
			"losses": PackedStringArray(),
		}
	)


## 시작 무기 교체 (WEAPONS 11.3절). 고른 무기를 허브에서 곧바로 들려 준다.
## 받은 자리에서 바로 휘둘러 보는 것이 곧 교체 피드백이다 (DESIGN_HUB 5.4절 선례)
func _swap_start_weapon() -> void:
	GameState.toggle_start_weapon()
	_apply_weapon_state()
	var picked: String = "총" if GameState.starts_with_gun() else "환도"
	_show_message("시작 무기: %s" % picked)


## 대화를 끝까지 본 시점에 플래그를 세운다. 1회성 대사는 여기서 소진 처리한다.
func _on_dialogue_finished(conversation_id: String) -> void:
	match conversation_id:
		"chasa_intro":
			GameState.mark_chasa_intro_done()
		"clerk_map":
			GameState.mark_map_received()
		"chasa_idle", "clerk_marks", "clerk_route", "":
			pass
		"smith_gun", "smith_swap":
			# 해금과 교체는 대사 소진이 아니라 자체 플래그가 상태를 들고 있다
			pass
		_:
			GameState.mark_line_seen(conversation_id)
	_update_marks()


func _show_message(text: String) -> void:
	if text.is_empty():
		return
	message_label.text = text
	_message_token += 1
	var token: int = _message_token
	await get_tree().create_timer(MESSAGE_TIME).timeout
	# 대기 중에 상행문으로 씬이 바뀌면 허브가 해제된다. 가드가 없으면
	# freed 인스턴스 접근 에러가 난다
	if not is_instance_valid(self) or not is_instance_valid(message_label):
		return
	if token == _message_token:
		message_label.text = ""


func _node_for(item: Dictionary) -> Node2D:
	var node_name: String = str(item.get("name", ""))
	return get_node_or_null(NodePath("Interactables/" + node_name)) as Node2D


func _on_unlock_changed(_key: String, _unlocked: bool) -> void:
	_apply_unlocks()


func _handle_debug(event: InputEvent) -> void:
	if not DevMode.enabled:
		return
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.physical_keycode:
		KEY_1:
			GameState.toggle_unlock("npc_sapsal")
		KEY_2:
			GameState.toggle_unlock("npc_blacksmith")
		KEY_3:
			GameState.toggle_unlock("station_weapon_swap")
		KEY_4:
			GameState.toggle_unlock("station_boon_gacha")
		KEY_0:
			# 게이팅 플래그까지 되돌린다. 첫 런 흐름을 반복 검증하려면 필요하다
			GameState.reset_all()
			_update_marks()
			_show_message("디버그: 진행 상태 초기화")
