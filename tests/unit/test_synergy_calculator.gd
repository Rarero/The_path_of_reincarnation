extends GdUnitTestSuite

## 계열 시너지 검증 (docs/systems/BOONS.md 8.7, 9.7, 10장 규칙 60/61).

const SANSIN: int = BoonDef.Pantheon.SANSIN
const JOWANG: int = BoonDef.Pantheon.JOWANG


func _boon(id: StringName, pantheon: int) -> BoonDef:
	var def: BoonDef = BoonDef.new()
	def.id = id
	def.pantheon = pantheon
	return def


func _loadout_with_counts(active_pantheon: int, slot_pantheons: Array) -> BoonLoadout:
	var loadout: BoonLoadout = BoonLoadout.new()
	if active_pantheon >= 0:
		loadout.set_active(_boon(&"active", active_pantheon))
	for i: int in range(slot_pantheons.size()):
		loadout.add_boon(_boon(StringName("slot_%d" % i), int(slot_pantheons[i])))
	return loadout


## 규칙 61: 단계는 0~4 범위를 벗어나지 않는다.
func test_stage_for_clamps_to_zero_and_four() -> void:
	assert_int(SynergyCalculator.stage_for(-1)).is_equal(0)
	assert_int(SynergyCalculator.stage_for(0)).is_equal(0)
	assert_int(SynergyCalculator.stage_for(4)).is_equal(4)
	assert_int(SynergyCalculator.stage_for(99)).is_equal(4)


## 규칙 60: 2단계 미만은 효과가 없다. stages()는 2단계 이상만 담는다.
func test_stages_excludes_below_two() -> void:
	# 액티브 산신 1 + 슬롯 산신 1 = 산신 2개 -> 2단계 미만이라 포함 안 됨
	var loadout: BoonLoadout = _loadout_with_counts(SANSIN, [JOWANG])
	var stages: Dictionary = SynergyCalculator.stages(loadout)
	assert_bool(stages.has(SANSIN)).is_false()


## 경계값: 같은 계열이 정확히 2개면 2단계.
func test_stages_boundary_at_two() -> void:
	var loadout: BoonLoadout = _loadout_with_counts(SANSIN, [SANSIN, JOWANG])
	var stages: Dictionary = SynergyCalculator.stages(loadout)
	assert_int(int(stages[SANSIN])).is_equal(2)


## 경계값: 3개면 3단계, 4개(액티브+슬롯3)면 4단계.
func test_stages_boundary_at_three_and_four() -> void:
	var loadout3: BoonLoadout = _loadout_with_counts(SANSIN, [SANSIN, SANSIN])
	assert_int(int(SynergyCalculator.stages(loadout3)[SANSIN])).is_equal(3)

	var loadout4: BoonLoadout = _loadout_with_counts(SANSIN, [SANSIN, SANSIN, SANSIN])
	assert_int(int(SynergyCalculator.stages(loadout4)[SANSIN])).is_equal(4)


## 규칙 61: 조합으로 칸이 줄면(권능 3개 -> 2개) 시너지 단계도 함께 내려간다.
func test_stage_drops_when_slot_count_drops() -> void:
	var loadout: BoonLoadout = _loadout_with_counts(SANSIN, [SANSIN, SANSIN])
	assert_int(int(SynergyCalculator.stages(loadout)[SANSIN])).is_equal(3)
	loadout.remove_slot(0)
	var stages: Dictionary = SynergyCalculator.stages(loadout)
	assert_int(int(stages.get(SANSIN, 0))).is_equal(2)


## 단계 효과는 누적이 아니라 치환이다: 3단계에서는 step3 효과만 나오고 step2는 나오지 않는다.
func test_active_effects_replace_not_stack() -> void:
	var step2_effect: BoonEffect = BoonEffect.new()
	step2_effect.hook = BoonEffect.Hook.STAT_MODIFIER
	step2_effect.target_key = &"step2_key"
	step2_effect.base_value = 1.0
	var step3_effect: BoonEffect = BoonEffect.new()
	step3_effect.hook = BoonEffect.Hook.STAT_MODIFIER
	step3_effect.target_key = &"step3_key"
	step3_effect.base_value = 2.0

	# 타입 배열은 지역 변수로 먼저 만든다 (test_relic_inventory.gd와 같은 규약)
	var step2_list: Array[BoonEffect] = [step2_effect]
	var step3_list: Array[BoonEffect] = [step3_effect]
	var entry: PantheonSynergy = PantheonSynergy.new()
	entry.pantheon = SANSIN
	entry.step2 = step2_list
	entry.step3 = step3_list
	var entries: Array[PantheonSynergy] = [entry]
	var table: SynergyTable = SynergyTable.new()
	table.entries = entries

	var loadout: BoonLoadout = _loadout_with_counts(SANSIN, [SANSIN, SANSIN])
	var effects: Array[BoonEffect] = SynergyCalculator.active_effects(loadout, table)
	var keys: Array[StringName] = []
	for effect: BoonEffect in effects:
		keys.append(effect.target_key)
	assert_bool(keys.has(&"step3_key")).is_true()
	assert_bool(keys.has(&"step2_key")).is_false()


## 겹내림처럼 계열이 둘인 권능도 메인 계열(instance.pantheon)로만 센다.
func test_pantheon_counts_uses_main_pantheon_only() -> void:
	var loadout: BoonLoadout = BoonLoadout.new()
	loadout.set_active(_boon(&"active", SANSIN))
	var cross_def: BoonDef = _boon(&"cross", SANSIN)  # 메인 계열이 산신인 겹내림 권능
	loadout.add_boon(cross_def)
	var counts: Dictionary = SynergyCalculator.pantheon_counts(loadout)
	assert_int(int(counts[SANSIN])).is_equal(2)
	assert_bool(counts.has(JOWANG)).is_false()
