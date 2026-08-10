extends GdUnitTestSuite

## 신당 재추첨/3칸 처리/조합의 RunState 통합 검증 (docs/systems/BOONS.md 7장, 10장 규칙 37).
##
## RunState는 오토로드라 프로젝트 부팅 시 리소스 풀이 이미 로드돼 있다. 다른 테스트와
## 상태가 섞이지 않도록 매 테스트 전후로 reset_run()을 호출한다.
## "신당당 1회" 제한은 room_shrine.gd(씬)가 방문 상태로 지키므로 여기서는 다루지
## 않는다. 여기서는 RunState가 지키는 두 조각만 검증한다: 무당 방울 부족 시 거부,
## 몸주 신당(액티브 없음)에는 애초에 재추첨이 없다.


func before_test() -> void:
	RunState.reset_run()


func after_test() -> void:
	RunState.reset_run()


## 규칙 37: 몸주 신당(액티브 없음)에는 재추첨이 없다. 방울이 있어도 마찬가지다.
func test_cannot_reroll_before_mongju_chosen() -> void:
	RunState.add_bells(5)
	assert_bool(RunState.boons.has_active()).is_false()
	assert_bool(RunState.can_reroll_shrine()).is_false()
	var result: Dictionary = RunState.reroll_shrine(1)
	assert_str(String(result.get("kind", ""))).is_equal("none")
	assert_int(RunState.divination_bells).is_equal(5)


## 규칙 37: 무당 방울이 모자라면 재추첨을 시도할 수 없다.
func test_cannot_reroll_without_enough_bells() -> void:
	RunState.commit_mongju(int(BoonDef.Pantheon.SANSIN))
	assert_int(RunState.divination_bells).is_equal(0)
	assert_bool(RunState.can_reroll_shrine()).is_false()
	var result: Dictionary = RunState.reroll_shrine(1)
	assert_str(String(result.get("kind", ""))).is_equal("none")


## 방울이 충분하고 액티브를 보유하면 재추첨이 가능하고, 성공 시 방울을 정확히 소비한다.
func test_reroll_spends_exactly_one_bell_when_allowed() -> void:
	RunState.commit_mongju(int(BoonDef.Pantheon.SANSIN))
	RunState.add_bells(2)
	assert_bool(RunState.can_reroll_shrine()).is_true()
	RunState.reroll_shrine(1)
	assert_int(RunState.divination_bells).is_equal(1)


## 슬롯 채우기용 테스트 전용 권능. 신당 실제 후보 풀과 무관하게 3칸 처리 API 자체를
## 검증한다. M2 권능 풀은 산신 정상형이 전부 액티브라 실제 신당 흐름만으로는 3칸을
## 채운 뒤 4번째 제시를 재현할 수 없다(12장에 기록할 별도 발견 사항). commit_boon과
## discard_and_commit_boon은 def 출처를 가리지 않으므로 합성 def로도 API를 검증할 수 있다.
func _fixture_boon(id: StringName) -> BoonDef:
	var effect: BoonEffect = BoonEffect.new()
	effect.hook = BoonEffect.Hook.STAT_MODIFIER
	effect.target_key = &"max_health"
	effect.base_value = 1.0
	var def: BoonDef = BoonDef.new()
	def.id = id
	def.pantheon = BoonDef.Pantheon.JOWANG
	var effects: Array[BoonEffect] = [effect]
	def.stat_effects = effects
	return def


## 3칸이 찼을 때 discard_and_commit_boon은 지정한 슬롯을 비우고 새 권능을 담는다.
func test_discard_and_commit_replaces_slot() -> void:
	RunState.commit_mongju(int(BoonDef.Pantheon.SANSIN))
	RunState.boons.add_boon(_fixture_boon(&"fx_a"))
	RunState.boons.add_boon(_fixture_boon(&"fx_b"))
	RunState.boons.add_boon(_fixture_boon(&"fx_c"))
	assert_bool(RunState.boon_slots_full()).is_true()

	var kept_id: StringName = RunState.boons.slots[1].id
	var incoming: BoonDef = _fixture_boon(&"fx_incoming")
	var message: String = RunState.discard_and_commit_boon(0, incoming)
	assert_str(message).is_not_equal("신당: 실패")
	assert_int(RunState.boons.slot_count()).is_equal(3)
	assert_str(String(RunState.boons.slots[0].id)).is_equal(String(incoming.id))
	assert_str(String(RunState.boons.slots[1].id)).is_equal(String(kept_id))


## decline_boon은 아무것도 바꾸지 않는다.
func test_decline_boon_keeps_slots_unchanged() -> void:
	RunState.commit_mongju(int(BoonDef.Pantheon.SANSIN))
	RunState.boons.add_boon(_fixture_boon(&"fx_a"))
	RunState.boons.add_boon(_fixture_boon(&"fx_b"))
	RunState.boons.add_boon(_fixture_boon(&"fx_c"))
	var before_ids: Array[StringName] = RunState.boons.held_ids()
	RunState.decline_boon()
	assert_bool(RunState.boons.held_ids() == before_ids).is_true()


## commit_fusion(main_ref == sub_ref)는 자기 자신과의 조합을 거부한다.
func test_commit_fusion_rejects_same_slot() -> void:
	RunState.commit_mongju(int(BoonDef.Pantheon.SANSIN))
	var outcome: Dictionary = RunState.commit_fusion(0, 0, 1)
	assert_bool(outcome.get("ok", true)).is_false()
	assert_str(String(outcome.get("reason", ""))).is_equal("same_slot")


## 액티브는 서브가 될 수 없다 (5장: 액티브가 항상 메인이다). 이 경로를 열어 두면
## 재료가 하나도 소모되지 않은 채 결과만 얻거나, 반대로 결과를 잃는다.
func test_fusion_rejects_active_as_sub() -> void:
	RunState.commit_mongju(int(BoonDef.Pantheon.SANSIN))
	RunState.boons.add_boon(_fixture_boon(&"fx_a"))
	assert_bool(RunState.boons.has_active()).is_true()

	var preview: Dictionary = RunState.fusion_preview(0, -1)
	assert_bool(preview.get("ok", true)).is_false()
	assert_str(String(preview.get("reason", ""))).is_equal("active_as_sub")

	var before_slots: int = RunState.boons.slot_count()
	var outcome: Dictionary = RunState.commit_fusion(0, -1, 1)
	assert_bool(outcome.get("ok", true)).is_false()
	assert_int(RunState.boons.slot_count()).is_equal(before_slots)
	assert_bool(RunState.boons.has_active()).is_true()


## 조합에 실패하는 경로에서 재료가 사라지면 안 된다 (규칙 14의 실질 보장).
## 결과 id를 이미 다른 칸이 들고 있으면 BoonLoadout이 중복을 거부하므로, 그 조합은
## 미리보기 단계에서 막히고 재료도 그대로 남아야 한다.
func test_fusion_with_duplicate_result_is_blocked_and_keeps_materials() -> void:
	RunState.commit_mongju(int(BoonDef.Pantheon.JOWANG))
	var janbul: BoonDef = RunState.boon_def(&"boon_jowang_janbul")
	var bulti: BoonDef = RunState.boon_def(&"boon_jowang_bulti")
	var ingeolbul: BoonDef = RunState.boon_def(&"boon_jowang_ingeolbul")
	assert_object(janbul).is_not_null()
	assert_object(bulti).is_not_null()
	assert_object(ingeolbul).is_not_null()

	# 조왕 1티어 둘의 조합 결과(잉걸불)를 미리 한 칸에 넣어 둔다
	RunState.boons.add_boon(ingeolbul)
	RunState.boons.add_boon(janbul)
	RunState.boons.add_boon(bulti)
	assert_int(RunState.boons.slot_count()).is_equal(3)

	var preview: Dictionary = RunState.fusion_preview(1, 2)
	assert_bool(preview.get("ok", true)).is_false()
	assert_str(String(preview.get("reason", ""))).is_equal("duplicate_result")

	var outcome: Dictionary = RunState.commit_fusion(1, 2, 1)
	assert_bool(outcome.get("ok", true)).is_false()
	assert_int(RunState.boons.slot_count()).is_equal(3)
	assert_bool(RunState.boons.has_boon(&"boon_jowang_janbul")).is_true()
	assert_bool(RunState.boons.has_boon(&"boon_jowang_bulti")).is_true()


## 정상 조합은 재료 둘이 빠지고 결과 하나가 들어와 칸이 하나 빈다 (3장 조합 루프).
func test_valid_fusion_consumes_both_materials() -> void:
	RunState.commit_mongju(int(BoonDef.Pantheon.JOWANG))
	RunState.boons.add_boon(RunState.boon_def(&"boon_jowang_janbul"))
	RunState.boons.add_boon(RunState.boon_def(&"boon_jowang_bulti"))
	assert_int(RunState.boons.slot_count()).is_equal(2)

	var outcome: Dictionary = RunState.commit_fusion(0, 1, 7)
	assert_bool(outcome.get("ok", false)).is_true()
	assert_int(RunState.boons.slot_count()).is_equal(1)
	assert_bool(RunState.boons.has_boon(&"boon_jowang_janbul")).is_false()
	assert_bool(RunState.boons.has_boon(&"boon_jowang_bulti")).is_false()
	assert_int(RunState.boons.slots[0].tier).is_equal(2)
