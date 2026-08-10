extends GdUnitTestSuite

## 이벤트 결과 데이터 검증 (docs/act1/EVENTS.md 11장 E1~E4).
##
## 풀 전체(구현 여부와 무관)를 대상으로 한다. 데이터가 규격을 벗어나면 생성기가
## 조용히 이상한 점수를 경로 검사에 넣게 되므로 여기서 막는다.

## 이벤트방 템플릿 (docs/RUN_STRUCTURE.md 6장 이벤트방 2개)
const EVENT_ROOM_SCENES: Array[String] = [
	"res://scenes/levels/room_event_wisp.tscn",
	"res://scenes/levels/room_event_roof.tscn",
]


func test_e1_score_magnitude_in_range() -> void:
	for outcome: EventOutcome in _pool().outcomes:
		var magnitude: int = absi(outcome.score)
		assert_int(magnitude).is_greater_equal(EventOutcome.SCORE_MIN_ABS)
		assert_int(magnitude).is_less_equal(EventOutcome.SCORE_MAX_ABS)


func test_e2_polarity_matches_score_sign() -> void:
	for outcome: EventOutcome in _pool().outcomes:
		assert_bool(outcome.has_matching_sign()).is_true()


func test_e2_big_value_flag_matches_score() -> void:
	for outcome: EventOutcome in _pool().outcomes:
		assert_bool(outcome.has_valid_big_value()).is_true()


func test_e3_content_completeness() -> void:
	var pool: EventPool = _pool()
	var seen: Dictionary = {}
	for outcome: EventOutcome in pool.outcomes:
		assert_bool(outcome.id != &"").is_true()
		assert_bool(seen.has(outcome.id)).is_false()
		seen[outcome.id] = true
		assert_bool(outcome.display_name.is_empty()).is_false()
		assert_bool(EventOutcome.TRIGGER_NAMES.has(outcome.trigger)).is_true()
		assert_bool(EventOutcome.ROOM_FLAVOR_NAMES.has(outcome.room_flavor)).is_true()
		assert_int(outcome.act).is_equal(1)
	assert_bool(pool.positives().is_empty()).is_false()
	assert_bool(pool.negatives().is_empty()).is_false()


func test_e4_pool_covers_every_room_flavor() -> void:
	var pool: EventPool = _pool()
	assert_bool(pool.has_room_flavor(EventOutcome.RoomFlavor.COMBAT)).is_true()
	assert_bool(pool.has_room_flavor(EventOutcome.RoomFlavor.INTERACTION)).is_true()
	# 플랫포밍 노드 자리를 이벤트가 대체하므로 플랫포밍형이 최소 1종 남아야 한다 (EVENTS 3장)
	assert_bool(pool.has_room_flavor(EventOutcome.RoomFlavor.PLATFORMING)).is_true()


func test_e4_event_room_templates_exist() -> void:
	assert_int(EVENT_ROOM_SCENES.size()).is_greater_equal(2)
	for path: String in EVENT_ROOM_SCENES:
		assert_bool(ResourceLoader.exists(path)).is_true()


func test_odds_tiers_are_loaded_and_distinct() -> void:
	var pool: EventPool = _pool()
	assert_int(pool.tiers.size()).is_equal(3)
	var seen: Dictionary = {}
	for tier: EventNodeConfig in pool.tiers:
		assert_bool(seen.has(tier.odds_tier)).is_false()
		seen[tier.odds_tier] = true
		assert_float(tier.positive_chance).is_between(0.0, 1.0)


## 구현 여부와 무관한 전체 풀. 데이터 검증은 미구현 결과까지 본다
func _pool() -> EventPool:
	return EventPool.load_act1(false)
