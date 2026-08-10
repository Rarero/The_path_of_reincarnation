extends Control

## 타이틀 화면 (main_menu).
##
## 이어하기, 게임 시작, 처음부터, 설정, 종료. 버튼은 좌측 하단에 배치한다.
## docs/DESIGN_INTRO.md 3장.
##
## 처음부터는 진행 상태를 전부 지우고 오프닝부터 다시 재생한다. 오프닝과 차사의
## 환도 지급을 반복해서 확인해야 하므로 상시 노출한다. 되돌릴 수 없어 확인을 받는다

@onready var continue_button: Button = %ContinueButton
@onready var start_button: Button = %StartButton
@onready var restart_button: Button = %RestartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_panel: SettingsMenu = %SettingsPanel
@onready var restart_confirm: ConfirmationDialog = %RestartConfirm


func _ready() -> void:
	AudioDirector.play_bgm(AudioDirector.Track.TITLE)
	continue_button.pressed.connect(_on_continue_pressed)
	start_button.pressed.connect(_on_start_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_panel.closed.connect(_on_settings_closed)
	restart_confirm.confirmed.connect(_on_restart_confirmed)
	restart_confirm.canceled.connect(_on_restart_canceled)
	settings_panel.hide()
	# 웹 빌드에는 프로세스 종료 개념이 없다. 종료 버튼을 숨긴다
	if OS.has_feature("web"):
		quit_button.hide()
	# 중단 저장이 있을 때만 이어하기를 노출하고 그쪽에 포커스를 준다
	if SaveGame.has_save():
		continue_button.show()
		continue_button.grab_focus()
	else:
		continue_button.hide()
		start_button.grab_focus()
	# 진입 시 자동 포커스에는 소리가 나지 않게 연결을 한 프레임 미룬다
	_connect_menu_sfx.call_deferred()


## 중단 저장을 불러와 런을 재개한다. 런 상태를 먼저 복원한 뒤(플레이어 최대 체력 보정 반영) 씬을 연다.
func _on_continue_pressed() -> void:
	var data: Dictionary = SaveGame.read()
	if data.is_empty():
		continue_button.hide()
		start_button.grab_focus()
		return
	RunState.load_save(data)
	SaveGame.request_resume(data)
	SceneRouter.goto_run()


func _on_start_pressed() -> void:
	if GameState.intro_seen:
		SceneRouter.goto_hub()
	else:
		SceneRouter.goto_intro()


## 처음부터. 되돌릴 수 없으므로 확인을 먼저 받는다
func _on_restart_pressed() -> void:
	restart_confirm.popup_centered()


## 확인됨. 진행 플래그(meta.json)와 중단 저장을 모두 지우고 오프닝부터 다시 시작한다.
## 오프닝, 차사 첫 대화와 환도 지급, 접수 관원 지도까지 매번 같은 순서로 다시 밟는다
func _on_restart_confirmed() -> void:
	GameState.reset_all()
	SaveGame.clear()
	continue_button.hide()
	SceneRouter.goto_intro()


func _on_restart_canceled() -> void:
	restart_button.grab_focus()


func _on_settings_pressed() -> void:
	settings_panel.show_panel()


func _on_settings_closed() -> void:
	settings_button.grab_focus()


func _on_quit_pressed() -> void:
	SceneRouter.quit_game()


## 메뉴 이동(포커스)과 선택(누름)에 공용 선택음을 붙인다 (SFX_PROMPTS.md 3번)
func _connect_menu_sfx() -> void:
	var buttons: Array[Button] = [
		continue_button,
		start_button,
		restart_button,
		settings_button,
		quit_button,
	]
	for button: Button in buttons:
		button.focus_entered.connect(_play_select_sfx)
		button.pressed.connect(_play_select_sfx)


func _play_select_sfx() -> void:
	AudioDirector.play_sfx(AudioDirector.Sfx.UI_SELECT)
