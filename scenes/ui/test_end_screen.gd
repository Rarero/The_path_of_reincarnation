class_name TestEndScreen
extends CanvasLayer

## 임시 테스트 종료 화면 (2막 미구현 대체, 2026-08-08).
##
## 1막 보스를 잡으면 이어질 막이 없어 흐름이 끊긴다. 오류로 떨어지거나 허브로 조용히
## 튕기지 않도록, 검은 화면과 "테스트 종료" 문구, 타이틀 복귀 버튼만 띄우는 임시 장치다.
## 2막이 붙으면 이 화면과 run_stage의 호출부를 통째로 제거한다.
##
## 트리를 멈춘 상태에서도 동작해야 하므로 process_mode를 항상 처리로 둔다.

signal closed

@onready var title_button: Button = $Root/Center/Box/TitleButton as Button


func _ready() -> void:
	visible = false
	title_button.pressed.connect(_on_title_pressed)


## 화면을 띄우고 트리를 멈춘다. 이후 입력은 버튼만 받는다.
func open() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true
	title_button.grab_focus()


func _on_title_pressed() -> void:
	get_tree().paused = false
	closed.emit()
	SceneRouter.goto_main_menu()
