class_name SynergyCalculator
extends RefCounted

## 계열 시너지 계산 (순수 로직, 단위 테스트 대상. docs/systems/BOONS.md 8.7, 9.7).
##
## 액티브 1개와 권능 3개를 합쳐 최대 4개를 세고, 같은 계열의 수가 시너지 단계다
## (규칙 60). 단계는 2 미만이면 효과가 없고, 4를 넘지 않는다 (규칙 61).

const MAX_STAGE: int = 4
const MIN_STAGE_WITH_EFFECT: int = 2


## 계열별 보유 수. 겹내림처럼 계열이 둘인 권능은 메인 계열(instance.pantheon)로만 센다.
## 티어는 세지 않는다.
static func pantheon_counts(loadout: BoonLoadout) -> Dictionary:
	var counts: Dictionary = {}
	if loadout == null:
		return counts
	for instance: BoonInstance in loadout.all_instances():
		if instance == null or instance.def == null:
			continue
		var pantheon: int = instance.pantheon
		counts[pantheon] = int(counts.get(pantheon, 0)) + 1
	return counts


## count를 0~MAX_STAGE 범위의 시너지 단계로 자른다 (규칙 61).
static func stage_for(count: int) -> int:
	return clampi(count, 0, MAX_STAGE)


## 효과가 붙는 계열만 담은 사전 {pantheon: stage}. 2단계 미만은 포함하지 않는다.
static func stages(loadout: BoonLoadout) -> Dictionary:
	var result: Dictionary = {}
	var counts: Dictionary = pantheon_counts(loadout)
	for pantheon: Variant in counts:
		var stage: int = stage_for(int(counts[pantheon]))
		if stage >= MIN_STAGE_WITH_EFFECT:
			result[pantheon] = stage
	return result


## 지금 적용 중인 시너지 효과 전부. 단계는 치환이므로 도달한 최고 단계의 효과만 담는다.
static func active_effects(loadout: BoonLoadout, table: SynergyTable) -> Array[BoonEffect]:
	var result: Array[BoonEffect] = []
	if table == null or loadout == null:
		return result
	var stg: Dictionary = stages(loadout)
	for entry: PantheonSynergy in table.entries:
		var pantheon: int = int(entry.pantheon)
		if not stg.has(pantheon):
			continue
		match int(stg[pantheon]):
			2:
				result.append_array(entry.step2)
			3:
				result.append_array(entry.step3)
			4:
				result.append_array(entry.step4)
	return result
