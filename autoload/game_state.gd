extends Node

## 게임 전역 상태 (오토로드: GameState).
##
## 오프닝 관람 여부, 시작 흐름 진행 플래그, 허브 해금 플래그를 보관한다.
## 시작 흐름 플래그는 사망해도 유지돼야 하므로 user://meta.json에 저장한다
## (docs/DESIGN_HUB.md 5.3절). RunState의 중단 저장(user://run_suspend.json)은
## 사망과 완주에 삭제되므로 같은 파일에 둘 수 없다.
##
## 여의주 조각과 해금 4키의 영속화는 G7(해금과 허브 서비스)이 이 파일에 얹는다.
## 그때 통째로 들어내기 쉽도록 저장 코드는 META_PATH 상수 하나와
## save_meta/load_meta 두 함수로만 둔다.

## 해금 상태 변화. key, unlocked
signal unlock_changed(key: String, unlocked: bool)

## 여의주 조각 변화. amount
signal yeouiju_changed(amount: int)

## 시작 흐름 진행 플래그 변화. key
signal progress_changed(key: String)

## 다음 런의 시작 무기가 바뀌었다. weapon은 WEAPON_HWANDO 또는 WEAPON_GUN
signal start_weapon_changed(weapon: String)

const META_PATH: String = "user://meta.json"
const META_VERSION: int = 1

## 시작 무기 식별자. 무기 정의(.tres)가 아니라 저장에 쓰는 문자열 키다
const WEAPON_HWANDO: String = "hwando"
const WEAPON_GUN: String = "gun"

## 오프닝 관람 여부. 참이면 타이틀의 게임 시작이 허브로 직행한다.
## 대입만으로 저장되게 세터를 둔다. intro.gd가 곧바로 씬을 넘기므로 별도 호출을
## 요구하면 저장 시점을 놓친다 (docs/DESIGN_INTRO.md 3.3절)
var intro_seen: bool = false:
	set(value):
		if intro_seen == value:
			return
		intro_seen = value
		save_meta()

## 여의주 조각. 메타 재화이며 사망해도 유지된다 (docs/GDD.md 4장 죽음 루프). 소멸 대상은 RunState가 보관한다
var yeouiju_shards: int = 0

## 차사 첫 대화(3단계)를 끝까지 봤다. 환도 지급도 이 시점에 함께 일어난다 (5.3절)
var chasa_intro_done: bool = false

## 접수 관원에게 1막 지도를 받았다 (5.3절)
var map_received: bool = false

## 상행문을 나선 횟수. 상행문 통과 직전에 1 올린다 (5.3절, 6장)
var run_count: int = 0

## 소진된 1회성 대사 id 목록 (5.6절)
var seen_lines: Array[String] = []

## 총을 해금했다. 대장장이 도깨비 첫 대화에서 열린다 (docs/systems/WEAPONS.md 11.2절
## 세 진입로 중 대장장이 해금). 해금 전에는 총 자체가 없으므로 사격과 재장전 입력,
## 총 자세 클립, 탄약 표시가 모두 잠긴다
var gun_unlocked: bool = false

## 다음 런의 시작 무기. WEAPON_HWANDO 또는 WEAPON_GUN이다. 총 해금 전에는 항상 환도이며
## 대장장이 해금 이후에만 총을 고를 수 있다 (WEAPONS 11.3절 대장장이가 슬롯 0을 자유화한다)
var start_weapon: String = WEAPON_HWANDO

## 허브 해금 플래그. 키는 docs/DESIGN_HUB.md 4장 표를 따른다
var _unlocks: Dictionary = {
	"npc_sapsal": false,
	"npc_blacksmith": false,
	"station_weapon_swap": false,
	"station_boon_gacha": false,
}

## load_meta가 값을 되살리는 동안 참. intro_seen 세터가 도로 저장하는 것을 막는다
var _loading: bool = false


func _ready() -> void:
	load_meta()


func is_unlocked(key: String) -> bool:
	return bool(_unlocks.get(key, false))


func set_unlocked(key: String, value: bool = true) -> void:
	if not _unlocks.has(key):
		push_warning("알 수 없는 해금 키: %s" % key)
		return
	if bool(_unlocks[key]) == value:
		return
	_unlocks[key] = value
	unlock_changed.emit(key, value)


func toggle_unlock(key: String) -> void:
	set_unlocked(key, not is_unlocked(key))


func unlocked_count() -> int:
	var count: int = 0
	for key: String in _unlocks:
		if bool(_unlocks[key]):
			count += 1
	return count


func unlock_keys() -> Array:
	return _unlocks.keys()


## 여의주 조각을 더한다 (보스 완주 보상). 음수면 차감한다.
func add_yeouiju(amount: int) -> void:
	if amount == 0:
		return
	yeouiju_shards = maxi(0, yeouiju_shards + amount)
	yeouiju_changed.emit(yeouiju_shards)


## 첫 런 상행문 개방 조건 (5.3절). 두 조건을 모두 만족해야 나갈 수 있다.
func can_depart() -> bool:
	return chasa_intro_done and map_received


## 상행문이 잠긴 이유. 열려 있으면 빈 문자열이다. 프롬프트와 토스트가 쓴다.
func depart_block_reason() -> String:
	if not chasa_intro_done:
		return "차사가 아직 할 말이 남았다."
	if not map_received:
		return "창구에서 약도를 받아 가라."
	return ""


## 차사 첫 대화 완료. 환도 지급도 같은 사건이라 플래그를 나누지 않는다 (5.4절).
func mark_chasa_intro_done() -> void:
	if chasa_intro_done:
		return
	chasa_intro_done = true
	progress_changed.emit("chasa_intro_done")
	save_meta()


## 지도 수령 완료.
func mark_map_received() -> void:
	if map_received:
		return
	map_received = true
	progress_changed.emit("map_received")
	save_meta()


## 상행문 통과. 런 시작 시점에 센다 (6장 근거 참고).
func advance_run_count() -> void:
	run_count += 1
	progress_changed.emit("run_count")
	save_meta()


## 총 해금. 대장장이 도깨비 첫 대화가 부른다 (WEAPONS 11.2절).
## 해금만 하고 시작 무기는 바꾸지 않는다. 무엇을 들고 나갈지는 플레이어가 고른다
func unlock_gun() -> void:
	if gun_unlocked:
		return
	gun_unlocked = true
	progress_changed.emit("gun_unlocked")
	save_meta()


## 다음 런의 시작 무기를 정한다. 총 해금 전에 총을 넣으면 환도로 되돌린다.
func set_start_weapon(weapon: String) -> void:
	var next: String = weapon
	if next != WEAPON_GUN and next != WEAPON_HWANDO:
		push_warning("알 수 없는 시작 무기: %s" % weapon)
		return
	if next == WEAPON_GUN and not gun_unlocked:
		next = WEAPON_HWANDO
	if start_weapon == next:
		return
	start_weapon = next
	start_weapon_changed.emit(start_weapon)
	save_meta()


## 환도와 총을 번갈아 고른다. 해금 전에는 아무 일도 하지 않는다.
func toggle_start_weapon() -> void:
	if not gun_unlocked:
		return
	set_start_weapon(WEAPON_GUN if start_weapon == WEAPON_HWANDO else WEAPON_HWANDO)


## 시작 무기가 총이면 true. 허브와 런 시작이 무기를 붙일 때 본다.
func starts_with_gun() -> bool:
	return gun_unlocked and start_weapon == WEAPON_GUN


## 1회성 대사를 봤는지 여부 (5.6절).
func has_seen_line(id: String) -> bool:
	return seen_lines.has(id)


## 1회성 대사를 소진 처리한다.
func mark_line_seen(id: String) -> void:
	if id.is_empty() or seen_lines.has(id):
		return
	seen_lines.append(id)
	progress_changed.emit("seen_lines")
	save_meta()


## 진행 플래그를 user://meta.json에 쓴다. 플래그가 바뀌는 순간에만 부르고
## 주기 저장은 하지 않는다 (5.3절).
func save_meta() -> void:
	if _loading:
		return
	var data: Dictionary = {
		"version": META_VERSION,
		"intro_seen": intro_seen,
		"chasa_intro_done": chasa_intro_done,
		"map_received": map_received,
		"run_count": run_count,
		"seen_lines": seen_lines,
		"gun_unlocked": gun_unlocked,
		"start_weapon": start_weapon,
	}
	var file: FileAccess = FileAccess.open(META_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("메타 저장 실패: %s" % META_PATH)
		return
	file.store_string(JSON.stringify(data))
	file.close()


## user://meta.json을 읽어 진행 플래그를 되살린다. 없거나 손상이면 기본값을 유지한다.
func load_meta() -> void:
	if not FileAccess.file_exists(META_PATH):
		return
	var file: FileAccess = FileAccess.open(META_PATH, FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("메타 파일 손상: %s" % META_PATH)
		return
	var data: Dictionary = parsed as Dictionary
	_loading = true
	intro_seen = bool(data.get("intro_seen", false))
	chasa_intro_done = bool(data.get("chasa_intro_done", false))
	map_received = bool(data.get("map_received", false))
	run_count = int(data.get("run_count", 0))
	seen_lines.clear()
	for entry: Variant in data.get("seen_lines", []):
		seen_lines.append(String(entry))
	gun_unlocked = bool(data.get("gun_unlocked", false))
	start_weapon = String(data.get("start_weapon", WEAPON_HWANDO))
	# 손상된 저장이나 해금 이전 값이 총으로 남아 있으면 환도로 되돌린다
	if start_weapon != WEAPON_GUN or not gun_unlocked:
		start_weapon = WEAPON_HWANDO
	_loading = false


## 저장 파일을 지운다 (디버그 초기화).
func clear_meta() -> void:
	if FileAccess.file_exists(META_PATH):
		DirAccess.remove_absolute(META_PATH)


## 새 게임 시작 시 상태 초기화 (스켈레톤 디버그용). 저장 파일도 지운다.
func reset_all() -> void:
	intro_seen = false
	yeouiju_shards = 0
	chasa_intro_done = false
	map_received = false
	run_count = 0
	seen_lines.clear()
	gun_unlocked = false
	start_weapon = WEAPON_HWANDO
	start_weapon_changed.emit(start_weapon)
	yeouiju_changed.emit(yeouiju_shards)
	progress_changed.emit("reset")
	for key: String in _unlocks:
		set_unlocked(key, false)
	clear_meta()
