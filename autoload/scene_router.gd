extends Node

## 씬 전환 라우터 (오토로드: SceneRouter).
##
## 페이드 아웃과 인을 넣어 씬을 교체한다. 프론트엔드 흐름의 단일 통로.
## docs/DESIGN_INTRO.md 2장 흐름도.

const MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"
const INTRO: String = "res://scenes/cutscene/intro.tscn"
const HUB: String = "res://scenes/hub/hub.tscn"
const STAGE_ACT1: String = "res://scenes/levels/stage_act1_rough.tscn"
const RUN_ACT1: String = "res://scenes/levels/run_stage.tscn"

## 페이드 한 방향에 걸리는 시간(초)
@export var fade_time: float = 0.35

var _fade: ColorRect = null
var _busy: bool = false


func _ready() -> void:
	_build_fade_layer()


func goto_main_menu() -> void:
	change_scene(MAIN_MENU)


func goto_intro() -> void:
	change_scene(INTRO)


func goto_hub() -> void:
	change_scene(HUB)


func goto_stage() -> void:
	change_scene(STAGE_ACT1)


## 노드 맵 기반 1막 런 (docs/RUN_STRUCTURE.md 3장). 허브 1막 진입의 기본 경로
func goto_run() -> void:
	change_scene(RUN_ACT1)


func quit_game() -> void:
	get_tree().quit()


## 페이드 아웃 후 씬을 바꾸고 다시 페이드 인한다
func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true
	# 히트스톱 중에 씬이 바뀌면 복원 타이머의 주인이 사라져 시간 배율이 고착된다.
	# 전환 시작 시점에 무조건 되돌린다 (2026-08-10 전체 검토)
	Engine.time_scale = 1.0
	EnemyBase.end_kill_hitstop()
	await _fade_to(1.0)
	var error: int = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("씬 전환 실패: %s (%d)" % [path, error])
	await get_tree().process_frame
	await _fade_to(0.0)
	_busy = false


func _build_fade_layer() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.anchor_right = 1.0
	_fade.anchor_bottom = 1.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)


func _fade_to(target_alpha: float) -> void:
	if _fade == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_fade, "color:a", target_alpha, fade_time)
	await tween.finished
