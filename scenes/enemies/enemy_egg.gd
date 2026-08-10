extends EnemyPatternActor

## 달걀도깨비 (docs/act1/ENEMIES.md 5.5).
##
## 저위협 지형 장애물이다. 평소 정지하거나 느리게 배회하다가, 플레이어가 근접 축선에
## 들면 진동 예비 후 직선으로 굴러온다. 처치보다 회피가 기본 대응이다.
##
## 공격 판정이 아니라 몸통 접촉이 위협이라 구르기는 ContactHitbox로 판정한다.
## 씬에 AttackHitbox 노드를 두지 않는다. 두면 공통 상태 머신이 판정 단계에서 그것도
## 함께 켜서 같은 구르기에 두 번 맞는다. 베이스는 노드가 없으면 조용히 건너뛴다.
##
## 벽이나 좌판에 부딪히면 잠시 튕겨 경직된다. 이 구간이 반격 창이다.

enum Mode { IDLE, ROLL, BOUNCE }

@export_group("감지")
## 근접 축선 판정의 세로 허용 폭 (px). 이보다 높낮이가 벌어지면 무시한다.
## 원거리에서는 장애물처럼 무시할 수 있어야 한다 (5.5 감지와 어그로)
@export var axis_tolerance: float = 26.0

@export_group("구르기")
## 구르는 동안의 이동속도 배율. 구를 때 순간 L 등급
@export var roll_speed_multiplier: float = 3.4
## 벽이나 좌판에 부딪혔을 때의 튕김 경직 (초). 30f
@export var bounce_stun_time: float = 0.50
## 튕길 때 뒤로 밀리는 속도 (px/s)
@export var bounce_back_velocity: float = 70.0
## 구르는 동안 스프라이트 회전 속도 (라디안/초). 구르는 회전 모션이 대표 실루엣이다
@export var roll_spin_speed: float = 12.0

@export_group("배회")
@export var wander_speed_ratio: float = 0.5

@export_group("피격")
## 구르는 동안 피격 경직에 곱할 배율. 굴러오는 덩어리는 때려도 멈추지 않고
## 아주 짧게 움찔한 뒤 계속 굴러야 한다. 처치가 아니라 회피가 기본 대응이기 때문이다
## (5.5 대응 방식). 0.16초 * 0.20 = 약 0.03초, 두 프레임쯤이다
@export var roll_hitstun_scale: float = 0.20

var _mode: int = Mode.IDLE
var _bounce_left: float = 0.0
var _spin: float = 0.0
var _afterimage_left: float = 0.0


func _tick_ai(delta: float) -> void:
	match _mode:
		Mode.BOUNCE:
			_tick_bounce(delta)
		Mode.ROLL:
			_tick_roll(delta)
		_:
			_tick_idle(delta)


## 근접 축선 안에 플레이어가 있는가. 거리와 높낮이를 함께 본다
func _player_on_axis() -> bool:
	var player: Node2D = find_player()
	if player == null:
		return false
	var gap: Vector2 = player.global_position - global_position
	if absf(gap.y) > axis_tolerance:
		return false
	return absf(gap.x) <= stats.detect_range


func _tick_idle(delta: float) -> void:
	if is_in_pattern():
		_tick_windup(delta)
		return
	if attack_ready() and _player_on_axis():
		var pattern: AttackPattern = pick_pattern(stats.attack_range)
		if pattern != null:
			set_facing(direction_to_player())
			start_pattern(pattern)
			return
	_wander()


func _wander() -> void:
	set_anim(&"hop")
	# 배회 중에도 천천히 굴러간다. 달걀은 걷지 않는다
	_spin += velocity.x * get_physics_process_delta_time() / 10.0
	pose_rotation = _spin
	var step: float = get_physics_process_delta_time()
	if not walk_toward(facing, stats.move_speed * wander_speed_ratio, step):
		set_facing(-facing)


## 진동 예비. 제자리에서 좌우로 잘게 떤다. 예비가 끝나면 구르기로 넘어간다
func _tick_windup(delta: float) -> void:
	var pattern: AttackPattern = current_pattern()
	velocity.x = 0.0
	if pattern != null and not _is_rolling_phase():
		# 진동 예비. 좌우로 잘게 떨고 몸이 눌렸다 펴진다. 구르기 직전 신호다
		var shiver: float = sin(Time.get_ticks_msec() * 0.05)
		velocity.x = shiver * 26.0
		pose_offset = Vector2(shiver * 2.5, 0.0)
		pose_scale = Vector2(1.0 + 0.10 * absf(shiver), 1.0 - 0.10 * absf(shiver))
		pose_rotation = deg_to_rad(shiver * 10.0)
	advance_pattern_clock(delta)
	if _is_rolling_phase():
		_enter_roll()
	elif not is_in_pattern():
		_mode = Mode.IDLE


## 판정 단계에 들어갔는지. 진동이 끝나고 실제로 구르기 시작하는 시점이다
func _is_rolling_phase() -> bool:
	return is_in_pattern() and _phase == Phase.ACTIVE


func _enter_roll() -> void:
	_mode = Mode.ROLL
	_spin = 0.0
	if contact_hitbox != null:
		contact_hitbox.damage = stats.contact_damage
		contact_hitbox.damage_multiplier = damage_multiplier
		contact_hitbox.active_duration = 0.0
		contact_hitbox.activate()


func _tick_roll(delta: float) -> void:
	velocity.x = float(facing) * stats.move_speed * roll_speed_multiplier
	# 구르기는 회전이 전부다. 이동 속도에 비례해 돌려야 미끄러지지 않고 굴러 보인다.
	# 반지름 약 10px이라 한 바퀴가 원둘레 63px에 대응한다
	_spin += velocity.x * delta / 10.0
	pose_rotation = _spin
	pose_scale = Vector2(1.06, 0.94)
	_afterimage_left -= delta
	if _afterimage_left <= 0.0:
		_afterimage_left = 0.07
		spawn_afterimage(0.3, 0.12)
	if is_on_wall() or not has_floor_ahead(facing):
		# 굴러와 부딪힌 좌판은 부수고 계속 간다 (5.5 지형 상호작용).
		# 못 넘는 벽이나 낭떠러지면 튕겨 경직된다
		if not (is_on_wall() and try_clear_obstacle()):
			_enter_bounce()
			return
	advance_pattern_clock(delta)
	if not is_in_pattern():
		_end_roll()


func _enter_bounce() -> void:
	_end_roll()
	_mode = Mode.BOUNCE
	_bounce_left = bounce_stun_time
	velocity.x = float(-facing) * bounce_back_velocity
	body_visual.self_modulate = Color(0.7, 0.7, 1.0)


func _tick_bounce(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	# 벽에 부딪혀 납작해졌다가 되돌아온다
	var t: float = _bounce_left / maxf(0.01, bounce_stun_time)
	pose_scale = Vector2(1.0 + 0.30 * t, 1.0 - 0.28 * t)
	pose_rotation = _spin
	_bounce_left = maxf(0.0, _bounce_left - delta)
	if _bounce_left > 0.0:
		return
	_mode = Mode.IDLE
	body_visual.self_modulate = Color.WHITE
	# 재정렬 후 반복한다. 다음 구르기는 반대쪽을 본다
	set_facing(-facing)


func _end_roll() -> void:
	end_pattern()
	_mode = Mode.IDLE
	if contact_hitbox != null and contact_hitbox.is_active():
		contact_hitbox.deactivate()
	# _spin 은 여기서 비우지 않는다. _enter_bounce 가 _end_roll 을 먼저 부르므로
	# 여기서 0으로 만들면 튕김 자세의 pose_rotation = _spin 이 늘 0이 되어,
	# 쌓인 회전이 최단 경로로 되감기며 역회전으로 보인다. 새 구르기 시작 때 비운다


## 방 클리어 판정에서 뺀다. 처치보다 회피가 기본 대응이라 세면 대응 방식이 뒤집힌다
## (5.5 대응 방식, 6장 클리어 카운트 제외 대상)
func counts_for_clear() -> bool:
	return false


## 구르는 동안에는 경직을 아주 짧게만 받는다
func hitstun_scale() -> float:
	return roll_hitstun_scale if _mode == Mode.ROLL else 1.0


## 짧은 경직 중에도 구르던 회전을 유지한다. 기본 늘어짐을 쓰면 회전이 0으로 돌아가
## 한 프레임 동안 똑바로 섰다가 다시 눕는 것처럼 보인다
func _tick_hitstun_pose() -> void:
	if _mode != Mode.ROLL:
		super()
		return
	pose_rotation = _spin
	pose_scale = Vector2(1.12, 0.88)


## 구르는 중에는 맞아도 구르기를 물리지 않는다. 짧게 움찔하고 그대로 굴러간다.
## 방이 정지시킬 때(set_suspended)는 예외 없이 물린다
func _cancel_action() -> void:
	if _mode == Mode.ROLL:
		if is_suspended():
			_end_roll()
		return
	super()
