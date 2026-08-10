extends GdUnitTestSuite

## 권능 보유 구조 검증 (docs/systems/BOONS.md 3). 액티브 1 + 권능 3칸.


func _boon(id: StringName, pantheon: BoonDef.Pantheon) -> BoonDef:
	var def: BoonDef = BoonDef.new()
	def.id = id
	def.pantheon = pantheon
	return def


func _stat_boon(id: StringName, key: StringName, value: float) -> BoonDef:
	var effect: BoonEffect = BoonEffect.new()
	effect.hook = BoonEffect.Hook.STAT_MODIFIER
	effect.target_key = key
	effect.base_value = value
	effect.is_multiplier = false
	var def: BoonDef = BoonDef.new()
	def.id = id
	var effects: Array[BoonEffect] = [effect]
	def.stat_effects = effects
	return def


func test_slot_cap_is_three() -> void:
	var loadout: BoonLoadout = BoonLoadout.new()
	assert_bool(loadout.add_boon(_boon(&"b1", BoonDef.Pantheon.SANSIN))).is_true()
	assert_bool(loadout.add_boon(_boon(&"b2", BoonDef.Pantheon.SANSIN))).is_true()
	assert_bool(loadout.add_boon(_boon(&"b3", BoonDef.Pantheon.JOWANG))).is_true()
	assert_bool(loadout.add_boon(_boon(&"b4", BoonDef.Pantheon.JOWANG))).is_false()
	assert_int(loadout.slot_count()).is_equal(3)


func test_duplicate_boon_rejected() -> void:
	var loadout: BoonLoadout = BoonLoadout.new()
	var boon: BoonDef = _boon(&"dup", BoonDef.Pantheon.SANSIN)
	assert_bool(loadout.add_boon(boon)).is_true()
	assert_bool(loadout.add_boon(boon)).is_false()


func test_active_sets_mongju() -> void:
	var loadout: BoonLoadout = BoonLoadout.new()
	loadout.set_active(_boon(&"active", BoonDef.Pantheon.JOWANG))
	assert_bool(loadout.has_active()).is_true()
	assert_int(loadout.mongju).is_equal(int(BoonDef.Pantheon.JOWANG))


func test_active_does_not_use_a_slot() -> void:
	var loadout: BoonLoadout = BoonLoadout.new()
	loadout.set_active(_boon(&"active", BoonDef.Pantheon.SANSIN))
	assert_int(loadout.slot_count()).is_equal(0)


func test_stat_aggregation_sums_active_and_slots() -> void:
	var loadout: BoonLoadout = BoonLoadout.new()
	loadout.set_active(_stat_boon(&"a", &"max_health", 20.0))
	loadout.add_boon(_stat_boon(&"b", &"max_health", 15.0))
	assert_float(loadout.flat_bonus(&"max_health")).is_equal_approx(35.0, 0.0001)


func test_clear_resets() -> void:
	var loadout: BoonLoadout = BoonLoadout.new()
	loadout.set_active(_boon(&"a", BoonDef.Pantheon.SANSIN))
	loadout.add_boon(_boon(&"b", BoonDef.Pantheon.JOWANG))
	loadout.clear()
	assert_bool(loadout.has_active()).is_false()
	assert_int(loadout.slot_count()).is_equal(0)
	assert_int(loadout.mongju).is_equal(-1)
