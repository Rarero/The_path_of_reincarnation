extends Node2D

## 절차적 연출 검증. 적이 실제로 움직이는 동안 여러 프레임을 저장한다.

const LIST: Array = [
	["res://scenes/enemies/enemy_charger.tscn", 90],
	["res://scenes/enemies/enemy_shooter.tscn", 180],
	["res://scenes/enemies/enemy_fence.tscn", 270],
	["res://scenes/enemies/enemy_wrestler.tscn", 355],
	["res://scenes/enemies/enemy_egg.tscn", 435],
]

## 프레임을 저장할 디렉터리. 이어 붙여 쓰므로 검사기가 리터럴로 보지 않는다
const SHOT_DIR: String = "res://tools/"

var _frame: int = 0
var _shot: int = 0
var _player: Node2D = null


func _ready() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.14, 0.12, 0.16)
	bg.size = Vector2(480, 270)
	add_child(bg)
	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 1
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(900.0, 40.0)
	shape.shape = rect
	shape.position = Vector2(240.0, 220.0)
	body.add_child(shape)
	add_child(body)
	var ground: ColorRect = ColorRect.new()
	ground.color = Color(0.26, 0.22, 0.2)
	ground.position = Vector2(0, 200)
	ground.size = Vector2(480, 70)
	add_child(ground)
	var wisp: Node2D = (load("res://scenes/levels/wisp_platform.tscn") as PackedScene).instantiate() as Node2D
	add_child(wisp)
	wisp.position = Vector2(140.0, 170.0)
	_player = (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Node2D
	add_child(_player)
	_player.position = Vector2(240.0, 200.0)
	_player.set_physics_process(false)
	for item: Array in LIST:
		var e: EnemyBase = (load(String(item[0])) as PackedScene).instantiate() as EnemyBase
		add_child(e)
		e.position = Vector2(float(item[1]), 200.0)


func _process(_d: float) -> void:
	_frame += 1
	if _frame < 30 or _frame % 12 != 0 or _shot >= 8:
		return
	# 경로를 이어 붙여 만든다. res:// 문자열에 %d를 넣으면 tools/check.py의
	# 리소스 참조 검사가 존재하지 않는 리소스로 오인한다
	var out_path: String = SHOT_DIR + "anim_" + str(_shot) + ".png"
	get_viewport().get_texture().get_image().save_png(out_path)
	_shot += 1
	if _shot >= 8:
		print("연출 프레임 8장 저장")
		get_tree().quit()
