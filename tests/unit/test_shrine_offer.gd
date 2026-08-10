extends GdUnitTestSuite

## 신당 3택 선택 로직 검증 (docs/systems/BOONS.md 7). 몸주 보장과 계열 다양성, 재현성.


func _boon(id: StringName, pantheon: BoonDef.Pantheon) -> BoonDef:
	var def: BoonDef = BoonDef.new()
	def.id = id
	def.pantheon = pantheon
	return def


func _mixed_pool() -> Array[BoonDef]:
	var pool: Array[BoonDef] = [
		_boon(&"s1", BoonDef.Pantheon.SANSIN),
		_boon(&"s2", BoonDef.Pantheon.SANSIN),
		_boon(&"j1", BoonDef.Pantheon.JOWANG),
		_boon(&"j2", BoonDef.Pantheon.JOWANG),
	]
	return pool


func test_offer_includes_mongju_pantheon() -> void:
	var offered: Array[BoonDef] = ShrineOffer.offer(
		_mixed_pool(), int(BoonDef.Pantheon.SANSIN), 123, 3
	)
	var has_mongju: bool = false
	for boon: BoonDef in offered:
		if int(boon.pantheon) == int(BoonDef.Pantheon.SANSIN):
			has_mongju = true
	assert_bool(has_mongju).is_true()


func test_offer_is_reproducible_by_seed() -> void:
	var first: Array[BoonDef] = ShrineOffer.offer(_mixed_pool(), -1, 77, 3)
	var second: Array[BoonDef] = ShrineOffer.offer(_mixed_pool(), -1, 77, 3)
	assert_int(first.size()).is_equal(second.size())
	for i: int in range(first.size()):
		assert_str(String(first[i].id)).is_equal(String(second[i].id))


func test_offer_not_all_same_pantheon_when_possible() -> void:
	var pool: Array[BoonDef] = [
		_boon(&"s1", BoonDef.Pantheon.SANSIN),
		_boon(&"s2", BoonDef.Pantheon.SANSIN),
		_boon(&"s3", BoonDef.Pantheon.SANSIN),
		_boon(&"j1", BoonDef.Pantheon.JOWANG),
	]
	var offered: Array[BoonDef] = ShrineOffer.offer(pool, int(BoonDef.Pantheon.SANSIN), 5, 3)
	var pantheons: Array[int] = []
	for boon: BoonDef in offered:
		if not pantheons.has(int(boon.pantheon)):
			pantheons.append(int(boon.pantheon))
	assert_int(pantheons.size()).is_greater_equal(2)


func test_offer_mongju_returns_distinct() -> void:
	var pantheons: Array[int] = [
		int(BoonDef.Pantheon.SANSIN),
		int(BoonDef.Pantheon.JOWANG),
		int(BoonDef.Pantheon.SANSIN),
	]
	var choices: Array[int] = ShrineOffer.offer_mongju(pantheons, 9, 3)
	assert_int(choices.size()).is_equal(2)
