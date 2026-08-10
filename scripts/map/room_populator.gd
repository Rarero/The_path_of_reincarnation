class_name RoomPopulator
extends RefCounted

## 슬롯 기반 랜덤 배치 계획기 (docs/ROOM_SPEC.md 3장, docs/act1/ENEMIES.md 2장과 6장).
##
## 씬과 노드에 의존하지 않는 순수 로직이다. 슬롯 목록과 맥락(위협 예산, 방 패턴, 시드)을
## 받아 "어느 슬롯에 무엇을 놓을지"만 정한다. 실제 인스턴스화는 Room이 한다.
##
## 규칙 요약
## - 위협 포인트 예산이 채우기 제약이다. 방 예산을 넘지 않는다.
##   예산은 지도 진행도가 정한다 (docs/RUN_STRUCTURE.md 11.7)
## - 웨이브가 둘이면 웨이브별 상한은 방 예산의 60퍼센트다
## - 슬롯은 비어도 정상이다. 목표 소비량과 건너뛰기 확률이 빈 슬롯을 만든다
## - 하드 금지 5건 중 배치로 통제하는 4건을 여기서 막는다. 잡도깨비 순차 공격은
##   행동 규칙이라 EnemyBase 쪽 책임이다 (docs/act1/ENEMIES.md 6장)

## 웨이브가 둘일 때 웨이브별 상한 비율
const WAVE_SHARE: float = 0.6
## 웨이브 목표 소비량의 하한 비율. 상한은 1.0이라 예산을 다 쓰지 않는 방이 나온다
const TARGET_MIN_RATIO: float = 0.75
## 슬롯 하나를 그냥 건너뛸 확률. 같은 예산이어도 배치 위치가 갈린다
const SKIP_CHANCE: float = 0.15
## 지형 소품 슬롯을 채울 확률
const PROP_FILL_CHANCE: float = 0.65
## 달걀도깨비 밀집 금지의 최소 간격 (px)
const EGG_MIN_DISTANCE: float = 96.0
## 웨이브 상한
const MAX_WAVES: int = 2

const MAX_SSIREUM_PER_WAVE: int = 1
const MAX_EGG_PER_WAVE: int = 2
const MAX_FENCE_PER_ROOM: int = 1

const ID_SSIREUM: StringName = &"ssireum_wrestler"
const ID_FENCE: StringName = &"fence_dokkaebi"
const ID_EGG: StringName = &"egg_dokkaebi"

## 방 패턴별 기준 조합 (docs/act1/ENEMIES.md 6장 방 패턴별 배치).
## roster는 가중치, caps는 방 하나에서의 개체 수 상한이다.
const PATTERNS: Dictionary = {
	"street":
	{
		"roster":
		{
			&"goblin_charger": 6,
			&"ssireum_wrestler": 3,
			&"lantern_shooter": 1,
		},
		"caps": {&"ssireum_wrestler": 1, &"lantern_shooter": 1},
	},
	"roof":
	{
		"roster": {&"lantern_shooter": 4, &"goblin_charger": 2},
		"caps": {&"goblin_charger": 2},
	},
	"alley":
	{
		"roster":
		{
			&"goblin_charger": 6,
			&"fence_dokkaebi": 3,
			&"egg_dokkaebi": 3,
		},
		"caps": {&"fence_dokkaebi": 1, &"egg_dokkaebi": 1},
	},
	"warehouse":
	{
		"roster":
		{
			&"goblin_charger": 5,
			&"fence_dokkaebi": 4,
			&"egg_dokkaebi": 1,
		},
		"caps": {&"fence_dokkaebi": 1, &"egg_dokkaebi": 1},
	},
	"platform":
	{
		"roster": {&"lantern_shooter": 2, &"egg_dokkaebi": 2},
		"caps": {&"egg_dokkaebi": 2},
	},
}


## 방 하나의 배치를 정한다.
##
## slots: SpawnSlot.to_plan_slot() 형식의 사전 배열
## context: pattern, budget, wave_count, seed, available_ids(선택)
static func plan(slots: Array, context: Dictionary) -> Dictionary:
	var pattern: String = String(context.get("pattern", "street"))
	if not PATTERNS.has(pattern):
		pattern = "street"
	var budget: float = maxf(0.0, float(context.get("budget", 6.0)))
	var wave_count: int = clampi(int(context.get("wave_count", 1)), 1, MAX_WAVES)
	var available: Array = context.get("available_ids", SpawnCatalog.available_enemy_ids())
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(context.get("seed", 0))

	var enemy_slots: Array = []
	var prop_slots: Array = []
	for slot: Dictionary in slots:
		if _accepts_any(slot, SpawnCatalog.ENEMY_TAGS):
			enemy_slots.append(slot)
		else:
			prop_slots.append(slot)

	var props: Array = _plan_props(prop_slots, rng)
	var result: Dictionary = _plan_waves(
		enemy_slots, pattern, budget, wave_count, available, rng
	)
	result["pattern"] = pattern
	result["budget"] = budget
	result["props"] = props
	return result


## 슬롯이 태그 중 하나라도 받는지
static func _accepts_any(slot: Dictionary, tags: Array) -> bool:
	var accepts: PackedStringArray = slot.get("accepts", PackedStringArray())
	for tag: String in tags:
		if accepts.has(tag):
			return true
	return false


static func _plan_props(prop_slots: Array, rng: RandomNumberGenerator) -> Array:
	var placed: Array = []
	for slot: Dictionary in prop_slots:
		if rng.randf() >= PROP_FILL_CHANCE:
			continue
		var candidates: Array = []
		for id: StringName in SpawnCatalog.ENTRIES:
			if SpawnCatalog.is_enemy(id) or not SpawnCatalog.is_available(id):
				continue
			if slot.get("accepts", PackedStringArray()).has(SpawnCatalog.tag_of(id)):
				candidates.append({"id": id, "weight": 1})
		if candidates.is_empty():
			continue
		placed.append({"slot": int(slot["index"]), "id": _weighted_pick(candidates, rng)})
	return placed


static func _plan_waves(
	enemy_slots: Array,
	pattern: String,
	budget: float,
	wave_count: int,
	available: Array,
	rng: RandomNumberGenerator
) -> Dictionary:
	var buckets: Array = _split_into_waves(enemy_slots, wave_count, rng)
	var wave_cap: float = budget if wave_count <= 1 else budget * WAVE_SHARE
	var room_counts: Dictionary = {}
	var waves: Array = []
	var wave_spent: Array = []
	var remaining: float = budget
	for index: int in range(wave_count):
		var cap: float = minf(wave_cap, remaining)
		var target: float = cap * rng.randf_range(TARGET_MIN_RATIO, 1.0)
		var filled: Dictionary = _fill_wave(
			buckets[index], pattern, cap, target, room_counts, available, rng
		)
		waves.append(filled["placed"])
		wave_spent.append(filled["spent"])
		remaining -= float(filled["spent"])
	var spent: float = budget - remaining
	return {"waves": waves, "wave_spent": wave_spent, "spent": spent}


## 슬롯을 섞어 웨이브별로 나눈다. 라운드 로빈이라 웨이브마다 방 전체에 흩어진다.
static func _split_into_waves(slots: Array, wave_count: int, rng: RandomNumberGenerator) -> Array:
	var buckets: Array = []
	for _i: int in range(wave_count):
		buckets.append([])
	var order: Array = _shuffled(slots, rng)
	for index: int in range(order.size()):
		buckets[index % wave_count].append(order[index])
	return buckets


static func _fill_wave(
	bucket: Array,
	pattern: String,
	cap: float,
	target: float,
	room_counts: Dictionary,
	available: Array,
	rng: RandomNumberGenerator
) -> Dictionary:
	var placed: Array = []
	var wave_counts: Dictionary = {}
	var egg_positions: Array = []
	var spent: float = 0.0
	for slot: Dictionary in bucket:
		if spent >= target:
			break
		if rng.randf() < SKIP_CHANCE:
			continue
		var candidates: Array = _candidates_for(
			slot, pattern, cap - spent, room_counts, wave_counts, egg_positions, available
		)
		if candidates.is_empty():
			continue
		var id: StringName = _weighted_pick(candidates, rng)
		placed.append({"slot": int(slot["index"]), "id": id})
		spent += SpawnCatalog.threat_pt(id)
		room_counts[id] = int(room_counts.get(id, 0)) + 1
		wave_counts[id] = int(wave_counts.get(id, 0)) + 1
		if id == ID_EGG:
			egg_positions.append(slot.get("position", Vector2.ZERO))
	return {"placed": placed, "spent": spent}


## 이 슬롯에 놓을 수 있는 후보와 가중치. 태그, 예산, 패턴 상한, 하드 금지를 모두 통과한 것만 남는다.
static func _candidates_for(
	slot: Dictionary,
	pattern: String,
	budget_left: float,
	room_counts: Dictionary,
	wave_counts: Dictionary,
	egg_positions: Array,
	available: Array
) -> Array:
	var spec: Dictionary = PATTERNS[pattern]
	var roster: Dictionary = spec["roster"]
	var caps: Dictionary = spec["caps"]
	var accepts: PackedStringArray = slot.get("accepts", PackedStringArray())
	var candidates: Array = []
	for id: StringName in roster:
		if not available.has(id):
			continue
		if not accepts.has(SpawnCatalog.tag_of(id)):
			continue
		if SpawnCatalog.threat_pt(id) > budget_left:
			continue
		if caps.has(id) and int(room_counts.get(id, 0)) >= int(caps[id]):
			continue
		if not _passes_hard_rules(id, slot, room_counts, wave_counts, egg_positions):
			continue
		candidates.append({"id": id, "weight": int(roster[id])})
	return candidates


## 예산으로 걸러지지 않는 하드 금지 (docs/act1/ENEMIES.md 6장 조합 금지 매트릭스).
static func _passes_hard_rules(
	id: StringName,
	slot: Dictionary,
	room_counts: Dictionary,
	wave_counts: Dictionary,
	egg_positions: Array
) -> bool:
	if id == ID_SSIREUM and int(wave_counts.get(id, 0)) >= MAX_SSIREUM_PER_WAVE:
		return false
	if id == ID_FENCE and int(room_counts.get(id, 0)) >= MAX_FENCE_PER_ROOM:
		return false
	if id == ID_EGG:
		if int(wave_counts.get(id, 0)) >= MAX_EGG_PER_WAVE:
			return false
		var here: Vector2 = slot.get("position", Vector2.ZERO)
		for other: Vector2 in egg_positions:
			if here.distance_to(other) < EGG_MIN_DISTANCE:
				return false
	return true


static func _weighted_pick(candidates: Array, rng: RandomNumberGenerator) -> StringName:
	var total: int = 0
	for candidate: Dictionary in candidates:
		total += maxi(1, int(candidate["weight"]))
	var roll: int = rng.randi_range(0, total - 1)
	for candidate: Dictionary in candidates:
		roll -= maxi(1, int(candidate["weight"]))
		if roll < 0:
			return candidate["id"]
	return candidates[candidates.size() - 1]["id"]


## 결정적 피셔예이츠. 같은 시드는 같은 순서를 낸다
static func _shuffled(source: Array, rng: RandomNumberGenerator) -> Array:
	var copy: Array = source.duplicate()
	for i: int in range(copy.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = copy[i]
		copy[i] = copy[j]
		copy[j] = tmp
	return copy
