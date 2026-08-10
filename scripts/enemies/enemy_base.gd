class_name EnemyBase
extends CharacterBody2D

## 적 공통 베이스. 수치는 EnemyStats 리소스에서 읽는다 (docs/CONVENTIONS.md 데이터).
## AI는 하위 클래스가 _tick_ai를 구현한다. M1은 최소 구현이며 전투 리듬 검증이 목적이다.

signal defeated(enemy: EnemyBase)

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/ui/damage_number.tscn")

## 처치 히트스톱 중복 방지 (동시 처치 시 한 번만). 클래스 전역
static var _kill_stop_active: bool = false

@export var stats: EnemyStats = null
@export var gravity: float = 900.0
@export var max_fall_speed: float = 520.0
## 부유형 적은 중력을 받지 않고 velocity.y를 스스로 관리한다.
## 등불 도깨비의 지형 앵커 부유가 이 경로다 (docs/act1/ENEMIES.md 5.2)
@export var floating: bool = false

@export_group("연출")
## 걸을 때 위아래로 흔들리는 폭 (px). 0이면 끈다.
## 1프레임 스프라이트라도 걸음이 미끄러짐으로 보이지 않게 하는 최소 장치다
@export var walk_bob_amplitude: float = 1.6
## 걸음 흔들림 속도 (이동 속도 1px/s당 위상 증가량)
@export var walk_bob_rate: float = 0.055
## 자세 변형이 목표값을 따라가는 속도 (1/초). 클수록 즉각적이다
@export var pose_response: float = 18.0
## 피격 흔들림 폭 (px)
@export var hit_shake: float = 2.5

@export_group("장애물 통과")
## 홉으로 넘을 수 있는 최대 단차 (px). 타일 16px 기준 2타일까지 넘긴다
@export var step_max_height: float = 36.0
## 홉 재시도 쿨다운 (초). 무한 홉 방지
@export var step_hop_cooldown: float = 0.35
## 벽에 막힌 채 이 시간이 지나면 잠시 반대로 돌아 우회를 시도한다 (초)
@export var stuck_turn_time: float = 1.0
## 우회를 유지하는 시간 (초). 곧바로 되돌아오면 벽 앞에서 진동한다
@export var detour_time: float = 1.4
## 걸어서 내려갈 수 있는 최대 낙차 (px). 이 안에 바닥이 있으면 턱에서 내려간다.
## 1막 방에는 낙사가 없다 (docs/act1/ENEMIES.md 5.5). 발밑만 보고 멈추면 적이
## 턱 위에 올라선 채 굳어 플레이어가 아래에 있어도 내려오지 못한다 (2026-08-09 실측)
@export var max_drop_height: float = 80.0

## 생기 몰림 배율. 방(Room)이 주입한다
var damage_multiplier: float = 1.0
## 이 개체가 사라질 때 처치 보상(엽전, 유물 드랍 굴림)을 줘야 하는가.
## 방 클리어 판정에서 빠지려고 defeated 를 재사용하는 개체가 있어(장물아비 이탈)
## 신호만으로는 처치와 도주를 구분할 수 없다. 도주 경로에서 false 로 내린다
var grants_kill_reward: bool = true
var facing: int = -1

var _hitstun_left: float = 0.0
var _attack_cooldown_left: float = 0.0
## 방 비활성 시 true. AI가 멈추고 플레이어를 인지하지 않는다 (방 경계 밖 추격 금지)
var _suspended: bool = false
var _step_cd: float = 0.0
## 벽에 막혀 나아가지 못한 누적 시간
var _stuck_time: float = 0.0
## 우회 중 남은 시간. 0보다 크면 요청한 방향과 반대로 걷는다
var _detour_left: float = 0.0
## 직전 프레임의 x. 실제로 나아갔는지 재는 기준
var _last_walk_x: float = 0.0

## 자세 변형. 하위 클래스가 매 프레임 목표값을 넣고 _tick_visual이 부드럽게 따라간다.
## 스프라이트가 1프레임뿐인 동안 패턴을 눈에 보이게 하는 유일한 수단이다 (2026-08-09)
var pose_scale: Vector2 = Vector2.ONE
var pose_offset: Vector2 = Vector2.ZERO
var pose_rotation: float = 0.0
var _pose_scale_now: Vector2 = Vector2.ONE
var _pose_offset_now: Vector2 = Vector2.ZERO
var _pose_rotation_now: float = 0.0
var _visual_base_scale: Vector2 = Vector2.ONE
var _visual_base_position: Vector2 = Vector2.ZERO
var _walk_phase: float = 0.0
var _shake_left: float = 0.0

@onready var health: Health = $Health as Health
@onready var hurtbox: Hurtbox = $Hurtbox as Hurtbox
## 접촉 공격이 없는 적(원거리형)은 이 노드가 없을 수 있다
@onready var contact_hitbox: Hitbox = get_node_or_null(^"ContactHitbox") as Hitbox
@onready var body_visual: CanvasItem = $BodyVisual as CanvasItem
## 낙사 방지용 전방 지면 감지. 없는 적은 이 노드가 없을 수 있다
@onready var floor_probe: RayCast2D = get_node_or_null(^"FloorProbe") as RayCast2D


func _ready() -> void:
	if stats == null:
		stats = EnemyStats.new()
	health.maximum = stats.max_health
	health.refill()
	if contact_hitbox != null:
		contact_hitbox.damage = stats.contact_damage
	health.died.connect(_on_died)
	hurtbox.hit_received.connect(_on_hit_received)
	var visual_node: Node2D = body_visual as Node2D
	if visual_node != null:
		_visual_base_scale = visual_node.scale
		_visual_base_position = visual_node.position


func _physics_process(delta: float) -> void:
	if _suspended:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		# 부유형은 중력이 없어 y가 저절로 정리되지 않는다. 정지 중에는 y도 함께 멈춘다.
		# 없으면 방을 비운 사이 앵커에서 떠내려가 지형 앵커 규칙이 깨진다
		if floating:
			velocity.y = move_toward(velocity.y, 0.0, 900.0 * delta)
		_apply_gravity(delta)
		move_and_slide()
		return

	_hitstun_left = maxf(0.0, _hitstun_left - delta)
	_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)
	_step_cd = maxf(0.0, _step_cd - delta)
	if contact_hitbox != null:
		contact_hitbox.damage_multiplier = damage_multiplier

	if _hitstun_left > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		clear_pose()
		_tick_hitstun_pose()
	else:
		clear_pose()
		_tick_ai(delta)

	_apply_gravity(delta)
	move_and_slide()
	_tick_visual(delta)


# --- 자세 연출 ---


## 이번 프레임의 자세를 리셋한다. 하위 클래스가 상태에 맞는 값을 다시 넣는다
func clear_pose() -> void:
	pose_scale = Vector2.ONE
	pose_offset = Vector2.ZERO
	pose_rotation = 0.0


## 웅크림. t는 0에서 1. 예비동작에 쓴다. 세로로 눌리고 가로로 퍼지며 살짝 뒤로 젖힌다
func pose_crouch(t: float) -> void:
	var k: float = clampf(t, 0.0, 1.0)
	pose_scale = Vector2(1.0 + 0.16 * k, 1.0 - 0.20 * k)
	pose_offset = Vector2(-3.0 * k * float(facing), 2.0 * k)
	pose_rotation = deg_to_rad(-5.0 * k * float(facing))


## 내지르기. t는 0에서 1. 판정 순간에 쓴다. 앞으로 늘어나며 기운다
func pose_lunge(t: float) -> void:
	var k: float = clampf(t, 0.0, 1.0)
	pose_scale = Vector2(1.0 + 0.18 * k, 1.0 - 0.08 * k)
	pose_offset = Vector2(4.0 * k * float(facing), -1.0 * k)
	pose_rotation = deg_to_rad(8.0 * k * float(facing))


## 앞으로 기울이기. 돌진과 밀어붙이기처럼 계속 나아가는 동작에 쓴다
func pose_dash(t: float) -> void:
	var k: float = clampf(t, 0.0, 1.0)
	pose_scale = Vector2(1.0 + 0.12 * k, 1.0 - 0.10 * k)
	pose_offset = Vector2(2.0 * k * float(facing), 1.0 * k)
	pose_rotation = deg_to_rad(12.0 * k * float(facing))


## 주저앉기. 경직과 기절에 쓴다
func pose_slump(t: float) -> void:
	var k: float = clampf(t, 0.0, 1.0)
	pose_scale = Vector2(1.0 + 0.10 * k, 1.0 - 0.16 * k)
	pose_offset = Vector2(-2.0 * k * float(facing), 2.0 * k)
	pose_rotation = deg_to_rad(-10.0 * k * float(facing))


## 잔상 하나를 남긴다. 돌진처럼 빠른 이동의 속도감을 만든다.
## 부모(방)에 붙여 본체가 사라져도 남지 않게 스스로 지운다
func spawn_afterimage(alpha: float = 0.45, life: float = 0.16) -> void:
	var source: Node2D = body_visual as Node2D
	var host: Node = get_parent()
	if source == null or host == null:
		return
	var ghost: Node2D = source.duplicate() as Node2D
	if ghost == null:
		return
	ghost.z_index = source.z_index - 1
	host.add_child(ghost)
	ghost.global_position = source.global_position
	ghost.global_scale = source.global_scale
	ghost.rotation = source.rotation
	ghost.modulate = Color(0.75, 0.78, 1.0, alpha)
	var tween: Tween = ghost.create_tween()
	tween.tween_property(ghost, ^"modulate:a", 0.0, life)
	tween.tween_callback(ghost.queue_free)


## 자세와 걸음 흔들림을 스프라이트에 적용한다.
## 목표값을 그대로 꽂지 않고 따라가게 해서 단계 전환이 툭 끊기지 않게 한다
func _tick_visual(delta: float) -> void:
	var visual_node: Node2D = body_visual as Node2D
	if visual_node == null:
		return
	var k: float = clampf(pose_response * delta, 0.0, 1.0)
	_pose_scale_now = _pose_scale_now.lerp(pose_scale, k)
	_pose_offset_now = _pose_offset_now.lerp(pose_offset, k)
	_pose_rotation_now = lerpf(_pose_rotation_now, pose_rotation, k)

	var bob: float = 0.0
	if walk_bob_amplitude > 0.0 and is_on_floor():
		var speed: float = absf(velocity.x)
		if speed > 4.0:
			_walk_phase += speed * walk_bob_rate * delta * TAU
			bob = -absf(sin(_walk_phase)) * walk_bob_amplitude
		else:
			_walk_phase = 0.0

	var shake: Vector2 = Vector2.ZERO
	if _shake_left > 0.0:
		_shake_left = maxf(0.0, _shake_left - delta)
		var amount: float = hit_shake * (_shake_left / maxf(0.01, stats.hitstun))
		shake = Vector2(sin(_shake_left * 90.0) * amount, 0.0)

	visual_node.scale = _visual_base_scale * _pose_scale_now
	visual_node.position = (
		_visual_base_position + _pose_offset_now + shake + Vector2(0.0, bob)
	)
	visual_node.rotation = _pose_rotation_now


## 하위 클래스가 구현한다.
func _tick_ai(_delta: float) -> void:
	pass


## 피격 경직에 들어갈 때 진행 중이던 행동을 취소한다. 하위 클래스가 필요하면 재정의한다.
func _cancel_action() -> void:
	pass


## 방(Room)이 활성 상태에 맞춰 호출한다. 정지 중에는 진행 중이던 행동도 취소한다.
func set_suspended(value: bool) -> void:
	if _suspended == value:
		return
	_suspended = value
	if value:
		_cancel_action()
		if contact_hitbox != null and contact_hitbox.is_active():
			contact_hitbox.deactivate()


func is_suspended() -> bool:
	return _suspended


## 외부(유물 개암 한 알 등)가 이 적을 짧게 경직시킨다.
## 슈퍼아머 구간은 여기서도 막는다. 뚫리면 슈퍼아머로 만든 대응 규칙(위치 선택)이
## 유물 하나로 무의미해진다 (docs/act1/ENEMIES.md 5.4 씨름꾼 그랩 예비).
func apply_stagger(duration: float) -> void:
	if _suspended or health.is_dead() or not can_be_staggered():
		return
	_hitstun_left = maxf(_hitstun_left, duration)
	_cancel_action()


## 주어진 방향 앞에 딛을 지면이 있는가. 프로브가 없거나 공중이면 true (이동을 막지 않는다).
func has_floor_ahead(direction: int) -> bool:
	if floor_probe == null or direction == 0 or not is_on_floor():
		return true
	floor_probe.position.x = absf(floor_probe.position.x) * float(direction)
	floor_probe.force_raycast_update()
	return floor_probe.is_colliding()


## 전방(바라보는 방향) 벽으로 부딪힌 충돌체. 없으면 null.
## move_and_slide 이후 유효하다 (다음 프레임의 _tick_ai에서 참조).
func front_collider() -> Object:
	for i: int in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		if signf(collision.get_normal().x) == float(-facing):
			return collision.get_collider()
	return null


## 전방 벽이 낮은 단차(약 1타일)인가. 발 높이는 막히고 머리 높이는 열렸으면 넘을 수 있다.
func wall_is_low_step() -> bool:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var reach: Vector2 = Vector2(14.0 * float(facing), 0.0)
	var low: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, -4.0), global_position + Vector2(0.0, -4.0) + reach, 1
	)
	var high: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		global_position + Vector2(0.0, -24.0), global_position + Vector2(0.0, -24.0) + reach, 1
	)
	low.exclude = [get_rid()]
	high.exclude = [get_rid()]
	var blocked_low: bool = not space.intersect_ray(low).is_empty()
	var open_high: bool = space.intersect_ray(high).is_empty()
	return blocked_low and open_high


## 그 방향으로 걸어 내려갈 수 있는가. 낙차 안에 바닥이 있으면 true.
## has_floor_ahead가 false여도 이쪽이 true면 내려가도 된다
func can_step_down(direction: int) -> bool:
	if direction == 0:
		return false
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var from: Vector2 = global_position + Vector2(16.0 * float(direction), -2.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		from, from + Vector2(0.0, max_drop_height), 1
	)
	query.exclude = [get_rid()]
	return not space.intersect_ray(query).is_empty()


## 전방 벽을 넘을 수 있는 높이 (px). 넘을 수 없거나 벽이 없으면 -1.
## 발 높이가 막혀 있고 그 위 어딘가가 열려 있으면 거기까지가 단차다
func wall_step_height() -> float:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var reach: Vector2 = Vector2(14.0 * float(facing), 0.0)
	var foot: Vector2 = global_position + Vector2(0.0, -4.0)
	var low: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		foot, foot + reach, 1
	)
	low.exclude = [get_rid()]
	if space.intersect_ray(low).is_empty():
		return -1.0
	var height: float = 8.0
	while height <= step_max_height:
		var at: Vector2 = global_position + Vector2(0.0, -(height + 6.0))
		var probe: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			at, at + reach, 1
		)
		probe.exclude = [get_rid()]
		if space.intersect_ray(probe).is_empty():
			return height
		height += 4.0
	return -1.0


## 전방 장애물을 처리한다. 부술 수 있으면 부수고, 넘을 수 있으면 홉으로 넘는다.
## 처리했으면 true (진행 방향 유지), 못 넘는 벽이면 false
func try_clear_obstacle() -> bool:
	var obstacle: Object = front_collider()
	if obstacle != null and obstacle.is_in_group(&"breakable"):
		obstacle.call(&"break_now")
		return true
	if _step_cd > 0.0 or not is_on_floor():
		return false
	var height: float = wall_step_height()
	if height < 0.0:
		return false
	# 단차 위로 올라설 초기 속도. v = sqrt(2 * g * h), 여유 12px를 더한다
	velocity.y = -sqrt(2.0 * gravity * (height + 12.0))
	_step_cd = step_hop_cooldown
	return true


## 한 방향으로 걷는다. 벽과 낭떠러지를 스스로 처리하고, 나아가지 못하면 false.
##
## 못 가는 상태가 stuck_turn_time 넘게 이어지면 잠시 반대로 돌아 우회한다.
## 이 장치가 없으면 넘지 못하는 벽 앞에서 속도 0으로 굳어 영원히 서 있는다.
## 2026-08-09 헤드리스 실측에서 창고와 골목 방의 잡도깨비가 실제로 그렇게 굳었다
func walk_toward(direction: int, speed: float, delta: float) -> bool:
	# 막힘은 is_on_wall()이 아니라 실제 이동량으로 잰다. 벽에 붙으면 is_on_wall()이
	# 프레임마다 켜졌다 꺼졌다 해서 누적 시간이 계속 0으로 초기화된다 (2026-08-09 실측)
	var progressed: float = absf(global_position.x - _last_walk_x)
	_last_walk_x = global_position.x
	if progressed < speed * delta * 0.3:
		_stuck_time += delta
	else:
		_stuck_time = 0.0

	if _detour_left > 0.0:
		_detour_left = maxf(0.0, _detour_left - delta)
		var away: int = -direction if direction != 0 else -facing
		set_facing(away)
		if is_on_wall():
			try_clear_obstacle()
		var can_go: bool = has_floor_ahead(away) or can_step_down(away)
		velocity.x = float(away) * speed if can_go else 0.0
		return false

	if direction == 0:
		velocity.x = 0.0
		return false
	set_facing(direction)
	if is_on_wall():
		try_clear_obstacle()
	if not has_floor_ahead(direction) and not can_step_down(direction):
		velocity.x = 0.0
		_start_detour_if_stuck()
		return false
	velocity.x = float(direction) * speed
	return not _start_detour_if_stuck()


## 오래 막혔으면 우회를 시작한다. 시작했으면 true
func _start_detour_if_stuck() -> bool:
	if _stuck_time < stuck_turn_time:
		return false
	_stuck_time = 0.0
	_detour_left = detour_time
	return true


## 플레이어 노드를 찾는다. 없으면 null
func find_player() -> Node2D:
	return get_tree().get_first_node_in_group(&"player") as Node2D


func distance_to_player() -> float:
	var player: Node2D = find_player()
	if player == null:
		return INF
	return global_position.distance_to(player.global_position)


func direction_to_player() -> int:
	var player: Node2D = find_player()
	if player == null:
		return facing
	return 1 if player.global_position.x > global_position.x else -1


func attack_ready() -> bool:
	return _attack_cooldown_left <= 0.0


## 기본 쿨다운을 건다. 이미 더 긴 쿨다운이 걸려 있으면 유지한다.
## 대입으로 두면 end_pattern 이 두 번 불릴 때(패턴 자연 종료 뒤 하위 클래스가 한 번 더)
## 패턴이 정한 cooldown_frames 가 stats.attack_cooldown 으로 조용히 덮인다
func start_attack_cooldown() -> void:
	_attack_cooldown_left = maxf(_attack_cooldown_left, stats.attack_cooldown)


## 지정한 시간으로 쿨다운을 건다. 패턴별 쿨다운(AttackPattern.cooldown_frames)을
## 쓰는 개체가 호출한다. 이미 걸린 쿨다운보다 짧으면 무시한다
func set_attack_cooldown(seconds: float) -> void:
	_attack_cooldown_left = maxf(_attack_cooldown_left, seconds)


func set_facing(direction: int) -> void:
	if direction == 0 or direction == facing:
		return
	facing = direction
	# Sprite2D와 AnimatedSprite2D 모두 flip_h를 가지므로 타입에 무관하게 설정한다
	if body_visual != null:
		body_visual.set(&"flip_h", direction < 0)


## 부유형은 중력을 건너뛴다. velocity.y는 개체가 직접 관리한다
func _apply_gravity(delta: float) -> void:
	if floating:
		return
	if is_on_floor():
		velocity.y = 0.0
		return
	velocity.y = minf(max_fall_speed, velocity.y + gravity * delta)


## 방 클리어 판정에 세는 개체인가.
##
## 회피가 기본 대응인 해저드성 개체는 세지 않는다. 세면 "굴러오는 것을 피한다"가
## "굴러오는 것을 전부 잡는다"로 바뀌어 대응 방식이 뒤집힌다
## (docs/act1/ENEMIES.md 6장 클리어 카운트 제외 대상).
func counts_for_clear() -> bool:
	return true


## 지금 피격 경직에 들어갈 수 있는가. 슈퍼아머 구간의 개체는 재정의해 false를 준다
func can_be_staggered() -> bool:
	return true


## 이번 피격의 경직 시간에 곱할 배율. 슈퍼아머(0)와 정상(1) 사이가 필요한 개체가 있다.
## 예: 구르는 달걀도깨비는 맞아도 아주 짧게만 움찔하고 계속 굴러야 한다 (5.5)
func hitstun_scale() -> float:
	return 1.0


## 경직 중 자세. 기본은 늘어짐이다. 경직 중에도 유지해야 할 변형이 있으면 재정의한다
func _tick_hitstun_pose() -> void:
	pose_slump(1.0)


## 처치 시 개체별 정리. 자기 밖에 만들어 둔 노드(예고 마커 등)를 거둘 때 재정의한다.
##
## _cancel_action과 분리해 둔 이유가 있다. 보스처럼 _cancel_action이 "진행 중 동작을
## 물리고 다음 자세로 잇는" 개체가 있어서(쓰러져 있으면 일어나는 동작으로 연결) 사망
## 경로에서 그것을 부르면 시체가 일어나려 한다. 사망 정리는 별도 훅으로 받는다
func _on_death_cleanup() -> void:
	pass


## 주어진 노드 아래의 모든 Hitbox를 끈다. 판정 노드가 여러 개이거나 깊이 박혀 있어도
## 빠뜨리지 않게 재귀로 훑는다 (잡도깨비 ContactHitbox + AttackHitbox 등)
func _deactivate_hitboxes(node: Node) -> void:
	for child: Node in node.get_children():
		var box: Hitbox = child as Hitbox
		if box != null and box.is_active():
			box.deactivate()
		_deactivate_hitboxes(child)


func _on_hit_received(amount: int, source_position: Vector2) -> void:
	_spawn_damage_number(amount)
	# 슈퍼아머 구간에서는 피해와 피격 표시만 받고 경직과 넉백, 행동 취소는 걸리지 않는다
	if can_be_staggered():
		# 경직 등급이 강할수록 짧게 밀린다 (docs/act1/ENEMIES.md 3장 피격 반응 규칙)
		var scale_now: float = hitstun_scale()
		_hitstun_left = stats.hitstun * stats.stagger_time_scale() * scale_now
		_shake_left = stats.hitstun * scale_now
		_cancel_action()
		var away: float = 1.0 if global_position.x >= source_position.x else -1.0
		velocity.x = away * 60.0 * stats.stagger_knockback_scale()
		# 애니메이션형 적은 피격 클립을 원샷 재생한다 (정적 스프라이트 적은 건너뛴다)
		if body_visual is AnimatedSprite2D:
			(body_visual as AnimatedSprite2D).play(&"hurt")
	# 피격 플래시는 _cancel_action 뒤에 건다. 행동 취소가 modulate를 흰색으로 되돌리므로
	# 먼저 칠하면 같은 프레임에 덮여 타격감이 사라진다
	body_visual.modulate = Color(1.0, 0.6, 0.6)
	var flash: SceneTreeTimer = get_tree().create_timer(stats.hitstun)
	flash.timeout.connect(_restore_color)


func _restore_color() -> void:
	if is_instance_valid(body_visual):
		body_visual.modulate = Color.WHITE


## 처치 순간 아주 짧은 전역 슬로우로 타격감을 준다. 실시간 타이머로 복원한다.
##
## 복원 콜백은 static 이어야 한다. 인스턴스 메서드에 연결하면, 이 적이 45ms 안에
## 해제될 때(방 강제 클리어, 씬 전환) 연결이 조용히 끊겨 Engine.time_scale 이 0.12로,
## _kill_stop_active 가 true 로 영구히 남는다. 그러면 게임 전체가 0.12배속으로 돌고
## 이후 어떤 처치 히트스톱도 발동하지 않는다
func _kill_hitstop() -> void:
	if _kill_stop_active:
		return
	_kill_stop_active = true
	Engine.time_scale = 0.12
	var timer: SceneTreeTimer = get_tree().create_timer(0.045, true, false, true)
	timer.timeout.connect(EnemyBase.end_kill_hitstop)


## 히트스톱 해제. static 이라 호출자 인스턴스가 사라져도 살아 있다.
## 씬 전환 방어(SceneRouter.change_scene)에서도 부른다
static func end_kill_hitstop() -> void:
	Engine.time_scale = 1.0
	_kill_stop_active = false


## 피격 피해값을 적 위에 수치로 띄운다. 적이 사라져도 남도록 부모(방)에 붙인다.
func _spawn_damage_number(amount: int) -> void:
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate() as DamageNumber
	if number == null:
		return
	number.setup(amount)
	var host: Node = get_parent()
	if host == null:
		host = self
	host.add_child(number)
	number.global_position = global_position + Vector2(0.0, -22.0)


func _on_died() -> void:
	# 시체에 판정이 남으면 맞지 않을 공격에 맞는다. 하위 노드의 Hitbox를 전부 끈다
	_deactivate_hitboxes(self)
	# 밖에 만들어 둔 예고(등불 착탄 마커 등)를 거둔다. 개체가 필요하면 재정의한다
	_on_death_cleanup()
	defeated.emit(self)
	_kill_hitstop()
	GameEvents.enemy_defeated.emit(global_position)
	set_physics_process(false)
	if contact_hitbox != null and contact_hitbox.is_active():
		contact_hitbox.deactivate()
	var shape: CollisionShape2D = get_node_or_null(^"Shape") as CollisionShape2D
	if shape != null:
		shape.set_deferred(&"disabled", true)
	if body_visual == null:
		queue_free()
		return
	# 사망 연출: 흰 섬광 후 납작해지며 사라진다
	body_visual.self_modulate = Color(2.0, 2.0, 2.0)
	var tween: Tween = create_tween()
	tween.tween_property(body_visual, ^"modulate:a", 0.0, 0.16)
	var node2d: Node2D = body_visual as Node2D
	if node2d != null:
		tween.parallel().tween_property(node2d, ^"scale", Vector2(1.35, 0.55), 0.16)
	tween.tween_callback(queue_free)
