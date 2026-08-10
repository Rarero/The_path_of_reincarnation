class_name EnemyStats
extends Resource

## 적 밸런스 수치. 코드에 하드코딩하지 않고 .tres로 분리한다 (docs/CONVENTIONS.md 데이터).

## 피격 경직 등급 (docs/act1/ENEMIES.md 3장 피격 반응 규칙).
## 슈퍼아머는 이 등급과 독립이라 별도 필드로 둔다. 씨름꾼처럼 평시 경직은 강하면서
## 특정 예비 구간에만 슈퍼아머가 붙는 개체를 하나의 정수로는 표현할 수 없다
enum Stagger { WEAK, MEDIUM, STRONG }

@export var display_name: String = "적"
@export var max_health: int = 30
@export var move_speed: float = 60.0
## 몸에 닿을 때의 피해 (docs/act1/ENEMIES.md 2장 접촉/공격력)
@export var contact_damage: int = 8
## 공격 판정(히트박스)에 맞을 때의 피해. 접촉 피해와 구분한다 (같은 2장).
## 개체가 AttackPattern을 쓰면 패턴별 damage가 이 값을 덮는다
@export var attack_damage: int = 10
## 플레이어를 인지하는 거리 (px)
@export var detect_range: float = 180.0
## 공격을 시작하는 거리 (px)
@export var attack_range: float = 28.0
## 공격 사이 최소 간격 (초)
@export var attack_cooldown: float = 1.4
## 피격 후 경직 시간 (초)
@export var hitstun: float = 0.16
## 피격 경직 등급. 경직 시간과 넉백 배율에 반영된다 (EnemyBase._on_hit_received)
@export var stagger_level: Stagger = Stagger.WEAK
## 처치 시 지급 엽전 (M1에서는 표시만)
@export var coin_reward: int = 3
## 위협 포인트 (docs/act1/ENEMIES.md 2장 위협 포인트 예산제).
## 방 배치는 개체 수가 아니라 이 값의 합을 방 위협 예산과 비교해 통제한다.
## scripts/map/spawn_catalog.gd의 같은 개체 값과 일치해야 한다
@export var threat_pt: float = 1.0
## 정형 공격 패턴 목록 (docs/act1/ENEMIES.md 5장). 가까운 range_px부터 검사한다.
## 이동 기반 특수행동은 여기 넣지 않는다 (scripts/data/attack_pattern.gd 주석)
@export var attack_patterns: Array[AttackPattern] = []


## 경직 등급에 따른 경직 시간 배율. 강할수록 짧게 밀린다
func stagger_time_scale() -> float:
	match stagger_level:
		Stagger.MEDIUM:
			return 0.7
		Stagger.STRONG:
			return 0.45
		_:
			return 1.0


## 경직 등급에 따른 넉백 배율
func stagger_knockback_scale() -> float:
	match stagger_level:
		Stagger.MEDIUM:
			return 0.6
		Stagger.STRONG:
			return 0.3
		_:
			return 1.0


## range_px가 가장 작은 패턴부터 정렬한 사본. 개체는 밀착 패턴을 먼저 검사한다.
##
## .tres는 배열을 Array[Resource]로 직렬화하므로(무기 쪽 WeaponDef.melee_combo와 같은 형식)
## 원소를 하나씩 AttackPattern으로 확인해 옮긴다. 통째로 형변환하면 타입이 어긋난다
func patterns_by_range() -> Array[AttackPattern]:
	var sorted: Array[AttackPattern] = []
	for item: Variant in attack_patterns:
		var pattern: AttackPattern = item as AttackPattern
		if pattern != null:
			sorted.append(pattern)
	sorted.sort_custom(_compare_range)
	return sorted


## sort_custom에 넘기는 비교자. 정적 함수로 두면 인스턴스에서 참조할 때 Callable 해석이
## 엔진 버전에 따라 달라질 수 있어 일반 메서드로 둔다
func _compare_range(a: AttackPattern, b: AttackPattern) -> bool:
	return a.range_px < b.range_px
