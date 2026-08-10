class_name SettingsMenu
extends Control

## 설정 패널 (settings_menu).
##
## 음량 3축(마스터, 음악, 효과)을 조절한다. 값은 AudioDirector가 들고 있고
## user://settings.json에 보관하므로 이 패널은 표시와 입력만 맡는다.
## 효과 축은 Ambience, Sfx, Ui 버스를 한꺼번에 움직인다 (2026-08-10 S1).
##
## 전체화면 토글과 조작 안내는 아직 미구현이다. docs/DESIGN_INTRO.md 3.4.
##
## 타이틀과 일시정지 메뉴가 이 씬을 함께 쓴다. 일시정지 중에도 조작되어야 하므로
## 부모(PauseMenu)의 process_mode ALWAYS를 그대로 물려받는다.

## 뒤로가기로 닫힘
signal closed

## 슬라이더 눈금. 0~100으로 두고 표시도 백분율로 한다
const SLIDER_MAX: float = 100.0

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var effects_slider: HSlider = %EffectsSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var effects_value: Label = %EffectsValue
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	effects_slider.value_changed.connect(_on_effects_changed)
	_sync_sliders()


## 패널을 열고 현재 음량을 슬라이더에 반영한 뒤 뒤로 버튼에 포커스를 준다
func show_panel() -> void:
	_sync_sliders()
	show()
	back_button.grab_focus()


func _sync_sliders() -> void:
	_load_row(master_slider, master_value, AudioDirector.Channel.MASTER)
	_load_row(music_slider, music_value, AudioDirector.Channel.MUSIC)
	_load_row(effects_slider, effects_value, AudioDirector.Channel.EFFECTS)


## 저장된 음량을 슬라이더에 얹는다. 되돌아오는 시그널을 막아 값이 흔들리지 않게 한다
func _load_row(slider: HSlider, value_label: Label, channel: int) -> void:
	slider.set_value_no_signal(AudioDirector.get_volume(channel) * SLIDER_MAX)
	value_label.text = _percent(slider.value)


func _on_master_changed(value: float) -> void:
	AudioDirector.set_volume(AudioDirector.Channel.MASTER, value / SLIDER_MAX)
	master_value.text = _percent(value)


func _on_music_changed(value: float) -> void:
	AudioDirector.set_volume(AudioDirector.Channel.MUSIC, value / SLIDER_MAX)
	music_value.text = _percent(value)


func _on_effects_changed(value: float) -> void:
	AudioDirector.set_volume(AudioDirector.Channel.EFFECTS, value / SLIDER_MAX)
	effects_value.text = _percent(value)


func _percent(value: float) -> String:
	return "%d%%" % int(roundf(value))


func _on_back_pressed() -> void:
	AudioDirector.save_settings()
	hide()
	closed.emit()
