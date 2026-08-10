@tool
class_name Block
extends StaticBody2D

## 지형 블록 (도형 콜리전 + 판자 타일 텍스처).
##
## 원점은 블록의 좌상단이다. 방 설계는 타일 격자에 맞춘다 (docs/ROOM_SPEC.md).
## 텍스처는 16px 판자 타일을 반복한다 (2026-08-02 배경 정합. 이전에는 단색 사각형).
## @tool: 에디터에서 size를 바꾸면 즉시 반영된다 (Windows에서 눈으로 배치하기 위함).

## 블록 크기 (px)
@export var size: Vector2i = Vector2i(64, 16):
	set(value):
		size = value
		_refresh()

## 텍스처에 곱하는 색 (기본 흰색 = 원색 유지)
@export var color: Color = Color.WHITE:
	set(value):
		color = value
		_refresh()

@onready var rect: TextureRect = $Rect as TextureRect
@onready var shape: CollisionShape2D = $Shape as CollisionShape2D


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_node_ready():
		return
	rect.position = Vector2.ZERO
	rect.size = Vector2(size)
	rect.self_modulate = color
	# 씬에 심어둔 RectangleShape2D를 재사용한다 (resource_local_to_scene=true라 인스턴스마다 사본).
	# 매번 새로 만들면 에디터 저장 시 인스턴스마다 sub_resource가 직렬화돼 씬 파일이 부푼다.
	var rectangle: RectangleShape2D = shape.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		shape.shape = rectangle
	rectangle.size = Vector2(size)
	shape.position = Vector2(size) * 0.5
