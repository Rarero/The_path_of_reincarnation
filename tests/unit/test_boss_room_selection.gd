extends GdUnitTestSuite

## 정규 보스 2종 시드 배정 검증 (docs/act1/BOSS.md 1장, 5장 "중간보스와 같은 방식").
##
## run_stage.gd의 _boss_scene()은 RoomRoster.pick(map_seed, node_id,
## regular_boss_rooms.size(), [])로 문얼굴/방망이 중 하나의 인덱스를 고른다. 보스는 런당
## 노드가 하나뿐이라 used를 넘기지 않는다. 여기서는 그 선택이 기대하는 성질(재현성,
## 풀 안에 머묦, 극단 편향 없음, node_id에 실제로 종속)을 pool_size=2 조건으로 직접 검증한다.
## 씬 트리 전체(RunStage)를 세우지 않고 순수 로직(RoomRoster.pick)만 검증하는 편이
## docs/CONVENTIONS.md의 단위 테스트 원칙과 test_room_roster.gd의 기존 방식에 맞는다.

const SEEDS: int = 200
const POOL_SIZE: int = 2
## 표본 보스 노드 id. 실제 지도에서는 생성마다 id가 달라지지만 선택 로직은 seed와
## node_id 조합에만 의존하므로 대표값으로 검증해도 결론은 같다.
const BOSS_NODE_ID: int = 39


func test_same_seed_reproduces_boss_pick() -> void:
	for value: int in range(SEEDS):
		var a: int = RoomRoster.pick(value, BOSS_NODE_ID, POOL_SIZE, [])
		var b: int = RoomRoster.pick(value, BOSS_NODE_ID, POOL_SIZE, [])
		assert_int(a).is_equal(b)


func test_boss_pick_stays_within_pool() -> void:
	for value: int in range(SEEDS):
		var index: int = RoomRoster.pick(value, BOSS_NODE_ID, POOL_SIZE, [])
		assert_int(index).is_between(0, POOL_SIZE - 1)


## 200개 시드 중 어느 한쪽으로 심하게 쏠리지 않아야 한다. 보상 기대값 동일성은 별도
## 테스트(test_boss_reward_parity.gd)로 보장하므로 여기서는 극단 편향만 배제한다.
func test_boss_pick_distribution_is_not_skewed() -> void:
	var counts: Array[int] = [0, 0]
	for value: int in range(SEEDS):
		var index: int = RoomRoster.pick(value, BOSS_NODE_ID, POOL_SIZE, [])
		counts[index] += 1
	assert_int(counts[0]).is_greater(SEEDS / 4)
	assert_int(counts[1]).is_greater(SEEDS / 4)


## 2026-08-10 사용자 확정: 지금 런에 나올 수 있는 정규 보스는 문얼굴 하나뿐이다.
## 방망이는 구현이 끝나지 않아 풀에 들어가면 안 된다.
##
## 위 테스트들은 POOL_SIZE 상수로 선택 로직만 검증하므로 실제 풀 내용은 잡지 못한다.
## 여기서는 run_stage 씬에 저장된 export 값을 직접 읽는다. 씬을 인스턴스화하면 스테이지
## 전체가 딸려 오므로 SceneState로 루트 노드의 속성만 꺼내 본다.
func test_regular_boss_pool_contains_only_muneolgul() -> void:
	var pool: Array = _stage_boss_pool()
	assert_int(pool.size()).is_equal(1)
	var room: PackedScene = pool[0] as PackedScene
	assert_object(room).is_not_null()
	assert_str(room.resource_path).contains("room_boss_daemun_gwangjang")


func _stage_boss_pool() -> Array:
	var scene: PackedScene = load("res://scenes/levels/run_stage.tscn")
	var state: SceneState = scene.get_state()
	for i: int in range(state.get_node_property_count(0)):
		if state.get_node_property_name(0, i) == &"regular_boss_rooms":
			return state.get_node_property_value(0, i) as Array
	return []


## node_id가 바뀌면 결과가 달라질 수 있어야 한다 (비공개성의 근거인 진입 전 미노출과는
## 별개로, 이 함수가 실제로 node_id를 반영해 파생하고 있는지 확인하는 회귀 가드).
func test_boss_pick_depends_on_node_id() -> void:
	var differs: int = 0
	for value: int in range(SEEDS):
		var a: int = RoomRoster.pick(value, BOSS_NODE_ID, POOL_SIZE, [])
		var b: int = RoomRoster.pick(value, BOSS_NODE_ID + 1, POOL_SIZE, [])
		if a != b:
			differs += 1
	assert_int(differs).is_greater(0)
