class_name SpawnCatalog
extends RefCounted

## 슬롯에 채울 수 있는 대상 목록 (docs/act1/ENEMIES.md 2장 위협 포인트, 6장 조합 규칙).
##
## 미구현 개체도 데이터로 남긴다. scene이 빈 문자열이면 아직 배치할 수 없고
## RoomPopulator의 기본 후보에서 빠진다. 구현되면 scene과 stats만 채우면 된다.
##
## threat_pt는 EnemyStats.threat_pt와 같은 값이어야 한다. 수치의 권위는 .tres 쪽이고
## 이 표는 미구현 개체까지 포함한 설계 표라, 둘이 어긋나지 않는지는 테스트로 고정한다
## (tests/unit/test_spawn_catalog.gd).

## 허용 태그 전체. 슬롯의 허용 목록도 이 안에서만 고른다
const KNOWN_TAGS: Array = ["ground", "high", "air", "lane", "cover", "wisp", "item"]

## 위협 예산을 소비하는 태그 (지형 소품과 아이템은 예산 밖이다)
const ENEMY_TAGS: Array = ["ground", "high", "air", "lane"]

const ENTRIES: Dictionary = {
	&"goblin_charger":
	{
		"display": "잡도깨비",
		"tag": "ground",
		"threat_pt": 1.0,
		"scene": "res://scenes/enemies/enemy_charger.tscn",
		"stats": "res://resources/enemies/goblin_charger.tres",
	},
	&"lantern_shooter":
	{
		"display": "등불 도깨비",
		"tag": "high",
		"threat_pt": 1.5,
		"scene": "res://scenes/enemies/enemy_shooter.tscn",
		"stats": "res://resources/enemies/lantern_shooter.tres",
	},
	&"fence_dokkaebi":
	{
		"display": "장물아비",
		"tag": "ground",
		"threat_pt": 2.0,
		"scene": "res://scenes/enemies/enemy_fence.tscn",
		"stats": "res://resources/enemies/fence_dokkaebi.tres",
	},
	&"ssireum_wrestler":
	{
		"display": "씨름꾼",
		"tag": "ground",
		"threat_pt": 4.0,
		"scene": "res://scenes/enemies/enemy_wrestler.tscn",
		"stats": "res://resources/enemies/ssireum_wrestler.tres",
	},
	&"egg_dokkaebi":
	{
		"display": "달걀도깨비",
		"tag": "lane",
		"threat_pt": 0.5,
		"scene": "res://scenes/enemies/enemy_egg.tscn",
		"stats": "res://resources/enemies/egg_dokkaebi.tres",
	},
	&"stall_cover":
	{
		"display": "파괴 가능 좌판",
		"tag": "cover",
		"threat_pt": 0.0,
		"scene": "res://scenes/levels/stall_cover.tscn",
		"stats": "",
	},
	&"wisp_platform":
	{
		"display": "도깨비불 발판",
		"tag": "wisp",
		"threat_pt": 0.0,
		"scene": "res://scenes/levels/wisp_platform.tscn",
		"stats": "",
	},
}


static func has_entry(id: StringName) -> bool:
	return ENTRIES.has(id)


static func entry(id: StringName) -> Dictionary:
	return ENTRIES.get(id, {})


## 표시 이름. 검증 화면과 로그가 쓴다 (인게임 개체에는 이름을 띄우지 않는다)
static func display_name(id: StringName) -> String:
	return String(entry(id).get("display", String(id)))


static func tag_of(id: StringName) -> String:
	return String(entry(id).get("tag", ""))


static func threat_pt(id: StringName) -> float:
	return float(entry(id).get("threat_pt", 0.0))


static func scene_path(id: StringName) -> String:
	return String(entry(id).get("scene", ""))


static func stats_path(id: StringName) -> String:
	return String(entry(id).get("stats", ""))


## 구현이 끝나 실제로 배치할 수 있는지
static func is_available(id: StringName) -> bool:
	return not scene_path(id).is_empty()


## 위협 예산을 소비하는 대상인지 (지형 소품과 아이템은 아니다)
static func is_enemy(id: StringName) -> bool:
	return ENEMY_TAGS.has(tag_of(id))


## 지금 배치 가능한 적 id 목록. 미구현 개체는 빠진다
static func available_enemy_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in ENTRIES:
		if is_enemy(id) and is_available(id):
			ids.append(id)
	return ids


## 설계상 정의된 적 id 전부 (미구현 포함). 테스트와 문서 대조용
static func all_enemy_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in ENTRIES:
		if is_enemy(id):
			ids.append(id)
	return ids
