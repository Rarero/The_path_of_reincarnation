class_name RelicEffect
extends Resource

## 유물 효과 1개. 하나의 유물이 복수 효과를 가질 수 있다 (docs/systems/RELICS.md 8.2).
## 유물은 자기 효과를 직접 실행하지 않는다. RunState가 훅별로 모으고 각 시스템이 훅 시점에 질의한다.

enum Hook {
	STAT_MODIFIER,  ## 상시 스탯 가산 또는 배율
	ON_HIT_TAKEN,  ## 피격 시 (개암 한 알)
	ON_KILL,  ## 처치 시
	ON_DODGE_THROUGH,  ## 대시 통과 시
	ON_PROP_BROKEN,  ## 파괴 오브젝트 파손 시 (놋대야, 선행 시스템 대기)
	ON_LETHAL_DAMAGE,  ## 치명 피해 시 (군번줄)
	ON_FIRST_STRIKE,  ## 미발견 상태 첫 타격 (도깨비 가면)
	ON_GRABBED,  ## 그랩에 잡힌 순간 (씨름 샅바)
	ON_KNOCKBACK_HIT,  ## 밀쳐낸 적이 충돌한 순간
	RULE_OVERRIDE,  ## 시스템 규칙 변경 (조명, 데스매치, 경제, 맵)
}

@export var hook: Hook = Hook.STAT_MODIFIER
## 효과 대상 키. 예: &"melee_damage", &"deathmatch_delay"
@export var target_key: StringName = &""
## 가산값 또는 배율값. 의미는 target_key와 is_multiplier가 정한다
@export var value: float = 0.0
@export var is_multiplier: bool = false
## 발동 효과의 재발동 간격 (초). 0이면 상시
@export var cooldown_sec: float = 0.0
## 런당 충전 횟수. -1은 무제한
@export var charges_per_run: int = -1
## 쉼터 통과 시 충전을 되돌리는지 (군번줄)
@export var recharge_at_rest: bool = false
