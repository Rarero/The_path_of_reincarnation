class_name ShrinePanel
extends Control

## 신당 선택 오버레이 (docs/systems/BOONS.md 7장).
##
## 진입 시 열리고, 게임은 호출자가 일시정지한다. 위아래로 고르고 점프/확인으로 결정한다.
## 신당 3택(고정 3개)뿐 아니라 3칸 처리 하위 메뉴와 조합 메뉴처럼 항목 수가 가변인
## 목록도 이 패널 하나로 연다. 항목 수 상한은 없고 Options 아래에 Label을 동적으로
## 만든다. 마우스 지원은 후속.

## 선택을 확정했다. index
signal chosen(index: int)
## 뒤로가기/취소. open()에서 allow_cancel이 true일 때만 발생한다
signal cancelled
## 재추첨 요청. open()에서 allow_reroll이 true일 때만 발생한다.
## 재추첨 입력을 방(room_shrine.gd)이 아니라 이 패널이 받는 이유: 선택 중에는
## get_tree().paused가 켜져 있고 방 노드는 PROCESS_MODE_INHERIT이라 입력을 받지
## 못한다. 이 패널만 PROCESS_MODE_ALWAYS(씬 process_mode = 3)라 멈춘 동안에도 돈다
signal reroll_requested

const HOT: Color = Color(1.0, 0.86, 0.45)
const DIM: Color = Color(0.78, 0.78, 0.78)
const DISABLED: Color = Color(0.45, 0.42, 0.4)

var _count: int = 0
var _selection: int = 0
var _options: Array[Label] = []
var _disabled: Array[bool] = []
var _allow_cancel: bool = false
var _allow_reroll: bool = false

@onready var _title: Label = $Box/Title as Label
@onready var _info: Label = $Box/Info as Label
@onready var _list: VBoxContainer = $Box/Options as VBoxContainer
@onready var _hint: Label = $Box/Hint as Label


func _ready() -> void:
	visible = false
	set_process_input(false)


## 제목과 항목들로 패널을 연다. info_text는 부제(확률, 자원 보유량 등)로 비우면 숨긴다.
## disabled_flags는 labels와 같은 길이면 그 인덱스를 고를 수 없게 흐리게 표시한다.
## hint_text를 비우면 기본 안내문을 쓴다. allow_cancel이 true면 뒤로가기 입력을,
## allow_reroll이 true면 재추첨 입력을 받는다.
func open(
	title_text: String,
	labels: Array[String],
	info_text: String = "",
	disabled_flags: Array[bool] = [],
	hint_text: String = "",
	allow_cancel: bool = false,
	allow_reroll: bool = false
) -> void:
	_title.text = title_text
	_info.text = info_text
	_info.visible = not info_text.is_empty()
	_hint.text = hint_text if not hint_text.is_empty() else "위아래 선택, 점프로 결정"
	_allow_cancel = allow_cancel
	_allow_reroll = allow_reroll
	_rebuild_options(labels, disabled_flags)
	_selection = _first_enabled()
	visible = true
	set_process_input(true)
	_highlight()


func _rebuild_options(labels: Array[String], disabled_flags: Array[bool]) -> void:
	# queue_free만 쓰면 해제가 프레임 끝으로 밀려 옛 항목과 새 항목이 한 프레임 겹쳐
	# 보인다. 트리에서 먼저 떼고 해제한다
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_options.clear()
	_disabled.clear()
	_count = labels.size()
	for i: int in range(_count):
		var label: Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.text = "%d. %s" % [i + 1, labels[i]]
		_list.add_child(label)
		_options.append(label)
		_disabled.append(disabled_flags[i] if i < disabled_flags.size() else false)


func _first_enabled() -> int:
	for i: int in range(_count):
		if not _disabled[i]:
			return i
	return 0


func _input(event: InputEvent) -> void:
	if not visible or _count == 0:
		return
	if event.is_action_pressed(&"move_up") or event.is_action_pressed(&"ui_up"):
		_move(-1)
	elif event.is_action_pressed(&"move_down") or event.is_action_pressed(&"ui_down"):
		_move(1)
	elif _is_confirm(event):
		_confirm()
	elif _allow_cancel and event.is_action_pressed(&"ui_cancel"):
		_cancel()
	elif _allow_reroll and event.is_action_pressed(&"shrine_reroll"):
		get_viewport().set_input_as_handled()
		reroll_requested.emit()


func _move(step: int) -> void:
	var next: int = _selection
	for _i: int in range(_count):
		next = (next + step + _count) % _count
		if not _disabled[next]:
			break
	_selection = next
	get_viewport().set_input_as_handled()
	_highlight()


func _is_confirm(event: InputEvent) -> bool:
	return (
		event.is_action_pressed(&"jump")
		or event.is_action_pressed(&"attack_ranged")
		or event.is_action_pressed(&"ui_accept")
	)


func _confirm() -> void:
	if _disabled[_selection]:
		return
	get_viewport().set_input_as_handled()
	_close()
	chosen.emit(_selection)


func _cancel() -> void:
	get_viewport().set_input_as_handled()
	_close()
	cancelled.emit()


func _close() -> void:
	visible = false
	set_process_input(false)


func _highlight() -> void:
	for i: int in range(_options.size()):
		if _disabled[i]:
			_options[i].modulate = DISABLED
		else:
			_options[i].modulate = HOT if i == _selection else DIM
