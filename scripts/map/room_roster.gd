class_name RoomRoster
extends RefCounted

## 방 템플릿 선택과 방 단위 시드 파생 (docs/RUN_STRUCTURE.md 6장, 7장 시드).
##
## 씬에 의존하지 않는 순수 로직이라 단위 테스트가 된다.
##
## 시드를 둘로 나눈 이유: 배경 조합 시드와 배치 시드를 같은 값으로 쓰면 배경 규칙을
## 손볼 때 적 배치까지 통째로 흔들린다. 아트 작업과 전투 밸런스가 서로를 깨지 않게
## 상수를 다르게 두어 분리한다. 둘 다 지도 시드와 노드 id에서만 파생하므로
## 중단 저장 이어하기에서 같은 값이 나온다.

## 배경 조합 시드 상수 (기존 배경을 바꾸지 않으려고 값을 그대로 유지한다)
const BG_MUL_SEED: int = 1103515245
const BG_MUL_NODE: int = 12820163
## 배치 시드 상수
const PLACE_MUL_SEED: int = 2246822519
const PLACE_MUL_NODE: int = 3266489917
const PLACE_OFFSET: int = 774610519
## 템플릿 추첨용 추가 교란값. 배치 시드와 같은 난수열을 쓰지 않게 한다
const ROSTER_SALT: int = 1540483477
const SEED_MASK: int = 0x7FFFFFFF


## 방 배경 조합 시드
static func background_seed(map_seed: int, node_id: int) -> int:
	return (map_seed * BG_MUL_SEED + node_id * BG_MUL_NODE) & SEED_MASK


## 방 안 슬롯 배치 시드
static func placement_seed(map_seed: int, node_id: int) -> int:
	return (map_seed * PLACE_MUL_SEED + node_id * PLACE_MUL_NODE + PLACE_OFFSET) & SEED_MASK


## 전투방 템플릿을 고른다. 이미 쓴 인덱스는 제외해 같은 템플릿이 한 런에 두 번 나오지 않게 한다.
## 후보가 전부 소진되면 전체 풀에서 다시 고른다 (풀이 등장 수보다 적은 비정상 설정 대비).
static func pick(map_seed: int, node_id: int, pool_size: int, used: Array) -> int:
	if pool_size <= 0:
		return -1
	var pool: Array[int] = []
	for index: int in range(pool_size):
		if not used.has(index):
			pool.append(index)
	if pool.is_empty():
		for index: int in range(pool_size):
			pool.append(index)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = (placement_seed(map_seed, node_id) + ROSTER_SALT) & SEED_MASK
	return pool[rng.randi_range(0, pool.size() - 1)]
