class_name Player
extends CharacterBody2D

## 플레이어 컨트롤러 (M1 검증 대상).
##
## 스펙은 docs/PROTOTYPE.md 2장. 튜닝 파라미터는 전부 @export로 노출한다.
## 점프 높이는 타일 수로 정의하고 물리 값은 JumpMath로 파생시킨다.
## 상태는 배타적 4종(이동, 구르기, 대시, 근접)이며 재장전만 병행 가능하다.

signal state_changed(state: int)

enum State { MOVE, DASH, MELEE }

## 활성 무기 종류. 시작은 환도(MELEE)이며 총(RANGED)은 대장장이 해금 뒤에만 들 수 있다
## (docs/systems/WEAPONS.md 11.2절). NONE은 차사에게 환도를 받기 전의 허브 상태다.
## 활성 종류가 입력과 애니메이션, HUD 표시를 모두 가른다 (WEAPONS 8.2절 총검 겸용 폐지)
enum WeaponKind { NONE, MELEE, RANGED }

## 타일 크기 (px). 점프 높이 환산 기준
@export var tile_size: int = 16
@export_group("이동")
@export var max_speed: float = 170.0
@export var ground_accel: float = 1500.0
@export var ground_decel: float = 2200.0
@export var air_accel: float = 520.0
@export var air_decel: float = 320.0
## 2026-08-06 완만화: 520 -> 420. 종단 속도가 낮아야 완만해진 하강이 유지된다
@export var max_fall_speed: float = 420.0
## 재장전 중 이동 속도 배율 (M1 판정 반영: 자동 재장전의 대가로 감속)
@export var reload_move_multiplier: float = 0.7
@export_group("점프")
@export var jump_height_tiles: float = 3.5
## 2026-08-06 완만화: 0.36 -> 0.46. 높이는 3.5타일 그대로 두고 체공만 늘린다
@export var time_to_peak: float = 0.46
## 2026-08-06 완만화: 0.28 -> 0.38
@export var time_to_descent: float = 0.38
## 점프 키를 떼면 상승 속도에 곱하는 값 (가변 점프 높이)
@export var jump_cut: float = 0.45
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.12
## 원웨이 발판 낙하 통과 시 oneway 레이어를 무시하는 시간 (초)
@export var drop_through_time: float = 0.18
@export_group("벽")
@export var wall_jump_push: float = 210.0
## 벽 점프 후 좌우 입력을 무시하는 시간 (초). 2026-08-06 0.12 -> 0.08
@export var wall_jump_lock: float = 0.08
## 2026-08-06 110 -> 84. 벽에 붙은 채 판단할 시간을 준다
@export var wall_slide_speed: float = 84.0
## 벽에서 떨어진 직후에도 벽 점프를 허용하는 시간 (초). 지상 코요테의 벽 판
@export var wall_coyote_time: float = 0.12
@export_group("대시 (완전 회피)")
## 대시 거리 = dash_speed * dash_duration. 속도를 낮추고 지속을 늘려 거리 약 88px(1.5배)는 유지, 무적창은 지속에 맞춤
@export var dash_speed: float = 490.0
@export var dash_duration: float = 0.18
## 대시 후 재사용까지의 후딜레이 (초). 남용 제한
@export var dash_recovery: float = 0.22
## 완전 회피: 대시 지속 동안 무적 창 (구르기에서 이관)
@export var dash_invuln_start: float = 0.0
@export var dash_invuln_end: float = 0.18
## 완전 회피의 대가로 소모하는 스태미나 (구르기에서 이관)
@export var dash_stamina_cost: float = 30.0

var facing: int = 1

## 외부 바람 밀림 속도 (px/s, 부호 포함). 문얼굴 바람 패턴 등이 set_wind로 넣는다.
## 이동 목표 속도에 더해지는 방식이라 최대속도와 같은 바람이면 걸어서 전진이 0이 되고,
## 대시(속도 직접 지정)는 바람을 뚫는다 (2026-08-07 G3)
var _wind_x: float = 0.0

var _state: int = State.MOVE
## 지금 들고 있는 무기 종류. 무기를 붙이기 전에는 NONE이다
var _weapon_kind: int = WeaponKind.NONE
var _rise_gravity: float = 0.0
var _fall_gravity: float = 0.0
var _jump_velocity: float = 0.0
var _coyote_left: float = 0.0
## 벽 코요테 잔여 시간과 그때의 벽 법선 방향
var _wall_coyote_left: float = 0.0
var _wall_coyote_dir: float = 0.0
var _buffer_left: float = 0.0
var _lock_left: float = 0.0
var _state_time: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_used_in_air: bool = false
var _dead: bool = false
## 피격 후 무적 잔여 시간 (초). 깜빡임 연출과 연동
var _hurt_invuln_left: float = 0.0
var _shake_left: float = 0.0
var _shake_strength: float = 0.0
var _recoil_left: float = 0.0
var _hitstop_active: bool = false
## 원샷 애니메이션(사격, 피격) 재생 중이면 이동 클립으로 덮어쓰지 않는다
var _anim_lock_left: float = 0.0
## 공중 스트레치와 착지 스쿼시 상태
var _was_airborne: bool = false
var _land_squash_left: float = 0.0
## 벽 매달림(슬라이드) 표시 상태. 애니메이션 클립 선택에 쓴다
var _wall_sliding: bool = false
## 대시 잔상 스폰 간격 타이머
var _dash_ghost_timer: float = 0.0
## 원웨이 낙하 통과 잔여 시간. 0이 되면 oneway 레이어 충돌을 되돌린다
var _drop_left: float = 0.0

## 액티브 권능이 건 행동 잠금 (산의 뼈). 남아 있는 동안 조작을 받지 않는다
var _boon_channel_left: float = 0.0

## 보너스를 빼고 남는 기준 최대 체력. 권능 재적용의 기준점이다
var _base_max_health: int = 0

@onready var health: Health = $Health as Health
@onready var stamina: Stamina = $Stamina as Stamina
@onready var hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var rifle: WeaponRifle = $Rifle as WeaponRifle
## 근접 무기 슬롯 (환도). 허브에서 차사가 지급하면 장착된다 (docs/DESIGN_HUB.md 5.4절)
@onready var hwando: WeaponMelee = get_node_or_null(^"Hwando") as WeaponMelee
@onready var _body_visual: AnimatedSprite2D = $BodyVisual as AnimatedSprite2D
## 몸 클립 위에 얹는 무기 오버레이. 몸에 무기를 굽지 않는다는 규칙의 구현부다
## (docs/ART_WEAPON_SPLIT.md 3.3)
@onready var _weapon_sprite: WeaponSprite = (
	get_node_or_null(^"BodyVisual/WeaponSprite") as WeaponSprite
)
@onready var _camera: Camera2D = $Camera2D as Camera2D


func _ready() -> void:
	_recalculate_motion()
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	stamina.stamina_changed.connect(_on_stamina_changed)
	hurtbox.hit_received.connect(_on_player_hit)
	rifle.fired.connect(_on_rifle_fired_feel)
	if hwando != null:
		hwando.swung.connect(_on_hwando_swung)
	rifle.reload_started.connect(_on_reload_started)
	rifle.reload_finished.connect(_on_reload_finished)
	_connect_boon_hit_hooks()
	GameEvents.enemy_defeated.connect(_on_enemy_defeated)
	GameEvents.screen_shake.connect(_start_camera_shake)
	RunState.boons_changed.connect(_on_run_bonuses_changed)
	RunState.relics_changed.connect(_on_run_bonuses_changed)
	RunState.run_bonuses_changed.connect(_on_run_bonuses_changed)
	# 무기는 붙이기 전까지 없다. 총이 시작 무기에서 빠졌으므로 기본이 빈손이며
	# 허브의 차사 지급이나 런 시작이 무기를 붙인다 (WEAPONS 2.1절, 11.1절)
	_set_weapon_kind(WeaponKind.NONE)
	_apply_run_bonuses()


## 적 처치 시 짧은 카메라 흔들림으로 타격감을 준다.
func _on_enemy_defeated(_position: Vector2) -> void:
	_start_camera_shake(2.0, 0.12)


## 런 상태의 유물과 권능 보너스를 반영한다. 런이 아니면(허브, M1) 보너스가 0이라 변화가 없다.
## 런 상태의 유물과 권능 보너스를 반영한다. 신당에서 권능을 얻으면 다시 불린다.
## 기준값(_base_max_health)에서 매번 다시 계산한다. += 로 누적하면 재적용마다 늘어난다.
func _apply_run_bonuses() -> void:
	if _base_max_health <= 0:
		_base_max_health = health.maximum
	var bonus_hp: int = int(round(RunState.total_stat_flat(&"max_health")))
	var next_max: int = maxi(1, _base_max_health + bonus_hp)
	if next_max != health.maximum:
		var missing: int = health.maximum - health.current()
		health.maximum = next_max
		# 잃은 만큼을 다시 비운다. apply_damage 로 깎으면 안 된다. 그 경로는
		# damage_filter(받는 피해 감소)를 타므로 피해감소 권능을 든 상태에서는
		# 덜 깎여 최대 체력이 오를 때마다 공짜 회복이 붙는다
		health.set_current(maxi(1, next_max - maxi(0, missing)))
	health.lethal_guard = _guard_lethal
	health.damage_filter = _filter_damage_taken


## 권능과 유물의 받는 피해 감소를 반영한다 (damage_taken은 음수 배율이 정상).
func _filter_damage_taken(amount: int) -> int:
	var scale: float = RunState.total_stat_mult(&"damage_taken")
	return maxi(1, int(round(float(amount) * clampf(scale, 0.05, 4.0))))


## 신당에서 권능이 바뀌면 최대 체력 같은 상시 보너스를 다시 계산한다.
func _on_run_bonuses_changed() -> void:
	_apply_run_bonuses()


## 치명 피해 시 유물(군번줄)로 생존을 시도한다. Health.lethal_guard가 호출한다.
func _guard_lethal() -> bool:
	return RunState.try_absorb_lethal()


## 시각 피드백 전용 프레임 처리 (물리와 분리).
func _process(delta: float) -> void:
	_tick_camera_shake(delta)
	_tick_recoil(delta)
	_tick_hurt_blink()
	_update_animation(delta)
	_tick_body_stretch(delta)


## 상태와 이동 여부로 재생 클립을 고른다. 사격/피격 원샷은 잠금 시간 동안 유지한다.
func _update_animation(delta: float) -> void:
	if _dead:
		return
	# 대시/근접은 각자의 클립을 유지한다 (이동 클립으로 덮지 않는다)
	if _state == State.DASH or _state == State.MELEE:
		return
	# 사격/피격 원샷 잠금을 먼저 처리해 피격 반응이 재장전보다 우선 보이게 한다
	if _anim_lock_left > 0.0:
		_anim_lock_left = maxf(0.0, _anim_lock_left - delta)
		return
	# 재장전 중에는 이동 여부로 상/하체 대체 클립을 매 프레임 고른다 (2클립 절충).
	# 총 자세 클립은 총이 활성일 때만 쓴다. 환도를 들고 총 모션이 나오면 안 된다
	if _weapon_kind == WeaponKind.RANGED and rifle.is_reloading():
		var moving_reload: bool = is_on_floor() and absf(velocity.x) > 12.0
		var reload_clip: StringName = &"reload_run" if moving_reload else &"reload"
		if _body_visual.animation != reload_clip:
			_body_visual.play(reload_clip)
		return
	var clip: StringName = &"idle"
	if _wall_sliding:
		clip = &"wall"
	elif not is_on_floor():
		clip = &"jump" if velocity.y < 0.0 else &"fall"
	elif absf(velocity.x) > 12.0:
		clip = &"run"
	# jump는 비순환이라 끝 프레임에서 정지 유지한다. 순환 클립은 loop 플래그로 이어진다
	if _body_visual.animation != clip:
		_body_visual.play(clip)


## 원샷 애니메이션을 재생하고 그 길이만큼 이동 클립을 막는다.
func _play_oneshot(clip: StringName, lock: float) -> void:
	if _dead:
		return
	_body_visual.play(clip)
	_anim_lock_left = lock


## 점프/낙하 스트레치와 착지 스쿼시. 전용 프레임 없는 동작에 무게감을 준다.
## 구르기(회전)와 대시(늘림)는 각자 처리하므로 여기서 건너뛴다.
func _tick_body_stretch(delta: float) -> void:
	if _dead or _state == State.DASH:
		return
	if not is_on_floor():
		_was_airborne = true
		# 전용 점프/낙하/벽 포즈가 있으므로 공중 왜곡은 최소화하고 포즈에 맡긴다
		_body_visual.scale = _body_visual.scale.lerp(Vector2.ONE, 0.3)
		return
	if _was_airborne:
		_was_airborne = false
		_land_squash_left = 0.11
		# 공중 1회 제한 해제와 점프 공격 착지 후딜 (WEAPONS 6장)
		if hwando != null:
			hwando.notify_landed()
	if _land_squash_left > 0.0:
		_land_squash_left = maxf(0.0, _land_squash_left - delta)
		_body_visual.scale = Vector2(1.22, 0.78)
	else:
		_body_visual.scale = _body_visual.scale.lerp(Vector2.ONE, 0.4)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_tick_timers(delta)
	# 산의 뼈처럼 제자리에 묶는 액티브. 이동도 공격도 받지 않고 중력만 받는다 (BOONS 8.2)
	if _boon_channel_left > 0.0:
		_boon_channel_left = maxf(0.0, _boon_channel_left - delta)
		_apply_horizontal(0.0, delta)
		_apply_gravity(delta)
		move_and_slide()
		_after_move()
		return
	_read_jump_input()

	match _state:
		State.DASH:
			_process_dash(delta)
		State.MELEE:
			_process_melee(delta)
		_:
			_process_move(delta)

	move_and_slide()
	_after_move()


## 튜닝 값을 바꾼 뒤 물리 파생값을 다시 계산한다 (에디터 튜닝용).
func _recalculate_motion() -> void:
	var height: float = JumpMath.tiles_to_pixels(jump_height_tiles, tile_size)
	_rise_gravity = JumpMath.rise_gravity(height, time_to_peak)
	_fall_gravity = JumpMath.fall_gravity(height, time_to_descent)
	_jump_velocity = JumpMath.jump_velocity(height, time_to_peak)


## 방 리셋 시 호출한다.
## refill_health가 거짓이면 체력을 그대로 둔다. 방 사이 이동이 이 경우다.
## 방마다 만피로 되돌리면 전투 손실이 의미를 잃는다 (2026-08-10 결정).
func respawn(spawn_position: Vector2, refill_health: bool = true) -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	_wind_x = 0.0
	_dead = false
	_state = State.MOVE
	_state_time = 0.0
	_dash_cooldown = 0.0
	_dash_used_in_air = false
	_coyote_left = 0.0
	_buffer_left = 0.0
	_lock_left = 0.0
	_drop_left = 0.0
	set_collision_mask_value(9, true)
	if refill_health:
		health.refill()
	# 사망 처리에서 켠 무적을 반드시 되돌린다. 남으면 복귀 후 피해를 받지 않는다
	health.set_invulnerable(false)
	stamina.refill()
	hurtbox.set_deferred("monitorable", true)
	_body_visual.modulate = Color.WHITE
	_body_visual.self_modulate = Color.WHITE
	_body_visual.position.x = 0.0
	_hurt_invuln_left = 0.0
	_anim_lock_left = 0.0
	_was_airborne = false
	_land_squash_left = 0.0
	_wall_sliding = false
	_body_visual.scale = Vector2.ONE
	_apply_state_squash(State.MOVE)
	_body_visual.play(&"idle")
	if _camera != null:
		_camera.offset = Vector2.ZERO


func is_dead() -> bool:
	return _dead


func state() -> int:
	return _state


func _tick_timers(delta: float) -> void:
	_state_time += delta
	_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	_lock_left = maxf(0.0, _lock_left - delta)
	_buffer_left = maxf(0.0, _buffer_left - delta)
	if _drop_left > 0.0:
		_drop_left = maxf(0.0, _drop_left - delta)
		if _drop_left <= 0.0:
			set_collision_mask_value(9, true)
	if _hurt_invuln_left > 0.0:
		_hurt_invuln_left = maxf(0.0, _hurt_invuln_left - delta)
		if _hurt_invuln_left > 0.0:
			health.set_invulnerable(true)
		else:
			health.set_invulnerable(false)
	if is_on_floor():
		_coyote_left = coyote_time
		_dash_used_in_air = false
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
	# 벽 코요테: 벽에서 미끄러져 떨어진 직후의 입력도 벽 점프로 받아 준다.
	# 이 여유가 없으면 벽 점프가 프레임 단위 정확도를 요구해 불쾌해진다
	if is_on_wall_only() and not is_on_floor():
		_wall_coyote_left = wall_coyote_time
		_wall_coyote_dir = get_wall_normal().x
	else:
		_wall_coyote_left = maxf(0.0, _wall_coyote_left - delta)


func _read_jump_input() -> void:
	if Input.is_action_just_pressed(&"jump"):
		_buffer_left = jump_buffer
	if Input.is_action_just_released(&"jump") and velocity.y < 0.0:
		velocity.y *= jump_cut


func _process_move(delta: float) -> void:
	var input_x: float = _input_axis()
	_apply_horizontal(input_x, delta)
	_apply_gravity(delta)
	_try_jump()
	_try_wall_slide()
	if _try_start_dash(input_x):
		return
	_try_weapon_input()


func _process_dash(delta: float) -> void:
	velocity.x = float(facing) * dash_speed
	velocity.y = 0.0
	# 대시 중 진행 방향으로 길게 늘려 속도감을 준다
	_body_visual.scale = Vector2(1.32, 0.82)
	# 속도감 강화: 대시 동안 캐릭터를 반투명 냉색으로 흐리게 (잔상과 함께 모션 블러 느낌)
	_body_visual.modulate = Color(0.85, 0.92, 1.0, 0.5)
	# 완전 회피: 대시 지속 동안 무적 (구르기에서 이관)
	var invulnerable: bool = _state_time >= dash_invuln_start and _state_time <= dash_invuln_end
	health.set_invulnerable(invulnerable)
	_dash_ghost_timer -= delta
	if _dash_ghost_timer <= 0.0:
		_dash_ghost_timer = 0.03
		_spawn_dash_ghost()
	if _state_time >= dash_duration:
		health.set_invulnerable(false)
		_dash_cooldown = dash_recovery
		velocity.x *= 0.4
		_body_visual.scale = Vector2.ONE
		_change_state(State.MOVE)


## 대시 잔상: 현재 프레임 텍스처를 반투명 복제로 남기고 사라지게 한다.
func _spawn_dash_ghost() -> void:
	var tex: Texture2D = _body_visual.sprite_frames.get_frame_texture(
		_body_visual.animation, _body_visual.frame
	)
	if tex == null:
		return
	var ghost: Sprite2D = Sprite2D.new()
	ghost.texture = tex
	ghost.global_position = _body_visual.global_position
	ghost.flip_h = _body_visual.flip_h
	ghost.scale = _body_visual.scale
	ghost.modulate = Color(0.6, 0.75, 1.0, 0.45)
	ghost.z_index = -1
	get_parent().add_child(ghost)
	var tween: Tween = ghost.create_tween()
	tween.tween_property(ghost, ^"modulate:a", 0.0, 0.18)
	tween.tween_callback(ghost.queue_free)


func _process_melee(delta: float) -> void:
	# 좌우 이동 입력은 잠그고, 타격마다 짧은 자동 전진만 준다 (WEAPONS 5.2절)
	_apply_horizontal(0.0, delta)
	_apply_gravity(delta)
	# 근접 상태는 환도로만 들어온다 (총검 겸용 폐지, WEAPONS 8.2절).
	# 무기가 바뀌어 환도가 없어졌다면 즉시 이동으로 되돌린다
	if not _melee_weapon_equipped():
		_change_state(State.MOVE)
		return
	# 대시는 공격의 어느 구간에서든 들어간다. 대신 진행 중인 공격은 취소된다
	# (WEAPONS 5.5절, 2026-08-07 사용자 확정). 예비든 타격이든 후딜이든
	# 빠져나갈 길이 항상 열려 있어야 근접이 답답하지 않다. 남용은 스태미나 30과
	# 대시 후딜 0.22초가 막고, 캔슬하면 콤보 카운터가 0으로 돌아간다
	if _try_start_dash(_input_axis()):
		hwando.cancel_attack()
		return
	var advance: float = hwando.consume_advance()
	if not is_zero_approx(advance):
		position.x += advance
	# 콤보 재입력을 근접 상태 안에서 받는다. 창을 놓치면 무기가 알아서 리셋한다
	if Input.is_action_just_pressed(&"attack_melee"):
		hwando.try_primary_attack(is_on_floor())
	if not hwando.is_attacking():
		_change_state(State.MOVE)


## 환도가 장착돼 있으면 근접은 환도가 맡는다. 없으면 기존 총검 경로다.
func _melee_weapon_equipped() -> bool:
	return hwando != null and hwando.is_equipped()


## 환도를 장착한다. 허브의 차사 지급과 런 시작이 부른다 (WEAPONS 2.1절 슬롯 0).
func equip_melee_weapon() -> void:
	_set_weapon_kind(WeaponKind.MELEE)


## 총을 장착한다. 대장장이 해금 뒤 시작 무기를 총으로 고른 경우다 (WEAPONS 11.3절).
## 총이 활성인 동안 근접 입력은 무시된다 (8.2절 총검 겸용 폐지)
func equip_ranged_weapon() -> void:
	_set_weapon_kind(WeaponKind.RANGED)


## 무기를 내린다. 첫 대화 전 허브가 이 상태다 (WEAPONS 2.1절 예외).
func unequip_melee_weapon() -> void:
	_set_weapon_kind(WeaponKind.NONE)


## 저장된 시작 무기 선택을 그대로 붙인다. 허브 복귀와 런 시작이 부른다.
## 총 해금 전이거나 환도를 골랐으면 환도다
func apply_start_weapon() -> void:
	if GameState.starts_with_gun():
		equip_ranged_weapon()
	else:
		equip_melee_weapon()


## 활성 무기 종류를 바꾼다. 표시, 판정, 입력, HUD 표기가 여기서 한 번에 갈린다.
func _set_weapon_kind(kind: int) -> void:
	_weapon_kind = kind
	if hwando != null:
		hwando.set_equipped(kind == WeaponKind.MELEE)
		if kind == WeaponKind.MELEE:
			hwando.set_facing(facing)
	if _weapon_sprite != null:
		_weapon_sprite.set_active(kind == WeaponKind.MELEE)
	if rifle != null:
		rifle.set_active(kind == WeaponKind.RANGED)
		if kind == WeaponKind.RANGED:
			rifle.set_facing(facing)
	# 근접 동작 중에 무기가 바뀌면 남은 판정을 접고 이동 상태로 되돌린다
	if kind != WeaponKind.MELEE and _state == State.MELEE:
		_change_state(State.MOVE)
	GameEvents.player_weapon_changed.emit(_weapon_kind, _weapon_display_name())


## 활성 무기 종류. HUD와 테스트가 읽는다
func weapon_kind() -> int:
	return _weapon_kind


func _weapon_display_name() -> String:
	match _weapon_kind:
		WeaponKind.MELEE:
			var label: String = "" if hwando == null else hwando.display_name()
			return "환도" if label.is_empty() else label
		WeaponKind.RANGED:
			return "총"
		_:
			return ""


## 무기가 휘둘렸다. 어느 타인지 아는 것은 무기뿐이므로 몸 클립도 무기가 고른다.
## 3연타의 타마다 다른 클립을 재생해야 연타가 한 동작으로 뭉개지지 않는다
func _on_hwando_swung(_step: int) -> void:
	if _dead or _body_visual.sprite_frames == null:
		return
	var clip: StringName = hwando.body_clip()
	if clip == &"" or not _body_visual.sprite_frames.has_animation(clip):
		clip = &"melee"
	_anim_lock_left = 0.0
	_body_visual.play(clip)


func has_melee_weapon() -> bool:
	return _melee_weapon_equipped()


## 외부(보스 바람 패턴)가 수평 밀림을 건다. 0을 넣으면 해제된다.
func set_wind(force_x: float) -> void:
	_wind_x = force_x


func _apply_horizontal(input_x: float, delta: float) -> void:
	if _lock_left > 0.0:
		return
	var accel: float = ground_accel if is_on_floor() else air_accel
	var decel: float = ground_decel if is_on_floor() else air_decel
	if is_zero_approx(input_x):
		velocity.x = move_toward(velocity.x, _wind_x, decel * delta)
		return
	var speed: float = max_speed
	if rifle.is_reloading():
		speed *= reload_move_multiplier
	velocity.x = move_toward(velocity.x, input_x * speed + _wind_x, accel * delta)
	_set_facing(1 if input_x > 0.0 else -1)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var gravity: float = _rise_gravity if velocity.y < 0.0 else _fall_gravity
	velocity.y = minf(max_fall_speed, velocity.y + gravity * delta)


func _try_jump() -> void:
	if _buffer_left <= 0.0:
		return
	if _coyote_left > 0.0:
		# 아래 + 점프: 원웨이 발판 위라면 점프 대신 낙하 통과한다
		if Input.is_action_pressed(&"move_down") and is_on_floor() and not _has_solid_floor():
			_start_drop_through()
			return
		_jump(_jump_velocity, 0.0)
		return
	var wall_dir: float = 0.0
	if is_on_wall_only():
		wall_dir = get_wall_normal().x
	elif _wall_coyote_left > 0.0:
		wall_dir = _wall_coyote_dir
	if not is_zero_approx(wall_dir):
		_jump(_jump_velocity * 0.92, wall_dir * wall_jump_push)
		_lock_left = wall_jump_lock
		_wall_coyote_left = 0.0
		_set_facing(1 if wall_dir > 0.0 else -1)


func _jump(vertical: float, horizontal: float) -> void:
	velocity.y = vertical
	if not is_zero_approx(horizontal):
		velocity.x = horizontal
	_buffer_left = 0.0
	_coyote_left = 0.0


## 발밑에 솔리드 지형(world 레이어)이 있는지. 없고 바닥 위라면 원웨이 발판 위다.
func _has_solid_floor() -> bool:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	for offset_x: float in [-6.0, 6.0]:
		var params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			global_position + Vector2(offset_x, -2.0), global_position + Vector2(offset_x, 6.0), 1
		)
		if not space.intersect_ray(params).is_empty():
			return true
	return false


## 원웨이 낙하 통과 시작. oneway 레이어(9)를 잠깐 끄고 아래로 밀어낸다.
func _start_drop_through() -> void:
	set_collision_mask_value(9, false)
	_drop_left = drop_through_time
	velocity.y = maxf(velocity.y, 60.0)
	_buffer_left = 0.0
	_coyote_left = 0.0


func _try_wall_slide() -> void:
	_wall_sliding = false
	if is_on_floor() or not is_on_wall():
		return
	# 벽에 붙어 하강할 때만 매달림으로 본다. 낙하를 늦추고 벽 쪽을 바라본다
	if velocity.y > 0.0:
		velocity.y = minf(velocity.y, wall_slide_speed)
		_wall_sliding = true
		_set_facing(1 if get_wall_normal().x < 0.0 else -1)


func _try_start_dash(input_x: float) -> bool:
	if not Input.is_action_just_pressed(&"dash") or _dash_cooldown > 0.0:
		return false
	if not is_on_floor() and _dash_used_in_air:
		return false
	# 완전 회피의 대가로 스태미나 소모 (구르기에서 이관). 부족하면 발동하지 않는다
	if not stamina.spend(dash_stamina_cost):
		return false
	if not is_on_floor():
		_dash_used_in_air = true
	if not is_zero_approx(input_x):
		_set_facing(1 if input_x > 0.0 else -1)
	_change_state(State.DASH)
	return true


## 무기 입력은 활성 무기 종류가 가른다 (WEAPONS 8.2절).
## 환도가 활성이면 사격과 재장전 입력이 무시되고, 총이 활성이면 근접 입력이 무시된다.
## 무기가 없으면(차사 지급 전) 셋 다 무시된다
func _try_weapon_input() -> void:
	if Input.is_action_just_pressed(&"active_skill"):
		BoonRuntime.try_cast_active()
	if _weapon_kind == WeaponKind.RANGED:
		if Input.is_action_just_pressed(&"reload"):
			rifle.try_reload()
		if Input.is_action_pressed(&"attack_ranged"):
			rifle.try_fire(_aim_direction())
		return
	if _weapon_kind != WeaponKind.MELEE:
		return
	if not Input.is_action_just_pressed(&"attack_melee"):
		return
	# 지상은 3연타, 공중은 점프 공격 (WEAPONS 5, 6장)
	if hwando.try_primary_attack(is_on_floor()):
		_change_state(State.MELEE)


## 사격 방향 (8방향). 상하 단독 입력은 수직, 이동과 함께 누르면 대각,
## 상하 입력이 없으면 바라보는 방향 수평.
func _aim_direction() -> Vector2:
	var vertical: float = 0.0
	if Input.is_action_pressed(&"move_up"):
		vertical = -1.0
	elif Input.is_action_pressed(&"move_down") and not is_on_floor():
		vertical = 1.0
	if is_zero_approx(vertical):
		return Vector2(float(facing), 0.0)
	var horizontal: float = _input_axis()
	if is_zero_approx(horizontal):
		return Vector2(0.0, vertical)
	return Vector2(signf(horizontal), vertical).normalized()


func _input_axis() -> float:
	return Input.get_axis(&"move_left", &"move_right")


func _set_facing(direction: int) -> void:
	if direction == 0 or direction == facing:
		return
	facing = direction
	rifle.set_facing(direction)
	if hwando != null:
		hwando.set_facing(direction)
	_body_visual.flip_h = direction < 0


func _change_state(next_state: int) -> void:
	if next_state == _state:
		return
	_state = next_state
	_state_time = 0.0
	_apply_state_squash(next_state)
	# 근접 클립은 swung 신호가 이미 골라 재생했다. 여기서 덮으면 3연타가
	# 한 클립으로 뭉개진다 (WEAPONS 5.2절)
	state_changed.emit(next_state)


## 상태 전환 시 스프라이트 변형 초기화. 세부 연출은 각 _process와 _tick_body_stretch가 맡는다.
func _apply_state_squash(next_state: int) -> void:
	if next_state == State.MOVE or next_state == State.MELEE:
		_body_visual.scale = Vector2.ONE
		_body_visual.rotation = 0.0
		_body_visual.modulate = Color.WHITE
		_dash_ghost_timer = 0.0


func _after_move() -> void:
	if _state == State.DASH and is_on_wall():
		_dash_cooldown = dash_recovery
		_change_state(State.MOVE)


func _on_health_changed(current: int, maximum: int) -> void:
	GameEvents.player_health_changed.emit(current, maximum)


func _on_stamina_changed(current: float, maximum: float) -> void:
	GameEvents.player_stamina_changed.emit(current, maximum)


func _on_died() -> void:
	_dead = true
	health.set_invulnerable(true)
	hurtbox.set_deferred("monitorable", false)
	_body_visual.modulate = Color(0.4, 0.4, 0.4, 0.6)
	_body_visual.play(&"hurt")
	_body_visual.stop()
	_start_camera_shake(4.0, 0.3)
	GameEvents.player_died.emit()


## 피격 피드백: 피격음 + 적색 점멸 + 무적 깜빡임 + 화면 흔들림 + 히트스톱 + 밀려남.
func _on_player_hit(_amount: int, source_position: Vector2) -> void:
	if _dead:
		return
	AudioDirector.play_sfx(AudioDirector.Sfx.PLAYER_HIT)
	_hurt_invuln_left = 0.6
	health.set_invulnerable(true)
	_body_visual.self_modulate = Color(1.0, 0.45, 0.45)
	var away: float = 1.0 if global_position.x >= source_position.x else -1.0
	velocity.x = away * 150.0
	velocity.y = minf(velocity.y, -70.0)
	_start_camera_shake(3.0, 0.22)
	_hitstop(0.05)
	_play_oneshot(&"hurt", 0.36)
	if RunState.consume_hit_taken_stagger():
		_stagger_nearby_enemies()


## 개암 한 알 유물: 피격 시 소리가 터져 주변 적을 짧게 경직시킨다 (docs/systems/RELICS.md 6.2 4번).
func _stagger_nearby_enemies() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"enemy"):
		var enemy: EnemyBase = node as EnemyBase
		if enemy == null:
			continue
		if enemy.global_position.distance_to(global_position) <= 90.0:
			enemy.apply_stagger(0.5)


## 사격 피드백: 반동 킥 + 총구 섬광 + 미세 흔들림 + 사격 클립.
## shoot 클립 첫 프레임이 이미 조준 자세라 발사와 자세가 일치한다.
## 잠금은 연사 주기(fire_interval 0.16)보다 약간 길게 잡아 연사 중 조준을 유지한다.
func _on_rifle_fired_feel(_remaining: int) -> void:
	_recoil_left = 0.07
	_body_visual.position.x = float(-facing) * 2.0
	_start_camera_shake(1.0, 0.06)
	_play_oneshot(&"shoot", 0.2)


## 재장전 시작. 애니메이션은 _update_animation이 이동 여부로 reload/reload_run을 매 프레임 고른다(2클립 절충).
## 재장전을 마쳤다. 조왕 불티의 "재장전 뒤 첫 명중" 조건을 연다 (BOONS 8.3).
func _on_reload_finished() -> void:
	BoonRuntime.notify_reload_finished()


## 근접 명중을 권능 런타임에 알린다. 컴포넌트(Hitbox)는 적도 함께 쓰므로 권능을
## 알지 못한다. 플레이어 무기 쪽에서만 연결한다 (BOONS 9장 계층 경계).
func _connect_boon_hit_hooks() -> void:
	var melee_hitbox: Hitbox = get_node_or_null(^"Hwando/Hitbox") as Hitbox
	if melee_hitbox != null:
		melee_hitbox.hit_landed.connect(_on_boon_melee_hit)
	var bayonet: Hitbox = get_node_or_null(^"Rifle/MeleeHitbox") as Hitbox
	if bayonet != null:
		bayonet.hit_landed.connect(_on_boon_melee_hit)


func _on_boon_melee_hit(target: Hurtbox, _amount: int) -> void:
	BoonRuntime.notify_melee_hit(target)


## 액티브 권능이 거는 무적. 기존 피격 무적 창을 그대로 쓴다 (연출과 판정이 한 경로).
func grant_invulnerability(duration: float) -> void:
	_hurt_invuln_left = maxf(_hurt_invuln_left, duration)


## 액티브 권능이 거는 행동 잠금.
func begin_boon_channel(duration: float) -> void:
	_boon_channel_left = maxf(_boon_channel_left, duration)
	if _state != State.MOVE:
		_change_state(State.MOVE)


## 범의 이빨: 스태미나를 전부 태우고 그동안 회복도 막는다 (BOONS 8.2).
func drain_stamina_for(duration: float) -> void:
	stamina.drain_all()
	stamina.suppress_regen(duration)


func _on_reload_started() -> void:
	pass


func _start_camera_shake(strength: float, duration: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)
	_shake_left = maxf(_shake_left, duration)


func _tick_camera_shake(delta: float) -> void:
	if _camera == null:
		return
	if _shake_left <= 0.0:
		_camera.offset = Vector2.ZERO
		_shake_strength = 0.0
		return
	_shake_left = maxf(0.0, _shake_left - delta)
	var s: float = _shake_strength * (_shake_left / maxf(_shake_left + delta, 0.001))
	_camera.offset = Vector2(randf_range(-s, s), randf_range(-s, s))


func _tick_recoil(delta: float) -> void:
	if _recoil_left <= 0.0:
		return
	_recoil_left = maxf(0.0, _recoil_left - delta)
	if _recoil_left <= 0.0:
		_body_visual.position.x = 0.0


## 무적 시간 동안 스프라이트를 깜빡인다.
func _tick_hurt_blink() -> void:
	if _dead:
		return
	if _hurt_invuln_left <= 0.0:
		if _body_visual.self_modulate != Color.WHITE:
			_body_visual.self_modulate = Color.WHITE
		return
	var phase: int = int(_hurt_invuln_left * 15.0) % 2
	_body_visual.self_modulate.a = 0.35 if phase == 0 else 1.0


## 짧은 시간 정지로 타격감을 만든다. 실시간 타이머로 복원한다.
func _hitstop(duration: float) -> void:
	if _hitstop_active:
		return
	_hitstop_active = true
	Engine.time_scale = 0.05
	var timer: SceneTreeTimer = get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(_end_hitstop)


func _end_hitstop() -> void:
	Engine.time_scale = 1.0
	_hitstop_active = false
