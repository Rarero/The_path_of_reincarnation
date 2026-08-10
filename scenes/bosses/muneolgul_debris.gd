class_name MuneolgulDebris
extends Node2D

## 문얼굴 보스의 낙하물/투척물 공용 투사체 (docs/act1/BOSS.md 3.1, 2026-08-07 재설계).
##
## 지진 패턴의 낙석(수직 낙하, 바닥에서 부서짐)과 바람 패턴의 장애물(수평 직선 비행,
## 왼쪽 경계에서 소멸)을 한 씬으로 쓴다. 보스가 setup으로 속도와 피해를 넣고 트리에 붙인다.
## 판정은 Hitbox 컴포넌트(활성 중 1회 타격) 재사용. 지형과 충돌하지 않는 연출 판정이라
## 발판을 통과한다 (발판 위도 안전하지 않다는 규칙, BOSS.md 3.1 낙석 항목).

var _velocity: Vector2 = Vector2.ZERO
var _texture: Texture2D = null
## 이 y에 닿으면 부서진다 (수직 낙하 전용). 수평 비행은 넘치게 큰 값을 둔다
var _ground_y: float = 100000.0
## 이 x보다 왼쪽이면 소멸한다 (수평 비행 전용)
var _kill_x: float = -100000.0
var _damage: int = 10
var _multiplier: float = 1.0
## 안전장치: 어떤 경로로도 소멸하지 못했을 때의 수명 (초)
var _life_left: float = 7.0
var _broken: bool = false

## 판정 상자가 그림보다 작으면 맞은 것처럼 보이는데 피해가 없다. 최소 크기 하한 (px)
const MIN_HIT_SIZE: float = 20.0
## 그림 크기 대비 판정 비율. 1.0이면 그림과 같은 크기다
const HIT_SIZE_RATIO: float = 0.9

@onready var _hitbox: Hitbox = $Hitbox as Hitbox
@onready var _hit_shape: CollisionShape2D = $Hitbox/Shape as CollisionShape2D
@onready var _visual: Sprite2D = $Visual as Sprite2D


## 트리에 붙이기 전에 호출한다 (Room.configure와 같은 주입 순서).
## texture는 낙석/궤짝 실제 아트다 (2026-08-07 요청서 024 생성분. 보스가 변주를 골라 넣는다).
func setup(
	velocity_value: Vector2,
	damage_value: int,
	multiplier: float,
	ground_y: float,
	kill_x: float,
	texture: Texture2D = null
) -> void:
	_velocity = velocity_value
	_damage = damage_value
	_multiplier = multiplier
	_ground_y = ground_y
	_kill_x = kill_x
	_texture = texture


func _ready() -> void:
	if _texture != null:
		_visual.texture = _texture
	_fit_hitbox_to_visual()
	_hitbox.damage = _damage
	_hitbox.damage_multiplier = _multiplier
	_hitbox.activate()


func _physics_process(delta: float) -> void:
	if _broken:
		return
	position += _velocity * delta
	_life_left -= delta
	if _velocity.y > 0.0 and global_position.y >= _ground_y:
		_break()
		return
	if global_position.x <= _kill_x or _life_left <= 0.0:
		queue_free()


## 판정 상자를 그림 크기에 맞춘다. 씬의 16 x 16 고정 상자는 27px 낙석과 26 x 28 궤짝보다
## 작아서, 스쳐도 맞은 것처럼 보이는데 피해가 들어가지 않는 원인이었다 (2026-08-08 사용자 보고).
## 모양 리소스는 씬 전체가 공유하므로 인스턴스마다 복제해서 고친다.
func _fit_hitbox_to_visual() -> void:
	var rect: RectangleShape2D = _hit_shape.shape as RectangleShape2D
	if rect == null:
		return
	rect = rect.duplicate() as RectangleShape2D
	var size: Vector2 = Vector2(MIN_HIT_SIZE, MIN_HIT_SIZE)
	if _texture != null:
		size = Vector2(_texture.get_width(), _texture.get_height()) * HIT_SIZE_RATIO
	rect.size = Vector2(maxf(size.x, MIN_HIT_SIZE), maxf(size.y, MIN_HIT_SIZE))
	_hit_shape.shape = rect


## 착지: 판정을 끄고 납작해지며 사라진다 (적 사망 연출과 같은 문법).
func _break() -> void:
	_broken = true
	_hitbox.deactivate()
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, ^"scale", Vector2(1.5, 0.25), 0.14)
	tween.tween_property(_visual, ^"modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)
