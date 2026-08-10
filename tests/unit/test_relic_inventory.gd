extends GdUnitTestSuite

## 유물 인벤토리 로직 검증 (docs/systems/RELICS.md 8, 9). 순수 로직만 단위 테스트한다.


func _stat_relic(id: StringName, key: StringName, value: float, multiplier: bool) -> RelicDef:
	var effect: RelicEffect = RelicEffect.new()
	effect.hook = RelicEffect.Hook.STAT_MODIFIER
	effect.target_key = key
	effect.value = value
	effect.is_multiplier = multiplier
	var def: RelicDef = RelicDef.new()
	def.id = id
	var effects: Array[RelicEffect] = [effect]
	def.effects = effects
	return def


func _rule_relic(id: StringName, key: StringName, value: float) -> RelicDef:
	var effect: RelicEffect = RelicEffect.new()
	effect.hook = RelicEffect.Hook.RULE_OVERRIDE
	effect.target_key = key
	effect.value = value
	var def: RelicDef = RelicDef.new()
	def.id = id
	var effects: Array[RelicEffect] = [effect]
	def.effects = effects
	return def


func _lethal_relic(id: StringName) -> RelicDef:
	var effect: RelicEffect = RelicEffect.new()
	effect.hook = RelicEffect.Hook.ON_LETHAL_DAMAGE
	effect.charges_per_run = 1
	effect.recharge_at_rest = true
	var def: RelicDef = RelicDef.new()
	def.id = id
	var effects: Array[RelicEffect] = [effect]
	def.effects = effects
	return def


func _hit_relic(id: StringName, cooldown: float) -> RelicDef:
	var effect: RelicEffect = RelicEffect.new()
	effect.hook = RelicEffect.Hook.ON_HIT_TAKEN
	effect.cooldown_sec = cooldown
	var def: RelicDef = RelicDef.new()
	def.id = id
	var effects: Array[RelicEffect] = [effect]
	def.effects = effects
	return def


func test_unique_blocks_duplicate() -> void:
	var inv: RelicInventory = RelicInventory.new()
	var relic: RelicDef = _stat_relic(&"r", &"melee_damage", 0.1, true)
	assert_bool(inv.add(relic)).is_true()
	assert_bool(inv.add(relic)).is_false()
	assert_int(inv.size()).is_equal(1)


func test_mult_and_flat_bonus_sum_additively() -> void:
	var inv: RelicInventory = RelicInventory.new()
	inv.add(_stat_relic(&"a", &"melee_damage", 0.08, true))
	inv.add(_stat_relic(&"b", &"melee_damage", 0.05, true))
	inv.add(_stat_relic(&"c", &"max_health", 20.0, false))
	assert_float(inv.mult_bonus(&"melee_damage")).is_equal_approx(0.13, 0.0001)
	assert_float(inv.flat_bonus(&"max_health")).is_equal_approx(20.0, 0.0001)


func test_rule_bonus_adds_to_default_via_caller() -> void:
	var inv: RelicInventory = RelicInventory.new()
	inv.add(_rule_relic(&"pat", &"deathmatch_delay", 30.0))
	assert_float(inv.rule_bonus(&"deathmatch_delay")).is_equal_approx(30.0, 0.0001)


func test_lethal_absorb_consumes_then_recharges_at_rest() -> void:
	var inv: RelicInventory = RelicInventory.new()
	inv.add(_lethal_relic(&"dogtag"))
	assert_bool(inv.try_absorb_lethal()).is_true()
	assert_bool(inv.try_absorb_lethal()).is_false()
	inv.recharge_at_rest()
	assert_bool(inv.try_absorb_lethal()).is_true()


func test_hit_taken_respects_cooldown() -> void:
	var inv: RelicInventory = RelicInventory.new()
	inv.add(_hit_relic(&"hazel", 8.0))
	assert_bool(inv.hit_taken_ready(0.0)).is_true()
	assert_bool(inv.hit_taken_ready(1.0)).is_false()
	assert_bool(inv.hit_taken_ready(8.5)).is_true()


func test_clear_empties_inventory() -> void:
	var inv: RelicInventory = RelicInventory.new()
	inv.add(_stat_relic(&"a", &"x", 1.0, false))
	inv.clear()
	assert_int(inv.size()).is_equal(0)
