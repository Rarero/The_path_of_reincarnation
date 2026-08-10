class_name WeaponMelee
extends WeaponBase

## 근접 무기 (환도). docs/systems/WEAPONS.md 5장과 6장.
##
## 지상 3연타 콤보 상태 기계와 점프 공격을 처리한다. 콤보 창 안에 다시 입력하면
## 정상 후딜을 건너뛰고 곧바로 다음 타의 windup으로 넘어간다. 창을 놓치면
## 카운터가 0으로 돌아가고 그 타의 정상 후딜이 그대로 흐른다.
## 패링(7장)과 2슬롯 스위칭(2.2절)은 이 세션 범위가 아니다.

## 콤보 카운터가 바뀌었다. 0이면 대기 상태
signal combo_changed(step: int)

## 콤보 창이 열리기 이 시간 전부터 눌러 둔 입력도 유효하다.
## 점프 버퍼와 같은 원칙이라 프레임 단위 정확도를 요구하지 않는다 (5.2절)
const INPUT_BUFFER: float = 0.05

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

var _phase: int = Phase.IDLE
var _step: int = -1
var _phase_left: float = 0.0
var _combo_left: float = 0.0
var _buffered: bool = false
var _is_jump_attack: bool = false
var _land_recovery_left: float = 0.0
var _pending_advance: float = 0.0
var _air_attack_used: bool = false
## 참격 이펙트 잔여 시간과 총 길이. 판정 창보다 길게 남아 궤도를 보여 준다
var _fx_left: float = 0.0
var _fx_total: float = 0.0

@onready var hitbox: Hitbox = get_node_or_null(^"Hitbox") as Hitbox
@onready var _fx: Sprite2D = get_node_or_null(^"Hitbox/Visual") as Sprite2D


func _ready() -> void:
	super()
	_apply_hitbox_shape()
	if _fx != null:
		_fx.visible = false


func _physics_process(delta: float) -> void:
	_tick_fx(delta)
	_land_recovery_left = maxf(0.0, _land_recovery_left - delta)
	if _phase == Phase.IDLE:
		_combo_left = maxf(0.0, _combo_left - delta)
		if _combo_left <= 0.0 and _step >= 0:
			_reset_combo()
		return
	_phase_left = maxf(0.0, _phase_left - delta)
	if _phase_left > 0.0:
		return
	_advance_phase()


## 주 공격. 지상이면 콤보, 공중이면 점프 공격이다.
func try_primary_attack(on_floor: bool) -> bool:
	if definition == null or not is_equipped():
		return false
	if _land_recovery_left > 0.0:
		return false
	if not on_floor:
		return _try_jump_attack()
	return _try_combo_attack()


func is_attacking() -> bool:
	return _phase != Phase.IDLE or _land_recovery_left > 0.0


## 현재 콤보 단계 (0부터). 대기 중이면 -1
func combo_step() -> int:
	return -1 if _is_jump_attack else _step


func is_jump_attack() -> bool:
	return _is_jump_attack and _phase != Phase.IDLE


## 공중 1회 제한을 푼다. Player가 착지할 때 부른다 (6장)
func notify_landed() -> void:
	_air_attack_used = false
	if _is_jump_attack and _phase != Phase.IDLE:
		return
	if _is_jump_attack:
		_land_recovery_left = definition.jump_attack_land_recovery


## 진행 중인 공격을 즉시 끊는다. 대시 캔슬이 부른다 (WEAPONS 5.5절).
##
## 판정을 먼저 끄는 것이 이 함수의 핵심이다. 끊고도 히트박스가 살아 있으면
## 대시로 빠져나가면서 공격은 그대로 맞는 상태가 되어, 캔슬이 대가 없는
## 이득만 남긴다. 참격 이펙트도 함께 끈다. 판정 없는 궤적이 화면에 남으면
## 무엇이 맞는지에 대한 정보가 거짓이 된다.
##
## 콤보 카운터는 0으로 돌린다. 빠져나간 대가이며, 캔슬 뒤 마무리부터
## 다시 잇는 이득을 막는다. 공중 1회 제한(_air_attack_used)은 풀지 않는다.
## 캔슬은 취소지 환불이 아니다
func cancel_attack() -> void:
	if _phase == Phase.IDLE and _land_recovery_left <= 0.0:
		return
	_phase = Phase.IDLE
	_phase_left = 0.0
	_land_recovery_left = 0.0
	_is_jump_attack = false
	_buffered = false
	_pending_advance = 0.0
	if hitbox != null:
		hitbox.deactivate()
	_stop_fx()
	_reset_combo()


func consume_advance() -> float:
	var value: float = _pending_advance
	_pending_advance = 0.0
	return value


## 지금 타에 맞는 몸 클립. 타마다 다른 클립을 줘야 3연타가 한 동작으로 뭉개지지
## 않는다. 정의에 비어 있으면 Player가 기본 클립을 고른다
func body_clip() -> StringName:
	var attack: MeleeAttackDef = _current_attack()
	if attack == null:
		return &""
	return attack.body_clip


func _try_combo_attack() -> bool:
	if _phase == Phase.IDLE:
		if _step >= 0 and _combo_left > 0.0:
			return _start_step(_step + 1, false)
		return _start_step(0, false)
	if _is_jump_attack:
		return false
	var current: MeleeAttackDef = definition.combo_step(_step)
	if current == null or current.combo_window <= 0.0:
		return false
	if _step + 1 >= definition.combo_length():
		return false
	# 후딜 중 입력은 콤보 창 안이다. 남은 후딜을 건너뛰고 곧바로 다음 타의
	# windup으로 넘어간다 (5.2절). 후딜이 끝나기를 기다리면 콤보가 느려진다
	if _phase == Phase.RECOVERY:
		return _start_step(_step + 1, false)
	# 창이 열리기 직전(active 끝 INPUT_BUFFER 이내)의 입력은 예약해 둔다.
	# 점프 버퍼와 같은 원칙이라 프레임 단위 정확도를 요구하지 않는다
	if _phase == Phase.ACTIVE and _phase_left <= INPUT_BUFFER:
		_buffered = true
		return true
	return false


func _try_jump_attack() -> bool:
	if _air_attack_used or _phase != Phase.IDLE:
		return false
	if definition.melee_jump_attack == null:
		return false
	_air_attack_used = true
	return _start_step(0, true)


func _start_step(index: int, jump_attack: bool) -> bool:
	var attack: MeleeAttackDef = (
		definition.melee_jump_attack if jump_attack else definition.combo_step(index)
	)
	if attack == null:
		_reset_combo()
		return false
	_is_jump_attack = jump_attack
	_step = index
	_buffered = false
	_phase = Phase.WINDUP
	_phase_left = attack.windup
	_combo_left = 0.0
	swung.emit(index)
	if not jump_attack:
		combo_changed.emit(index + 1)
	return true


func _advance_phase() -> void:
	var attack: MeleeAttackDef = _current_attack()
	if attack == null:
		_reset_combo()
		return
	match _phase:
		Phase.WINDUP:
			_enter_active(attack)
		Phase.ACTIVE:
			_enter_recovery(attack)
		Phase.RECOVERY:
			_finish_step(attack)


func _enter_active(attack: MeleeAttackDef) -> void:
	_phase = Phase.ACTIVE
	_phase_left = attack.active
	_pending_advance += attack.advance * float(facing)
	if hitbox != null:
		hitbox.damage = attack.damage
		hitbox.active_duration = attack.active
		# 생기 몰림 배율에 유물 근접 보정을 곱한다 (weapon_rifle과 같은 규칙)
		hitbox.damage_multiplier = damage_multiplier * RunState.total_stat_mult(&"melee_damage")
		hitbox.activate()
	_start_fx(attack)


func _enter_recovery(attack: MeleeAttackDef) -> void:
	# 이펙트는 판정과 함께 끄지 않는다. 0.08초는 눈에 남지 않는다.
	# 자체 타이머(_tick_fx)가 fx_duration만큼 끌고 간다
	# 콤보 창 안에 예약된 입력이 있으면 후딜을 건너뛰고 다음 타로 간다
	if _buffered and not _is_jump_attack and attack.combo_window > 0.0:
		var next_index: int = _step + 1
		if next_index < definition.combo_length():
			_start_step(next_index, false)
			return
	_phase = Phase.RECOVERY
	_phase_left = attack.recovery


func _finish_step(attack: MeleeAttackDef) -> void:
	_phase = Phase.IDLE
	_phase_left = 0.0
	if _is_jump_attack:
		_is_jump_attack = false
		_reset_combo()
		return
	# 마무리 타는 콤보 창이 없으므로 즉시 리셋한다 (5.2절)
	if attack.combo_window <= 0.0 or _step + 1 >= definition.combo_length():
		_reset_combo()
		return
	_combo_left = attack.combo_window
	if _buffered:
		_start_step(_step + 1, false)


func _current_attack() -> MeleeAttackDef:
	if definition == null:
		return null
	if _is_jump_attack:
		return definition.melee_jump_attack
	return definition.combo_step(_step)


func _reset_combo() -> void:
	_step = -1
	_combo_left = 0.0
	_buffered = false
	combo_changed.emit(0)


func _on_unequipped() -> void:
	_phase = Phase.IDLE
	_phase_left = 0.0
	_land_recovery_left = 0.0
	_is_jump_attack = false
	_pending_advance = 0.0
	if hitbox != null:
		hitbox.deactivate()
	_stop_fx()
	_reset_combo()


## 참격 이펙트를 켠다. 히트박스의 자식이라 위치가 판정 중심과 자동으로 맞는다
## (요청서 025 C-3, 이펙트가 판정보다 커서 생기는 오인을 줄인다)
func _start_fx(attack: MeleeAttackDef) -> void:
	if _fx == null or attack.fx_texture == null:
		return
	_fx.texture = attack.fx_texture
	_fx.hframes = maxi(1, attack.fx_frames)
	_fx.frame = 0
	_fx.visible = true
	_fx_total = maxf(attack.fx_duration, 0.02)
	_fx_left = _fx_total


func _stop_fx() -> void:
	_fx_left = 0.0
	if _fx != null:
		_fx.visible = false


## 이펙트 프레임을 시간으로 넘긴다. 판정 상태와 독립이라 후딜 중에도 이어진다
func _tick_fx(delta: float) -> void:
	if _fx_left <= 0.0:
		return
	_fx_left = maxf(0.0, _fx_left - delta)
	if _fx == null:
		return
	if _fx_left <= 0.0:
		_fx.visible = false
		return
	var progress: float = 1.0 - _fx_left / _fx_total
	_fx.frame = mini(_fx.hframes - 1, int(progress * float(_fx.hframes)))


## 정의의 히트박스 크기와 위치를 실제 노드에 반영한다.
func _apply_hitbox_shape() -> void:
	if hitbox == null or definition == null:
		return
	hitbox.position = definition.hitbox_offset
	var shape_node: CollisionShape2D = hitbox.get_node_or_null(^"Shape") as CollisionShape2D
	if shape_node == null:
		return
	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rect != null:
		rect.size = definition.hitbox_size
