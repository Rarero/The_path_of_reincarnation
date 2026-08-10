class_name SpawnSlot
extends Marker2D

## 배치 후보 지점 (docs/ROOM_SPEC.md 3장 슬롯 규격).
##
## 방 씬에는 후보 지점만 두고 실제 배치는 런타임에 RoomPopulator가 정한다.
## 슬롯이 비는 것은 정상 상태다. 모든 슬롯을 항상 채우면 고정 배치와 다를 바가 없다.
##
## 슬롯마다 허용 태그를 두고, 배치 대상의 태그가 허용 목록에 있을 때만 채운다.
## 지상 슬롯에 등불 도깨비(high)가 들어가지 않고, 공중 슬롯에 잡도깨비(ground)가
## 들어가지 않는 것이 이 규칙의 목적이다.

## 슬롯 종류. 값이 씬 파일에 정수로 저장되므로 순서를 바꾸지 않는다.
## tools/reach_check.py의 SLOT_* 상수도 같은 값을 쓴다.
enum Kind { GROUND, HIGH, AIR, LANE, COVER, WISP, ITEM }

## 종류별 기본 허용 태그 (docs/ROOM_SPEC.md 3장 표)
const KIND_ACCEPTS: Dictionary = {
	Kind.GROUND: ["ground"],
	Kind.HIGH: ["ground", "high"],
	Kind.AIR: ["air", "high"],
	Kind.LANE: ["lane"],
	Kind.COVER: ["cover"],
	Kind.WISP: ["wisp"],
	Kind.ITEM: ["item"],
}

## 표면 위에 서는 슬롯. 도달 가능성 검사에서 설 수 있는 자리여야 한다
const SURFACE_KINDS: Array = [Kind.GROUND, Kind.HIGH, Kind.LANE, Kind.COVER]

@export var kind: Kind = Kind.GROUND
## 기본 허용 태그에 더할 예외 태그. 방 하나에서만 규칙을 넓힐 때 쓴다
@export var extra_accepts: PackedStringArray = PackedStringArray()


## 종류별 기본 허용 태그에 예외 태그를 더한 목록.
static func accepts_for(kind_value: int, extra: PackedStringArray) -> PackedStringArray:
	var tags: PackedStringArray = PackedStringArray()
	for tag: String in KIND_ACCEPTS.get(kind_value, []):
		tags.append(tag)
	for tag: String in extra:
		if not tags.has(tag):
			tags.append(tag)
	return tags


## 표면 위에 서는 슬롯인지 (반대는 부유 슬롯이라 발밑 지형이 필요 없다).
static func is_surface_kind(kind_value: int) -> bool:
	return SURFACE_KINDS.has(kind_value)


func accepts() -> PackedStringArray:
	return accepts_for(kind, extra_accepts)


## RoomPopulator에 넘길 순수 자료. 씬 의존을 여기서 끊어 계획 단계를 테스트 가능하게 둔다.
func to_plan_slot(index: int) -> Dictionary:
	return {
		"index": index,
		"kind": int(kind),
		"accepts": accepts(),
		"position": position,
	}
