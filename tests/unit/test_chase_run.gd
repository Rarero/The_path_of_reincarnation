extends GdUnitTestSuite

## 장물아비 추격 달리기 검증 (docs/act1/EVENTS.md 부록 A, 2026-08-06 탑뷰 재설계).
##
## 레인 이동 범위, 충돌 한도, 포획 조건, 재현성을 고정한다.
## 장애물이 다섯 레인을 모두 막지 않는지도 본다 (막다른 길 금지).


func test_lane_move_is_clamped() -> void:
	var run: ChaseRun = ChaseRun.new(3, 20, 1)
	for i: int in range(10):
		run.move(-1)
	assert_int(run.player_lane).is_equal(0)
	for i: int in range(10):
		run.move(1)
	assert_int(run.player_lane).is_equal(ChaseRun.LANE_COUNT - 1)


func test_three_hits_end_the_run() -> void:
	var run: ChaseRun = ChaseRun.new(4, 20, 3)
	# 표적을 쫓지 않고 장애물만 맞도록 레인을 고정한 채 오래 달린다
	for i: int in range(4000):
		run.advance(0.02)
		if run.is_over():
			break
	assert_bool(run.is_over()).is_true()
	if run.failed():
		assert_int(run.hits).is_equal(ChaseRun.MAX_HITS)


func test_catch_requires_same_lane() -> void:
	var run: ChaseRun = ChaseRun.new(1, 40, 11)
	run.gap = 0.5
	run.player_lane = (run.target_lane() + 1) % ChaseRun.LANE_COUNT
	run.advance(0.1)
	# 레인이 어긋나면 잡히지 않고 거리가 다시 벌어진다
	assert_int(run.caught_count()).is_equal(0)
	assert_float(run.gap).is_greater(0.0)
	run.player_lane = run.target_lane()
	run.gap = 0.05
	run.advance(0.1)
	assert_int(run.caught_count()).is_equal(1)


func test_catching_everyone_finishes_the_run() -> void:
	var run: ChaseRun = ChaseRun.new(3, 30, 21)
	for i: int in range(500):
		if run.is_over():
			break
		run.player_lane = run.target_lane()
		run.gap = 0.05
		run.advance(0.05)
	assert_bool(run.all_caught()).is_true()
	assert_bool(run.is_over()).is_true()
	assert_int(run.caught_coins()).is_equal(90)
	assert_int(run.lost_coins()).is_equal(0)


func test_obstacles_never_block_every_lane() -> void:
	var run: ChaseRun = ChaseRun.new(3, 20, 77)
	for i: int in range(2000):
		run.advance(0.02)
		var rows: Dictionary = {}
		for obstacle: Dictionary in run.obstacles:
			var key: int = int(round(float(obstacle["y"]) / 8.0))
			var lanes: Dictionary = rows.get(key, {})
			lanes[int(obstacle["lane"])] = true
			rows[key] = lanes
		for key: int in rows:
			var free: int = ChaseRun.LANE_COUNT - (rows[key] as Dictionary).size()
			assert_int(free).is_greater_equal(1)
		if run.is_over():
			break


func test_same_seed_reproduces_run() -> void:
	var a: ChaseRun = ChaseRun.new(4, 25, 909)
	var b: ChaseRun = ChaseRun.new(4, 25, 909)
	for i: int in range(300):
		a.advance(0.02)
		b.advance(0.02)
		if i % 17 == 0:
			a.move(1)
			b.move(1)
	assert_int(a.hits).is_equal(b.hits)
	assert_int(a.caught_count()).is_equal(b.caught_count())
	assert_int(a.player_lane).is_equal(b.player_lane)
	assert_float(a.gap).is_equal_approx(b.gap, 0.0001)


func test_coins_are_split_across_thieves() -> void:
	var run: ChaseRun = ChaseRun.new(5, 12, 5)
	assert_int(run.thieves.size()).is_equal(5)
	assert_int(run.caught_coins() + run.lost_coins()).is_equal(60)


func test_track_resource_is_loadable_and_harder_than_the_draft() -> void:
	var path: String = "res://resources/minigames/chase_track_act1.tres"
	var track: ChaseTrack = load(path) as ChaseTrack
	assert_object(track).is_not_null()
	# 2026-08-07 상향. 초안(스크롤 150, 간격 0.55~0.95, 막는 레인 1~3)보다 빡빡해야 한다
	assert_float(track.scroll_speed).is_greater(150.0)
	assert_float(track.spawn_max).is_less(0.55)
	assert_int(track.blocked_min).is_greater_equal(2)
	assert_bool(track.blocked_min <= track.blocked_max).is_true()
	assert_bool(track.spawn_min <= track.spawn_max).is_true()
	assert_float(track.evade_chance).is_greater(0.0)


func test_fast_frames_do_not_skip_collisions() -> void:
	var run: ChaseRun = ChaseRun.new(1, 10, 5)
	run.obstacles.clear()
	run.player_lane = 2
	run.obstacles.append({"lane": 2, "y": 40.0, "prev_y": 40.0, "spent": false, "shape": 0})
	# 한 프레임에 판정 폭을 통째로 건너뛰는 큰 걸음이어도 지나친 것을 잡아야 한다
	run.advance(0.5)
	assert_int(run.hits).is_equal(1)


func test_target_avoids_the_player_lane() -> void:
	var track: ChaseTrack = ChaseTrack.new()
	track.evade_chance = 1.0
	for s: int in range(20):
		var run: ChaseRun = ChaseRun.new(1, 10, s, track)
		run.player_lane = run.target_lane()
		var before: int = run.player_lane
		# 레인을 바꾸는 주기를 한 번만 넘긴다
		run.advance(track.switch_interval + 0.05)
		assert_int(run.target_lane()).is_not_equal(before)
