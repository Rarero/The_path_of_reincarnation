extends GdUnitTestSuite

## 정규 보스 2종(문얼굴, 방망이) 보상 등급 동일성 검증 (docs/act1/BOSS.md 7장 "동일 등급").
##
## 두 보스 씬 모두 BossBase의 보상 관련 export 기본값을 그대로 쓰고 각자 오버라이드하지
## 않는다. 그래서 파생 방식으로 동일성을 보장한다: 값을 나란히 두 번 정의하지 않으므로
## 한쪽만 고치는 실수가 구조적으로 나지 않는다. 이 테스트는 그 전제(오버라이드 없음)가
## 깨졌을 때 바로 잡아내는 회귀 가드다.

const MUNEOLGUL_SCENE: PackedScene = preload("res://scenes/bosses/dokkaebi_muneolgul.tscn")
const BANGMANGI_SCENE: PackedScene = preload("res://scenes/bosses/dokkaebi_bangmangi.tscn")


func test_both_regular_bosses_grant_reward() -> void:
	var muneolgul: BossBase = auto_free(MUNEOLGUL_SCENE.instantiate()) as BossBase
	var bangmangi: BossBase = auto_free(BANGMANGI_SCENE.instantiate()) as BossBase
	add_child(muneolgul)
	add_child(bangmangi)
	assert_bool(muneolgul.grants_reward).is_true()
	assert_bool(bangmangi.grants_reward).is_true()


func test_reward_relic_grade_is_equal_between_regular_bosses() -> void:
	var muneolgul: BossBase = auto_free(MUNEOLGUL_SCENE.instantiate()) as BossBase
	var bangmangi: BossBase = auto_free(BANGMANGI_SCENE.instantiate()) as BossBase
	add_child(muneolgul)
	add_child(bangmangi)
	assert_int(muneolgul.reward_relic_grade).is_equal(bangmangi.reward_relic_grade)
	assert_int(muneolgul.reward_relic_grade).is_equal(RelicDef.Grade.JINPUM)


func test_reward_relic_source_is_equal_between_regular_bosses() -> void:
	var muneolgul: BossBase = auto_free(MUNEOLGUL_SCENE.instantiate()) as BossBase
	var bangmangi: BossBase = auto_free(BANGMANGI_SCENE.instantiate()) as BossBase
	add_child(muneolgul)
	add_child(bangmangi)
	assert_str(String(muneolgul.reward_relic_source)).is_equal(String(bangmangi.reward_relic_source))


func test_reward_coin_is_equal_between_regular_bosses() -> void:
	var muneolgul: BossBase = auto_free(MUNEOLGUL_SCENE.instantiate()) as BossBase
	var bangmangi: BossBase = auto_free(BANGMANGI_SCENE.instantiate()) as BossBase
	add_child(muneolgul)
	add_child(bangmangi)
	assert_int(muneolgul.reward_coin).is_equal(bangmangi.reward_coin)
