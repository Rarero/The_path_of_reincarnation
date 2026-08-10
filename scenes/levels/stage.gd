extends Node2D

## 스테이지: 방을 가로로 이어 붙인 고정 루트 (M1 축약 구성).
##
## 방을 x축으로 방 폭만큼 띄워 배치하고 플레이어를 첫 방에 놓는다.
## 노드 맵 UI와 씬 전환은 M2에서 붙인다 (docs/PROTOTYPE.md 4장).

## 이어 붙일 방 씬 목록. 순서가 고정 루트다
@export var room_scenes: Array[PackedScene] = []
## 방 폭 (px). docs/ROOM_SPEC.md 기준
@export var room_width: int = 640
## 사망 후 재시작까지의 지연 (초)
@export var restart_delay: float = 1.2
## 사망 시 재시작 대신 허브로 반송할지 여부 (런 스테이지에서 참, docs/DESIGN_HUB.md 6장)
@export var return_to_hub_on_death: bool = false
## 이 y좌표보다 아래로 떨어지면 낙사로 처리한다 (px)
@export var fall_limit_y: float = 640.0
## 낙사 시 잃는 체력
@export var fall_damage: int = 10
## 카메라 세로 상한 (px). 방 높이 352와 뷰포트 360의 차이 8px를 위로 배분한다
@export var camera_limit_top: int = -8
## 카메라 세로 하한 (px). docs/ROOM_SPEC.md 방 높이 기준
@export var camera_limit_bottom: int = 352

var _rooms: Array[Room] = []
var _camera: Camera2D = null
var _camera_room_index: int = -1

@onready var player: Player = $Player as Player
@onready var rooms_root: Node2D = $Rooms as Node2D


func _ready() -> void:
	AudioDirector.play_bgm(AudioDirector.Track.STAGE)
	_build_rooms()
	_place_player()
	_camera = player.get_node_or_null(^"Camera2D") as Camera2D
	_update_camera_limits()
	GameEvents.player_died.connect(_on_player_died)
	GameEvents.room_cleared.connect(_on_room_cleared)


func _process(_delta: float) -> void:
	_update_camera_limits()
	if player.is_dead() or player.global_position.y <= fall_limit_y:
		return
	_recover_from_fall()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_restart"):
		_restart()


func rooms() -> Array[Room]:
	return _rooms


func _build_rooms() -> void:
	for index: int in range(room_scenes.size()):
		var scene: PackedScene = room_scenes[index]
		if scene == null:
			continue
		var instance: Node = scene.instantiate()
		var room: Room = instance as Room
		if room == null:
			instance.queue_free()
			push_warning("Room이 아닌 씬이 room_scenes에 있다: index %d" % index)
			continue
		room.position = Vector2(float(index * room_width), 0.0)
		rooms_root.add_child(room)
		_rooms.append(room)


func _place_player() -> void:
	if _rooms.is_empty():
		return
	player.respawn(_rooms[0].spawn_point.global_position)


## 카메라를 현재 방 범위로 가둔다. 옆 방이 보이면 시선이 분산된다 (M1 판정 지적).
## 방 경계를 넘으면 limit이 새 방으로 바뀌며 잘라 전환된다.
func _update_camera_limits() -> void:
	if _camera == null or _rooms.is_empty():
		return
	var index: int = clampi(int(player.global_position.x / float(room_width)), 0, _rooms.size() - 1)
	if index == _camera_room_index:
		return
	_camera_room_index = index
	_camera.limit_left = index * room_width
	_camera.limit_right = (index + 1) * room_width
	_camera.limit_top = camera_limit_top
	_camera.limit_bottom = camera_limit_bottom
	_camera.reset_smoothing()


## 낙사 처리: 현재 위치에서 가장 가까운 방의 스폰 지점으로 되돌리고 체력을 깎는다
func _recover_from_fall() -> void:
	if _rooms.is_empty():
		_restart()
		return
	var index: int = clampi(int(player.global_position.x / float(room_width)), 0, _rooms.size() - 1)
	player.global_position = _rooms[index].spawn_point.global_position
	player.velocity = Vector2.ZERO
	player.health.apply_damage(fall_damage)


func _on_room_cleared(room_name: String, elapsed: float) -> void:
	print("[room_cleared] %s %.1fs" % [room_name, elapsed])


func _on_player_died() -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(restart_delay)
	if return_to_hub_on_death:
		timer.timeout.connect(SceneRouter.goto_hub)
	else:
		timer.timeout.connect(_restart)


func _restart() -> void:
	get_tree().reload_current_scene()
