class_name WeaponSprite
extends Sprite2D

## 몸 클립 위에 무기를 얹는 오버레이 (docs/ART_WEAPON_SPLIT.md 3.3).
##
## 몸과 무기를 한 그림에 굽지 않는 것이 이 프로젝트의 규칙이다. 무기마다 몸을
## 다시 그리면 무기가 늘 때마다 인물이 바뀐다는 것이 2026-08-07 실측의 결론이다
## (docs/DECISIONS.md). 그래서 몸은 맨손 클립 하나뿐이고 무기는 여기서 얹는다.
##
## 이 노드는 BodyVisual(AnimatedSprite2D)의 자식이다. 부모의 재생 프레임을 매
## 프레임 읽어 앵커표에서 손 위치와 각도를 찾는다. frame_changed 시그널만 쓰지
## 않는 이유는 flip_h와 애니메이션 교체가 시그널을 내지 않아 한 프레임 어긋나기
## 때문이다. 읽는 값이 셋뿐이라 매 프레임 확인이 더 싸다.
##
## 각도는 런타임 회전이 아니라 프리베이크 프레임 교체다. ART_STYLE 8장의
## 스프라이트 회전 금지를 지킨다.

## 각도 프레임을 이어 붙인 가로 스트립. 한 칸이 정사각이다
@export var angles_texture: Texture2D = null

## 클립별 프레임별 손 위치와 각도
@export var anchors: WeaponAnchorSet = null

var _body: AnimatedSprite2D = null
var _active: bool = false
var _frame_size: int = 0
var _half_canvas: float = 0.0


func _ready() -> void:
	_body = get_parent() as AnimatedSprite2D
	if angles_texture != null:
		texture = angles_texture
		_frame_size = angles_texture.get_height()
		region_enabled = true
	if anchors != null:
		_half_canvas = float(anchors.canvas) * 0.5
	visible = false
	set_process(false)


## 무기를 들었는지. Player가 장착과 해제에서 부른다 (call down 원칙)
func set_active(value: bool) -> void:
	_active = value
	set_process(value)
	if not value:
		visible = false
		return
	_refresh()


func is_active() -> bool:
	return _active


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	if not _active or _body == null or anchors == null or _frame_size <= 0:
		visible = false
		return
	var data: Vector4i = anchors.anchor(_body.animation, _body.frame)
	if data.w == 0:
		visible = false
		return
	visible = true
	region_rect = Rect2(float(data.z * _frame_size), 0.0, float(_frame_size), float(_frame_size))
	# 몸이 뒤집히면 그림 전체가 뒤집힌 것이므로 무기도 좌우를 그대로 되비춘다.
	# 각도 index를 따로 뒤집지 않는다. 두 번 뒤집으면 날 방향이 되돌아간다
	var offset_x: float = float(data.x) - _half_canvas
	if _body.flip_h:
		offset_x = -offset_x
	flip_h = _body.flip_h
	position = Vector2(offset_x, float(data.y) - _half_canvas)
