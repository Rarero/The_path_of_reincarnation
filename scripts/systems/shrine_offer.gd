class_name ShrineOffer
extends RefCounted

## 신당 3택 선택 로직 (순수 로직, 단위 테스트 대상. docs/systems/BOONS.md 7장).
##
## 시드로 확정한다 (재현성). 몸주 계열 최소 1개 보장, 3택 전부 같은 계열 금지.
## 후보 필터링(구현 여부, 티어, 보유 제외)은 호출자가 미리 한다.


## 권능 3택을 만든다. mongju가 -1이면 몸주 보장을 생략한다.
static func offer(
	candidates: Array[BoonDef], mongju: int, offer_seed: int, count: int = 3
) -> Array[BoonDef]:
	var pool: Array[BoonDef] = candidates.duplicate()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = offer_seed
	_shuffle(pool, rng)

	var result: Array[BoonDef] = []
	if mongju >= 0:
		for def: BoonDef in pool:
			if int(def.pantheon) == mongju:
				result.append(def)
				break

	for def: BoonDef in pool:
		if result.size() >= count:
			break
		if result.has(def):
			continue
		result.append(def)

	_ensure_diversity(result, pool)
	return result


## 몸주 신당 3택: 상시 계열 후보에서 서로 다른 계열을 뽑는다.
static func offer_mongju(pantheons: Array[int], offer_seed: int, count: int = 3) -> Array[int]:
	var pool: Array[int] = []
	for value: int in pantheons:
		if not pool.has(value):
			pool.append(value)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = offer_seed
	_shuffle_ints(pool, rng)
	return pool.slice(0, mini(count, pool.size()))


## 3택이 전부 같은 계열이면 다른 계열 후보로 마지막 하나를 교체한다.
static func _ensure_diversity(result: Array[BoonDef], pool: Array[BoonDef]) -> void:
	if result.size() < 2:
		return
	var first_pantheon: int = int(result[0].pantheon)
	for def: BoonDef in result:
		if int(def.pantheon) != first_pantheon:
			return
	for def: BoonDef in pool:
		if result.has(def):
			continue
		if int(def.pantheon) != first_pantheon:
			result[result.size() - 1] = def
			return


static func _shuffle(array: Array[BoonDef], rng: RandomNumberGenerator) -> void:
	for i: int in range(array.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: BoonDef = array[i]
		array[i] = array[j]
		array[j] = temp


static func _shuffle_ints(array: Array[int], rng: RandomNumberGenerator) -> void:
	for i: int in range(array.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: int = array[i]
		array[i] = array[j]
		array[j] = temp
