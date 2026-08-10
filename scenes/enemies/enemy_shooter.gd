extends EnemyBase

## 등불 도깨비 (docs/act1/ENEMIES.md 5.2).
##
## 지형 앵커 주변을 부유하며 포물선으로 등불알을 던진다. 근접당하면 짧게 도약해 이탈한다.
## 2026-08-06(D11) 정합 구현: 직선 조준 + 중력 보행이던 M1 축약 구현을 설계대로 교체했다.
## - 지형 앵커 부유: 스폰 지점을 앵커로 잡고 그 반경 안에서만 뜬 채로 움직인다.
##   무한 후퇴로 플레이어를 방 밖까지 끌지 않게 한다
## - 포물선 투척: 착탄 예정 지점에 바닥 마커를 띄우고 그 지점으로 던진다.
##   마커 밖으로 이동하거나 엄폐물로 궤도를 막는 두 가지 회피가 성립한다
## - 도약 이탈: 밀착당하면 앵커 안쪽으로 짧게 도약한다
##
## 부유는 EnemyBase.floating으로 켠다. 씬에서 켜 두므로 이 스크립트가 강제하지 않는다.
## 공격 프레임은 stats.attack_patterns[0] (AttackPattern)이 갖는다.

enum Phase { IDLE, WINDUP, RECOVERY }

@export_group("투척")
@export var bullet_scene: PackedScene = null
@export var impact_scene: PackedScene = null
## 투사체에 걸리는 중력 (px/s^2). 포물선의 휘어짐을 정한다.
## 정점 높이는 대략 arc_gravity * flight_time^2 / 8 이다 (수평 착탄 기준 약 81px).
## 너무 평평하면 총알과 구분되지 않고, 너무 높으면 좌판 높이의 엄폐가 무의미해진다
@export var arc_gravity: float = 800.0
## 착탄까지의 비행 시간 (초). 패링 하한(검 1타 windup 0.10초)보다 넉넉히 크게 둔다
## (docs/DECISIONS.md 2026-08-07 패링 신설의 D11 인계 항목)
@export var flight_time: float = 0.90
## 투사체가 감지할 레이어 비트 합 (지형 1 + 플레이어 피격판정 8)
@export var bullet_mask: int = 9
## 조준 목표를 발 기준에서 위로 올리는 값 (px). 착탄 마커의 높이 기준이다
@export var aim_height: float = 6.0
## 착탄 지점에 남는 불꽃 지대의 지속 시간 (초).
## 비교 대상은 쿨다운이 아니라 한 사이클 전체다. 예비 0.40 + 후딜 0.30 + 쿨다운 1.00
## = 1.70초 간격으로 던지므로 2.0초면 0.30초만 겹친다. 1.7초를 크게 넘기면
## 지대가 상시 두 겹이 되어 서 있기만 해도 초당 피해가 두 배가 된다
@export var burn_time: float = 2.0
## 불꽃 지대의 주기 피해. 직격(패턴 damage)보다 낮게 둔다.
## 지대는 여러 번 때리므로 같은 값이면 직격을 맞는 쪽이 이득이 된다
@export var burn_tick_damage: int = 4

@export_group("지형 앵커 부유")
## 앵커에서 좌우로 벗어날 수 있는 최대 거리 (px)
@export var anchor_radius: float = 56.0
## 부유 흔들림 진폭 (px)
@export var bob_amplitude: float = 4.0
## 부유 흔들림 주기 (초)
@export var bob_period: float = 2.2
## 앵커 높이로 돌아가는 최대 속도 (px/s)
@export var return_speed: float = 46.0
## 유지하려는 거리 (px). 0이면 stats.attack_range를 쓴다 (수치 권위는 .tres)
@export var preferred_range: float = 0.0
## 유지 거리 허용 오차 (px)
@export var range_tolerance: float = 24.0

@export_group("도약 이탈")
## 이 거리 안으로 들어오면 도약해 이탈한다 (px)
@export var evade_trigger_range: float = 44.0
## 도약 수평 속도 (px/s)
@export var evade_speed: float = 170.0
## 도약 상승 속도 (px/s)
@export var evade_lift: float = 90.0
## 도약 유지 시간 (초)
@export var evade_duration: float = 0.22
## 도약 재사용 쿨다운 (초)
@export var evade_cooldown: float = 2.6

var _anchor: Vector2 = Vector2.ZERO
var _muzzle_offset: float = 0.0
var _bob_time: float = 0.0
var _phase: int = Phase.IDLE
var _phase_left: float = 0.0
var _pattern: AttackPattern = null
var _marker: LanternImpact = null
var _evade_left: float = 0.0
var _evade_cd: float = 0.0
var _evade_dir: int = 1

@onready var muzzle: Marker2D = $Muzzle as Marker2D


func _ready() -> void:
	super()
	_anchor = global_position
	_muzzle_offset = absf(muzzle.position.x)


func _tick_ai(delta: float) -> void:
	_bob_time += delta
	_evade_cd = maxf(0.0, _evade_cd - delta)

	if _evade_left > 0.0:
		_tick_evade(delta)
		return

	var distance: float = distance_to_player()
	if distance > stats.detect_range:
		# 어그로가 풀렸으면 예고를 거둔다. 마커만 남으면 거짓 신호가 된다
		_cancel_throw()
		_hover(0.0)
		return

	set_facing(direction_to_player())
	muzzle.position.x = _muzzle_offset * float(facing)

	# 밀착당하면 예비를 끊고 도약으로 빠진다. 경직이 큰 개체라 접근에 취약한 것이
	# 설계 의도이므로 도약은 쿨다운으로 제한한다 (ENEMIES.md 5.2 스탯 등급)
	if distance <= evade_trigger_range and _evade_cd <= 0.0:
		_start_evade()
		return

	if _phase != Phase.IDLE:
		_tick_phase(delta)
		return

	if attack_ready() and _throw_pattern() != null:
		_start_windup()
		return

	_hover(_drift_step(distance))


## 이 개체가 쓰는 투척 패턴. 없으면 null (그 경우 공격하지 않는다)
func _throw_pattern() -> AttackPattern:
	if stats == null or stats.attack_patterns.is_empty():
		return null
	return stats.attack_patterns[0]


# --- 지형 앵커 부유 ---


## 앵커 주변에 뜬 채로 머문다. step은 좌우 이동 방향 (-1, 0, 1).
## 앵커 반경 밖으로는 나가지 않는다. 무한 후퇴 금지 (ENEMIES.md 5.2 지형 앵커)
##
## delta를 받지 않는다. 위치가 아니라 속도를 정하고 move_and_slide가 적분하므로
## 프레임 시간이 필요 없다. 이동량 상한도 move_speed와 return_speed로 이미 걸려 있다
func _hover(step: float) -> void:
	var low: float = _anchor.x - anchor_radius
	var high: float = _anchor.x + anchor_radius
	var target_x: float = clampf(global_position.x + step * anchor_radius, low, high)
	var gap_x: float = target_x - global_position.x
	velocity.x = clampf(gap_x * 6.0, -stats.move_speed, stats.move_speed)
	# 앵커 높이로 돌아가며 사인파로 흔들린다
	var bob: float = 0.0
	if bob_period > 0.0:
		bob = sin(TAU * _bob_time / bob_period) * bob_amplitude
	var gap_y: float = _anchor.y + bob - global_position.y
	velocity.y = clampf(gap_y * 8.0, -return_speed, return_speed)


## 사거리를 유지하기 위한 좌우 이동 방향
func _drift_step(distance: float) -> float:
	var hold: float = preferred_range if preferred_range > 0.0 else stats.attack_range
	if distance < hold - range_tolerance:
		return float(-facing)
	if distance > hold + range_tolerance:
		return float(facing)
	return 0.0


# --- 투척 (AttackPattern 기반) ---


func _start_windup() -> void:
	_pattern = _throw_pattern()
	_phase = Phase.WINDUP
	_phase_left = _pattern.windup()
	_spawn_marker()


func _tick_phase(delta: float) -> void:
	_hover(0.0)
	_phase_left = maxf(0.0, _phase_left - delta)
	if _phase == Phase.WINDUP:
		_pulse_windup()
		# 던지기 전 몸을 뒤로 젖힌다. 색 점멸만으로는 예비가 잘 안 읽힌다
		var total: float = maxf(0.01, _pattern.windup())
		pose_crouch(1.0 - _phase_left / total)
	elif _phase == Phase.RECOVERY:
		# 던진 뒤 앞으로 따라 나간다. 후딜이 반격 창임을 자세로 알린다
		pose_lunge(_phase_left / maxf(0.01, _pattern.recovery()))
	if _phase_left > 0.0:
		return
	if _phase == Phase.WINDUP:
		body_visual.self_modulate = Color.WHITE
		_throw()
		_phase = Phase.RECOVERY
		_phase_left = _pattern.recovery()
		return
	set_attack_cooldown(_pattern.cooldown())
	_phase = Phase.IDLE
	_phase_left = 0.0
	_pattern = null


## 예고: 등불알을 난색으로 밝힌다. 적색은 데스매치 전용 채널이라 쓰지 않는다
## (docs/DECISIONS.md 2026-08-04 예고 신호 표준)
func _pulse_windup() -> void:
	var pulse: int = int(_phase_left * 14.0) % 2
	body_visual.self_modulate = Color(1.7, 1.35, 0.85) if pulse == 0 else Color(1.2, 1.1, 1.0)


## 착탄 예정 지점에 마커를 띄운다. 마커가 곧 위험 범위 표시다
func _spawn_marker() -> void:
	if impact_scene == null:
		return
	var marker: LanternImpact = impact_scene.instantiate() as LanternImpact
	if marker == null:
		push_warning("impact_scene이 LanternImpact가 아니다: 마커 없이 투척한다")
		return
	_host().add_child(marker)
	marker.global_position = _aim_target()
	marker.burn_time = burn_time
	# 마커는 남은 예비 시간 + 비행 시간 동안 차오르고, 착탄하면 불꽃 지대로 바뀐다.
	# 지대 피해는 직격보다 낮은 주기 피해다 (직격은 아래 _throw가 패턴 damage로 준다)
	marker.setup(burn_tick_damage, damage_multiplier, _phase_left + flight_time)
	_marker = marker


## 조준 지점. 플레이어의 현재 위치를 예측 없이 그대로 쓴다.
## 예측 사격은 예비 24f를 보고 피하는 학습을 무의미하게 만든다 (ENEMIES.md 1장)
func _aim_target() -> Vector2:
	var player: Node2D = find_player()
	if player == null:
		return global_position
	return player.global_position - Vector2(0.0, aim_height)


func _throw() -> void:
	var marker: LanternImpact = _marker
	_marker = null
	# 마커가 먼저 사라졌을 수 있다(수명 만료). 해제된 참조를 그대로 쓰면 터진다
	if marker != null and not is_instance_valid(marker):
		marker = null
	if bullet_scene == null or _pattern == null:
		return
	var projectile: Projectile = bullet_scene.instantiate() as Projectile
	if projectile == null:
		push_warning("bullet_scene이 Projectile이 아니다: 투척 무시")
		return
	_host().add_child(projectile)
	projectile.global_position = muzzle.global_position
	var target: Vector2 = marker.global_position if marker != null else _aim_target()
	var damage: int = int(round(float(_pattern.damage) * damage_multiplier))
	projectile.launch_arc(target, damage, flight_time, arc_gravity, bullet_mask)
	if marker == null:
		return
	projectile.impacted.connect(marker.on_projectile_impacted)
	projectile.absorbed.connect(marker.on_projectile_absorbed)


## 투사체와 마커는 적이 죽어도 남아야 하므로 방 쪽에 붙인다
func _host() -> Node:
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	return host


# --- 도약 이탈 ---


func _start_evade() -> void:
	_cancel_throw()
	_evade_left = evade_duration
	_evade_cd = evade_cooldown
	_evade_dir = _pick_evade_dir()
	velocity.y = -evade_lift


## 플레이어 반대쪽으로 빠지되, 앵커 반경을 벗어나는 방향이면 반대로 돈다.
## 앵커 밖으로 도약하면 착지 후 반경 제한과 싸우느라 제자리로 밀려 보인다
func _pick_evade_dir() -> int:
	var away: int = -direction_to_player()
	var reach: float = float(away) * evade_speed * evade_duration
	var landing: float = global_position.x + reach
	if absf(landing - _anchor.x) > anchor_radius:
		return -away
	return away


func _tick_evade(delta: float) -> void:
	_evade_left = maxf(0.0, _evade_left - delta)
	velocity.x = float(_evade_dir) * evade_speed
	# 도약 중에는 상승 후 감속한다. 부유형이라 중력은 받지 않는다
	velocity.y = move_toward(velocity.y, 0.0, evade_lift * 3.0 * delta)
	if _evade_left <= 0.0:
		velocity.x = 0.0


## 피격 경직이나 도약 진입 시 진행 중인 투척을 취소한다.
## 마커도 함께 지운다. 취소된 공격의 예고가 남으면 신호가 거짓이 된다
func _cancel_throw() -> void:
	if _phase == Phase.IDLE:
		return
	# 끊긴 공격도 쿨다운을 먹는다. 이게 없으면 압박당할 때 오히려 더 자주 던진다
	# (피격 -> 취소 -> 쿨다운 0 -> 즉시 재시도 경로)
	if _pattern != null:
		set_attack_cooldown(_pattern.cooldown())
	_phase = Phase.IDLE
	_phase_left = 0.0
	_pattern = null
	body_visual.self_modulate = Color.WHITE
	if _marker != null and is_instance_valid(_marker):
		_marker.queue_free()
	_marker = null


func _cancel_action() -> void:
	_cancel_throw()


## 처치 시: 아직 날아가지 않은 착탄 마커를 거둔다. 남으면 오지 않을 공격이 예고된다
func _on_death_cleanup() -> void:
	_cancel_throw()
