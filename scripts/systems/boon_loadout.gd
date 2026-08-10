class_name BoonLoadout
extends RefCounted

## 런 스코프 권능 보유 구조 (순수 로직, 단위 테스트 대상).
##
## 보유 상한은 액티브 1 + 권능 3칸이다 (docs/systems/BOONS.md 3장).
## 보유 항목은 정의(BoonDef)가 아니라 인스턴스(BoonInstance)다. 등급과 티어와 각인이
## 인스턴스에 얹힌다 (9.8). 스탯 효과는 가산 합산이며, 등급 배율(rarity_table)과
## 계열 시너지(synergy_table)가 있으면 함께 반영한다.

const MAX_SLOTS: int = 3

## 몸주 계열 전용 액티브 1개
var active: BoonInstance = null
## 권능 3칸
var slots: Array[BoonInstance] = []
## 몸주 계열 (BoonDef.Pantheon). -1은 미정
var mongju: int = -1
## 등급 배율 테이블. RunState가 주입한다. null이면 배율 없이 base_value를 그대로 쓴다
var rarity_table: RarityTable = null
## 계열 시너지 테이블. RunState가 주입한다. null이면 시너지 효과가 없다
var synergy_table: SynergyTable = null


## 몸주 액티브를 설정한다. 몸주 계열도 함께 확정된다.
func set_active(def: BoonDef, rarity: int = BoonDef.Rarity.SEUCHIM) -> BoonInstance:
	var instance: BoonInstance = BoonInstance.new(def)
	instance.rarity = rarity
	set_active_instance(instance)
	return instance


## 이미 만들어진 인스턴스(조합 결과 등)를 액티브로 설정한다.
func set_active_instance(instance: BoonInstance) -> void:
	active = instance
	if instance != null and instance.def != null:
		mongju = int(instance.def.pantheon)


func has_active() -> bool:
	return active != null


## 권능을 한 칸에 넣는다. 칸이 차 있으면 false.
func add_boon(def: BoonDef, rarity: int = BoonDef.Rarity.SEUCHIM) -> bool:
	if def == null:
		return false
	if slots.size() >= MAX_SLOTS:
		return false
	if has_boon(def.id):
		return false
	var instance: BoonInstance = BoonInstance.new(def)
	instance.rarity = rarity
	slots.append(instance)
	return true


## 이미 만들어진 인스턴스(조합 결과, 재추첨 등)를 권능 칸에 넣는다.
func add_instance(instance: BoonInstance) -> bool:
	if instance == null or instance.def == null:
		return false
	if slots.size() >= MAX_SLOTS:
		return false
	if has_boon(instance.def.id):
		return false
	slots.append(instance)
	return true


## 지정한 자리에 인스턴스를 끼워 넣는다. 범위를 넘으면 끝에 붙인다.
## 3칸 처리에서 버린 자리에 새 권능을 그대로 앉힐 때 쓴다 (7장 규칙 6).
func insert_instance(index: int, instance: BoonInstance) -> bool:
	if instance == null or instance.def == null:
		return false
	if slots.size() >= MAX_SLOTS:
		return false
	if has_boon(instance.def.id):
		return false
	slots.insert(clampi(index, 0, slots.size()), instance)
	return true


## index 자리의 권능을 비우고 돌려준다. 3칸이 찼을 때 버릴 것을 고르는 처리에 쓴다.
func remove_slot(index: int) -> BoonInstance:
	if index < 0 or index >= slots.size():
		return null
	return slots.pop_at(index)


func has_boon(id: StringName) -> bool:
	for instance: BoonInstance in slots:
		if instance.id == id:
			return true
	return false


func slot_count() -> int:
	return slots.size()


func is_full() -> bool:
	return slots.size() >= MAX_SLOTS


func held_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	if active != null:
		ids.append(active.id)
	for instance: BoonInstance in slots:
		ids.append(instance.id)
	return ids


func clear() -> void:
	active = null
	slots.clear()
	mongju = -1


## 액티브와 권능(+시너지)의 STAT_MODIFIER 가산 효과 합 (target_key 일치).
func flat_bonus(key: StringName) -> float:
	return _sum_effects(key, false)


## 액티브와 권능(+시너지)의 STAT_MODIFIER 배율 효과 합 (1.0 미포함).
func mult_bonus(key: StringName) -> float:
	return _sum_effects(key, true)


func _sum_effects(key: StringName, want_multiplier: bool) -> float:
	var total: float = 0.0
	for instance: BoonInstance in all_instances():
		if instance == null or instance.def == null:
			continue
		for effect: BoonEffect in instance.def.stat_effects:
			if effect.hook != BoonEffect.Hook.STAT_MODIFIER:
				continue
			if effect.target_key != key or effect.is_multiplier != want_multiplier:
				continue
			total += _scaled_value(effect, instance)
	for effect: BoonEffect in SynergyCalculator.active_effects(self, synergy_table):
		if effect.hook != BoonEffect.Hook.STAT_MODIFIER:
			continue
		if effect.target_key == key and effect.is_multiplier == want_multiplier:
			total += effect.base_value
	return total


func _scaled_value(effect: BoonEffect, instance: BoonInstance) -> float:
	if not effect.rarity_scales or rarity_table == null:
		return effect.base_value
	return effect.base_value * rarity_table.multiplier_for(instance.rarity, instance.rarity_bonus)


## 액티브와 권능 3칸을 합친 전체 목록 (최대 4개). 시너지 계산 등 외부에서도 쓴다.
func all_instances() -> Array[BoonInstance]:
	var instances: Array[BoonInstance] = []
	if active != null:
		instances.append(active)
	for instance: BoonInstance in slots:
		instances.append(instance)
	return instances
