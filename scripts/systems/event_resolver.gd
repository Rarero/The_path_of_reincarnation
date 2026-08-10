class_name EventResolver
extends RefCounted

## 이벤트 노드의 P/N 결과를 맵 생성 시 시드로 확정한다
## (docs/act1/EVENTS.md 9장, docs/RUN_STRUCTURE.md 7장 생성 절차 4단계 콘텐츠 선택).
##
## 절차: 방 테마 배정 -> 확률 등급 배정 -> 극성 확정 -> 결과 선택(필터) -> 실점수와 표시 확률 기록.
## 노드 종류와 확률 등급은 맵에 공개하고 결과 내용은 비공개다 (EVENTS 1장 공개 수준).
##
## 재현성: 노드마다 (맵 시드, 노드 id)로 파생한 서브 시드를 쓰고 노드를 id 오름차순으로
## 처리한다. 같은 시드와 같은 플래그면 같은 확정이 나온다 (E10). 중단 저장 이어하기가 이
## 재현성에 의존한다. run_stage.gd의 _background_seed()가 같은 방식의 선례다.
##
## 이 세션에서 구현하지 않은 것: EVENTS 9.2절 예산 위반 시 이벤트 결과 재조정.
## RUN_STRUCTURE 10장의 DP 예산 검사와 부분 재배정 자체가 아직 없어 선행이 없다.
## 여기서는 실점수를 노출하는 인터페이스(RunMap.node_actual_score, path_score)까지만 만든다.

## 큰 값(절대값 30) 결과의 막당 한도 (docs/act1/EVENTS.md 9.3 초안 1개, E6)
const BIG_VALUE_LIMIT_PER_ACT: int = 1
## 방 테마 풀. 노드마다 시드로 하나를 배정하고 theme_tags 필터에 쓴다 (EVENTS 8.4)
const THEMES: Array[StringName] = [&"street", &"roof", &"alley"]
## 시드 파생 상수. run_stage.gd _background_seed()와 같은 결정적 조합 방식이다
const SEED_MULT_MAP: int = 1103515245
const SEED_MULT_NODE: int = 22695477
const SEED_MASK: int = 0x7FFFFFFF
## theme_tags가 노드 테마와 맞는 후보의 가중치 (우선이지 강제가 아니다)
const WEIGHT_THEME_MATCH: float = 3.0
## 테마 태그가 없는 후보의 가중치 (어느 테마에도 놓일 수 있다)
const WEIGHT_THEME_FREE: float = 1.0

## 이번 런에 이미 확정된 결과 id 집합 (E7 런 내 중복 금지)
var used_ids: Dictionary = {}
## 이번 막에 확정된 big_value 결과 수 (E6)
var big_value_used: int = 0

var _pool: EventPool = null
var _big_value_limit: int = BIG_VALUE_LIMIT_PER_ACT


func _init(pool: EventPool, big_value_limit: int = BIG_VALUE_LIMIT_PER_ACT) -> void:
	_pool = pool
	_big_value_limit = big_value_limit


## 노드별 서브 시드. 같은 맵 시드와 같은 노드 id면 항상 같다
static func node_seed(map_seed: int, node_id: int) -> int:
	return (map_seed * SEED_MULT_MAP + (node_id + 1) * SEED_MULT_NODE) & SEED_MASK


## 맵의 모든 이벤트 노드에 결과를 확정한다. flags는 런 시작 시점의 상태 스냅샷이다.
func resolve(map: RunMap, flags: Dictionary = {}) -> void:
	used_ids.clear()
	big_value_used = 0
	if _pool == null or _pool.is_empty():
		push_warning("이벤트 풀이 비어 있어 확정을 건너뛴다")
		return
	for node_id: int in _event_node_ids(map):
		_resolve_node(map.seed_value, map.get_node_by_id(node_id), flags)


## 이벤트 종류 노드의 id를 오름차순으로 (처리 순서를 고정해 중복 금지와 한도를 결정적으로 만든다).
func _event_node_ids(map: RunMap) -> Array[int]:
	var ids: Array[int] = []
	for node: RunMapNode in map.nodes:
		if node.kind == RunMap.Kind.EVENT:
			ids.append(node.id)
	ids.sort()
	return ids


func _resolve_node(map_seed: int, node: RunMapNode, flags: Dictionary) -> void:
	if node == null:
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = node_seed(map_seed, node.id)
	node.theme = THEMES[rng.randi_range(0, THEMES.size() - 1)]
	var tier: EventNodeConfig = _pick_tier(rng)
	if tier == null:
		push_warning("확률 등급 풀이 비어 있다")
		return
	node.odds_tier = tier.odds_tier
	node.positive_chance = tier.positive_chance
	var positive: bool = rng.randf() < tier.positive_chance
	var outcome: EventOutcome = _pick_first_available(positive, node, flags, rng)
	if outcome == null:
		push_warning("이벤트 결과 후보가 없다: 노드 %d" % node.id)
		return
	_apply_outcome(node, outcome)


## 폴백 사다리. 아래로 갈수록 규칙을 하나씩 놓는다. 노드를 빈 채로 두지 않는 것이 우선이다.
##
## 1. 확정된 극성에서 고른다 (정상 경로)
## 2. 반대 극성에서 고른다. 그 극성 후보가 필터로 전부 빠진 경우다
## 3. 중복 금지를 놓고 다시 고른다. 이벤트 노드 수가 풀 크기를 넘을 때 일어난다.
##    1막 지도의 이벤트 노드는 2~5개다 (RunMap.KIND_BANDS). 구현된 결과가
##    그보다 적으면 중복 없이 채울 수 없다. 콘텐츠가 늘면 이 단계는 자연히 안 쓰인다
func _pick_first_available(
	positive: bool, node: RunMapNode, flags: Dictionary, rng: RandomNumberGenerator
) -> EventOutcome:
	var outcome: EventOutcome = _pick_outcome(positive, node, flags, rng, false)
	if outcome != null:
		return outcome
	outcome = _pick_outcome(not positive, node, flags, rng, false)
	if outcome != null:
		return outcome
	outcome = _pick_outcome(positive, node, flags, rng, true)
	if outcome != null:
		return outcome
	return _pick_outcome(not positive, node, flags, rng, true)


func _apply_outcome(node: RunMapNode, outcome: EventOutcome) -> void:
	node.outcome_id = outcome.id
	node.outcome_score = outcome.score
	node.outcome_polarity = outcome.polarity
	node.outcome_flavor = outcome.room_flavor
	node.outcome_trigger = outcome.trigger
	used_ids[outcome.id] = true
	if outcome.big_value:
		big_value_used += 1


## 확률 등급을 가중치로 뽑는다.
func _pick_tier(rng: RandomNumberGenerator) -> EventNodeConfig:
	var total: float = 0.0
	for tier: EventNodeConfig in _pool.tiers:
		total += maxf(tier.pick_weight, 0.0)
	if total <= 0.0:
		return _pool.tiers[0] if not _pool.tiers.is_empty() else null
	var roll: float = rng.randf() * total
	for tier: EventNodeConfig in _pool.tiers:
		roll -= maxf(tier.pick_weight, 0.0)
		if roll <= 0.0:
			return tier
	return _pool.tiers[_pool.tiers.size() - 1]


## 필터를 통과한 후보 (E5). 중복, 선행 조건, big_value 막당 한도를 본다.
## allow_reuse가 켜지면 중복 금지만 놓는다 (폴백 사다리 3단계).
func candidates(
	positive: bool, node: RunMapNode, flags: Dictionary, allow_reuse: bool = false
) -> Array[EventOutcome]:
	var polarity: int = (
		EventOutcome.Polarity.POSITIVE if positive else EventOutcome.Polarity.NEGATIVE
	)
	var found: Array[EventOutcome] = []
	for outcome: EventOutcome in _pool.by_polarity(polarity):
		if not allow_reuse and used_ids.has(outcome.id):
			continue
		if not outcome.meets_prerequisites(flags):
			continue
		if outcome.big_value and big_value_used >= _big_value_limit:
			continue
		found.append(outcome)
	return found


## 테마가 맞는 후보만 남긴다. 전부 빠지면 빈 배열이고 호출부가 전체 후보로 폴백한다 (8.4).
func theme_filtered(pool_list: Array[EventOutcome], theme: StringName) -> Array[EventOutcome]:
	var found: Array[EventOutcome] = []
	for outcome: EventOutcome in pool_list:
		if outcome.accepts_theme(theme):
			found.append(outcome)
	return found


func _pick_outcome(
	positive: bool,
	node: RunMapNode,
	flags: Dictionary,
	rng: RandomNumberGenerator,
	allow_reuse: bool
) -> EventOutcome:
	var base: Array[EventOutcome] = candidates(positive, node, flags, allow_reuse)
	if base.is_empty():
		return null
	var picks: Array[EventOutcome] = theme_filtered(base, node.theme)
	if picks.is_empty():
		picks = base
	return _weighted_pick(picks, node.theme, rng)


## 테마가 명시된 후보를 더 자주 뽑는다 (우선 가중치).
func _weighted_pick(
	pool_list: Array[EventOutcome], theme: StringName, rng: RandomNumberGenerator
) -> EventOutcome:
	var total: float = 0.0
	for outcome: EventOutcome in pool_list:
		total += _weight_of(outcome, theme)
	var roll: float = rng.randf() * total
	for outcome: EventOutcome in pool_list:
		roll -= _weight_of(outcome, theme)
		if roll <= 0.0:
			return outcome
	return pool_list[pool_list.size() - 1]


func _weight_of(outcome: EventOutcome, theme: StringName) -> float:
	return WEIGHT_THEME_MATCH if outcome.prefers_theme(theme) else WEIGHT_THEME_FREE
