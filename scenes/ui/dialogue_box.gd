class_name DialogueBox
extends Control

## 허브 순차 대화 상자 (docs/DESIGN_HUB.md 5.2절).
##
## 한 줄 토스트로는 차사 3단계 대화를 담을 수 없어 신설했다. 다른 NPC의 짧은
## 스텁 메시지도 이 시스템으로 흡수한다.
## 자동으로 넘어가지 않는다. 진행 입력은 move_up 또는 ui_accept이며 새 액션을
## 만들지 않는다(오프닝 intro.gd와 같은 규약). 타자 연출 뒤 한 번 더 눌러야
## 다음 줄로 가는 2단 입력이다.
## 팔레트와 폰트 크기는 EventResultPopup과 같은 값을 쓴다.

## 대화가 끝났다(마지막 줄을 넘겼거나 건너뛰었다). conversation_id
signal finished(conversation_id: String)

## 그 줄의 연출 훅이 발생했다. effect (예: grant_sword, grant_map)
signal effect_fired(effect: String)

const BOX: Rect2 = Rect2(48, 192, 384, 62)
const PAD: float = 16.0
const PANEL: Color = Color(0.06, 0.06, 0.10, 0.92)
const INK: Color = Color(0.90, 0.87, 0.80)
const INK_DIM: Color = Color(0.60, 0.58, 0.54)
const LANTERN: Color = Color(0.92, 0.66, 0.28)
const NAME_SIZE: int = 8
const FONT_SIZE: int = 9
const LINE_GAP: float = 13.0
## 글자 노출 속도 (자/초)
const REVEAL_SPEED: float = 45.0
## 본문 최대 행 수 (5.2절 분량 상한)
const MAX_ROWS: int = 2

var _lines: Array = []
var _index: int = 0
var _revealed: float = 0.0
var _conversation_id: String = ""
var _skippable: bool = false
var _active: bool = false
var _blink: float = 0.0


func _ready() -> void:
	visible = false
	set_process(false)
	set_process_unhandled_input(false)


## 대화 하나를 연다. conversation은 hub_lines.gd의 사전 규격을 따른다
## (id, lines, skippable). 이미 열려 있으면 무시한다.
func open(conversation: Dictionary) -> void:
	if _active:
		return
	var lines: Array = conversation.get("lines", []) as Array
	if lines.is_empty():
		return
	_conversation_id = String(conversation.get("id", ""))
	_skippable = bool(conversation.get("skippable", true))
	_lines = lines
	_index = 0
	_revealed = 0.0
	_blink = 0.0
	_active = true
	visible = true
	set_process(true)
	set_process_unhandled_input(true)
	_fire_effect_of_current()
	queue_redraw()


func is_active() -> bool:
	return _active


func _process(delta: float) -> void:
	_blink += delta
	if _revealed < float(_current_text().length()):
		_revealed += REVEAL_SPEED * delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if _skippable and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
		return
	if not (event.is_action_pressed(&"move_up") or event.is_action_pressed(&"ui_accept")):
		return
	get_viewport().set_input_as_handled()
	_advance()


## 2단 입력. 타자 연출이 진행 중이면 그 줄을 즉시 다 보여주고, 다 나왔으면 다음 줄로.
func _advance() -> void:
	var full: int = _current_text().length()
	if _revealed < float(full):
		_revealed = float(full)
		return
	_index += 1
	if _index >= _lines.size():
		_close()
		return
	_revealed = 0.0
	_fire_effect_of_current()


func _close() -> void:
	_active = false
	visible = false
	set_process(false)
	set_process_unhandled_input(false)
	var id: String = _conversation_id
	_lines = []
	_conversation_id = ""
	finished.emit(id)


func _fire_effect_of_current() -> void:
	var effect: String = _current_field("effect")
	if not effect.is_empty():
		effect_fired.emit(effect)


func _current_field(key: String) -> String:
	if _index < 0 or _index >= _lines.size():
		return ""
	var line: Dictionary = _lines[_index] as Dictionary
	return String(line.get(key, ""))


func _current_text() -> String:
	return _current_field("text")


func _draw() -> void:
	if not _active:
		return
	draw_rect(BOX, PANEL)
	draw_rect(BOX, INK_DIM, false, 1.0)
	var font: Font = get_theme_default_font()
	var speaker: String = _current_field("speaker")
	var body_top: float = BOX.position.y + PAD + 4.0
	if not speaker.is_empty():
		draw_string(
			font,
			Vector2(BOX.position.x + PAD, BOX.position.y + 14.0),
			speaker,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			NAME_SIZE,
			INK_DIM
		)
		body_top = BOX.position.y + 30.0
	var color: Color = LANTERN if not _current_field("effect").is_empty() else INK
	var shown: String = _current_text().substr(0, int(_revealed))
	var width: float = BOX.size.x - PAD * 2.0
	var y: float = body_top
	for row: String in _wrap(shown, font, width):
		draw_string(
			font,
			Vector2(BOX.position.x + PAD, y),
			row,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			FONT_SIZE,
			color
		)
		y += LINE_GAP
	_draw_next_mark(font)


## 다음 줄이 있고 타자 연출이 끝났을 때만 우하단 삼각을 깜빡인다.
func _draw_next_mark(_font: Font) -> void:
	if _revealed < float(_current_text().length()):
		return
	if fmod(_blink, 1.0) > 0.5:
		return
	var base: Vector2 = BOX.position + BOX.size - Vector2(PAD, 8.0)
	var points: PackedVector2Array = PackedVector2Array(
		[base, base + Vector2(6.0, 0.0), base + Vector2(3.0, 4.0)]
	)
	draw_colored_polygon(points, INK_DIM)


## 폭에 맞춰 줄바꿈한다. 상한 행 수를 넘는 부분은 버린다(5.2절 분량 상한).
func _wrap(text: String, font: Font, width: float) -> PackedStringArray:
	var rows: PackedStringArray = PackedStringArray()
	var current: String = ""
	for i: int in range(text.length()):
		var candidate: String = current + text[i]
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x > width:
			rows.append(current)
			current = text[i]
			if rows.size() >= MAX_ROWS:
				return rows
		else:
			current = candidate
	if not current.is_empty():
		rows.append(current)
	return rows
