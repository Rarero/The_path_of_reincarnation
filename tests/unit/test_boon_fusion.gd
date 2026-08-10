extends GdUnitTestSuite

## 권능 조합 판정 검증 (docs/systems/BOONS.md 5장, 9.3, 10장 규칙 10/13/14/16/21/24/31/32/43/45/48).
##
## 타입 배열은 반드시 지역 변수로 먼저 만들어 넘긴다. 배열 리터럴을 Array[T] 인자나
## 프로퍼티에 바로 넣으면 변환에 실패한다 (test_relic_inventory.gd와 같은 규약).

const SANSIN: int = BoonDef.Pantheon.SANSIN
const JOWANG: int = BoonDef.Pantheon.JOWANG


func _boon(
	id: StringName,
	pantheon: int,
	tier: int = 1,
	layer: int = BoonDef.Layer.REGULAR,
	weapon_tag_inherits: bool = false
) -> BoonDef:
	var def: BoonDef = BoonDef.new()
	def.id = id
	def.pantheon = pantheon
	def.tier = tier
	def.layer = layer
	def.weapon_tag_inherits = weapon_tag_inherits
	return def


## 인자는 일부러 타입 없는 Array로 받는다. 리터럴을 Array[T] 인자에 바로 넣는 것을
## 피하려고 만든 헬퍼인데 헬퍼 자신이 그 형태면 의미가 없다.
func _tags(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: Variant in values:
		result.append(StringName(value))
	return result


func _instance(def: BoonDef, tier: int = -1) -> BoonInstance:
	var instance: BoonInstance = BoonInstance.new(def)
	if tier >= 0:
		instance.tier = tier
	return instance


func _rule(
	main_pantheon: int,
	sub_pantheon: int,
	is_active: bool,
	main_tier: int,
	sub_tier: int,
	result_id: StringName,
	success: float = 0.95,
	great: float = 0.05
) -> FusionRule:
	var rule: FusionRule = FusionRule.new()
	rule.main_pantheon = main_pantheon
	rule.sub_pantheon = sub_pantheon
	rule.is_active_fusion = is_active
	rule.main_tier = main_tier
	rule.sub_tier = sub_tier
	rule.result_id = result_id
	rule.success_chance = success
	rule.great_chance = great
	return rule


func _rules(items: Array) -> Array[FusionRule]:
	var result: Array[FusionRule] = []
	for item: Variant in items:
		result.append(item as FusionRule)
	return result


## 규칙 43: 같은 계열 쌍은 태그 판정 없이 항상 조합 가능하다.
func test_fusible_same_pantheon_always_true() -> void:
	var main: BoonDef = _boon(&"m", SANSIN)
	var sub: BoonDef = _boon(&"s", SANSIN)
	assert_bool(BoonDef.fusible(main, sub)).is_true()


## 규칙 43: 특수 계열이 서브면 태그 판정 없이 항상 조합 가능하다.
func test_fusible_special_sub_always_true() -> void:
	var main: BoonDef = _boon(&"m", SANSIN)
	var sub: BoonDef = _boon(&"s", JOWANG, 1, BoonDef.Layer.SPECIAL)
	assert_bool(BoonDef.fusible(main, sub)).is_true()


## 규칙 43: 다른 계열 쌍은 메인의 fusion_accepts와 서브의 fusion_tags 교집합이 있어야 한다.
func test_fusible_cross_pantheon_requires_tag_overlap() -> void:
	var main: BoonDef = _boon(&"m", SANSIN)
	main.fusion_accepts = _tags([&"chigi"])
	var sub_match: BoonDef = _boon(&"s1", JOWANG)
	sub_match.fusion_tags = _tags([&"chigi", &"beotim"])
	var sub_miss: BoonDef = _boon(&"s2", JOWANG)
	sub_miss.fusion_tags = _tags([&"norim"])
	assert_bool(BoonDef.fusible(main, sub_match)).is_true()
	assert_bool(BoonDef.fusible(main, sub_miss)).is_false()


## 규칙 43: fusion_deny_ids에 있으면 태그가 맞아도 조합할 수 없다.
func test_fusible_deny_ids_blocks_even_with_tag_match() -> void:
	var main: BoonDef = _boon(&"m", SANSIN)
	main.fusion_accepts = _tags([&"chigi"])
	main.fusion_deny_ids = _tags([&"s1"])
	var sub: BoonDef = _boon(&"s1", JOWANG)
	sub.fusion_tags = _tags([&"chigi"])
	assert_bool(BoonDef.fusible(main, sub)).is_false()


## 규칙 45: fusion_tags/fusion_accepts 값은 태그 어휘 8종 안에만 있어야 한다.
func test_fusion_tag_vocabulary_is_closed_set() -> void:
	assert_int(BoonDef.FUSION_TAGS.size()).is_equal(8)
	for tag: StringName in [&"chigi", &"ssogi", &"mom", &"beotim"]:
		assert_bool(BoonDef.FUSION_TAGS.has(tag)).is_true()
	assert_bool(BoonDef.FUSION_TAGS.has(&"not_a_real_tag")).is_false()


func test_check_rejects_tier_mismatch() -> void:
	var main: BoonInstance = _instance(_boon(&"m", SANSIN, 1))
	var sub: BoonInstance = _instance(_boon(&"s", SANSIN, 2))
	var result: Dictionary = BoonFusion.check(main, sub, false)
	assert_bool(result["ok"]).is_false()
	assert_str(result["reason"]).is_equal("tier")


## 규칙 10: 3티어는 재료가 되지 않는다.
func test_check_rejects_max_tier_main() -> void:
	var main: BoonInstance = _instance(_boon(&"m", SANSIN, 3))
	var sub: BoonInstance = _instance(_boon(&"s", SANSIN, 3))
	var result: Dictionary = BoonFusion.check(main, sub, false)
	assert_bool(result["ok"]).is_false()
	assert_str(result["reason"]).is_equal("max_tier")


## 규칙 21: 액티브도 3티어가 상한이라 그 이상 조합되지 않는다.
func test_check_rejects_active_fusion_at_max_tier() -> void:
	var main: BoonInstance = _instance(_boon(&"m", SANSIN, 3))
	var sub: BoonInstance = _instance(_boon(&"s", SANSIN, 2))
	var result: Dictionary = BoonFusion.check(main, sub, true)
	assert_bool(result["ok"]).is_false()
	assert_str(result["reason"]).is_equal("max_tier")


## 규칙 10: 액티브 조합의 서브로도 3티어 권능은 쓸 수 없다.
func test_check_rejects_tier3_boon_as_active_sub() -> void:
	var main: BoonInstance = _instance(_boon(&"m", SANSIN, 2))
	var sub: BoonInstance = _instance(_boon(&"s", SANSIN, 3))
	var result: Dictionary = BoonFusion.check(main, sub, true)
	assert_bool(result["ok"]).is_false()
	assert_str(result["reason"]).is_equal("sub_max_tier")


## 규칙 31: 액티브 조합은 서브 티어가 액티브 티어 이상이어야 한다.
func test_check_active_fusion_requires_sub_tier_at_least_main() -> void:
	var main: BoonInstance = _instance(_boon(&"m", SANSIN, 2))
	var sub_low: BoonInstance = _instance(_boon(&"s", SANSIN, 1))
	var sub_ok: BoonInstance = _instance(_boon(&"s2", SANSIN, 2))
	assert_bool(BoonFusion.check(main, sub_low, true)["ok"]).is_false()
	assert_bool(BoonFusion.check(main, sub_ok, true)["ok"]).is_true()


## 규칙 13/24: 유물 보정 전후 모두 성공+대성공 합이 1.0이고 각각 0 이상이다.
func test_adjust_probabilities_sum_stays_one() -> void:
	var rule: FusionRule = _rule(SANSIN, SANSIN, false, 1, 1, &"r", 0.95, 0.05)
	var base: Dictionary = BoonFusion.adjust_probabilities(rule, 0.0)
	assert_float(float(base["success"]) + float(base["great"])).is_equal_approx(1.0, 0.0001)
	var boosted: Dictionary = BoonFusion.adjust_probabilities(rule, 0.5)
	assert_float(float(boosted["success"]) + float(boosted["great"])).is_equal_approx(1.0, 0.0001)
	assert_float(boosted["success"]).is_greater_equal(0.0)
	assert_float(boosted["great"]).is_equal_approx(0.55, 0.0001)


## 규칙 24: 대성공 상승분은 성공에서만 빠진다. 극단값도 합 1.0과 0 이상을 지킨다.
func test_adjust_probabilities_clamps_extreme_bonus() -> void:
	var rule: FusionRule = _rule(SANSIN, SANSIN, false, 1, 1, &"r", 0.95, 0.05)
	var extreme: Dictionary = BoonFusion.adjust_probabilities(rule, 2.0)
	assert_float(extreme["great"]).is_equal_approx(1.0, 0.0001)
	assert_float(extreme["success"]).is_equal_approx(0.0, 0.0001)


## 규칙 16: 같은 시드로 같은 조합을 하면 같은 결과가 나온다.
func test_resolve_is_reproducible_by_seed() -> void:
	var result_def: BoonDef = _boon(&"result", SANSIN, 2)
	var pool: Dictionary = {&"result": result_def}
	var rules: Array[FusionRule] = _rules([_rule(SANSIN, SANSIN, false, 1, 1, &"result")])
	var rarity_table: RarityTable = RarityTable.new()

	var main1: BoonInstance = _instance(_boon(&"m", SANSIN, 1))
	var sub1: BoonInstance = _instance(_boon(&"s", SANSIN, 1))
	var outcome1: Dictionary = BoonFusion.resolve(
		main1, sub1, false, rules, pool, {}, rarity_table, 42
	)

	var main2: BoonInstance = _instance(_boon(&"m", SANSIN, 1))
	var sub2: BoonInstance = _instance(_boon(&"s", SANSIN, 1))
	var outcome2: Dictionary = BoonFusion.resolve(
		main2, sub2, false, rules, pool, {}, rarity_table, 42
	)

	assert_bool(outcome1["great"]).is_equal(outcome2["great"])
	var instance1: BoonInstance = outcome1["instance"] as BoonInstance
	var instance2: BoonInstance = outcome2["instance"] as BoonInstance
	assert_str(String(instance1.id)).is_equal(String(instance2.id))
	assert_int(instance1.tier).is_equal(instance2.tier)


## 규칙 14: 조합 판정은 성공 또는 대성공뿐이다. ok가 true면 항상 instance가 나온다.
func test_resolve_never_fails_when_valid() -> void:
	var result_def: BoonDef = _boon(&"result", SANSIN, 2)
	var pool: Dictionary = {&"result": result_def}
	var rules: Array[FusionRule] = _rules([_rule(SANSIN, SANSIN, false, 1, 1, &"result")])
	var rarity_table: RarityTable = RarityTable.new()
	for roll: int in range(20):
		var main: BoonInstance = _instance(_boon(&"m", SANSIN, 1))
		var sub: BoonInstance = _instance(_boon(&"s", SANSIN, 1))
		var outcome: Dictionary = BoonFusion.resolve(
			main, sub, false, rules, pool, {}, rarity_table, roll
		)
		assert_bool(outcome["ok"]).is_true()
		assert_object(outcome["instance"]).is_not_null()


## 규칙 10/32: 조합 결과의 티어는 메인 재료 티어 + 1이다.
func test_resolve_result_tier_is_main_tier_plus_one() -> void:
	var result_def: BoonDef = _boon(&"result", SANSIN, 2)
	var pool: Dictionary = {&"result": result_def}
	var rules: Array[FusionRule] = _rules([_rule(SANSIN, SANSIN, false, 1, 1, &"result")])
	var main: BoonInstance = _instance(_boon(&"m", SANSIN, 1))
	var sub: BoonInstance = _instance(_boon(&"s", SANSIN, 1))
	var outcome: Dictionary = BoonFusion.resolve(
		main, sub, false, rules, pool, {}, RarityTable.new(), 1
	)
	var instance: BoonInstance = outcome["instance"] as BoonInstance
	assert_int(instance.tier).is_equal(2)


## 규칙 22/42: 액티브 조합은 main 인스턴스를 그대로 강화한다 (같은 객체, id 불변).
func test_resolve_active_fusion_mutates_main_in_place() -> void:
	var rules: Array[FusionRule] = _rules([_rule(SANSIN, SANSIN, true, 2, 2, &"")])
	var main: BoonInstance = _instance(_boon(&"active", SANSIN, 2))
	var sub: BoonInstance = _instance(_boon(&"s", SANSIN, 2))
	var outcome: Dictionary = BoonFusion.resolve(
		main, sub, true, rules, {}, {}, RarityTable.new(), 1
	)
	var instance: BoonInstance = outcome["instance"] as BoonInstance
	assert_object(instance).is_same(main)
	assert_int(instance.tier).is_equal(3)
	assert_str(String(instance.id)).is_equal("active")


## 규칙 52: weapon_tag_inherits가 true면 결과가 메인의 실효 무기 태그를 물려받는다.
func test_resolve_inherits_weapon_tag_when_flagged() -> void:
	var main_def: BoonDef = _boon(&"m", SANSIN)
	main_def.weapon_tag = BoonDef.WeaponTag.MELEE
	var result_def: BoonDef = _boon(&"result", SANSIN, 2, BoonDef.Layer.REGULAR, true)
	var pool: Dictionary = {&"result": result_def}
	var rules: Array[FusionRule] = _rules([_rule(SANSIN, SANSIN, false, 1, 1, &"result")])
	var main: BoonInstance = _instance(main_def, 1)
	var sub: BoonInstance = _instance(_boon(&"s", SANSIN, 1))
	var outcome: Dictionary = BoonFusion.resolve(
		main, sub, false, rules, pool, {}, RarityTable.new(), 1
	)
	var instance: BoonInstance = outcome["instance"] as BoonInstance
	assert_int(instance.effective_weapon_tag()).is_equal(int(BoonDef.WeaponTag.MELEE))


## 규칙 48: 대성공은 등급을 1단계 올리고 덤을 더한다. 최고 등급이면 등급은 그대로다.
func test_great_success_raises_rarity_and_caps_bonus() -> void:
	var result_def: BoonDef = _boon(&"result", SANSIN, 2)
	var pool: Dictionary = {&"result": result_def}
	var rules: Array[FusionRule] = _rules([_rule(SANSIN, SANSIN, false, 1, 1, &"result", 0.0, 1.0)])
	var rarity_table: RarityTable = RarityTable.new()

	var main: BoonInstance = _instance(_boon(&"m", SANSIN, 1))
	main.rarity = BoonDef.Rarity.ONNAERIM
	var sub: BoonInstance = _instance(_boon(&"s", SANSIN, 1))
	var outcome: Dictionary = BoonFusion.resolve(
		main, sub, false, rules, pool, {}, rarity_table, 1
	)
	var instance: BoonInstance = outcome["instance"] as BoonInstance
	assert_bool(outcome["great"]).is_true()
	assert_int(instance.rarity).is_equal(int(BoonDef.Rarity.ONNAERIM))
	assert_float(instance.rarity_bonus).is_equal_approx(rarity_table.great_bonus, 0.0001)

	# 덤이 누적돼도 bonus_cap을 넘지 않는다
	var main2: BoonInstance = _instance(_boon(&"m2", SANSIN, 1))
	main2.rarity_bonus = rarity_table.bonus_cap
	var sub2: BoonInstance = _instance(_boon(&"s2", SANSIN, 1))
	var outcome2: Dictionary = BoonFusion.resolve(
		main2, sub2, false, rules, pool, {}, rarity_table, 1
	)
	var instance2: BoonInstance = outcome2["instance"] as BoonInstance
	assert_float(instance2.rarity_bonus).is_less_equal(rarity_table.bonus_cap)


## 규칙 47: 등급 배율은 total_cap을 넘지 않는다.
func test_rarity_multiplier_respects_caps() -> void:
	var table: RarityTable = RarityTable.new()
	assert_float(table.multiplier_for(int(BoonDef.Rarity.SEUCHIM), 0.0)).is_equal_approx(1.0, 0.0001)
	assert_float(table.multiplier_for(int(BoonDef.Rarity.ONNAERIM), 10.0)).is_less_equal(
		table.total_cap
	)
	assert_float(table.multiplier_for(-5, 0.0)).is_greater_equal(1.0)


func test_find_rule_matches_active_by_sub_tier_at_least() -> void:
	var rule_t1: FusionRule = _rule(SANSIN, SANSIN, true, 1, 1, &"")
	var rule_t2: FusionRule = _rule(SANSIN, SANSIN, true, 2, 2, &"")
	var rules: Array[FusionRule] = _rules([rule_t1, rule_t2])
	var main: BoonInstance = _instance(_boon(&"m", SANSIN, 1))
	var sub: BoonInstance = _instance(_boon(&"s", SANSIN, 2))
	var found: FusionRule = BoonFusion.find_rule(main, sub, true, rules)
	assert_object(found).is_same(rule_t1)
