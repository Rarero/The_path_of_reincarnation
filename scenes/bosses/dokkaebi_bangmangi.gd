extends BossBase

## 방망이 보스 (순수 전투 2페이즈. docs/act1/BOSS.md 3.2).
##
## 방망이가 스스로 요술을 부려 재물과 사물을 소환해 공격한다. 직접 타격이 아니라 소환물로 싸운다.
## 1페이즈 요술 소환: 도깨비불과 재물 낙하로 원거리 압박, 소환 직후 본체가 잠깐 노출된다.
## 2페이즈 난무: 접근해 방망이 난타(SmashHitbox)와 소환을 병행한다.
## 기믹 없이 요술 패턴을 회피하고 본체에 딜을 넣는 구성이다.

@export var fire_scene: PackedScene = null  ## 도깨비불 투사체 (projectile_fire.tscn)
@export var treasure_scene: PackedScene = null  ## 재물 낙하 (projectile.tscn 재사용)
@export var fire_damage: int = 6
@export var treasure_damage: int = 8
## 지형 1 + 플레이어 피격판정 8
@export var projectile_mask: int = 9
@export var fire_speed: float = 180.0
@export var treasure_speed: float = 240.0
@export var summon_interval_p1: float = 1.6
@export var summon_interval_p2: float = 1.1
@export var smash_range: float = 40.0
@export var smash_windup: float = 0.35
@export var treasure_drop_height: float = 120.0

var _summon_cd: float = 0.0
var _smash_cd: float = 0.0
var _smashing: bool = false
var _smash_left: float = 0.0

@onready var muzzle: Marker2D = $Muzzle as Marker2D
@onready var smash_hitbox: Hitbox = get_node_or_null(^"SmashHitbox") as Hitbox


func _tick_ai(delta: float) -> void:
	_summon_cd = maxf(0.0, _summon_cd - delta)
	_smash_cd = maxf(0.0, _smash_cd - delta)
	set_facing(direction_to_player())
	if phase >= 2:
		_tick_phase2(delta)
	else:
		_tick_phase1(delta)


## 1페이즈: 느린 드리프트 + 주기적 요술 소환.
func _tick_phase1(delta: float) -> void:
	var target_vx: float = float(direction_to_player()) * stats.move_speed * 0.4
	velocity.x = move_toward(velocity.x, target_vx, 300.0 * delta)
	if _summon_cd <= 0.0:
		_summon_cd = summon_interval_p1
		_cast_fire()
		_cast_treasure()


## 2페이즈: 접근해 난타, 사거리 밖이면 도깨비불 소환.
func _tick_phase2(delta: float) -> void:
	if _smashing:
		_tick_smash(delta)
		return
	var dist: float = distance_to_player()
	if dist > smash_range:
		velocity.x = move_toward(
			velocity.x, float(direction_to_player()) * stats.move_speed, 600.0 * delta
		)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 800.0 * delta)
		if _smash_cd <= 0.0:
			_start_smash()
	if _summon_cd <= 0.0:
		_summon_cd = summon_interval_p2
		_cast_fire()


func _start_smash() -> void:
	if smash_hitbox == null:
		return
	_smashing = true
	_smash_left = smash_windup + smash_hitbox.active_duration


func _tick_smash(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_smash_left = maxf(0.0, _smash_left - delta)
	var elapsed: float = (smash_windup + smash_hitbox.active_duration) - _smash_left
	if elapsed >= smash_windup and not smash_hitbox.is_active() and _smash_left > 0.0:
		smash_hitbox.damage_multiplier = damage_multiplier
		smash_hitbox.activate()
	if _smash_left <= 0.0:
		_smashing = false
		_smash_cd = stats.attack_cooldown


## 피격 경직 시 진행 중이던 난타를 취소한다.
func _cancel_action() -> void:
	if not _smashing:
		return
	_smashing = false
	if smash_hitbox != null and smash_hitbox.is_active():
		smash_hitbox.deactivate()


## 도깨비불을 플레이어 방향으로 소환한다.
func _cast_fire() -> void:
	var player: Node2D = find_player()
	if fire_scene == null or player == null:
		return
	var proj: Projectile = fire_scene.instantiate() as Projectile
	if proj == null:
		return
	_host().add_child(proj)
	proj.global_position = muzzle.global_position
	var aim: Vector2 = (
		(player.global_position - Vector2(0.0, 12.0) - muzzle.global_position).normalized()
	)
	proj.launch(
		aim, int(round(float(fire_damage) * damage_multiplier)), fire_speed, projectile_mask
	)


## 재물을 플레이어 머리 위에서 떨어뜨린다.
func _cast_treasure() -> void:
	var player: Node2D = find_player()
	if treasure_scene == null or player == null:
		return
	var proj: Projectile = treasure_scene.instantiate() as Projectile
	if proj == null:
		return
	_host().add_child(proj)
	proj.global_position = Vector2(
		player.global_position.x, global_position.y - treasure_drop_height
	)
	proj.launch(
		Vector2.DOWN,
		int(round(float(treasure_damage) * damage_multiplier)),
		treasure_speed,
		projectile_mask
	)


func _host() -> Node:
	var host: Node = get_tree().current_scene
	return host if host != null else get_tree().root
