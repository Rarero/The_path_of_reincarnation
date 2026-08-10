extends GdUnitTestSuite

## 방 템플릿 선택과 시드 파생 검증 (scripts/map/room_roster.gd).
##
## docs/RUN_STRUCTURE.md 6장: 같은 템플릿이 한 런에 두 번 나오지 않아야 한다.

const SEEDS: int = 200
const POOL_SIZE: int = 8
## 1막 전투 배정층 L1, L2, L4, L8에 해당하는 노드 id 표본
const COMBAT_NODE_IDS: Array = [0, 3, 11, 27]


func test_same_seed_and_node_reproduce_pick() -> void:
	for value: int in range(SEEDS):
		var a: int = RoomRoster.pick(value, 11, POOL_SIZE, [])
		var b: int = RoomRoster.pick(value, 11, POOL_SIZE, [])
		assert_int(a).is_equal(b)


func test_no_combat_template_repeats_within_a_run() -> void:
	for value: int in range(SEEDS):
		var used: Array[int] = []
		for node_id: int in COMBAT_NODE_IDS:
			var index: int = RoomRoster.pick(value, node_id, POOL_SIZE, used)
			assert_int(index).is_between(0, POOL_SIZE - 1)
			assert_bool(used.has(index)).is_false()
			used.append(index)


## 중간보스가 빌려 쓰는 템플릿을 미리 뺀 상태에서도 4개 전투 노드를 겹치지 않게 채운다
func test_reserved_template_is_never_reused() -> void:
	for value: int in range(SEEDS):
		var used: Array[int] = [POOL_SIZE - 1]
		for node_id: int in COMBAT_NODE_IDS:
			var index: int = RoomRoster.pick(value, node_id, POOL_SIZE, used)
			assert_int(index).is_not_equal(POOL_SIZE - 1)
			used.append(index)


func test_exhausted_pool_falls_back_to_full_pool() -> void:
	var used: Array[int] = [0, 1]
	var index: int = RoomRoster.pick(1234, 5, 2, used)
	assert_int(index).is_between(0, 1)


func test_empty_pool_returns_invalid_index() -> void:
	assert_int(RoomRoster.pick(1, 1, 0, [])).is_equal(-1)


## 배경 시드와 배치 시드를 분리한 이유: 배경 규칙을 손봐도 적 배치가 흔들리지 않아야 한다
func test_background_and_placement_seeds_are_independent() -> void:
	var same: int = 0
	for value: int in range(SEEDS):
		if RoomRoster.background_seed(value, 7) == RoomRoster.placement_seed(value, 7):
			same += 1
	assert_int(same).is_equal(0)


func test_seeds_stay_in_positive_range() -> void:
	for value: int in [0, 1, -1, 2147483647, -2147483648]:
		assert_int(RoomRoster.placement_seed(value, 13)).is_greater_equal(0)
		assert_int(RoomRoster.background_seed(value, 13)).is_greater_equal(0)
