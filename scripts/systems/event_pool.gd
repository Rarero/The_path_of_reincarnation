class_name EventPool
extends RefCounted

## 이벤트 결과와 확률 등급의 풀 (docs/act1/EVENTS.md 8.4).
##
## 생성기는 act가 같은 EventOutcome을 모아 극성별 P 풀과 N 풀을 만들고, 확률 등급 3종을
## 함께 들고 있는다. 씬 참조가 없는 순수 자료구조라 gdUnit4 단위 테스트가 된다.
## 경로는 상수 배열로 명시한다 (RunState의 유물, 권능 풀과 같은 방식. 내보내기에서 안전하다).

## 1막 결과 16종 (docs/act1/EVENTS.md 4, 5장). 파일 추가 시 이 목록에 넣는다
const ACT1_OUTCOME_PATHS: Array[String] = [
	"res://resources/events/act1/event_p1_blacksmith_rescue.tres",
	"res://resources/events/act1/event_p2_bangmangi.tres",
	"res://resources/events/act1/event_p3_night_market_boom.tres",
	"res://resources/events/act1/event_p4_debt_paying_dokkaebi.tres",
	"res://resources/events/act1/event_p5_drunk_merchant.tres",
	"res://resources/events/act1/event_p6_memil_offering.tres",
	"res://resources/events/act1/event_p7_wisp_festival.tres",
	"res://resources/events/act1/event_p8_dokkaebi_weir.tres",
	"res://resources/events/act1/event_n1_dokkaebi_teo.tres",
	"res://resources/events/act1/event_n2_fence_den.tres",
	"res://resources/events/act1/event_n3_dark_alley.tres",
	"res://resources/events/act1/event_n4_angry_merchants.tres",
	"res://resources/events/act1/event_n5_ssireum_challenge.tres",
	"res://resources/events/act1/event_n6_plague_dokkaebi.tres",
	"res://resources/events/act1/event_n7_spiteful_dokkaebi.tres",
	"res://resources/events/act1/event_n8_toll.tres",
]

## 확률 등급 3종 (docs/act1/EVENTS.md 2장)
const ODDS_PATHS: Array[String] = [
	"res://resources/events/odds/odds_good_omen.tres",
	"res://resources/events/odds/odds_even.tres",
	"res://resources/events/odds/odds_grim.tres",
]

## 대장장이 해금 플래그와 짝지은 허브 해금 키 (docs/DESIGN_HUB.md 4장)
const BLACKSMITH_UNLOCK_KEY: String = "npc_blacksmith"

var outcomes: Array[EventOutcome] = []
var tiers: Array[EventNodeConfig] = []


## 1막 풀을 읽어 만든다. implemented_only면 방 전개가 있는 결과만 담는다.
## 런 생성기는 true, 데이터 검증 테스트는 false로 부른다.
static func load_act1(implemented_only: bool = true) -> EventPool:
	var pool: EventPool = EventPool.new()
	for path: String in ACT1_OUTCOME_PATHS:
		var outcome: EventOutcome = load(path) as EventOutcome
		if outcome == null:
			push_warning("이벤트 결과를 읽지 못했다: %s" % path)
			continue
		if implemented_only and not outcome.implemented:
			continue
		pool.outcomes.append(outcome)
	for path: String in ODDS_PATHS:
		var tier: EventNodeConfig = load(path) as EventNodeConfig
		if tier == null:
			push_warning("확률 등급을 읽지 못했다: %s" % path)
			continue
		pool.tiers.append(tier)
	return pool


## 선행 조건 판정용 런 상태 스냅샷 (docs/act1/EVENTS.md 9.3).
## 맵 생성 시점에 한 번 찍어 저장에 남긴다. 런 도중 값이 바뀌어도 확정이 흔들리지 않는다.
static func run_flags() -> Dictionary:
	return {
		&"blacksmith_locked": not GameState.is_unlocked(BLACKSMITH_UNLOCK_KEY),
	}


## 저장(JSON)에서 되살린 플래그의 키를 StringName으로 되돌린다.
static func normalize_flags(data: Dictionary) -> Dictionary:
	var flags: Dictionary = {}
	for key: Variant in data:
		flags[StringName(str(key))] = bool(data[key])
	return flags


## 저장에 넣을 수 있게 키를 문자열로 바꾼다.
static func flags_to_save(flags: Dictionary) -> Dictionary:
	var data: Dictionary = {}
	for key: Variant in flags:
		data[str(key)] = bool(flags[key])
	return data


func size() -> int:
	return outcomes.size()


func is_empty() -> bool:
	return outcomes.is_empty()


## 극성별 풀 (EventOutcome.Polarity).
func by_polarity(polarity: int) -> Array[EventOutcome]:
	var found: Array[EventOutcome] = []
	for outcome: EventOutcome in outcomes:
		if outcome.polarity == polarity:
			found.append(outcome)
	return found


func positives() -> Array[EventOutcome]:
	return by_polarity(EventOutcome.Polarity.POSITIVE)


func negatives() -> Array[EventOutcome]:
	return by_polarity(EventOutcome.Polarity.NEGATIVE)


func find_by_id(outcome_id: StringName) -> EventOutcome:
	for outcome: EventOutcome in outcomes:
		if outcome.id == outcome_id:
			return outcome
	return null


## 등급 enum 값에 대응하는 설정. 없으면 null
func tier_for(odds_tier: int) -> EventNodeConfig:
	for tier: EventNodeConfig in tiers:
		if tier.odds_tier == odds_tier:
			return tier
	return null


## 그 방 성격의 결과가 풀에 있는지 (E4 플랫포밍형 최소 1종 검사에 쓴다).
func has_room_flavor(flavor: int) -> bool:
	for outcome: EventOutcome in outcomes:
		if outcome.room_flavor == flavor:
			return true
	return false


## big_value 결과 수. 막당 한도(E6) 검사 참고값이다
func big_value_count() -> int:
	var count: int = 0
	for outcome: EventOutcome in outcomes:
		if outcome.big_value:
			count += 1
	return count
