extends GdUnitTestSuite

## 무기 오버레이 검증 (docs/ART_WEAPON_SPLIT.md 3.3, A6 반입).
##
## 몸 클립에 무기를 굽지 않고 얹는 구조라, 깨지는 방식이 "그림이 어긋난다"가
## 아니라 "표가 어긋난다"다. 앵커 프레임 수가 클립 프레임 수와 하나라도 다르면
## 마지막 프레임에서 무기가 사라지거나 엉뚱한 각도가 나온다. 눈으로 잡기
## 어려운 종류라 회귀로 묶는다.

const ANCHORS_PATH: String = "res://resources/weapons/hwando_anchors.tres"
const FRAMES_PATH: String = "res://scenes/player/player_frames.tres"
const ANGLES_PATH: String = "res://assets/sprites/weapons/hwando_angles.png"
const HWANDO_PATH: String = "res://resources/weapons/hwando.tres"
const PLAYER_PATH: String = "res://scenes/player/player.tscn"

## 앵커를 가진 클립. 총 클립(shoot, reload, reload_run)과 roll은 무기를 얹지
## 않는다. 총은 몸에 굽고, roll은 1프레임 자리표시자다
const OVERLAY_CLIPS: Array[StringName] = [
	&"idle", &"run", &"jump", &"fall", &"wall", &"hurt", &"melee",
	&"attack1", &"attack2", &"attack3", &"air_attack",
]

## 스윙 중 무기를 끄고 참격 이펙트가 대신하는 클립 (6장 확인 1)
const ATTACK_CLIPS: Array[StringName] = [
	&"attack1", &"attack2", &"attack3", &"air_attack",
]


func _anchors() -> WeaponAnchorSet:
	return load(ANCHORS_PATH) as WeaponAnchorSet


func _frames() -> SpriteFrames:
	return load(FRAMES_PATH) as SpriteFrames


## 앵커 프레임 수가 몸 클립 프레임 수와 정확히 같아야 한다.
## 하나라도 모자라면 그 프레임에서 무기가 사라진다
func test_anchor_frame_count_matches_body_clip() -> void:
	var anchors: WeaponAnchorSet = _anchors()
	var frames: SpriteFrames = _frames()
	assert_object(anchors).is_not_null()
	for clip: StringName in OVERLAY_CLIPS:
		assert_bool(frames.has_animation(clip)).override_failure_message(
			"몸 클립 없음: %s" % clip
		).is_true()
		assert_bool(anchors.has_clip(clip)).override_failure_message(
			"앵커 없음: %s" % clip
		).is_true()
		assert_int(anchors.frame_count(clip)).override_failure_message(
			"프레임 수 불일치: %s" % clip
		).is_equal(frames.get_frame_count(clip))


## 앵커 좌표가 캔버스 안이고 각도 index가 프레임 범위 안이다.
func test_anchor_values_stay_in_range() -> void:
	var anchors: WeaponAnchorSet = _anchors()
	var angles: Texture2D = load(ANGLES_PATH) as Texture2D
	var steps: int = angles.get_width() / angles.get_height()
	assert_int(steps).is_equal(anchors.angle_steps)
	for clip: StringName in OVERLAY_CLIPS:
		for index in anchors.frame_count(clip):
			var data: Vector4i = anchors.anchor(clip, index)
			assert_int(data.x).is_between(0, anchors.canvas)
			assert_int(data.y).is_between(0, anchors.canvas)
			assert_int(data.z).is_between(0, steps - 1)


## 공격 클립은 타격 순간에 무기를 끈다. 전 프레임이 켜져 있으면
## 참격 이펙트와 무기가 겹쳐 궤도가 두 개로 읽힌다
func test_attack_clips_hide_weapon_on_impact() -> void:
	var anchors: WeaponAnchorSet = _anchors()
	for clip: StringName in ATTACK_CLIPS:
		var hidden: int = 0
		var shown: int = 0
		for index in anchors.frame_count(clip):
			if anchors.anchor(clip, index).w == 0:
				hidden += 1
			else:
				shown += 1
		assert_int(hidden).override_failure_message(
			"타격 프레임에 무기를 끄지 않았다: %s" % clip
		).is_greater(0)
		assert_int(shown).override_failure_message(
			"예비와 회수에서 무기가 보이지 않는다: %s" % clip
		).is_greater(0)


## 없는 클립과 범위 밖 프레임은 표시 꺼짐으로 떨어진다 (오버레이가 조용히 사라진다)
func test_missing_anchor_falls_back_to_hidden() -> void:
	var anchors: WeaponAnchorSet = _anchors()
	assert_int(anchors.anchor(&"shoot", 0).w).is_equal(0)
	assert_int(anchors.anchor(&"idle", 999).w).is_equal(0)
	assert_int(anchors.anchor(&"idle", -1).w).is_equal(0)


## 3연타는 타마다 다른 몸 클립을 쓴다. 같은 클립이면 연타가 한 동작으로 뭉개진다
func test_each_combo_step_has_its_own_body_clip() -> void:
	var definition: WeaponDef = load(HWANDO_PATH) as WeaponDef
	var frames: SpriteFrames = _frames()
	var seen: Array[StringName] = []
	for index in definition.combo_length():
		var clip: StringName = definition.combo_step(index).body_clip
		assert_bool(frames.has_animation(clip)).override_failure_message(
			"몸 클립 없음: %s" % clip
		).is_true()
		assert_bool(seen.has(clip)).override_failure_message(
			"타끼리 몸 클립이 겹친다: %s" % clip
		).is_false()
		seen.append(clip)
	var jump_clip: StringName = definition.melee_jump_attack.body_clip
	assert_bool(frames.has_animation(jump_clip)).is_true()
	assert_bool(seen.has(jump_clip)).is_false()


## 타마다 참격 이펙트가 붙어 있다. 스윙 중 무기를 끄는 대가로 이펙트가
## 궤도를 그리므로, 비어 있으면 그 순간 화면에 아무것도 남지 않는다
func test_every_attack_has_slash_fx() -> void:
	var definition: WeaponDef = load(HWANDO_PATH) as WeaponDef
	var attacks: Array[MeleeAttackDef] = []
	for index in definition.combo_length():
		attacks.append(definition.combo_step(index))
	attacks.append(definition.melee_jump_attack)
	for attack: MeleeAttackDef in attacks:
		assert_object(attack.fx_texture).override_failure_message(
			"참격 이펙트 없음: %s" % attack.body_clip
		).is_not_null()
		assert_int(attack.fx_frames).is_greater(0)
		# 이펙트는 판정 창보다 길게 남아야 눈에 읽힌다
		assert_float(attack.fx_duration).is_greater_equal(attack.active)


## 무기 상태 기계가 지금 타에 맞는 몸 클립을 돌려준다.
func test_weapon_reports_body_clip_of_current_step() -> void:
	var packed: PackedScene = load("res://scenes/player/weapon_melee.tscn") as PackedScene
	var weapon: WeaponMelee = auto_free(packed.instantiate()) as WeaponMelee
	add_child(weapon)
	weapon.set_equipped(true)
	weapon.set_physics_process(false)
	assert_str(weapon.body_clip()).is_equal("")
	weapon.try_primary_attack(true)
	assert_str(weapon.body_clip()).is_equal("attack1")


## 오버레이가 앵커대로 자리를 잡고, 몸이 뒤집히면 좌우를 되비춘다.
func test_overlay_follows_anchor_and_mirrors_with_body() -> void:
	var body: AnimatedSprite2D = auto_free(AnimatedSprite2D.new())
	body.sprite_frames = _frames()
	var sprite: WeaponSprite = auto_free(WeaponSprite.new())
	sprite.angles_texture = load(ANGLES_PATH) as Texture2D
	sprite.anchors = _anchors()
	body.add_child(sprite)
	add_child(body)
	body.animation = &"idle"
	body.frame = 0
	sprite.set_active(true)

	var anchors: WeaponAnchorSet = _anchors()
	var data: Vector4i = anchors.anchor(&"idle", 0)
	var half: float = float(anchors.canvas) * 0.5
	assert_bool(sprite.visible).is_true()
	assert_float(sprite.position.x).is_equal_approx(float(data.x) - half, 0.001)
	assert_float(sprite.position.y).is_equal_approx(float(data.y) - half, 0.001)

	body.flip_h = true
	sprite._process(0.0)
	assert_bool(sprite.flip_h).is_true()
	assert_float(sprite.position.x).is_equal_approx(-(float(data.x) - half), 0.001)

	# 앵커가 없는 클립에서는 조용히 사라진다
	body.flip_h = false
	body.animation = &"shoot"
	sprite._process(0.0)
	assert_bool(sprite.visible).is_false()


## 플레이어 씬이 오버레이 노드를 갖고 있고, 장착 전에는 보이지 않는다.
func test_player_scene_wires_overlay_and_hides_until_equipped() -> void:
	var packed: PackedScene = load(PLAYER_PATH) as PackedScene
	var player: Node = auto_free(packed.instantiate())
	add_child(player)
	var sprite: WeaponSprite = player.get_node_or_null(^"BodyVisual/WeaponSprite") as WeaponSprite
	assert_object(sprite).is_not_null()
	assert_bool(sprite.is_active()).is_false()
	assert_bool(sprite.visible).is_false()
	player.equip_melee_weapon()
	assert_bool(sprite.is_active()).is_true()
	assert_bool(sprite.visible).is_true()
	player.unequip_melee_weapon()
	assert_bool(sprite.is_active()).is_false()
	assert_bool(sprite.visible).is_false()


## 3연타를 실제로 진행시키며 몸 클립이 타마다 바뀌는지 본다.
## _change_state가 클립을 되덮으면 3타 전부 총검 클립으로 돌아간다.
## 그 결함은 표 검사로는 안 잡히고 여기서만 드러난다
func test_combo_switches_body_clip_each_step() -> void:
	var packed: PackedScene = load(PLAYER_PATH) as PackedScene
	var player: Node = auto_free(packed.instantiate())
	add_child(player)
	player.equip_melee_weapon()
	var body: AnimatedSprite2D = player.get_node(^"BodyVisual") as AnimatedSprite2D
	var weapon: WeaponMelee = player.get_node(^"Hwando") as WeaponMelee
	weapon.set_physics_process(false)

	var expected: Array[StringName] = [&"attack1", &"attack2", &"attack3"]
	for step in 3:
		assert_bool(weapon.try_primary_attack(true)).override_failure_message(
			"%d타가 시작되지 않았다" % (step + 1)
		).is_true()
		assert_str(body.animation).override_failure_message(
			"%d타 몸 클립이 어긋난다" % (step + 1)
		).is_equal(expected[step])
		# 다음 입력은 후딜 중에 넣는다. 설계상 후딜을 건너뛰고 다음 타로 간다
		# (WEAPONS 5.2). 판정 창 끝 0.05초는 예약 구간이라 그 자리에서 넣으면
		# 이번 타가 그대로 이어져 클립이 바뀌지 않는다
		_tick_to_recovery(weapon)

	# 점프 공격은 지상 콤보와 다른 클립을 쓴다
	weapon._on_unequipped()
	weapon.set_equipped(true)
	weapon.set_physics_process(false)
	assert_bool(weapon.try_primary_attack(false)).is_true()
	assert_str(body.animation).is_equal("air_attack")


## 후딜 구간에 들어갈 때까지 물리 틱을 돌린다. 프레임 수로 세면 부동소수
## 누적 때문에 판정 창 끝에 한 틱 걸쳐 예약 경로로 새는 일이 있다
func _tick_to_recovery(weapon: WeaponMelee, limit: int = 300) -> void:
	var guard: int = 0
	while weapon._phase != WeaponMelee.Phase.RECOVERY and guard < limit:
		weapon._physics_process(1.0 / 60.0)
		guard += 1
	assert_int(guard).override_failure_message("후딜에 도달하지 못했다").is_less(limit)
