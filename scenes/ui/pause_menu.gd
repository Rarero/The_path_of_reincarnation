class_name PauseMenu
extends CanvasLayer

## 인게임 일시정지 메뉴. ESC로 열고 닫는다 (docs/DESIGN_INTRO.md 프론트엔드 흐름의 인게임 대응).
##
## 항목: 게임 재개, 설정, 타이틀로, 게임 종료.
## - 열려 있는 동안 get_tree().paused로 플레이를 멈춘다. process_mode는 ALWAYS라 멈춘 동안에도 동작한다
## - 타이틀로는 진행 중인 런을 포기한다. 사망/완주와 같은 규칙으로 RunState.reset_run 후 타이틀로 나간다
## - 노드 지도 표시 중에는 이미 paused 상태라 ESC로 열리지 않는다 (중첩 방지)

@onready var _root: Control = $Root as Control
@onready var _panel: Control = %Panel as Control
@onready var _resume_button: Button = %ResumeButton as Button
@onready var _settings_button: Button = %SettingsButton as Button
@onready var _title_button: Button = %TitleButton as Button
@onready var _quit_button: Button = %QuitButton as Button
@onready var _settings_panel: SettingsMenu = %SettingsPanel as SettingsMenu


func _ready() -> void:
	_resume_button.pressed.connect(_on_resume_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_title_button.pressed.connect(_on_title_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_settings_panel.closed.connect(_on_settings_closed)
	_settings_panel.hide()
	_root.hide()
	# 웹 빌드에는 프로세스 종료 개념이 없다. 종료 버튼을 숨긴다
	if OS.has_feature("web"):
		_quit_button.hide()
	_connect_menu_sfx()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	if _root.visible:
		if _settings_panel.visible:
			_back_from_settings()
		else:
			_close()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused:
		_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	_settings_panel.hide()
	_panel.show()
	_root.show()
	get_tree().paused = true
	_resume_button.grab_focus()


func _close() -> void:
	_root.hide()
	get_tree().paused = false


func _on_resume_pressed() -> void:
	_close()


func _on_settings_pressed() -> void:
	_panel.hide()
	_settings_panel.show_panel()


func _on_settings_closed() -> void:
	_back_from_settings()


func _back_from_settings() -> void:
	_settings_panel.hide()
	_panel.show()
	_settings_button.grab_focus()


## 타이틀로 나가기 전 반드시 paused를 풀어야 SceneRouter의 페이드 트윈이 진행된다
func _on_title_pressed() -> void:
	get_tree().paused = false
	RunState.reset_run()
	SceneRouter.goto_main_menu()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	SceneRouter.quit_game()


## 메뉴 이동(포커스)과 선택(누름)에 공용 선택음을 붙인다 (SFX_PROMPTS.md 3번)
func _connect_menu_sfx() -> void:
	var buttons: Array[Button] = [
		_resume_button,
		_settings_button,
		_title_button,
		_quit_button,
	]
	for button: Button in buttons:
		button.focus_entered.connect(_play_select_sfx)
		button.pressed.connect(_play_select_sfx)


func _play_select_sfx() -> void:
	AudioDirector.play_sfx(AudioDirector.Sfx.UI_SELECT)
