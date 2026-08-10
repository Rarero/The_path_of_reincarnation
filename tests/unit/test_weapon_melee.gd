extends GdUnitTestSuite

## 환도 근접 무기 검증 (docs/systems/WEAPONS.md 5장과 6장, G4 축소판).
##
## 콤보 상태 기계, 마무리 고정, 점프 공격 격리와 공중 1회 제한을 본다.
## 패링(7장)과 2슬롯 스위칭(2.2절)은 이 세션 범위가 아니다.

const HWANDO_PATH: String = "res://resources/weapons/hwando.tres"
const SCENE_PATH: String = "res://scenes/player/weapon_melee.tscn"


func _new_weapon() -> WeaponMelee:
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	var weapon: WeaponMelee = auto_free(packed.instantiate()) as WeaponMelee
	add_child(weapon)
	weapon.set_equipped(true)
	# set_equipped가 물리 처리를 켠다. 엔진 틱과 수동 틱이 겹치면 시간이 두 배로
	# 흘러 판정이 어긋나므로, 테스트는 수동 틱만 쓴다
	weapon.set_physics_process(false)
	return weapon


## 시간을 흘린다. 물리 틱을 직접 돌려 프레임 의존을 없앤다
func _tick(weapon: WeaponMelee, seconds: float, step: float = 1.0 / 60.0) -> void:
	var left: float = seconds
	while left > 0.0:
		weapon._physics_process(minf(step, left))
		left -= step


func test_definition_loads_with_three_step_combo() -> void:
	var definition: WeaponDef = load(HWANDO_PATH) as WeaponDef
	assert_object(definition).is_not_null()
	assert_int(definition.combo_length()).is_equal(3)
	assert_object(definition.melee_jump_attack).is_not_null()
	assert_str(definition.display_name).is_equal("환도")


## 3타 수치가 설계표와 맞는다 (5.2절).
func test_combo_damage_matches_design() -> void:
	var definition: WeaponDef = load(HWANDO_PATH) as WeaponDef
	assert_int(definition.combo_step(0).damage).is_equal(10)
	assert_int(definition.combo_step(1).damage).is_equal(10)
	assert_int(definition.combo_step(2).damage).is_equal(20)
	assert_int(definition.melee_jump_attack.damage).is_equal(15)


## 마무리 타는 콤보 창이 0이라 어떤 입력으로도 이어지지 않는다 (규칙 7).
func test_finisher_has_no_combo_window() -> void:
	var definition: WeaponDef = load(HWANDO_PATH) as WeaponDef
	assert_float(definition.combo_step(2).combo_window).is_equal(0.0)
	assert_bool(definition.combo_step(2).knockback).is_true()


## 첫 입력은 1타부터 시작한다.
func test_first_attack_starts_at_step_one() -> void:
	var weapon: WeaponMelee = _new_weapon()
	assert_bool(weapon.try_primary_attack(true)).is_true()
	assert_int(weapon.combo_step()).is_equal(0)
	assert_bool(weapon.is_attacking()).is_true()


## 콤보 창 안의 입력이 다음 타로 이어진다 (규칙 5).
func test_input_within_window_chains_to_next_step() -> void:
	var weapon: WeaponMelee = _new_weapon()
	weapon.try_primary_attack(true)
	# windup + active를 지나 콤보 창 구간으로 들어간다
	_tick(weapon, 0.19)
	weapon.try_primary_attack(true)
	_tick(weapon, 0.02)
	assert_int(weapon.combo_step()).is_equal(1)


## 창 밖의 입력은 콤보 카운터를 0으로 되돌린다 (규칙 5).
func test_input_after_window_resets_counter() -> void:
	var weapon: WeaponMelee = _new_weapon()
	weapon.try_primary_attack(true)
	# 1타 전체 + 콤보 창까지 전부 흘려보낸다
	_tick(weapon, 1.2)
	assert_bool(weapon.is_attacking()).is_false()
	weapon.try_primary_attack(true)
	assert_int(weapon.combo_step()).is_equal(0)


## 3타 완료 후 카운터가 자동으로 0이 된다 (규칙 6).
func test_combo_resets_after_finisher() -> void:
	var weapon: WeaponMelee = _new_weapon()
	for i: int in range(3):
		weapon.try_primary_attack(true)
		_tick(weapon, 0.19)
	# 마무리까지 전부 흘린다
	_tick(weapon, 1.0)
	assert_bool(weapon.is_attacking()).is_false()
	weapon.try_primary_attack(true)
	assert_int(weapon.combo_step()).is_equal(0)


## 점프 공격은 지상 콤보 카운터에 영향을 주지 않는다 (규칙 8).
func test_jump_attack_is_isolated_from_ground_combo() -> void:
	var weapon: WeaponMelee = _new_weapon()
	assert_bool(weapon.try_primary_attack(false)).is_true()
	assert_bool(weapon.is_jump_attack()).is_true()
	assert_int(weapon.combo_step()).is_equal(-1)
	_tick(weapon, 1.0)
	weapon.notify_landed()
	_tick(weapon, 0.2)
	weapon.try_primary_attack(true)
	assert_int(weapon.combo_step()).is_equal(0)


## 착지 전까지 점프 공격은 한 번만 허용된다 (규칙 9).
func test_air_attack_limited_to_once_before_landing() -> void:
	var weapon: WeaponMelee = _new_weapon()
	assert_bool(weapon.try_primary_attack(false)).is_true()
	_tick(weapon, 0.5)
	assert_bool(weapon.try_primary_attack(false)).is_false()
	weapon.notify_landed()
	_tick(weapon, 0.3)
	assert_bool(weapon.try_primary_attack(false)).is_true()


## 장착 해제하면 진행 중 판정이 취소되고 공격을 받지 않는다.
func test_unequip_cancels_attack() -> void:
	var weapon: WeaponMelee = _new_weapon()
	weapon.try_primary_attack(true)
	weapon.set_equipped(false)
	assert_bool(weapon.is_attacking()).is_false()
	assert_bool(weapon.try_primary_attack(true)).is_false()


## 타격마다 자동 전진이 쌓이고 소비하면 비워진다 (5.2절).
func test_advance_accumulates_and_drains() -> void:
	var weapon: WeaponMelee = _new_weapon()
	weapon.set_facing(1)
	weapon.try_primary_attack(true)
	_tick(weapon, 0.12)
	var advance: float = weapon.consume_advance()
	assert_float(advance).is_greater(0.0)
	assert_float(weapon.consume_advance()).is_equal(0.0)


## 바라보는 방향이 바뀌면 전진 부호도 따라간다.
func test_advance_follows_facing() -> void:
	var weapon: WeaponMelee = _new_weapon()
	weapon.set_facing(-1)
	weapon.try_primary_attack(true)
	_tick(weapon, 0.12)
	assert_float(weapon.consume_advance()).is_less(0.0)


## 대시 캔슬은 어느 구간에서든 공격을 끊는다 (5.5절).
func test_cancel_stops_attack_in_windup() -> void:
	var weapon: WeaponMelee = _new_weapon()
	weapon.try_primary_attack(true)
	_tick(weapon, 0.05)
	assert_bool(weapon.is_attacking()).is_true()
	weapon.cancel_attack()
	assert_bool(weapon.is_attacking()).is_false()
	assert_int(weapon.combo_step()).is_equal(-1)


## 타격 구간에서 끊으면 판정이 즉시 꺼진다. 안 그러면 캔슬이 대가 없는 이득이 된다.
##
## monitoring 이 아니라 is_active() 를 본다. Hitbox 는 물리 콜백 중에 monitoring 을
## 바꿀 수 없어 set_deferred 로 미루는데, 이 테스트는 _physics_process 를 손으로만
## 돌려서 지연 호출이 흘러갈 틈이 없다. is_active() 는 같은 프레임에 반영되는
## 권위 플래그이고 Hitbox._physics_process 의 판정 게이트도 이 값이다
func test_cancel_deactivates_hitbox_during_active() -> void:
	var weapon: WeaponMelee = _new_weapon()
	weapon.try_primary_attack(true)
	_tick(weapon, 0.12)
	assert_bool(weapon.hitbox.is_active()).is_true()
	weapon.cancel_attack()
	assert_bool(weapon.hitbox.is_active()).is_false()


## 캔슬 뒤 다음 공격은 마무리가 아니라 1타부터다.
##
## 두 번째 입력 뒤에 한 틱을 더 흘린다. 0.19초 시점은 아직 타격 구간이고 그 입력은
## 예약(_buffered)으로 들어가 후딜 진입 때 다음 타로 풀린다. 즉시 단정하면 예약이
## 풀리기 전 값을 읽어 0이 나온다 (test_input_within_window_chains_to_next_step 과 같은 규칙)
func test_cancel_resets_combo_counter() -> void:
	var weapon: WeaponMelee = _new_weapon()
	weapon.try_primary_attack(true)
	_tick(weapon, 0.19)
	weapon.try_primary_attack(true)
	_tick(weapon, 0.02)
	assert_int(weapon.combo_step()).is_equal(1)
	weapon.cancel_attack()
	assert_bool(weapon.try_primary_attack(true)).is_true()
	assert_int(weapon.combo_step()).is_equal(0)


## 캔슬은 취소지 환불이 아니다. 공중 공격 1회 제한은 그대로 소모된 채 남는다.
func test_cancel_does_not_refund_air_attack() -> void:
	var weapon: WeaponMelee = _new_weapon()
	weapon.try_primary_attack(false)
	_tick(weapon, 0.05)
	weapon.cancel_attack()
	assert_bool(weapon.try_primary_attack(false)).is_false()


## 후딜 구간 캔슬. 가장 답답하던 마무리 0.30초가 즉시 끊긴다.
func test_cancel_during_finisher_recovery() -> void:
	var weapon: WeaponMelee = _new_weapon()
	weapon.try_primary_attack(true)
	_tick(weapon, 0.19)
	weapon.try_primary_attack(true)
	_tick(weapon, 0.19)
	weapon.try_primary_attack(true)
	# 예약이 풀릴 만큼 흘린다. 2타 타격 구간이 0.0233초 남아 있어 한 틱(0.0167)으로는
	# 부족하다. 실측으로 0.05초면 후딜 진입과 함께 3타 windup 으로 넘어간다
	_tick(weapon, 0.05)
	assert_int(weapon.combo_step()).is_equal(2)
	# 마무리 windup 0.14 + active 0.10 을 지나 후딜에 들어간다
	_tick(weapon, 0.22)
	assert_bool(weapon.is_attacking()).is_true()
	weapon.cancel_attack()
	assert_bool(weapon.is_attacking()).is_false()
