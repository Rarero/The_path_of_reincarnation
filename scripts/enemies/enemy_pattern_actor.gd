class_name EnemyPatternActor
extends EnemyBase

## AttackPattern 기반 공격을 쓰는 적의 공통 베이스 (docs/act1/ENEMIES.md 9장 상태 머신).
##
## 예비 -> 판정 -> (다단이면 간격) -> 후딜 -> 쿨다운의 진행을 여기서 돌린다. 수치는
## 전부 AttackPattern 리소스가 갖고 이 클래스는 시간만 센다. 개체별 특수 행동(돌진,
## 도주, 구르기)은 하위 클래스가 이 상태 머신 바깥에 따로 둔다.
##
## 잡도깨비(scenes/enemies/enemy_charger.gd)는 같은 로직을 자기 안에 갖고 있다. 검증이
## 끝난 코드라 이번에는 건드리지 않았고, 통합은 후속 과제로 남긴다.

## 공격 패턴의 진행 단계. 프레임 규격은 AttackPattern이 갖는다
enum Phase { NONE, WINDUP, ACTIVE, GAP, RECOVERY }

## 예비 구간에 쓰는 임시 밝기 신호. 부위 분리 스프라이트가 없어 전신에 적용한다
const WINDUP_TINT: Color = Color(1.6, 1.6, 0.9)
const WINDUP_TINT_DIM: Color = Color(1.1, 1.1, 1.0)

var _phase: int = Phase.NONE
var _phase_left: float = 0.0
var _pattern: AttackPattern = null
var _hits_left: int = 0
## 패턴 순번. 후보가 둘 이상이면 번갈아 쓴다. 무작위가 아닌 것은 의도다.
## 이지선다 심리전보다 반응 가능성을 우선한다 (docs/act1/ENEMIES.md 1장)
var _pattern_turn: int = 0

@onready var sprite: AnimatedSprite2D = get_node_or_null(^"BodyVisual") as AnimatedSprite2D
@onready var attack_hitbox: Hitbox = get_node_or_null(^"AttackHitbox") as Hitbox


func _ready() -> void:
	super()
	if attack_hitbox != null:
		attack_hitbox.deactivate()


## 현재와 다른 클립일 때만 재생한다 (순환 클립이 매 프레임 재시작되지 않게)
func set_anim(clip: StringName) -> void:
	if sprite != null and sprite.animation != clip:
		sprite.play(clip)


## 진행 중인 패턴이 슈퍼아머면 경직되지 않는다
func can_be_staggered() -> bool:
	if _phase == Phase.NONE or _pattern == null:
		return true
	return not _pattern.super_armor


func is_in_pattern() -> bool:
	return _phase != Phase.NONE


func current_pattern() -> AttackPattern:
	return _pattern


## 사거리에 드는 패턴 하나를 고른다. 없으면 null
func pick_pattern(distance: float) -> AttackPattern:
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


func start_pattern(pattern: AttackPattern) -> void:
	_pattern = pattern
	_phase = Phase.WINDUP
	_phase_left = pattern.windup()
	_hits_left = maxi(1, pattern.hit_count)
	velocity.x = 0.0
	set_facing(direction_to_player())
	apply_hitbox_shape(pattern)
	if pattern.windup_clip != &"":
		set_anim(pattern.windup_clip)
	else:
		set_anim(&"idle")
	body_visual.self_modulate = WINDUP_TINT
	_on_pattern_windup(pattern)


## 예비 진입 훅. 개체별 예고 연출을 붙인다
func _on_pattern_windup(_pattern_started: AttackPattern) -> void:
	pass


## 판정 진입 훅. 이동 기반 패턴(도약 돌진 등)이 속도를 넣는 자리다
func _on_pattern_active(_pattern_active: AttackPattern) -> void:
	pass


## 후딜 진입 훅
func _on_pattern_recovery(_pattern_done: AttackPattern) -> void:
	pass


## 패턴 진행 중 매 프레임. 기본은 제자리에 선다.
## 이동하는 패턴을 쓰는 개체는 재정의한다
func tick_pattern(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	pose_for_phase()
	advance_pattern_clock(delta)


## 진행 단계에 맞는 자세를 잡는다. 예비는 웅크리고 판정은 내지른다.
## 스프라이트가 1프레임뿐이라 이 변형이 사실상 공격 애니메이션 역할을 한다
func pose_for_phase() -> void:
	if _pattern == null:
		return
	match _phase:
		Phase.WINDUP:
			var total: float = maxf(0.01, _pattern.windup())
			# 예비가 끝나갈수록 깊이 웅크린다. 터지기 직전이 가장 눌린 자세다
			pose_crouch(1.0 - _phase_left / total)
		Phase.ACTIVE:
			pose_lunge(1.0)
		Phase.GAP:
			pose_lunge(0.5)
		Phase.RECOVERY:
			var left: float = maxf(0.01, _pattern.recovery())
			pose_lunge(_phase_left / left * 0.6)


## 시계만 돌린다. 이동을 직접 다루는 하위 클래스가 쓴다
func advance_pattern_clock(delta: float) -> void:
	_phase_left = maxf(0.0, _phase_left - delta)
	if _phase == Phase.WINDUP:
		pulse_windup(_phase_left)
	if _phase_left > 0.0:
		return
	_advance_phase()


func _advance_phase() -> void:
	if _pattern == null:
		end_pattern()
		return
	match _phase:
		Phase.WINDUP:
			_enter_active()
		Phase.ACTIVE:
			_hits_left -= 1
			if _hits_left > 0 and _pattern.hit_interval_frames > 0:
				_phase = Phase.GAP
				_phase_left = _pattern.hit_interval()
				if attack_hitbox != null:
					attack_hitbox.deactivate()
			elif _hits_left > 0:
				_enter_active()
			else:
				_enter_recovery()
		Phase.GAP:
			_enter_active()
		Phase.RECOVERY:
			end_pattern()


func _enter_active() -> void:
	_phase = Phase.ACTIVE
	_phase_left = _pattern.active()
	body_visual.self_modulate = Color.WHITE
	if _pattern.active_clip != &"":
		set_anim(_pattern.active_clip)
	elif sprite != null:
		sprite.play(&"attack")
	if attack_hitbox != null:
		attack_hitbox.damage = _pattern.damage
		attack_hitbox.active_duration = _pattern.active()
		attack_hitbox.damage_multiplier = damage_multiplier
		attack_hitbox.activate()
	_on_pattern_active(_pattern)


func _enter_recovery() -> void:
	_phase = Phase.RECOVERY
	_phase_left = _pattern.recovery()
	if attack_hitbox != null:
		attack_hitbox.deactivate()
	_on_pattern_recovery(_pattern)


func end_pattern() -> void:
	var cooldown_frames: int = 0 if _pattern == null else _pattern.cooldown_frames
	_phase = Phase.NONE
	_phase_left = 0.0
	_pattern = null
	_hits_left = 0
	body_visual.self_modulate = Color.WHITE
	if attack_hitbox != null:
		attack_hitbox.deactivate()
	if cooldown_frames > 0:
		set_attack_cooldown(float(cooldown_frames) / AttackPattern.FPS)
	else:
		start_attack_cooldown()


## 후딜을 건너뛰고 곧바로 끝낸다 (그랩 성공처럼 결과가 갈리는 패턴이 쓴다)
func finish_pattern_early() -> void:
	if _phase == Phase.NONE:
		return
	_enter_recovery()


## 판정 영역 크기와 위치를 패턴에 맞춘다. x는 바라보는 방향으로 뒤집는다
func apply_hitbox_shape(pattern: AttackPattern) -> void:
	if attack_hitbox == null:
		return
	attack_hitbox.position = Vector2(
		absf(pattern.hitbox_offset.x) * float(facing), pattern.hitbox_offset.y
	)
	var shape: CollisionShape2D = attack_hitbox.get_node_or_null(^"Shape") as CollisionShape2D
	if shape == null:
		return
	var rect: RectangleShape2D = shape.shape as RectangleShape2D
	if rect != null:
		rect.size = pattern.hitbox_size


## 예비 구간의 밝기 점멸
func pulse_windup(time_left: float) -> void:
	var step: int = int(time_left * 15.0) % 2
	body_visual.self_modulate = WINDUP_TINT if step == 0 else WINDUP_TINT_DIM


func _cancel_action() -> void:
	if _phase != Phase.NONE:
		end_pattern()
