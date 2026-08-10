extends EnemyBase

## 잡도깨비 (docs/act1/ENEMIES.md 5.1).
##
## 순찰 -> 인지 -> 접근 -> (거리에 따라) 근접 패턴 또는 예고형 돌진.
## 근접 패턴 2종(휘두르기, 할퀴기)은 stats.attack_patterns의 AttackPattern이 수치를 갖고
## AttackHitbox로 판정한다. 예고형 돌진은 이동 기반 특수행동이라 이 스크립트의 export가
## 수치를 갖고 ContactHitbox로 판정한다 (2026-08-06 D11).
##
## 웅크림 예비 클립은 아직 없다(018 잡도깨비 charge 클립 미생성). 정지 + 밝기 펄스 +
## 예고음 훅으로 자리만 잡아두고, 실제 클립과 부위 분리 하이라이트는 A8 아트 세션에서 교체한다.

## 근접 패턴의 진행 단계. 프레임 규격은 AttackPattern이 갖는다
enum Phase { NONE, WINDUP, ACTIVE, GAP, RECOVERY }

@export_group("예고형 돌진")
@export var charge_speed_multiplier: float = 2.9
@export var charge_duration: float = 0.70
## 돌진 전 웅크림 예비 시간. 반응 임계(0.23s/14f, docs/DECISIONS.md 2026-08-04) 이상을 지킨다
## (2026-08-06 D11 수치 확정: 20f/0.33s, 임계 대비 1.43배 여유)
@export var charge_windup_time: float = 0.33
## 돌진을 시작하는 최대 거리 (px). 돌진 도달 거리(약 122px)보다 조금 넓게 둔다.
## 이 밖에서는 걸어서 접근한다. 감지 범위(300px) 전체에서 돌진하면 대부분 헛돌진이 된다
@export var charge_trigger_range: float = 132.0

@export_group("접근")
## 접근 중 속도가 흔들리는 폭 (0이면 등속). 어수룩한 이동을 만든다 (ENEMIES.md 5.1 지그재그)
@export var approach_wobble: float = 0.35
## 속도 흔들림 주기 (초)
@export var approach_wobble_period: float = 0.9

@export_group("이동")
@export var patrol_turn_margin: float = 6.0

@export_group("돌진 충돌")
## 못 넘는 벽에 돌진으로 부딪혔을 때의 경직 (초).
## 반격 창이자 무한 재시도 방지 장치다. 이것이 없으면 벽에 머리를 박는 0px 돌진을
## 쿨다운마다 반복해 개체가 고장난 것처럼 보인다 (2026-08-09 헤드리스 실측)
@export var bonk_stun_time: float = 0.55

@export_group("연출")
## 웅크림 예비 텔레그래프 사운드. 클립 미제작으로 비워둘 수 있다(자리만 예약, A8에서 배정)
@export var telegraph_sound: AudioStream = null

var _charging: bool = false
var _charge_left: float = 0.0
var _charge_windup_left: float = -1.0
var _wobble_time: float = 0.0
## 벽에 박은 뒤 남은 경직 시간
var _bonk_left: float = 0.0
## 다음 잔상까지 남은 시간 (초)
var _afterimage_left: float = 0.0

## 진행 중인 근접 패턴
var _phase: int = Phase.NONE
var _phase_left: float = 0.0
var _pattern: AttackPattern = null
var _hits_left: int = 0
## 근접 패턴 순번. 같은 패턴만 반복하지 않게 번갈아 고른다
var _pattern_turn: int = 0

@onready var _sprite: AnimatedSprite2D = $BodyVisual as AnimatedSprite2D
@onready var _attack_hitbox: Hitbox = get_node_or_null(^"AttackHitbox") as Hitbox
@onready var _telegraph_player: AudioStreamPlayer2D = (
	get_node_or_null(^"TelegraphSound") as AudioStreamPlayer2D
)


func _ready() -> void:
	super()
	if _attack_hitbox != null:
		_attack_hitbox.deactivate()


## 현재와 다른 클립일 때만 재생한다 (순환 클립이 매 프레임 재시작되지 않게).
func _set_anim(clip: StringName) -> void:
	if _sprite != null and _sprite.animation != clip:
		_sprite.play(clip)


## 근접 패턴 예비 구간의 슈퍼아머를 반영한다. 기본 패턴은 전부 꺼져 있다
func can_be_staggered() -> bool:
	if _phase == Phase.NONE or _pattern == null:
		return true
	return not _pattern.super_armor


func _tick_ai(delta: float) -> void:
	if _bonk_left > 0.0:
		_tick_bonk(delta)
		return
	if _phase != Phase.NONE:
		_pose_for_melee()
		_tick_pattern(delta)
		return
	if _charging:
		_tick_charge(delta)
		return
	if _charge_windup_left > 0.0:
		_tick_charge_windup(delta)
		return

	var distance: float = distance_to_player()
	if distance > stats.detect_range:
		_wobble_time = 0.0
		_patrol()
		return

	if attack_ready():
		# 근접 사거리 안이면 패턴을, 그 밖이면 예고형 돌진을 쓴다.
		# stats.attack_range가 근접 진입 게이트이고 패턴별 range_px가 그 안에서 다시 갈린다
		var pattern: AttackPattern = null
		if distance <= stats.attack_range:
			pattern = _pick_melee_pattern(distance)
		if pattern != null:
			_start_pattern(pattern)
			return
		if distance <= charge_trigger_range:
			_start_charge_windup()
			return

	_approach(delta)


## 사거리에 드는 근접 패턴 중 하나를 고른다. 없으면 null.
## 같은 패턴만 반복하지 않게 후보가 둘 이상이면 순번으로 번갈아 쓴다.
## 무작위가 아니라 순번인 것은 의도다. 이지선다 심리전보다 반응 가능성을 우선한다
## (docs/act1/ENEMIES.md 1장 원칙)
func _pick_melee_pattern(distance: float) -> AttackPattern:
	if stats == null:
		return null
	var candidates: Array[AttackPattern] = []
	for pattern: AttackPattern in stats.patterns_by_range():
		if distance <= pattern.range_px:
			candidates.append(pattern)
	if candidates.is_empty():
		return null
	var index: int = _pattern_turn % candidates.size()
	_pattern_turn += 1
	return candidates[index]


func _patrol() -> void:
	_set_anim(&"hop")
	if not walk_toward(facing, stats.move_speed, get_physics_process_delta_time()):
		set_facing(-facing)


## 플레이어를 향해 걸어간다. 속도를 흔들어 어수룩한 접근을 만든다.
## 낭떠러지나 못 넘는 벽에서는 멈춘다 (낙사 방지)
func _approach(delta: float) -> void:
	_set_anim(&"hop")
	_wobble_time += delta
	var wobble: float = 1.0
	if approach_wobble > 0.0 and approach_wobble_period > 0.0:
		var phase: float = TAU * _wobble_time / approach_wobble_period
		wobble = 1.0 - approach_wobble * 0.5 * (1.0 - cos(phase))
	walk_toward(direction_to_player(), stats.move_speed * wobble, delta)


## 돌진 경로가 트였는지. 못 넘는 지형이 앞을 막고 있으면 돌진하지 않는다.
## 부술 수 있는 좌판은 뚫고 가므로 막힌 것으로 보지 않는다
func _charge_path_clear() -> bool:
	set_facing(direction_to_player())
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var reach: float = stats.move_speed * charge_speed_multiplier * charge_duration
	# 발 높이와 몸 높이 둘 다 본다. 한쪽만 보면 낮은 턱을 놓쳐 돌진하자마자 박는다
	for offset: float in [-6.0, -20.0]:
		var from: Vector2 = global_position + Vector2(0.0, offset)
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			from, from + Vector2(reach * float(facing), 0.0), 1
		)
		query.exclude = [get_rid()]
		var hit: Dictionary = space.intersect_ray(query)
		if hit.is_empty():
			continue
		var node: Node = hit.get("collider", null) as Node
		if node == null or not node.is_in_group(&"breakable"):
			return false
	return true


## 근접 패턴 진행 단계에 맞는 자세. EnemyPatternActor의 같은 로직을 잡도깨비가
## 자체 상태 머신을 갖고 있어 여기에 한 벌 더 둔다 (통합은 후속 과제)
func _pose_for_melee() -> void:
	if _pattern == null:
		return
	match _phase:
		Phase.WINDUP:
			pose_crouch(1.0 - _phase_left / maxf(0.01, _pattern.windup()))
		Phase.ACTIVE:
			pose_lunge(1.0)
		Phase.GAP:
			pose_lunge(0.5)
		Phase.RECOVERY:
			pose_lunge(_phase_left / maxf(0.01, _pattern.recovery()) * 0.6)


# --- 근접 패턴 (AttackPattern 기반) ---


func _start_pattern(pattern: AttackPattern) -> void:
	_pattern = pattern
	_phase = Phase.WINDUP
	_phase_left = pattern.windup()
	_hits_left = maxi(1, pattern.hit_count)
	velocity.x = 0.0
	set_facing(direction_to_player())
	_apply_hitbox_shape(pattern)
	# 예비 신호: 클립이 지정되지 않았으면 정지 + 밝기 점멸로 대체한다 (A8에서 교체)
	if pattern.windup_clip != &"":
		_set_anim(pattern.windup_clip)
	else:
		_set_anim(&"idle")
	body_visual.self_modulate = Color(1.6, 1.6, 0.9)
	_play_telegraph()


func _tick_pattern(delta: float) -> void:
	# 근접 패턴 중에는 제자리에 선다. 예비를 보고 옆으로 빠지면 헛치게 된다
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_phase_left = maxf(0.0, _phase_left - delta)
	if _phase == Phase.WINDUP:
		_pulse_windup(_phase_left)
	if _phase_left > 0.0:
		return
	_advance_phase()


func _advance_phase() -> void:
	if _pattern == null:
		_end_pattern()
		return
	match _phase:
		Phase.WINDUP:
			_enter_active()
		Phase.ACTIVE:
			_hits_left -= 1
			if _hits_left > 0 and _pattern.hit_interval_frames > 0:
				_phase = Phase.GAP
				_phase_left = _pattern.hit_interval()
				if _attack_hitbox != null:
					_attack_hitbox.deactivate()
			elif _hits_left > 0:
				_enter_active()
			else:
				_enter_recovery()
		Phase.GAP:
			_enter_active()
		Phase.RECOVERY:
			_end_pattern()


func _enter_active() -> void:
	_phase = Phase.ACTIVE
	_phase_left = _pattern.active()
	body_visual.self_modulate = Color.WHITE
	if _pattern.active_clip != &"":
		_set_anim(_pattern.active_clip)
	elif _sprite != null:
		_sprite.play(&"attack")
	if _attack_hitbox == null:
		return
	_attack_hitbox.damage = _pattern.damage
	_attack_hitbox.active_duration = _pattern.active()
	_attack_hitbox.damage_multiplier = damage_multiplier
	_attack_hitbox.activate()


func _enter_recovery() -> void:
	_phase = Phase.RECOVERY
	_phase_left = _pattern.recovery()
	if _attack_hitbox != null:
		_attack_hitbox.deactivate()


func _end_pattern() -> void:
	var cooldown_frames: int = 0 if _pattern == null else _pattern.cooldown_frames
	_phase = Phase.NONE
	_phase_left = 0.0
	_pattern = null
	_hits_left = 0
	body_visual.self_modulate = Color.WHITE
	if _attack_hitbox != null:
		_attack_hitbox.deactivate()
	# 패턴 쿨다운이 지정돼 있으면 그것을, 없으면 개체 공통 쿨다운을 쓴다
	if cooldown_frames > 0:
		set_attack_cooldown(float(cooldown_frames) / AttackPattern.FPS)
	else:
		start_attack_cooldown()


## 판정 영역 크기와 위치를 패턴에 맞춘다. x는 바라보는 방향으로 뒤집는다
func _apply_hitbox_shape(pattern: AttackPattern) -> void:
	if _attack_hitbox == null:
		return
	_attack_hitbox.position = Vector2(
		absf(pattern.hitbox_offset.x) * float(facing), pattern.hitbox_offset.y
	)
	var shape: CollisionShape2D = _attack_hitbox.get_node_or_null(^"Shape") as CollisionShape2D
	if shape == null:
		return
	var rect: RectangleShape2D = shape.shape as RectangleShape2D
	if rect != null:
		rect.size = pattern.hitbox_size


# --- 예고형 돌진 (이동 기반 특수행동) ---


## 웅크림 예비를 시작한다. 이 구간에는 아직 돌진 판정이 없다(예고 전용).
## 제자리에 멈추고 임시 밝기 펄스와 예고음으로 신호를 준다.
func _start_charge_windup() -> void:
	_charge_windup_left = charge_windup_time
	velocity.x = 0.0
	_set_anim(&"idle")
	body_visual.self_modulate = Color(1.6, 1.6, 0.9)
	_play_telegraph()


## 웅크림 예비의 펄스와 카운트다운. 끝나면 실제 돌진으로 넘어간다.
func _tick_charge_windup(delta: float) -> void:
	_charge_windup_left = maxf(0.0, _charge_windup_left - delta)
	velocity.x = 0.0
	pose_crouch(1.0 - _charge_windup_left / maxf(0.01, charge_windup_time))
	_pulse_windup(_charge_windup_left)
	if _charge_windup_left <= 0.0:
		_start_charge()


func _start_charge() -> void:
	body_visual.self_modulate = Color.WHITE
	if contact_hitbox == null:
		return
	set_facing(direction_to_player())
	_charging = true
	_charge_left = charge_duration
	contact_hitbox.active_duration = charge_duration
	contact_hitbox.activate()
	body_visual.modulate = Color(1.0, 0.85, 0.5)
	# 돌진(근접 공격)에 진입하며 휘두르기 클립을 원샷 재생한다
	if _sprite != null:
		_sprite.play(&"attack")


func _tick_charge(delta: float) -> void:
	velocity.x = float(facing) * stats.move_speed * charge_speed_multiplier
	pose_dash(1.0)
	_afterimage_left -= delta
	if _afterimage_left <= 0.0:
		_afterimage_left = 0.05
		spawn_afterimage()
	_charge_left -= delta
	if is_on_wall() and not try_clear_obstacle():
		# 못 넘는 벽에 머리를 박았다. 짧은 경직이 반격 창이 되고, 곧바로 다시
		# 돌진하는 것을 막는다 (2026-08-09 무한 0px 돌진 수정)
		_bonk()
		return
	if _charge_left > 0.0:
		return
	_end_charge()


func _end_charge() -> void:
	_charging = false
	_charge_left = 0.0
	if contact_hitbox != null:
		contact_hitbox.deactivate()
	body_visual.modulate = Color.WHITE
	start_attack_cooldown()


## 벽에 박은 직후. 뒤로 살짝 튕기고 경직에 들어간다
func _bonk() -> void:
	_end_charge()
	_bonk_left = bonk_stun_time
	velocity.x = float(-facing) * 70.0
	if _sprite != null:
		_sprite.play(&"hurt")
	body_visual.self_modulate = Color(0.72, 0.72, 1.0)
	set_attack_cooldown(bonk_stun_time + 0.35)


func _tick_bonk(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	pose_slump(1.0)
	_bonk_left = maxf(0.0, _bonk_left - delta)
	if _bonk_left <= 0.0:
		body_visual.self_modulate = Color.WHITE


# --- 공통 연출과 취소 ---


## 예비 구간의 밝기 점멸. 부위 분리 스프라이트가 없어 전신에 임시 적용한다
func _pulse_windup(time_left: float) -> void:
	var phase: int = int(time_left * 15.0) % 2
	body_visual.self_modulate = Color(1.6, 1.6, 0.9) if phase == 0 else Color(1.1, 1.1, 1.0)


func _play_telegraph() -> void:
	if _telegraph_player != null and telegraph_sound != null:
		_telegraph_player.stream = telegraph_sound
		_telegraph_player.play()


## 피격 경직 중에는 _tick_ai가 돌지 않아 타이머가 멈춘다.
## 판정만 먼저 꺼지고 이동은 남는 어긋남을 막기 위해 경직 진입 시 진행 중인 행동을 취소한다.
func _cancel_action() -> void:
	if _charging:
		_end_charge()
		return
	if _charge_windup_left > 0.0:
		_charge_windup_left = -1.0
		body_visual.self_modulate = Color.WHITE
		return
	if _phase != Phase.NONE:
		_end_pattern()
