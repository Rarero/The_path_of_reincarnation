class_name DamageNumber
extends Node2D

## 적 피격 시 뜨는 피해 수치. 위로 살짝 떠오르며 페이드한 뒤 스스로 사라진다.
## enemy_base가 피격 콜백에서 인스턴스화하고 setup(피해값)을 호출한다.

## 떠오르는 높이 (px)
@export var rise: float = 14.0
## 표시 지속 시간 (초). 읽을 수 있게 넉넉히 잡는다
@export var duration: float = 0.9

var _value: int = 0

@onready var _label: Label = $Label as Label


## 표시할 피해값을 지정한다. add_child 전에 호출해도 된다 (값만 저장).
func setup(value: int) -> void:
	_value = value
	if is_node_ready():
		_label.text = str(value)


func _ready() -> void:
	_label.text = str(_value)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	# 앞 구간에 이동을 몰아 위로 톡 떠오른 뒤 멈춘다 (계속 흐르지 않게).
	# 스폰 위치 지정이 이 트윈보다 늦게 실행되므로 절대값이 아니라 상대 이동(as_relative)으로 잡는다
	(
		tween
		. tween_property(self, ^"position:y", -rise, duration * 0.4)
		. as_relative()
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	# 뒤 구간에서만 페이드해 그 전까지는 또렷하게 읽히도록 한다
	tween.tween_property(self, ^"modulate:a", 0.0, duration * 0.3).set_delay(duration * 0.7)
	tween.chain().tween_callback(queue_free)
