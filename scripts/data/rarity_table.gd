class_name RarityTable
extends Resource

## 등급 배율 전역 테이블 (docs/systems/BOONS.md 6장, 9.5). BoonDef가 아니라 여기 둔다.
## 적용 대상은 rarity_scales가 true인 BoonEffect의 base_value뿐이다 (규칙 47).

## Rarity 순서: 스침, 실림, 온내림
@export var multipliers: PackedFloat32Array = PackedFloat32Array([1.0, 1.5, 2.0])
## 대성공 1회당 인스턴스에 더해지는 덤
@export var great_bonus: float = 0.25
## 덤 누적 상한 (대성공 2회분)
@export var bonus_cap: float = 0.5
## 최종 배율 상한
@export var total_cap: float = 2.5


## 최종 배율 = multipliers[등급] + 인스턴스의 rarity_bonus이고 total_cap을 넘지 않는다.
func multiplier_for(rarity: int, rarity_bonus: float) -> float:
	var base: float = 1.0
	if rarity >= 0 and rarity < multipliers.size():
		base = multipliers[rarity]
	var bonus: float = clampf(rarity_bonus, 0.0, bonus_cap)
	return minf(base + bonus, total_cap)
