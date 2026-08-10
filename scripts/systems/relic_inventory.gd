class_name RelicInventory
extends RefCounted

## 런 스코프 유물 소지 목록 (순수 로직, 단위 테스트 대상).
##
## 유물은 자기 효과를 실행하지 않는다. 이 인벤토리가 훅별 질의 API를 제공하고
## 각 시스템(무기, 방, 체력, 플레이어)이 훅 시점에 질의한다 (docs/systems/RELICS.md 8.3).
## 효과 합산은 가산이다. 곱연산은 쓰지 않는다 (3장).

var _relics: Array[RelicDef] = []
## 발동형 유물의 충전 잔량. key: 유물 id, value: 남은 충전
var _charges: Dictionary = {}
## 쿨다운 종료 시각. key: 유물 id, value: 초
var _cooldown_ready_at: Dictionary = {}


## 유물을 추가한다. 중복(unique)과 배타 그룹을 지키면 true.
func add(def: RelicDef) -> bool:
	if def == null or def.id == &"":
		return false
	if def.unique and has(def.id):
		return false
	if def.exclusive_group != &"" and _has_group(def.exclusive_group):
		return false
	_relics.append(def)
	_init_charges(def)
	return true


func has(id: StringName) -> bool:
	for def: RelicDef in _relics:
		if def.id == id:
			return true
	return false


func all() -> Array[RelicDef]:
	return _relics.duplicate()


func size() -> int:
	return _relics.size()


func clear() -> void:
	_relics.clear()
	_charges.clear()
	_cooldown_ready_at.clear()


## STAT_MODIFIER 중 가산 효과의 합 (target_key 일치).
func flat_bonus(key: StringName) -> float:
	var total: float = 0.0
	for def: RelicDef in _relics:
		for effect: RelicEffect in def.effects:
			if effect.hook != RelicEffect.Hook.STAT_MODIFIER:
				continue
			if effect.target_key == key and not effect.is_multiplier:
				total += effect.value
	return total


## STAT_MODIFIER 중 배율 효과의 합 (1.0 미포함. 소비자가 1.0 + 합으로 쓴다).
func mult_bonus(key: StringName) -> float:
	var total: float = 0.0
	for def: RelicDef in _relics:
		for effect: RelicEffect in def.effects:
			if effect.hook != RelicEffect.Hook.STAT_MODIFIER:
				continue
			if effect.target_key == key and effect.is_multiplier:
				total += effect.value
	return total


## RULE_OVERRIDE 효과의 가산 합 (target_key 일치). 소비자가 기본값에 더한다.
func rule_bonus(key: StringName) -> float:
	var total: float = 0.0
	for def: RelicDef in _relics:
		for effect: RelicEffect in def.effects:
			if effect.hook == RelicEffect.Hook.RULE_OVERRIDE and effect.target_key == key:
				total += effect.value
	return total


## 치명 피해를 무효화할 충전이 있으면 한 번 소비하고 true (군번줄).
func try_absorb_lethal() -> bool:
	for def: RelicDef in _relics:
		if not _has_hook(def, RelicEffect.Hook.ON_LETHAL_DAMAGE):
			continue
		if int(_charges.get(def.id, 0)) > 0:
			_charges[def.id] = int(_charges[def.id]) - 1
			return true
	return false


## 쉼터 통과 시 recharge_at_rest 효과의 충전을 되돌린다.
func recharge_at_rest() -> void:
	for def: RelicDef in _relics:
		for effect: RelicEffect in def.effects:
			if effect.recharge_at_rest and effect.charges_per_run >= 0:
				_charges[def.id] = effect.charges_per_run


## 피격 시 발동형(개암 한 알)이 쿨다운을 벗어났으면 재무장하고 true.
func hit_taken_ready(now_sec: float) -> bool:
	var triggered: bool = false
	for def: RelicDef in _relics:
		for effect: RelicEffect in def.effects:
			if effect.hook != RelicEffect.Hook.ON_HIT_TAKEN:
				continue
			if now_sec < float(_cooldown_ready_at.get(def.id, 0.0)):
				continue
			_cooldown_ready_at[def.id] = now_sec + effect.cooldown_sec
			triggered = true
	return triggered


func _init_charges(def: RelicDef) -> void:
	for effect: RelicEffect in def.effects:
		if effect.charges_per_run >= 0:
			_charges[def.id] = effect.charges_per_run


func _has_hook(def: RelicDef, hook: RelicEffect.Hook) -> bool:
	for effect: RelicEffect in def.effects:
		if effect.hook == hook:
			return true
	return false


func _has_group(group: StringName) -> bool:
	for def: RelicDef in _relics:
		if def.exclusive_group == group:
			return true
	return false
