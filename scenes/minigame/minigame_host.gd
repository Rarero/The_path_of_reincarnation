class_name MinigameHost
extends CanvasLayer

## 미니게임 오버레이 호스트.
##
## 방 위에 미니게임을 띄우고 도는 동안 트리를 일시정지한다. 끝나면 결과를 그대로
## 올려보내고 정리한다. 보상 반영과 결과 팝업은 run_stage가 맡는다.

signal finished(result: Dictionary)

var _current: Minigame = null


func is_open() -> bool:
	return _current != null


## 미니게임을 연다. config는 그대로 미니게임의 begin으로 넘어간다.
func open(scene: PackedScene, config: Dictionary) -> void:
	if scene == null or _current != null:
		return
	var game: Minigame = scene.instantiate() as Minigame
	if game == null:
		push_error("미니게임 씬의 루트가 Minigame이 아니다")
		return
	_current = game
	game.finished.connect(_on_finished)
	add_child(game)
	get_tree().paused = true
	game.begin(config)


func _on_finished(result: Dictionary) -> void:
	get_tree().paused = false
	if _current != null:
		_current.queue_free()
		_current = null
	finished.emit(result)
