class_name BoonEffect
extends Resource

## 권능 효과 1개 (docs/systems/BOONS.md 9.2).
## 등급 배율은 rarity_scales가 true일 때만 적용한다 (6장). 확률과 횟수는 false로 고정.

enum Hook {
	STAT_MODIFIER,
	ON_MELEE_HIT,
	ON_RANGED_HIT,
	ON_SHOT_FIRED,  ## 발사 순간. M2 미사용이며 D8 무기 세션 대비로 남긴다
	ON_DODGE_END,
	ON_DASH,
	ON_KILL,
	ON_HIT_TAKEN,
	ON_ROOM_ENTER,
	ON_COIN_GAINED,
	ON_KNOCKBACK_HIT,
	ON_WEAPON_SWAP,  ## 무기 스왑 순간. 규격은 D8 의존 (2026-08-05 신설, 솥뚜껑)
	ON_STATUS_CAP,  ## 계열 고유 상태가 상한에 닿았을 때 (2026-08-05 신설, 잿불)
	RULE_OVERRIDE,  ## 조작 규칙 자체를 바꾼다. 발동이 아니라 상시 적용이다
	ACTIVE_CAST,
}

@export var hook: Hook = Hook.STAT_MODIFIER
@export var target_key: StringName = &""
@export var base_value: float = 0.0
@export var is_multiplier: bool = false
## 확률과 횟수 효과는 false로 고정 (docs/systems/BOONS.md 6장)
@export var rarity_scales: bool = true
@export var chance: float = 1.0
@export var duration_sec: float = 0.0
## 명중당 발동 효과의 폭주 방지
@export var cooldown_sec: float = 0.0
@export var stack_cap: int = 0
## 발동 전제 조건. 빈 값이면 무조건 (9.2 조건 키 어휘표를 따른다. 2026-08-05 신설)
@export var condition_key: StringName = &""
## 조건에 수치가 필요할 때만 쓴다
@export var condition_value: float = 0.0
