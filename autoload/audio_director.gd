extends Node

## 오디오 총괄 (오토로드: AudioDirector).
##
## 배경음악 재생과 음량 설정을 맡는다. 곡은 전부 루프이고, 장면이 바뀌면 짧은
## 크로스페이드로 갈아탄다. 같은 곡을 다시 요청하면 끊지 않고 그대로 이어간다.
##
## 트리가 멈춰도(일시정지, 지도 펼침, 미니게임 오버레이) 음악은 계속 흘러야 하므로
## process_mode를 ALWAYS로 둔다. 트윈과 저장 타이머도 이 노드에 묶여 같은 규칙을 따른다.
##
## 버스는 Master 아래 Music, Ambience, Sfx, Ui다 (resources/audio/default_bus_layout.tres).
## 설정 화면의 음량 3축은 마스터=Master, 음악=Music, 효과=Ambience+Sfx+Ui다.
##
## 효과음은 확정 3종(플레이어 피격, 적 피격, 이동/선택)을 재생기 풀로 낸다 (play_sfx,
## SFX_PROMPTS.md). 앰비언스는 아직 소스가 없다.

## 재생 중인 곡이 바뀌었다. track은 Track 값이고 정지는 Track.NONE이다
signal bgm_changed(track: int)

## 음량이 바뀌었다. channel은 Channel 값, value는 0.0~1.0 선형 음량이다
signal volume_changed(channel: int, value: float)

## 배경음악 트랙. 2026-08-10 기준 7곡으로 14개 자리를 덮는다 (docs/DECISIONS.md).
## 전용 곡이 없는 자리는 STAGE와 EVENT가 나눠 맡고, 런 종료 화면만 무음이다
enum Track { NONE = -1, TITLE, INTRO, HUB, STAGE, EVENT, SHRINE, BOSS }

## 음량 축. 설정 화면 슬라이더 3종과 1:1로 대응한다
enum Channel { MASTER, MUSIC, EFFECTS }

## 효과음 종류. 전투음은 assets/audio/sfx, 메뉴와 지도 조작음은 assets/audio/ui에 둔다
enum Sfx { PLAYER_HIT, ENEMY_HIT, UI_SELECT }

## 트랙별 음원 경로
const TRACK_PATHS: Dictionary = {
	Track.TITLE: "res://assets/audio/bgm/bgm_title.mp3",
	Track.INTRO: "res://assets/audio/bgm/bgm_intro.mp3",
	Track.HUB: "res://assets/audio/bgm/bgm_hub.mp3",
	Track.STAGE: "res://assets/audio/bgm/bgm_stage.mp3",
	Track.EVENT: "res://assets/audio/bgm/bgm_event.mp3",
	Track.SHRINE: "res://assets/audio/bgm/bgm_shrine.mp3",
	Track.BOSS: "res://assets/audio/bgm/bgm_boss.mp3",
}

## 곡을 갈아탈 때 겹치는 시간 (초)
const CROSSFADE_TIME: float = 1.2
## 재생기를 재워 두는 음량 (dB)
const SILENT_DB: float = -60.0
## 지도를 펼친 동안 음악을 눌러 두는 폭 (dB). AUDIO_LIST 1장 메모(지도는 전용 곡 없이
## 재생 중인 곡을 낮게 눌러 쓴다)를 따른다
const DUCK_DB: float = -9.0
## 더킹이 걸리고 풀리는 시간 (초)
const DUCK_TIME: float = 0.25

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
## 효과 축이 한꺼번에 움직이는 버스 목록
const EFFECT_BUSES: Array = [&"Ambience", &"Sfx", &"Ui"]

## 효과음별 음원. 짧은 원샷이라 프리로드로 들고 있는다
const SFX_STREAMS: Dictionary = {
	Sfx.PLAYER_HIT: preload("res://assets/audio/sfx/sfx_player_hit_01.wav"),
	Sfx.ENEMY_HIT: preload("res://assets/audio/sfx/sfx_enemy_hit_01.wav"),
	Sfx.UI_SELECT: preload("res://assets/audio/ui/ui_select_01.wav"),
}
## 효과음이 나가는 버스. 전투음은 Sfx, 메뉴와 지도 조작음은 Ui다
const SFX_BUSES: Dictionary = {
	Sfx.PLAYER_HIT: &"Sfx",
	Sfx.ENEMY_HIT: &"Sfx",
	Sfx.UI_SELECT: &"Ui",
}
## 피치 변주 폭. 적 피격음만 살짝 흔들어 연타의 기계적 반복감을 줄인다
const SFX_PITCH_JITTER: Dictionary = {Sfx.ENEMY_HIT: 0.08}
## 같은 효과음의 최소 재생 간격 (초). 한 프레임 다중 히트가 소리를 겹쳐 키우는 것을 막는다
const SFX_MIN_INTERVAL: float = 0.04
## 효과음 재생기 수. 풀을 돌려 가며 써서 이 수만큼 겹쳐 울릴 수 있다
const SFX_PLAYER_COUNT: int = 6

const SETTINGS_PATH: String = "user://settings.json"
const SETTINGS_VERSION: int = 1
## 음량 기본값 (0.0~1.0). 음악은 효과음에 묻히지 않게 조금 낮춘다
const DEFAULT_VOLUMES: Dictionary = {Channel.MASTER: 1.0, Channel.MUSIC: 0.8, Channel.EFFECTS: 1.0}
## 이 값 이하는 음소거로 본다. 0에 가까운 선형 음량은 dB로 바꾸면 발산한다
const MUTE_EPSILON: float = 0.001
## 슬라이더를 끄는 동안 매 프레임 파일을 쓰지 않도록 저장을 미루는 시간 (초)
const SAVE_DEBOUNCE: float = 0.4

## 크로스페이드용 재생기 2개. 한쪽이 올라오는 동안 다른 쪽이 내려간다
var _players: Array[AudioStreamPlayer] = []
## 지금 소리를 내는 재생기 인덱스
var _active: int = 0
## 재생 중인 트랙 (Track 값)
var _track: int = Track.NONE
## 축별 선형 음량 (0.0~1.0)
var _volumes: Dictionary = {}
## 지도 더킹으로 깎인 폭 (dB). 0이면 원래 음량이다
var _duck_db: float = 0.0
var _fade: Tween = null
var _duck: Tween = null
var _save_timer: Timer = null
## 효과음 재생기 풀과 순환 인덱스
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0
## 효과음별 마지막 재생 시각 (msec). 최소 간격 판정에 쓴다
var _sfx_last_ms: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_volumes = DEFAULT_VOLUMES.duplicate()
	_build_players()
	_build_sfx_players()
	_build_save_timer()
	load_settings()


## 배경음악을 건다. 같은 곡이면 아무 일도 하지 않아 방을 옮겨도 곡이 끊기지 않는다.
## Track.NONE을 넣으면 정지와 같다
func play_bgm(track: int, fade_time: float = CROSSFADE_TIME) -> void:
	if track == Track.NONE:
		stop_bgm(fade_time)
		return
	if track == _track and _players[_active].playing:
		return
	var path: String = String(TRACK_PATHS.get(track, ""))
	if path.is_empty():
		push_warning("알 수 없는 BGM 트랙: %d" % track)
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		push_warning("BGM을 불러오지 못했다: %s" % path)
		return
	_force_loop(stream)
	_track = track
	var previous: AudioStreamPlayer = _players[_active]
	_active = 1 - _active
	var next: AudioStreamPlayer = _players[_active]
	next.stream = stream
	next.volume_db = SILENT_DB
	next.play()
	_start_fade(next, previous, fade_time)
	bgm_changed.emit(_track)


## 배경음악을 끈다. 런 종료 화면처럼 무음이어야 하는 자리에서 부른다
func stop_bgm(fade_time: float = CROSSFADE_TIME) -> void:
	if _track == Track.NONE:
		return
	_track = Track.NONE
	_kill_tween(_fade)
	var current: AudioStreamPlayer = _players[_active]
	if not current.playing:
		bgm_changed.emit(_track)
		return
	if fade_time <= 0.0:
		current.stop()
	else:
		_fade = create_tween()
		_fade.tween_property(current, "volume_db", SILENT_DB, fade_time)
		_fade.tween_callback(_stop_all)
	bgm_changed.emit(_track)


## 지금 걸린 트랙 (Track 값). 정지 상태는 Track.NONE이다
func current_track() -> int:
	return _track


## 효과음을 낸다. 재생기 풀을 순환하며, 같은 소리는 최소 간격 안에서 한 번만 낸다.
## 오토로드가 ALWAYS라 일시정지와 지도 화면에서도 울린다
func play_sfx(id: int) -> void:
	var stream: AudioStream = SFX_STREAMS.get(id) as AudioStream
	if stream == null:
		push_warning("알 수 없는 효과음: %d" % id)
		return
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = int(_sfx_last_ms.get(id, -1000))
	if now_ms - last_ms < int(SFX_MIN_INTERVAL * 1000.0):
		return
	_sfx_last_ms[id] = now_ms
	var player: AudioStreamPlayer = _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx_players.size()
	var jitter: float = float(SFX_PITCH_JITTER.get(id, 0.0))
	player.stream = stream
	player.bus = StringName(SFX_BUSES.get(id, &"Sfx"))
	player.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	player.play()


## 지도를 펼치는 동안 음악을 눌러 둔다. 곡을 바꾸지 않고 Music 버스만 깎는다
func set_music_ducked(ducked: bool, fade_time: float = DUCK_TIME) -> void:
	var target: float = DUCK_DB if ducked else 0.0
	if is_equal_approx(_duck_db, target):
		return
	_kill_tween(_duck)
	if fade_time <= 0.0:
		_set_duck_db(target)
		return
	_duck = create_tween()
	_duck.tween_method(_set_duck_db, _duck_db, target, fade_time)


## 음량 축 하나를 바꾸고 즉시 반영한다. value는 0.0~1.0 선형이다
func set_volume(channel: int, value: float) -> void:
	if not _volumes.has(channel):
		push_warning("알 수 없는 음량 축: %d" % channel)
		return
	var next: float = clampf(value, 0.0, 1.0)
	if is_equal_approx(float(_volumes[channel]), next):
		return
	_volumes[channel] = next
	_apply_channel(channel)
	volume_changed.emit(channel, next)
	if _save_timer != null:
		_save_timer.start()


func get_volume(channel: int) -> float:
	return float(_volumes.get(channel, DEFAULT_VOLUMES.get(channel, 1.0)))


## 음량 설정을 user://settings.json에 쓴다. 슬라이더를 놓고 잠시 뒤에 한 번만 돈다
func save_settings() -> void:
	var data: Dictionary = {
		"version": SETTINGS_VERSION,
		"master": get_volume(Channel.MASTER),
		"music": get_volume(Channel.MUSIC),
		"effects": get_volume(Channel.EFFECTS),
	}
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("설정 저장 실패: %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify(data))
	file.close()


## 저장된 음량을 되살린다. 파일이 없거나 손상이면 기본값을 그대로 쓴다
func load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file != null:
			var text: String = file.get_as_text()
			file.close()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary:
				var data: Dictionary = parsed as Dictionary
				_volumes[Channel.MASTER] = _read_volume(data, "master", Channel.MASTER)
				_volumes[Channel.MUSIC] = _read_volume(data, "music", Channel.MUSIC)
				_volumes[Channel.EFFECTS] = _read_volume(data, "effects", Channel.EFFECTS)
			else:
				push_warning("설정 파일 손상: %s" % SETTINGS_PATH)
	_apply_all()


func _read_volume(data: Dictionary, key: String, channel: int) -> float:
	return clampf(float(data.get(key, DEFAULT_VOLUMES[channel])), 0.0, 1.0)


func _build_players() -> void:
	for index: int in range(2):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "BgmPlayer%d" % index
		player.bus = BUS_MUSIC
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)


func _build_sfx_players() -> void:
	for index: int in range(SFX_PLAYER_COUNT):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % index
		player.bus = &"Sfx"
		add_child(player)
		_sfx_players.append(player)


func _build_save_timer() -> void:
	_save_timer = Timer.new()
	_save_timer.name = "SettingsSaveTimer"
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DEBOUNCE
	_save_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_save_timer.timeout.connect(save_settings)
	add_child(_save_timer)


## 임포트 설정(loop=true)이 어긋난 파일이 섞여도 곡이 한 번 돌고 끊기지 않게 한 번 더 강제한다
func _force_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


func _start_fade(next: AudioStreamPlayer, previous: AudioStreamPlayer, fade_time: float) -> void:
	_kill_tween(_fade)
	if fade_time <= 0.0:
		next.volume_db = 0.0
		previous.stop()
		return
	_fade = create_tween()
	_fade.set_parallel(true)
	_fade.tween_property(next, "volume_db", 0.0, fade_time)
	if previous.playing:
		_fade.tween_property(previous, "volume_db", SILENT_DB, fade_time)
	_fade.set_parallel(false)
	_fade.tween_callback(_stop_inactive)


## 크로스페이드가 끝나면 물러난 재생기를 세운다
func _stop_inactive() -> void:
	for index: int in range(_players.size()):
		if index != _active and _players[index].playing:
			_players[index].stop()


func _stop_all() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()


func _set_duck_db(value: float) -> void:
	_duck_db = value
	_apply_channel(Channel.MUSIC)


func _apply_all() -> void:
	for channel: int in _volumes:
		_apply_channel(channel)


func _apply_channel(channel: int) -> void:
	match channel:
		Channel.MASTER:
			_apply_bus(BUS_MASTER, get_volume(Channel.MASTER), 0.0)
		Channel.MUSIC:
			_apply_bus(BUS_MUSIC, get_volume(Channel.MUSIC), _duck_db)
		Channel.EFFECTS:
			for bus: StringName in EFFECT_BUSES:
				_apply_bus(bus, get_volume(Channel.EFFECTS), 0.0)


func _apply_bus(bus: StringName, linear: float, offset_db: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		push_warning("오디오 버스를 찾지 못했다: %s" % bus)
		return
	var muted: bool = linear <= MUTE_EPSILON
	AudioServer.set_bus_mute(index, muted)
	if muted:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(linear) + offset_db)


func _kill_tween(tween: Tween) -> void:
	if tween != null and tween.is_valid():
		tween.kill()
