class_name EventResultPopup
extends Control

## 이벤트 결과 팝업 (docs/act1/EVENTS.md 10.2 결과 피드백).
##
## 획득과 손실을 줄로 갈라 명확히 보여준다. 대사는 넣지 않고 결과만 적는다
## (도입 대사 최소, Dead Cells 상한. GDD 2장).
## 색 채널은 미니게임과 같다. 획득은 등불 호박, 손실은 남색과 회색이며
## 적색과 청록은 쓰지 않는다 (EVENTS 10.1).

## 표시가 끝났다
signal closed

const BOX: Rect2 = Rect2(120, 40, 240, 96)
const PANEL: Color = Color(0.06, 0.06, 0.10, 0.92)
const INK: Color = Color(0.90, 0.87, 0.80)
const INK_DIM: Color = Color(0.60, 0.58, 0.54)
const LANTERN: Color = Color(0.92, 0.66, 0.28)
const NIGHT_DIM: Color = Color(0.52, 0.52, 0.56)
const FONT_SIZE: int = 9
const LINE_GAP: float = 14.0

## 팝업이 떠 있는 시간 (초)
@export var hold_time: float = 2.6
## 사라지는 데 걸리는 시간 (초)
@export var fade_time: float = 0.4

var _title: String = ""
var _gains: PackedStringArray = PackedStringArray()
var _losses: PackedStringArray = PackedStringArray()
var _alpha: float = 0.0


func _ready() -> void:
	visible = false


## 결과 사전을 받아 띄운다 (scenes/minigame/minigame.gd 결과 규격).
func show_result(result: Dictionary) -> void:
	_title = String(result.get("title", ""))
	_gains = result.get("gains", PackedStringArray())
	_losses = result.get("losses", PackedStringArray())
	if _title.is_empty() and _gains.is_empty() and _losses.is_empty():
		closed.emit()
		return
	visible = true
	_alpha = 1.0
	queue_redraw()
	var tween: Tween = create_tween()
	tween.tween_interval(hold_time)
	tween.tween_method(_set_alpha, 1.0, 0.0, fade_time)
	tween.tween_callback(_close)


func _set_alpha(value: float) -> void:
	_alpha = value
	queue_redraw()


func _close() -> void:
	visible = false
	closed.emit()


func _draw() -> void:
	var lines: int = _gains.size() + _losses.size()
	var box: Rect2 = Rect2(BOX.position, Vector2(BOX.size.x, 34.0 + float(lines) * LINE_GAP))
	draw_rect(box, Color(PANEL, PANEL.a * _alpha))
	draw_rect(box, Color(INK_DIM, _alpha), false, 1.0)
	_draw_line_at(_title, box.position.y + 16.0, Color(INK, _alpha))
	var y: float = box.position.y + 32.0
	for text: String in _gains:
		_draw_line_at("+ " + text, y, Color(LANTERN, _alpha))
		y += LINE_GAP
	for text: String in _losses:
		_draw_line_at("- " + text, y, Color(NIGHT_DIM, _alpha))
		y += LINE_GAP


func _draw_line_at(text: String, y: float, color: Color) -> void:
	if text.is_empty():
		return
	var font: Font = get_theme_default_font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x
	var x: float = BOX.position.x + BOX.size.x * 0.5 - width * 0.5
	draw_string(font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, color)
