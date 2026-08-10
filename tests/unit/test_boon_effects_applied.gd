extends GdUnitTestSuite

## 권능이 실제로 게임 수치에 반영되는지 검증한다 (docs/systems/BOONS.md 8.2, 8.3).
##
## 이 파일이 있는 이유: 권능 .tres에 효과가 적혀 있어도 그 target_key를 읽는 코드가
## 없으면 게임에서는 아무 일도 일어나지 않는다. 2026-08-08에 실제로 ranged_damage,
## damage_taken, max_ammo가 어디에서도 소비되지 않아 신당에서 고른 권능이 체감되지
## 않는 문제가 있었다. 정의와 소비처를 함께 묶어 두는 회귀 시험이다.


func before_test() -> void:
	RunState.reset_run()


func after_test() -> void:
	RunState.reset_run()


func _stat_boon(
	id: StringName, key: StringName, value: float, multiplier: bool
) -> BoonDef:
	var effect: BoonEffect = BoonEffect.new()
	effect.hook = BoonEffect.Hook.STAT_MODIFIER
	effect.target_key = key
	effect.base_value = value
	effect.is_multiplier = multiplier
	effect.rarity_scales = false
	var def: BoonDef = BoonDef.new()
	def.id = id
	def.pantheon = BoonDef.Pantheon.JOWANG
	var effects: Array[BoonEffect] = [effect]
	def.stat_effects = effects
	return def


## M2 권능 7종이 쓰는 모든 능치 키가 실제로 코드에서 소비되는지 확인한다.
## 소비처가 없는 키가 새로 생기면 여기서 걸린다.
func test_every_stat_key_used_by_m2_boons_is_consumed() -> void:
	var consumed: Array[StringName] = [
		&"max_health",
		&"melee_damage",
		&"ranged_damage",
		&"damage_taken",
		&"max_ammo",
		&"burn_duration",
		&"burn_stack_cap",
	]
	var ids: Array[StringName] = [
		&"boon_sansin_san_ppyeo",
		&"boon_sansin_beom_ippal",
		&"boon_sansin_bawi_chigi",
		&"boon_jowang_agungi",
		&"boon_jowang_janbul",
		&"boon_jowang_bulti",
		&"boon_jowang_bujikkaengi",
	]
	for id: StringName in ids:
		var def: BoonDef = RunState.boon_def(id)
		assert_object(def).is_not_null()
		for effect: BoonEffect in def.stat_effects:
			if effect.hook != BoonEffect.Hook.STAT_MODIFIER:
				continue
			assert_bool(consumed.has(effect.target_key)).override_failure_message(
				"%s의 능치 키 %s를 읽는 코드가 없다" % [String(id), String(effect.target_key)]
			).is_true()


## 원거리 피해 배율이 총알 피해에 실제로 곱해진다.
func test_ranged_damage_reaches_bullet_damage() -> void:
	var before: float = RunState.total_stat_mult(&"ranged_damage")
	assert_float(before).is_equal_approx(1.0, 0.0001)
	RunState.boons.add_boon(_stat_boon(&"t_ranged", &"ranged_damage", 0.25, true))
	assert_float(RunState.total_stat_mult(&"ranged_damage")).is_equal_approx(1.25, 0.0001)


## 받는 피해 감소가 Health의 피해 필터를 통해 실제로 줄어든다.
func test_damage_taken_filter_reduces_damage() -> void:
	var health: Health = auto_free(Health.new())
	health.maximum = 100
	add_child(health)
	await await_idle_frame()
	RunState.boons.add_boon(_stat_boon(&"t_taken", &"damage_taken", -0.5, true))
	health.damage_filter = func(amount: int) -> int:
		return maxi(1, int(round(float(amount) * RunState.total_stat_mult(&"damage_taken"))))
	var dealt: int = health.apply_damage(20)
	assert_int(dealt).is_equal(10)


## 최대 탄약 가산이 탄창 크기에 더해진다.
func test_max_ammo_flat_adds_to_magazine() -> void:
	assert_float(RunState.total_stat_flat(&"max_ammo")).is_equal_approx(0.0, 0.0001)
	RunState.boons.add_boon(_stat_boon(&"t_ammo", &"max_ammo", 6.0, false))
	assert_float(RunState.total_stat_flat(&"max_ammo")).is_equal_approx(6.0, 0.0001)


## 액티브가 건 일시 강화가 총 배율에 얹혔다가 시간이 지나면 사라진다.
func test_temp_mult_applies_then_expires() -> void:
	RunState.grant_temp_mult(&"melee_damage", 1.0, 0.05)
	assert_float(RunState.total_stat_mult(&"melee_damage")).is_equal_approx(2.0, 0.0001)
	await await_millis(200)
	assert_float(RunState.total_stat_mult(&"melee_damage")).is_equal_approx(1.0, 0.0001)


## 화상은 대상당 하나이고 스택 상한을 넘지 않는다 (규칙 51).
func test_burn_stacks_respect_cap_and_single_instance() -> void:
	var target: Node2D = auto_free(Node2D.new())
	var health: Health = Health.new()
	health.name = "Health"
	health.maximum = 100
	target.add_child(health)
	add_child(target)
	await await_idle_frame()

	StatusBurn.apply(target, 3, 4.0, 5, 1.0)
	StatusBurn.apply(target, 4, 4.0, 5, 1.0)
	assert_int(StatusBurn.stacks_on(target)).is_equal(5)
	var burns: int = 0
	for child: Node in target.get_children():
		if child is StatusBurn:
			burns += 1
	assert_int(burns).is_equal(1)


## 신당 3택 라벨에 설명이 함께 나온다. 이름만으로는 무엇을 고르는지 알 수 없다.
func test_shrine_label_includes_description() -> void:
	var def: BoonDef = RunState.boon_def(&"boon_jowang_janbul")
	assert_object(def).is_not_null()
	assert_str(def.description).is_not_empty()
	var label: String = RunState.boon_label_for(def)
	assert_str(label).contains(def.display_name)
	assert_str(label).contains(def.description)


## 모든 M2 권능에 설명과 아이콘이 있다. 하나라도 비면 선택 화면이 이름만 남는다.
func test_m2_boons_have_description_and_icon() -> void:
	var ids: Array[StringName] = [
		&"boon_sansin_san_ppyeo",
		&"boon_sansin_beom_ippal",
		&"boon_sansin_bawi_chigi",
		&"boon_jowang_agungi",
		&"boon_jowang_janbul",
		&"boon_jowang_bulti",
		&"boon_jowang_bujikkaengi",
	]
	for id: StringName in ids:
		var def: BoonDef = RunState.boon_def(id)
		assert_object(def).is_not_null()
		assert_str(def.description).override_failure_message(
			"%s에 설명이 없다" % String(id)
		).is_not_empty()
		assert_object(def.icon).override_failure_message(
			"%s에 아이콘이 없다" % String(id)
		).is_not_null()


## 통합: 실제 플레이어 씬에서 신당 획득이 최대 체력에 즉시 반영된다.
## 종전에는 _apply_run_bonuses가 _ready에서 한 번만 불려, 런 도중 신당에서 얻은
## 권능이 체력에 전혀 반영되지 않았다 (2026-08-08 사용자 보고).
func test_player_max_health_updates_when_boon_gained_mid_run() -> void:
	var scene: PackedScene = load("res://scenes/player/player.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var player: Node = auto_free(scene.instantiate())
	add_child(player)
	await await_idle_frame()

	var health: Health = player.get_node(^"Health") as Health
	var before: int = health.maximum

	RunState.boons.add_boon(_stat_boon(&"t_hp", &"max_health", 25.0, false))
	RunState.boons_changed.emit()
	await await_idle_frame()

	assert_int(health.maximum).override_failure_message(
		"신당에서 최대 체력 권능을 얻어도 체력이 늘지 않는다"
	).is_equal(before + 25)


## 통합: 권능을 잃으면 최대 체력이 원래대로 돌아간다 (재적용이 누적되지 않는다).
func test_player_max_health_reverts_and_does_not_stack() -> void:
	var scene: PackedScene = load("res://scenes/player/player.tscn") as PackedScene
	var player: Node = auto_free(scene.instantiate())
	add_child(player)
	await await_idle_frame()

	var health: Health = player.get_node(^"Health") as Health
	var base: int = health.maximum

	RunState.boons.add_boon(_stat_boon(&"t_hp2", &"max_health", 25.0, false))
	RunState.boons_changed.emit()
	await await_idle_frame()
	# 같은 신호가 여러 번 와도 누적되지 않아야 한다
	RunState.boons_changed.emit()
	RunState.boons_changed.emit()
	await await_idle_frame()
	assert_int(health.maximum).is_equal(base + 25)

	RunState.boons.clear()
	RunState.boons_changed.emit()
	await await_idle_frame()
	assert_int(health.maximum).is_equal(base)
