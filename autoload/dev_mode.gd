extends Node

## 개발자 모드. 백틱(`) 키로 켜고 끈다.
##
## 개발 빌드에서만 동작한다. 배포 빌드(OS.is_debug_build()가 거짓)에서는 토글 자체가 막히고
## 표시도 만들지 않으므로, 각 씬의 디버그 단축키를 DevMode.enabled로만 막아 두면
## 출시 빌드에 디버그 조작이 새어 나가지 않는다.
##
## 상태는 저장하지 않는다. 실행할 때마다 꺼진 상태로 시작한다.
## 켜져 있는 동안 우상단에 DEV 표시가, 우하단에 그 씬의 디버그 키 목록이 뜬다.
##
## 씬에서 쓰는 법
## - _unhandled_input 맨 앞에서 DevMode.enabled를 확인한 뒤 키를 처리한다
## - _ready에서 DevMode.set_hints([...])로 그 씬의 디버그 키를 등록한다.
##   씬이 바뀌면 자동으로 지워지므로 해제는 신경 쓰지 않아도 된다

## 개발자 모드가 켜지거나 꺼졌다
signal changed(enabled: bool)

## 토글 키. 물리 키 위치로 잡아 한글 자판이나 IME 상태와 무관하게 듣는다
const TOGGLE_KEYCODE: int = KEY_QUOTELEFT

var enabled: bool = false

var _layer: CanvasLayer = null
var _label: Label = null
var _hints: Label = null
var _scene_ref: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not is_available():
		set_process_unhandled_input(false)
		set_process(false)
		return
	_build_indicator()


## 개발 빌드에서만 쓸 수 있다. 배포 빌드에서는 항상 거짓이다
func is_available() -> bool:
	return OS.is_debug_build()


## 씬이 바뀌면 이전 씬의 키 목록을 지운다. 새 씬이 등록하지 않으면 빈 채로 남는다
func _process(_delta: float) -> void:
	var current: Node = get_tree().current_scene
	if current == _scene_ref:
		return
	_scene_ref = current
	clear_hints()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode != TOGGLE_KEYCODE:
		return
	toggle()
	get_viewport().set_input_as_handled()


func toggle() -> void:
	set_enabled(not enabled)


func set_enabled(value: bool) -> void:
	if not is_available() or enabled == value:
		return
	enabled = value
	_update_indicator()
	changed.emit(enabled)


## 현재 씬의 디버그 키 목록을 등록한다. 줄 하나가 키 하나다
func set_hints(lines: PackedStringArray) -> void:
	if _hints == null:
		return
	_scene_ref = get_tree().current_scene
	_hints.text = "\n".join(lines)
	_update_indicator()


func clear_hints() -> void:
	if _hints != null:
		_hints.text = ""
		_update_indicator()


## 우상단 DEV 표시와 우하단 키 목록. 일시정지 중에도 보이도록 오토로드 아래에 직접 붙인다
func _build_indicator() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "DevIndicator"
	_layer.layer = 90
	add_child(_layer)

	_label = Label.new()
	_label.name = "DevLabel"
	_label.text = "DEV"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24))
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.offset_left = -44.0
	_label.offset_top = 3.0
	_label.offset_right = -6.0
	_label.offset_bottom = 17.0
	_layer.add_child(_label)

	_hints = Label.new()
	_hints.name = "DevHints"
	_hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hints.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_hints.add_theme_font_size_override("font_size", 9)
	_hints.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24))
	_hints.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hints.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hints.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hints.offset_left = -240.0
	_hints.offset_top = -80.0
	_hints.offset_right = -6.0
	_hints.offset_bottom = -4.0
	_layer.add_child(_hints)

	_update_indicator()


func _update_indicator() -> void:
	if _label != null:
		_label.visible = enabled
	if _hints != null:
		_hints.visible = enabled and not _hints.text.is_empty()
