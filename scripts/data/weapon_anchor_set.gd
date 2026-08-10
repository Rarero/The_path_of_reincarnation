class_name WeaponAnchorSet
extends Resource

## 무기 오버레이 앵커표 (docs/ART_WEAPON_SPLIT.md 3.3).
##
## 몸 클립에 무기를 얹을 위치를 클립 이름과 프레임 번호로 찾는다. 값은
## tools/pipeline/gen_weapon_anchors.py가 굽는다. 손으로 고치지 않는다.
##
## 프레임당 4개 값을 이어 붙인 PackedInt32Array다. Dictionary에 배열의 배열을
## 넣으면 .tres가 장황해지고 Godot이 Variant로 다뤄 형이 흐려진다.
##   x  y  angle_index  visible
## x y는 몸 클립 캔버스 안의 손 위치이며 무기 각도 프레임의 정중앙(그립)이
## 그 자리에 온다. visible이 0이면 그 프레임은 무기를 그리지 않는다.
## 타격 순간이 그렇고 참격 이펙트가 대신한다 (6장 확인 1).

const STRIDE: int = 4

## 클립 이름(StringName) -> PackedInt32Array
@export var clips: Dictionary = {}

## 몸 클립 한 프레임의 한 변 (px). 앵커 좌표계의 기준이다
@export var canvas: int = 76

## 각도 프레임 개수. 한 칸이 360/steps 도다
@export var angle_steps: int = 16


func has_clip(clip: StringName) -> bool:
	return clips.has(clip)


func frame_count(clip: StringName) -> int:
	var packed: PackedInt32Array = clips.get(clip, PackedInt32Array())
	@warning_ignore("integer_division")
	return packed.size() / STRIDE


## 프레임 하나의 앵커. x, y, 각도 index, 표시 여부를 담는다.
## 클립이나 프레임이 없으면 표시 여부가 0인 값을 돌려준다
func anchor(clip: StringName, frame: int) -> Vector4i:
	var packed: PackedInt32Array = clips.get(clip, PackedInt32Array())
	var offset: int = frame * STRIDE
	if frame < 0 or offset + STRIDE > packed.size():
		return Vector4i.ZERO
	return Vector4i(packed[offset], packed[offset + 1], packed[offset + 2], packed[offset + 3])
