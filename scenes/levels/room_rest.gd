extends Room

## 쉼터 방 (docs/RUN_STRUCTURE.md 3장 노드 규칙, 11.5 빈 방 규칙).
##
## 보스 직전의 안전방이다. 적이 없고, 들어서면 회복과 강화 중 하나를 고른다.
## 둘 다 무상이며 한 방에서 한 번만 받는다. 되짚어 온 쉼터는 아무것도 주지 않는다.
##
## 체력이 방 사이로 이어지므로(2026-08-10 결정) 이 방이 런의 유일한 회복 지점이다.
## 수치는 2026-08-10 채택값이다 (DECISIONS). export라 에디터에서 바로 조정되며
## M2 밸런싱에서 재검토한다.
##
## 유물 군번줄처럼 쉼터에서 충전을 되돌리는 효과도 여기서 돌아간다
## (docs/systems/RELICS.md 6.2절 17번, RunState.notify_rest).

## 회복을 골랐을 때 채우는 양. 최대 체력에 대한 비율이다 (2026-08-10 채택)
@export var heal_ratio: float = 0.4
## 강화를 골랐을 때 오르는 최대 체력. 오른 만큼 즉시 채워진다 (2026-08-10 채택)
@export var max_health_gain: int = 8

var _opened: bool = false
## 쉼터에 들어선 플레이어. 부모 Room 의 _player 와는 수명이 다르다.
## 부모 쪽은 전투 활성 구간에서만 살아 있고 방을 나가면 비워진다. 쉼터는 전투가 없어
## 부모가 일찍 _finished 로 갈 수 있으므로 자기 참조를 따로 들고 있는다.
## 이름을 겹치면 GDScript 가 파서 오류를 낸다 (부모 멤버 중복 선언)
var _rest_player: Player = null

@onready var _notice: Label = get_node_or_null(^"Notice/Text") as Label
@onready var _panel: ShrinePanel = get_node_or_null(^"RestUi/ShrinePanel") as ShrinePanel


func _ready() -> void:
	super()
	zone.body_entered.connect(_on_rest_entered)
	if _panel != null:
		_panel.chosen.connect(_on_choice)


func _on_rest_entered(body: Node2D) -> void:
	if _opened or not body.is_in_group(&"player"):
		return
	_rest_player = body as Player
	# 되짚어 온 쉼터는 비어 있다. 이 검사가 없으면 왕복만으로 무한히 회복할 수 있다
	if is_empty_room():
		_set_notice("이미 쉬어 간 자리")
		return
	_opened = true
	_open_menu()


func _open_menu() -> void:
	if _panel == null:
		return
	get_tree().paused = true
	_panel.open("쉼터", [_heal_label(), _gain_label()], "", [], "위아래 선택, 점프로 결정")


func _heal_label() -> String:
	return "회복  체력 %d" % _heal_amount()


func _gain_label() -> String:
	return "강화  최대 체력 +%d" % max_health_gain


## 회복량. 최대 체력 비례라 강화를 쌓을수록 회복도 같이 커진다
func _heal_amount() -> int:
	if _rest_player == null:
		return 0
	return maxi(1, int(round(float(_rest_player.health.maximum) * heal_ratio)))


func _on_choice(index: int) -> void:
	get_tree().paused = false
	# 어느 쪽을 고르든 쉼터를 지난 것이므로 유물 충전을 되돌린다
	RunState.notify_rest()
	if index == 0:
		_take_heal()
	else:
		_take_gain()


func _take_heal() -> void:
	if _rest_player == null:
		return
	var healed: int = _rest_player.health.heal(_heal_amount())
	if healed <= 0:
		_set_notice("이미 온전하다")
		return
	_set_notice("체력 %d 회복" % healed)


## 최대 체력 상승은 RunState가 런 스코프로 들고 있다가 사망 시 함께 사라진다.
## 갱신 신호를 받은 플레이어가 오른 만큼을 즉시 채운다 (player._apply_run_bonuses)
func _take_gain() -> void:
	RunState.add_rest_max_health(max_health_gain)
	_set_notice("최대 체력 +%d" % max_health_gain)


func _set_notice(text: String) -> void:
	if _notice != null:
		_notice.text = text
