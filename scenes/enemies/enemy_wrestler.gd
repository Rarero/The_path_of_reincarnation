extends EnemyPatternActor

## 씨름꾼 (docs/act1/ENEMIES.md 5.4).
##
## 공격은 항상 씨름 자세(선행 예비)를 거친다. 자세에 들어간 뒤 거리로 갈린다.
## 멀면 도약 돌진, 붙어 있으면 그랩이다. 플레이어는 자세를 보고 대응 위치를 미리 잡는다.
##
## 자세를 패턴 예비에 합치지 않고 따로 둔 이유가 있다. 합치면 어느 패턴을 쓸지가
## 자세에 들어가는 순간 이미 정해져 버린다. 설계 의도는 "자세를 먼저 보여주고, 그 사이
## 플레이어가 잡은 위치가 다음 패턴을 정한다"이므로 분기 시점이 자세 끝이어야 한다.
##
## 그랩 예비 구간에만 슈퍼아머가 붙는다 (AttackPattern.super_armor). 평시 경직은 강이라
## 두 값이 독립이며, 그래서 EnemyStats.stagger_level과 별개 필드로 갈라져 있다.
##
## 미구현으로 남긴 것: 왼다리 약점(부위 판정), GRAB_HOLD 구속과 연타 탈출. 둘 다 M2다.
## 지금은 그랩이 성공하면 큰 피해와 강한 넉백으로 던지기를 대신한다.

enum Mode { IDLE, STANCE, PATTERN, STUN }

## 도약 돌진 패턴 id. 자세 후 거리 분기에 쓴다
const LEAP_NAME: String = "도약 돌진"

@export_group("씨름 자세")
## 모든 공격에 앞서는 선행 예비 (초). 24f
@export var stance_time: float = 0.40

@export_group("도약 돌진")
## 도약 중 이동속도 배율
@export var leap_speed_multiplier: float = 4.2
## 도약을 시작하는 최대 거리 (px). 이 밖이면 걸어서 접근한다
@export var leap_trigger_range: float = 150.0
## 도약 중 살짝 뜨는 초기 상승 속도 (px/s). 외다리 도약의 실루엣을 만든다
@export var leap_hop_velocity: float = 150.0
## 빗나가 벽이나 좌판에 부딪혔을 때의 경직 (초). 40f
@export var miss_stun_time: float = 0.67

@export_group("그랩")
## 그랩이 성공했을 때 플레이어에게 주는 던지기 속도 (px/s)
@export var throw_velocity: Vector2 = Vector2(190.0, -170.0)

var _mode: int = Mode.IDLE
var _stance_left: float = 0.0
var _stun_left: float = 0.0
var _leap_active: bool = false
var _grab_hit: bool = false
var _afterimage_left: float = 0.0


func _ready() -> void:
	super()
	if attack_hitbox != null and not attack_hitbox.hit_landed.is_connected(_on_attack_landed):
		attack_hitbox.hit_landed.connect(_on_attack_landed)


func _tick_ai(delta: float) -> void:
	match _mode:
		Mode.STUN:
			_tick_stun(delta)
		Mode.STANCE:
			_tick_stance(delta)
		Mode.PATTERN:
			_tick_attack(delta)
		_:
			_tick_idle(delta)


func _tick_idle(_delta: float) -> void:
	var distance: float = distance_to_player()
	if distance > stats.detect_range:
		_patrol()
		return
	if attack_ready() and distance <= leap_trigger_range:
		_enter_stance()
		return
	_approach()


func _patrol() -> void:
	set_anim(&"hop")
	if not walk_toward(facing, stats.move_speed * 0.7, get_physics_process_delta_time()):
		set_facing(-facing)


func _approach() -> void:
	set_anim(&"hop")
	walk_toward(direction_to_player(), stats.move_speed, get_physics_process_delta_time())


# --- 씨름 자세 (선행 예비) ---


func _enter_stance() -> void:
	_mode = Mode.STANCE
	_stance_left = stance_time
	velocity.x = 0.0
	set_facing(direction_to_player())
	set_anim(&"idle")
	body_visual.self_modulate = WINDUP_TINT


## 자세 유지. 판정이 없고, 끝나는 순간의 거리로 다음 패턴이 갈린다
func _tick_stance(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_stance_left = maxf(0.0, _stance_left - delta)
	# 씨름 자세. 허리를 낮추고 어깨를 벌린다. 모든 공격에 앞서는 가장 큰 신호다
	var t: float = 1.0 - _stance_left / maxf(0.01, stance_time)
	pose_scale = Vector2(1.0 + 0.22 * t, 1.0 - 0.18 * t)
	pose_offset = Vector2(0.0, 3.0 * t)
	pulse_windup(_stance_left)
	if _stance_left > 0.0:
		return
	_branch_from_stance()


func _branch_from_stance() -> void:
	var distance: float = distance_to_player()
	var chosen: AttackPattern = null
	for pattern: AttackPattern in stats.patterns_by_range():
		var is_leap: bool = pattern.display_name == LEAP_NAME
		if not is_leap and distance <= pattern.range_px:
			chosen = pattern
			break
		if is_leap and distance <= pattern.range_px:
			chosen = pattern
	if chosen == null:
		_mode = Mode.IDLE
		body_visual.self_modulate = Color.WHITE
		start_attack_cooldown()
		return
	_mode = Mode.PATTERN
	_grab_hit = false
	_leap_active = false
	start_pattern(chosen)


# --- 패턴 진행 ---


func _tick_attack(delta: float) -> void:
	if not is_in_pattern():
		_mode = Mode.IDLE
		return
	if _leap_active:
		_tick_leap(delta)
		return
	tick_pattern(delta)
	if not is_in_pattern():
		_mode = Mode.IDLE


func _tick_leap(delta: float) -> void:
	velocity.x = float(facing) * stats.move_speed * leap_speed_multiplier
	pose_dash(1.0)
	_afterimage_left -= delta
	if _afterimage_left <= 0.0:
		_afterimage_left = 0.05
		spawn_afterimage()
	if is_on_wall() and not try_clear_obstacle():
		# 빗나가 충돌했다. 유도 충돌 STUN이 반격 창이 된다 (5.4)
		_enter_stun()
		return
	advance_pattern_clock(delta)
	if not is_in_pattern():
		_mode = Mode.IDLE


func _on_pattern_active(pattern: AttackPattern) -> void:
	if pattern.display_name != LEAP_NAME:
		return
	_leap_active = true
	if is_on_floor():
		velocity.y = -leap_hop_velocity


func _on_pattern_recovery(_pattern_done: AttackPattern) -> void:
	_leap_active = false


## 그랩이 붙었다. 던지기로 잇고 실패 후딜은 건너뛴다
func _on_attack_landed(target: Hurtbox, _amount: int) -> void:
	var pattern: AttackPattern = current_pattern()
	if pattern == null or pattern.display_name == LEAP_NAME or _grab_hit:
		return
	_grab_hit = true
	_throw(target)
	finish_pattern_early()


## 배지기 던지기. GRAB_HOLD 구속과 연타 탈출은 M2라, 지금은 강한 넉백으로 대신한다
func _throw(target: Hurtbox) -> void:
	var body: CharacterBody2D = target.get_parent() as CharacterBody2D
	if body == null:
		return
	var away: float = 1.0 if body.global_position.x >= global_position.x else -1.0
	body.velocity = Vector2(throw_velocity.x * away, throw_velocity.y)


# --- 유도 충돌 경직 ---


func _enter_stun() -> void:
	end_pattern()
	_leap_active = false
	_mode = Mode.STUN
	_stun_left = miss_stun_time
	velocity.x = 0.0
	set_anim(&"hurt")
	body_visual.self_modulate = Color(0.7, 0.7, 1.0)


func _tick_stun(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	pose_slump(1.0)
	_stun_left = maxf(0.0, _stun_left - delta)
	if _stun_left > 0.0:
		return
	_mode = Mode.IDLE
	body_visual.self_modulate = Color.WHITE


## 유도 충돌 STUN 중에는 슈퍼아머가 없다. 이 구간이 반격 창이다
func can_be_staggered() -> bool:
	if _mode == Mode.STUN:
		return true
	return super()


func _cancel_action() -> void:
	_leap_active = false
	if _mode == Mode.STANCE:
		_stance_left = 0.0
		_mode = Mode.IDLE
		body_visual.self_modulate = Color.WHITE
		return
	if _mode == Mode.PATTERN:
		_mode = Mode.IDLE
		super()
