extends GdUnitTestSuite

## 문얼굴 보스 검증 (docs/act1/BOSS.md 3.1, 2026-08-10 재설계 3차).
##
## 3차 재설계의 골자는 세 가지다.
##   1. 넘어지기를 폐기하고 우 얼굴의 증기로 바꿨다. 안전지대는 아레나 왼쪽 끝에만 남는다
##   2. 좌 얼굴(지진, 소환)과 우 얼굴(증기, 바람, 눈 광선)이 별도 갈래로 돈다.
##      1~2페이즈는 한 갈래씩 번갈아, 3페이즈는 두 갈래가 동시에 돈다
##   3. 눈 광선은 3페이즈 전용이고, 3페이즈는 밀도와 속도가 함께 올라간다
##
## 여기서는 순환표, 얼굴 배정, 증기 판정면 기하, 3페이즈 동시성과 가중치를 검증한다.
## 낙석 궤적과 판정 타이밍처럼 물리 프레임이 필요한 항목은 엔진 검증으로 남긴다 (BOSS.md 9장).

const BOSS_SCENE: PackedScene = preload("res://scenes/bosses/dokkaebi_muneolgul.tscn")

## 얼굴 첨자 (보스 스크립트의 LEFT / RIGHT와 같아야 한다)
const LEFT: int = 0
const RIGHT: int = 1


func _make_boss() -> BossBase:
	var boss: BossBase = auto_free(BOSS_SCENE.instantiate()) as BossBase
	add_child(boss)
	return boss


## 개전은 스크립트 고유 함수라 이름으로 부른다 (BossBase 정적 타입에는 없다).
func _start(boss: BossBase) -> void:
	boss.call(&"start_encounter")


## 체력 비율을 목표치로 떨어뜨리고 페이즈를 재판정한다.
func _drop_to(boss: BossBase, ratio: float) -> void:
	var target: int = int(float(boss.health.maximum) * ratio)
	boss.health.apply_damage(boss.health.current() - target)
	boss._check_phase()


func _consts(boss: BossBase) -> Dictionary:
	return boss.get_script().get_script_constant_map()


func _cycle(boss: BossBase, side: int) -> Array:
	return boss.call(&"cycle_for", side) as Array


# --- 개전과 페이즈 ---


## 방에 들어가도 전투는 시작되지 않는다. 다만 무적은 아니다: 문을 때리면 그것이 개전이다.
## 1차 구현은 대기 중 무적이라 문에 붙어 때려도 아무 반응이 없었다 (2026-08-08 사용자 보고).
func test_starts_dormant_but_not_invulnerable() -> void:
	var boss: BossBase = _make_boss()
	assert_int(boss.phase).is_equal(1)
	assert_bool(boss.health.is_invulnerable()).is_false()
	assert_int(boss.health.apply_damage(10)).is_equal(10)


## 피격이 개전을 겸한다: 상호작용 키를 찾지 못해도 전투가 시작된다.
func test_hit_while_dormant_starts_encounter() -> void:
	var boss: BossBase = _make_boss()
	assert_bool(bool(boss.get(&"_dormant"))).is_true()
	boss.call(&"_on_hit_received", 10, Vector2.ZERO)
	assert_bool(bool(boss.get(&"_dormant"))).is_false()


## 체력 70퍼센트 초과에서는 1페이즈에 머문다 (문턱 오검출 방지).
func test_stays_in_phase_one_above_seventy_percent() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	_drop_to(boss, 0.75)
	assert_int(boss.phase).is_equal(1)


## 체력 70퍼센트 이하에서 2페이즈(소환과 바람 합류)로 넘어간다.
func test_transitions_to_phase_two_at_seventy_percent() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	_drop_to(boss, 0.65)
	assert_int(boss.phase).is_equal(2)


## 체력 30퍼센트 이하에서 3페이즈(동시 진행)로 넘어간다. 중간을 건너뛰어도 최종 페이즈가 맞다.
func test_transitions_to_phase_three_at_thirty_percent() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	_drop_to(boss, 0.25)
	assert_int(boss.phase).is_equal(3)


## 회복으로 체력 비율이 문턱 위로 돌아가도 페이즈는 역행하지 않는다.
func test_phase_never_regresses_after_heal() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	_drop_to(boss, 0.05)
	assert_int(boss.phase).is_equal(3)
	boss.health.heal(boss.health.maximum)
	boss._check_phase()
	assert_int(boss.phase).is_equal(3)


# --- 얼굴별 순환표 ---


## 넘어지기는 폐기했다. 어떤 순환표에도 남아 있으면 안 된다 (2026-08-10 3차 재설계).
func test_fall_pattern_is_gone_from_every_cycle() -> void:
	var boss: BossBase = _make_boss()
	var consts: Dictionary = _consts(boss)
	var names: Array[StringName] = [
		&"LEFT_CYCLE_P1", &"LEFT_CYCLE", &"RIGHT_CYCLE_P1", &"RIGHT_CYCLE_P2", &"RIGHT_CYCLE_P3"
	]
	for key: StringName in names:
		assert_array(consts[String(key)] as Array).not_contains([&"fall"])


## 넘어지기 판정 노드도 함께 사라졌다. 남아 있으면 죽은 판정이 화면 밖에서 살아 있는 셈이다.
func test_slam_nodes_are_removed() -> void:
	var boss: BossBase = _make_boss()
	assert_object(boss.get_node_or_null(^"SlamHitbox")).is_null()
	assert_object(boss.get_node_or_null(^"SlamShadow")).is_null()


## 1페이즈는 좌 지진, 우 증기 한 가지씩이다.
func test_phase_one_cycles_are_quake_and_steam() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	assert_array(_cycle(boss, LEFT)).contains([&"quake"])
	assert_array(_cycle(boss, RIGHT)).contains([&"steam"])
	assert_array(_cycle(boss, LEFT)).not_contains([&"summon"])
	assert_array(_cycle(boss, RIGHT)).not_contains([&"wind"])


## 개전 직후 첫 패턴은 좌 얼굴의 지진, 우 얼굴이 준비하는 것은 증기다.
func test_first_patterns_are_quake_left_and_steam_right() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	assert_str(String(boss.call(&"peek_next", LEFT))).is_equal("quake")
	assert_str(String(boss.call(&"peek_next", RIGHT))).is_equal("steam")


## 2페이즈에서 소환은 좌 얼굴, 바람은 우 얼굴로 합류한다 (2026-08-10 요청).
func test_phase_two_adds_summon_left_and_wind_right() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	_drop_to(boss, 0.65)
	assert_array(_cycle(boss, LEFT)).contains([&"summon"])
	assert_array(_cycle(boss, RIGHT)).contains([&"wind"])


## 눈 광선은 3페이즈 전용이다. 1~2페이즈 순환표에 있으면 안 된다.
func test_beam_is_phase_three_only() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	assert_array(_cycle(boss, RIGHT)).not_contains([&"beam"])
	_drop_to(boss, 0.65)
	assert_array(_cycle(boss, RIGHT)).not_contains([&"beam"])
	_drop_to(boss, 0.25)
	assert_array(_cycle(boss, RIGHT)).contains([&"beam"])


# --- 3페이즈 동시 진행 ---


## 1~2페이즈는 한 얼굴씩 번갈아 움직인다. 차례가 아닌 쪽은 시작하지 못한다.
func test_only_one_face_acts_before_phase_three() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	assert_bool(bool(boss.call(&"_can_start", LEFT))).is_true()
	assert_bool(bool(boss.call(&"_can_start", RIGHT))).is_false()


## 3페이즈는 두 얼굴이 동시에 시작할 수 있다. 이것이 3페이즈의 정의다 (2026-08-10 요청).
func test_phase_three_lets_both_faces_act_at_once() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	_drop_to(boss, 0.25)
	assert_bool(bool(boss.call(&"_can_start", LEFT))).is_true()
	assert_bool(bool(boss.call(&"_can_start", RIGHT))).is_true()


## 3페이즈는 밀도와 속도가 함께 올라간다. 낙석과 장애물 간격은 _rate로 나누고,
## 지속시간은 _scale을 곱하고, 증기 예고는 따로 더 줄인다 (1.5~2배 요청).
func test_phase_three_raises_intensity() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	var batch: int = int(boss.call(&"summon_batch"))
	assert_float(float(boss.call(&"_rate"))).is_equal_approx(1.0, 0.001)
	assert_float(float(boss.call(&"_steam_windup_scale"))).is_equal_approx(1.0, 0.001)
	_drop_to(boss, 0.25)
	assert_float(float(boss.call(&"_rate"))).is_greater_equal(1.5)
	assert_float(float(boss.call(&"_scale"))).is_less(1.0)
	assert_float(float(boss.call(&"_steam_windup_scale"))).is_less(1.0)
	assert_int(int(boss.call(&"summon_batch"))).is_greater(batch)


## 바람은 2페이즈에서 플레이어 최대 속도(170)와 같고, 3페이즈에서 그보다 강해진다.
## 같으면 걸어서 전진이 0이고, 강하면 걸어서는 뒤로 밀린다.
func test_wind_matches_player_speed_then_exceeds_it() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	assert_float(float(boss.call(&"current_wind_force"))).is_equal_approx(170.0, 0.01)
	_drop_to(boss, 0.25)
	assert_float(float(boss.call(&"current_wind_force"))).is_greater(170.0)


## 3페이즈 장애물 주기는 더 길고 낮은 것만 이어지지 않는다 (연속 점프 강요).
func test_phase_three_obstacle_cycle_is_denser() -> void:
	var boss: BossBase = _make_boss()
	var consts: Dictionary = _consts(boss)
	var base: Array = consts["OBSTACLE_CYCLE"] as Array
	var berserk: Array = consts["OBSTACLE_CYCLE_BERSERK"] as Array
	assert_int(berserk.size()).is_greater(base.size())


# --- 증기 (우 얼굴, 넘어지기 대체) ---


## 증기는 아레나 왼쪽 끝 안전지대만 남기고 대문 앞까지 들어찬다 (2026-08-10 요청).
func test_steam_fills_arena_except_the_far_left_safe_zone() -> void:
	var boss: BossBase = _make_boss()
	var consts: Dictionary = _consts(boss)
	var arena_left: float = float(consts["ARENA_LEFT_X"])
	var gate_front: float = float(consts["GATE_FRONT_X"])
	var rect: Rect2 = boss.call(&"steam_rect") as Rect2
	var safe: float = float(boss.call(&"steam_safe"))
	assert_float(rect.position.x - arena_left).is_equal_approx(safe, 0.01)
	assert_float(rect.position.x + rect.size.x).is_equal_approx(gate_front, 0.01)


## 안전지대는 약 100px이다. 플레이어 몸 폭(12)이 여유 있게 들어가되 널널하지는 않다.
func test_steam_safe_zone_is_about_a_hundred_pixels() -> void:
	var boss: BossBase = _make_boss()
	assert_float(float(boss.call(&"steam_safe"))).is_equal_approx(100.0, 1.0)


## 3페이즈에서는 안전지대가 더 좁아진다 (2026-08-10 요청).
func test_steam_safe_zone_narrows_in_phase_three() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	var wide: float = float(boss.call(&"steam_safe"))
	_drop_to(boss, 0.25)
	assert_float(float(boss.call(&"steam_safe"))).is_less(wide)


## 증기 높이는 점프로 넘을 수 없어야 한다. 플레이어 점프 정점은 56px다.
## 넘을 수 있으면 안전지대가 무의미해져 패턴 자체가 성립하지 않는다.
func test_steam_is_too_tall_to_jump_over() -> void:
	var boss: BossBase = _make_boss()
	var consts: Dictionary = _consts(boss)
	assert_float(float(consts["STEAM_HEIGHT"])).is_greater(56.0)


## 증기 판정 노드가 실제로 있고 적 판정 층에 올바로 놓여 있다 (층 64, 마스크 8).
func test_steam_hitbox_is_on_the_enemy_layer() -> void:
	var boss: BossBase = _make_boss()
	var steam: Area2D = boss.get_node_or_null(^"SteamHitbox") as Area2D
	assert_object(steam).is_not_null()
	assert_int(steam.collision_layer).is_equal(64)
	assert_int(steam.collision_mask).is_equal(8)


## 증기는 수동으로 끄는 지속 판정이다. 자동 만료 시간이 붙어 있으면 한 번 스치고 꺼진다.
func test_steam_hitbox_does_not_auto_expire() -> void:
	var boss: BossBase = _make_boss()
	var steam: Hitbox = boss.get_node(^"SteamHitbox") as Hitbox
	assert_float(steam.active_duration).is_equal_approx(0.0, 0.001)


## 증기 아트가 실제로 붙어 있어야 한다 (2026-08-10 사용자 요청: 증기 뿜는 표현 추가).
## 단색 사각형만 있던 시절에는 판정은 맞는데 무엇에 맞는지 보이지 않았다.
func test_steam_visual_has_art_layers() -> void:
	var boss: BossBase = _make_boss()
	for path: NodePath in [^"SteamVisual/BandBack", ^"SteamVisual/BandFront"]:
		var band: Sprite2D = boss.get_node_or_null(path) as Sprite2D
		assert_object(band).is_not_null()
		assert_object(band.texture).is_not_null()
		assert_bool(band.region_enabled).is_true()
		# 가로로 이어 붙여 흘리려면 반복 그리기가 켜져 있어야 한다
		assert_int(band.texture_repeat).is_equal(CanvasItem.TEXTURE_REPEAT_ENABLED)
	for path: NodePath in [^"SteamVisual/Crown", ^"SteamVisual/Jet", ^"SteamVisual/Vent"]:
		var puffs: CPUParticles2D = boss.get_node_or_null(path) as CPUParticles2D
		assert_object(puffs).is_not_null()
		assert_object(puffs.texture).is_not_null()
		# 대기 중에 뿜고 있으면 안 된다
		assert_bool(puffs.emitting).is_false()


## 증기 띠 텍스처의 세로 크기가 판정 높이와 같아야 한다. 다르면 그림과 판정이 어긋난다.
func test_steam_band_height_matches_hitbox_height() -> void:
	var boss: BossBase = _make_boss()
	var band: Sprite2D = boss.get_node(^"SteamVisual/BandFront") as Sprite2D
	var height: float = float(_consts(boss)["STEAM_HEIGHT"])
	assert_int(band.texture.get_height()).is_equal(int(height))


## 판정면이 바뀌면 그림도 같이 따라와야 한다. 3페이즈에서 판정만 넓어지면 안 보이는 곳에 맞는다.
func test_steam_art_follows_the_hit_rect() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	_drop_to(boss, 0.25)
	boss.call(&"_apply_steam_shape")
	var rect: Rect2 = boss.call(&"steam_rect") as Rect2
	var band: Sprite2D = boss.get_node(^"SteamVisual/BandFront") as Sprite2D
	assert_float(band.position.x).is_equal_approx(rect.position.x, 0.01)
	assert_float(band.region_rect.size.x).is_equal_approx(rect.size.x, 0.01)
	var crown: CPUParticles2D = boss.get_node(^"SteamVisual/Crown") as CPUParticles2D
	assert_float(crown.emission_rect_extents.x).is_equal_approx(rect.size.x * 0.5, 0.01)


# --- 소환 (좌 얼굴, 2페이즈부터) ---


## 한 번에 나오는 수가 4기 이상이다 (2026-08-10 요청: 종전의 2배).
func test_summon_batch_is_doubled() -> void:
	var boss: BossBase = _make_boss()
	assert_int(int(boss.get(&"summon_count"))).is_greater_equal(4)


## 소환 목록이 여러 종류이고, 전부 실제로 존재하는 씬이다.
func test_summon_roster_is_varied_and_valid() -> void:
	var boss: BossBase = _make_boss()
	var scenes: Array = _consts(boss)["MINION_SCENES"] as Array
	assert_int(scenes.size()).is_greater_equal(3)
	for path: String in scenes:
		assert_bool(ResourceLoader.exists(path)).is_true()


## 소환수는 문틈에서 나와 문 밖으로 걸어 나온다. 목표 지점이 문틈보다 바깥이어야
## "문에서 나왔다"로 읽힌다 (2026-08-10 사용자 보고: 날아오듯 슉슉한다).
func test_minions_walk_outward_from_the_gate_gap() -> void:
	var boss: BossBase = _make_boss()
	var consts: Dictionary = _consts(boss)
	assert_float(float(consts["MINION_EXIT_X"])).is_less(float(consts["MINION_GATE_X"]))
	assert_float(float(boss.get(&"summon_walk_time"))).is_greater(0.4)


## 소환 총량 상한: 상한을 다 쓰면 더는 소환 조건이 서지 않는다 (노잣돈 파밍 방지 겸용).
func test_summon_stops_at_total_cap() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	boss.set(&"_summon_total", boss.get(&"summon_total_cap"))
	boss.set(&"_summon_cd", 0.0)
	assert_bool(bool(boss.call(&"_should_summon"))).is_false()


## 소환 재사용 대기 중에는 소환 조건이 서지 않는다.
func test_summon_waits_for_cooldown() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	boss.set(&"_summon_cd", 5.0)
	assert_bool(bool(boss.call(&"_should_summon"))).is_false()
	boss.set(&"_summon_cd", 0.0)
	assert_bool(bool(boss.call(&"_should_summon"))).is_true()


# --- 약점과 아레나 ---


## 회귀: 문 앞면 판정이 배리어 바깥으로 나와 플레이어 몸과 겹친다.
func test_hurtbox_overlaps_player_stop_line() -> void:
	var boss: BossBase = _make_boss()
	var hurt: CollisionShape2D = boss.get_node(^"Hurtbox/Shape") as CollisionShape2D
	var barrier: CollisionShape2D = boss.get_node(^"GateBarrier/Shape") as CollisionShape2D
	var hs: Vector2 = (hurt.shape as RectangleShape2D).size
	var bs: Vector2 = (barrier.shape as RectangleShape2D).size
	var barrier_front: float = barrier.position.x - bs.x * 0.5
	var player_stop: float = barrier_front - 6.0
	assert_float(hurt.position.x - hs.x * 0.5).is_less_equal(player_stop)
	assert_float(hurt.position.x + hs.x * 0.5).is_greater(player_stop)


## 회귀: 문 앞면 전체가 약점이어야 한다 (2026-08-08 수정의 핵심).
## 1차 구현은 약점을 얼굴 위치(지상 66px 위)에 두어 문에 붙어도 때릴 수 없었다.
func test_hurtbox_reaches_outside_barrier_and_down_to_ground() -> void:
	var boss: BossBase = _make_boss()
	var hurt: CollisionShape2D = boss.get_node(^"Hurtbox/Shape") as CollisionShape2D
	var barrier: CollisionShape2D = boss.get_node(^"GateBarrier/Shape") as CollisionShape2D
	var hurt_size: Vector2 = (hurt.shape as RectangleShape2D).size
	var barrier_size: Vector2 = (barrier.shape as RectangleShape2D).size
	var hurt_front: float = hurt.position.x - hurt_size.x * 0.5
	var barrier_front: float = barrier.position.x - barrier_size.x * 0.5
	assert_float(hurt_front).is_less(barrier_front)
	assert_float(hurt.position.y + hurt_size.y * 0.5).is_greater_equal(0.0)


## 낙석 생성 범위가 아레나 안에 들어 있어야 한다. 벗어나면 화면 밖에서 떨어진다.
func test_rock_spawn_range_stays_inside_the_arena() -> void:
	var boss: BossBase = _make_boss()
	var consts: Dictionary = _consts(boss)
	var arena_left: float = float(consts["ARENA_LEFT_X"])
	var gate_front: float = float(consts["GATE_FRONT_X"])
	assert_float(float(consts["ROCK_MIN_X"])).is_greater_equal(arena_left)
	assert_float(float(consts["ROCK_MAX_X"])).is_less_equal(gate_front)


## 아레나는 진입 즉시 대문이 보이고, 문 앞에 서면 좌우 문짝이 한 화면에 다 들어와야 한다.
## 문 앞면 위치는 배리어에서 뽑는다. 문 폭을 바꿔도 이 검사가 같이 따라온다.
func test_arena_short_enough_to_see_gate_on_entry() -> void:
	var room_scene: PackedScene = load("res://scenes/levels/room_boss_daemun_gwangjang.tscn")
	var room: Node2D = auto_free(room_scene.instantiate()) as Node2D
	var boss: Node2D = room.get_node(^"Enemies/Boss") as Node2D
	var spawn: Marker2D = room.get_node(^"SpawnPoint") as Marker2D
	var barrier: CollisionShape2D = boss.get_node(^"GateBarrier/Shape") as CollisionShape2D
	var barrier_w: float = (barrier.shape as RectangleShape2D).size.x
	var gate_front: float = boss.position.x + barrier.position.x - barrier_w * 0.5
	var room_width: float = float(room.get(&"room_width"))
	# 진입 지점의 카메라 중심 (좌우 240px씩 보인다)
	var entry_center: float = clampf(spawn.position.x, 240.0, room_width - 240.0)
	# 문짝 하나 폭(76)은 진입 즉시 보여야 한다. 대문이 있다는 사실을 놓칠 수 없게 한다
	assert_float(gate_front + 76.0).is_less(entry_center + 240.0)
	# 문 앞에 붙었을 때 대문 전체가 한 화면에 들어오는지 (뷰포트 480)
	var at_gate: float = clampf(gate_front - 16.0, 240.0, room_width - 240.0)
	assert_float(gate_front).is_greater_equal(at_gate - 240.0)
	assert_float(boss.position.x).is_less_equal(at_gate + 240.0)


# --- 얼굴 표시와 체력바 ---


## 대기 중에는 두 얼굴이 모두 눈을 감고 있다.
func test_both_faces_closed_while_dormant() -> void:
	var boss: BossBase = _make_boss()
	assert_bool(bool(boss.get(&"_left_awake"))).is_false()
	assert_bool(bool(boss.get(&"_right_awake"))).is_false()


## 개전 직후에는 차례인 좌 얼굴만 뜬다.
func test_only_the_acting_face_is_awake_in_phase_one() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	boss.call(&"_refresh_faces")
	assert_bool(bool(boss.get(&"_left_awake"))).is_true()
	assert_bool(bool(boss.get(&"_right_awake"))).is_false()


## 3페이즈는 두 얼굴이 상시 뜬다 (둘 다 동시에 움직이므로).
func test_phase_three_keeps_both_faces_open() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	_drop_to(boss, 0.25)
	boss.call(&"_refresh_faces")
	assert_bool(bool(boss.get(&"_left_awake"))).is_true()
	assert_bool(bool(boss.get(&"_right_awake"))).is_true()


## 화면 하단 체력바는 개전 전에는 뜨지 않는다. 대기 연출이 먼저다 (2026-08-10 요청).
func test_boss_bar_appears_only_after_the_encounter_starts() -> void:
	var boss: BossBase = _make_boss()
	assert_bool(boss.auto_show_bar).is_false()
	assert_bool(boss.is_boss_bar_shown()).is_false()
	_start(boss)
	assert_bool(boss.is_boss_bar_shown()).is_true()


## 체력바에 띄울 이름과 전체 페이즈 수가 붙어 있어야 한다.
func test_boss_bar_reports_name_and_phase_total() -> void:
	var boss: BossBase = _make_boss()
	assert_str(boss.display_name).is_not_empty()
	assert_int(boss.phase_total()).is_equal(3)


## 보스가 죽으면 체력바를 내린다. 남아 있으면 보상 화면까지 따라간다.
func test_boss_bar_hides_on_death() -> void:
	var boss: BossBase = _make_boss()
	_start(boss)
	assert_bool(boss.is_boss_bar_shown()).is_true()
	boss.hide_boss_bar()
	assert_bool(boss.is_boss_bar_shown()).is_false()
