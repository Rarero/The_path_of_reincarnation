class_name BoonFusion
extends RefCounted

## 권능 조합 판정 (순수 로직, 단위 테스트 대상. docs/systems/BOONS.md 5장, 9.3).
##
## 신당에서만 호출된다. 메인과 서브는 호출자가 지정하며, 결과의 성격과 무기 태그와
## 주 계열은 메인이 결정한다 (5장). 조합 실패는 없다. 성공과 대성공 둘 중 하나만
## 나온다 (2026-07-27 결정). 확률은 조합 화면에 공개하므로 preview와 resolve를
## 분리해 rng를 굴리지 않고도 확률을 미리 계산할 수 있게 한다.

const MAX_TIER: int = 3


## 재료 둘의 조합 가능 여부와 사유. is_active가 true면 fusible() 태그 판정을 건너뛴다 (5장).
static func check(main: BoonInstance, sub: BoonInstance, is_active: bool) -> Dictionary:
	if main == null or main.def == null or sub == null or sub.def == null:
		return {"ok": false, "reason": "invalid"}
	if is_active:
		# 액티브도 3티어가 상한이고 그 이상 조합되지 않는다 (규칙 21)
		if main.tier >= MAX_TIER:
			return {"ok": false, "reason": "max_tier"}
		# 3티어는 재료가 되지 않는다 (규칙 10). 액티브 조합의 서브에도 그대로 적용한다
		if sub.tier >= MAX_TIER:
			return {"ok": false, "reason": "sub_max_tier"}
		if sub.tier < main.tier:
			return {"ok": false, "reason": "tier"}
		return {"ok": true, "reason": ""}
	if main.tier != sub.tier:
		return {"ok": false, "reason": "tier"}
	if main.tier >= MAX_TIER:
		return {"ok": false, "reason": "max_tier"}
	if not BoonDef.fusible(main.def, sub.def):
		return {"ok": false, "reason": "not_fusible"}
	return {"ok": true, "reason": ""}


## 조합 규칙 검색. main_pantheon, sub_pantheon, main_tier, is_active_fusion이 일치하고
## (액티브는 sub_tier 이상, 일반은 sub_tier 일치) 하는 첫 규칙을 돌려준다. 없으면 null.
static func find_rule(
	main: BoonInstance, sub: BoonInstance, is_active: bool, rules: Array[FusionRule]
) -> FusionRule:
	for rule: FusionRule in rules:
		if rule.is_active_fusion != is_active:
			continue
		if int(rule.main_pantheon) != main.pantheon:
			continue
		if rule.main_tier != main.tier:
			continue
		if is_active:
			if sub.tier < rule.sub_tier:
				continue
		elif rule.sub_tier != sub.tier:
			continue
		if sub.def.layer != BoonDef.Layer.SPECIAL and int(rule.sub_pantheon) != sub.pantheon:
			continue
		return rule
	return null


## 유물 보정을 반영한 성공/대성공 확률. 대성공 상승분은 성공에서만 빼서 합 1.0을
## 유지한다 (5장, 규칙 24). great_bonus가 커도 대성공은 1.0을, 성공은 0.0을 넘지 않는다.
static func adjust_probabilities(rule: FusionRule, great_bonus: float = 0.0) -> Dictionary:
	var great: float = clampf(rule.great_chance + great_bonus, 0.0, 1.0)
	var success: float = 1.0 - great
	return {"success": success, "great": great}


## UI 미리보기. 규칙과 확률만 돌려주고 아무것도 소모하거나 굴리지 않는다.
static func preview(
	main: BoonInstance, sub: BoonInstance, is_active: bool, rules: Array[FusionRule], great_bonus: float = 0.0
) -> Dictionary:
	var checked: Dictionary = check(main, sub, is_active)
	if not checked.get("ok", false):
		return checked
	var rule: FusionRule = find_rule(main, sub, is_active, rules)
	if rule == null:
		return {"ok": false, "reason": "no_rule"}
	var probs: Dictionary = adjust_probabilities(rule, great_bonus)
	return {
		"ok": true,
		"reason": "",
		"rule": rule,
		"success_chance": probs["success"],
		"great_chance": probs["great"],
	}


## 조합을 실행한다. roll_seed로 성공/대성공을 결정적으로 정한다 (재현성, 규칙 16).
## result_pool: {StringName -> BoonDef} 결과 정의 조회용. overlay_pool: {StringName -> PantheonOverlay}.
static func resolve(
	main: BoonInstance,
	sub: BoonInstance,
	is_active: bool,
	rules: Array[FusionRule],
	result_pool: Dictionary,
	overlay_pool: Dictionary,
	rarity_table: RarityTable,
	roll_seed: int,
	great_bonus: float = 0.0
) -> Dictionary:
	var preview_result: Dictionary = preview(main, sub, is_active, rules, great_bonus)
	if not preview_result.get("ok", false):
		return preview_result
	var rule: FusionRule = preview_result["rule"] as FusionRule
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = roll_seed
	var is_great: bool = rng.randf() < float(preview_result["great_chance"])
	var instance: BoonInstance = _build_result(
		main, sub, rule, is_active, is_great, result_pool, overlay_pool, rarity_table
	)
	preview_result["great"] = is_great
	preview_result["instance"] = instance
	preview_result["is_active_fusion"] = is_active
	return preview_result


static func _build_result(
	main: BoonInstance,
	sub: BoonInstance,
	rule: FusionRule,
	is_active: bool,
	is_great: bool,
	result_pool: Dictionary,
	overlay_pool: Dictionary,
	rarity_table: RarityTable
) -> BoonInstance:
	var instance: BoonInstance
	if is_active:
		instance = main
		instance.tier = mini(main.tier + 1, MAX_TIER)
		# 액티브 모듈러 구조(계열 모디파이어)는 적용 대기다. modifier_id는 M2에서 항상 비어 있다 (5장).
	else:
		var result_def: BoonDef = result_pool.get(rule.result_id, null)
		instance = BoonInstance.new(result_def)
		instance.tier = main.tier + 1
		instance.rarity = main.rarity
		instance.rarity_bonus = main.rarity_bonus
		if result_def != null and result_def.weapon_tag_inherits:
			instance.weapon_tag_effective = main.effective_weapon_tag()
		if not String(rule.addon_id).is_empty():
			var overlay: PantheonOverlay = overlay_pool.get(rule.addon_id, null)
			if overlay != null:
				instance.overlays.append(overlay)
		if sub.def.layer == BoonDef.Layer.SPECIAL:
			instance.mark_pantheon = sub.pantheon
	if is_great:
		_apply_great_bonus(instance, rarity_table)
	return instance


## 대성공 처리 (6장, 규칙 48). 등급 1단계 상승 + 덤. 최고 등급에서는 등급이 오르지
## 않고 덤만 붙는다. 덤은 bonus_cap을 넘지 않는다.
static func _apply_great_bonus(instance: BoonInstance, rarity_table: RarityTable) -> void:
	var bonus: float = rarity_table.great_bonus if rarity_table != null else 0.25
	var cap: float = rarity_table.bonus_cap if rarity_table != null else 0.5
	instance.rarity_bonus = clampf(instance.rarity_bonus + bonus, 0.0, cap)
	if instance.rarity < BoonDef.Rarity.ONNAERIM:
		instance.rarity += 1
