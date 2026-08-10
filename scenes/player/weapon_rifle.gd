class_name WeaponRifle
extends Node2D

## 검증용 무기 1종: 기본 총 + 총검 (docs/PROTOTYPE.md 3장).
##
## - 원거리: 탄창 소모, 재장전 필요. 재장전 중 이동 가능
## - 근접: 총검 타격. 탄약 소모 없음, 재장전 중에도 사용 가능
## 목적은 탄약 관리와 재장전-근접 전환이 전투 리듬을 만드는지 검증하는 것이다.

signal fired(remaining: int)
signal reload_started
signal reload_finished
signal melee_swung

@export var bullet_scene: PackedScene = null
@export_group("사격")
@export var magazine_size: int = 8
@export var fire_interval: float = 0.16
@export var reload_time: float = 1.10
## 탄창 소진 시 자동 재장전 (M1 판정 반영). 수동 R로 먼저 장전할 수도 있다
@export var auto_reload: bool = true
@export var bullet_damage: int = 8
@export var bullet_speed: float = 520.0
## 투사체가 감지할 레이어 비트 합 (지형 1 + 적 피격판정 16)
@export var bullet_mask: int = 17
@export_group("총검")
## 선딜. 총검 찌르기 클립(8프레임 15fps)의 앞발 내딛고 찌르는 순간(f3 부근)에 타격 판정이 걸리도록 맞춘다
@export var melee_windup: float = 0.2
## 후딜. 찌른 뒤 앞발과 무게중심이 복귀하는 구간. 총검은 보조 수단이라 연타 주기를 총보다 느리게 잡는다
@export var melee_recovery: float = 0.34

var damage_multiplier: float = 1.0
var facing: int = 1

var _ammo: int = 0
var _muzzle_offset: float = 0.0
var _melee_offset: float = 0.0
var _fire_cooldown: float = 0.0
var _reload_left: float = 0.0
var _melee_left: float = 0.0
var _melee_fired: bool = false
var _flash_left: float = 0.0
## 총이 활성 무기인지. 꺼져 있으면 사격, 재장전, 탄약 발행이 전부 막힌다
var _active: bool = false

@onready var muzzle: Marker2D = $Muzzle as Marker2D
@onready var melee_hitbox: Hitbox = $MeleeHitbox as Hitbox
@onready var _muzzle_flash: Sprite2D = get_node_or_null(^"Muzzle/Flash") as Sprite2D
## 총검 스윙 임시 표시 (M1 검증 보조). 판정 창 동안만 보인다
@onready var _melee_visual: CanvasItem = get_node_or_null(^"MeleeHitbox/Visual") as CanvasItem


func _ready() -> void:
	_ammo = effective_magazine()
	_muzzle_offset = absf(muzzle.position.x)
	_melee_offset = absf(melee_hitbox.position.x)
	# 총은 시작 무기가 아니다. 대장장이 해금 뒤 총을 들었을 때만 켜진다
	# (docs/systems/WEAPONS.md 11.2절). 기본은 꺼진 상태이며 탄약도 알리지 않는다
	set_active(false)


## 총 활성 여부. 꺼져 있으면 표시와 틱, 탄약 발행이 모두 멈춘다.
## Player가 활성 무기 종류를 바꿀 때 부른다
func set_active(value: bool) -> void:
	_active = value
	visible = value
	set_physics_process(value)
	if value:
		_emit_ammo()
		return
	_cancel_in_progress()


func is_active() -> bool:
	return _active


## 진행 중인 사격 후딜, 재장전, 총검 판정을 모두 접는다. 총을 내릴 때 부른다
func _cancel_in_progress() -> void:
	_fire_cooldown = 0.0
	_reload_left = 0.0
	_melee_left = 0.0
	_melee_fired = false
	_flash_left = 0.0
	if _muzzle_flash != null:
		_muzzle_flash.visible = false
	if _melee_visual != null:
		_melee_visual.visible = false
	melee_hitbox.deactivate()


## 입력과 소모가 Player의 물리 틱에서 일어나므로 쿨다운도 같은 틱에서 흘린다.
func _physics_process(delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	_tick_reload(delta)
	_tick_melee(delta)
	if _flash_left > 0.0:
		_flash_left = maxf(0.0, _flash_left - delta)
		if _flash_left <= 0.0 and _muzzle_flash != null:
			_muzzle_flash.visible = false
	if _melee_visual != null and _melee_visual.visible and not melee_hitbox.is_active():
		_melee_visual.visible = false


## 바라보는 방향을 갱신한다. 총구와 총검 판정 위치를 좌우 반전한다
func set_facing(direction: int) -> void:
	if direction == 0:
		return
	facing = direction
	muzzle.position.x = _muzzle_offset * float(direction)
	melee_hitbox.position.x = _melee_offset * float(direction)
	var arc: Sprite2D = _melee_visual as Sprite2D
	if arc != null:
		arc.flip_h = direction < 0


## 사격을 시도한다. 발사에 성공하면 true. direction이 0벡터면 바라보는 방향으로 쏜다
func try_fire(direction: Vector2 = Vector2.ZERO) -> bool:
	if not _active:
		return false
	if _fire_cooldown > 0.0 or _reload_left > 0.0 or _ammo <= 0:
		return false
	if bullet_scene == null:
		push_warning("bullet_scene 미지정: 사격 무시")
		return false
	_ammo -= 1
	_fire_cooldown = fire_interval
	_spawn_bullet(direction)
	if _muzzle_flash != null:
		_muzzle_flash.visible = true
		_flash_left = 0.05
	fired.emit(_ammo)
	_emit_ammo()
	if auto_reload and _ammo == 0:
		try_reload()
	return true


## 재장전을 시도한다. 시작되면 true.
func try_reload() -> bool:
	if not _active:
		return false
	if _reload_left > 0.0 or _ammo >= effective_magazine():
		return false
	_reload_left = reload_time
	reload_started.emit()
	_emit_ammo()
	return true


## 총검 타격을 시도한다. 시작되면 true.
##
## 총검 겸용은 폐지됐다 (docs/systems/WEAPONS.md 8.2절). 근접은 환도가 전담하고
## 총이 활성일 때 attack_melee는 무시된다. Player는 더 이상 이 함수를 부르지 않으며
## 노드와 수치는 후속 정리 대상으로 남겨 둔다
func try_melee() -> bool:
	if not _active or _melee_left > 0.0:
		return false
	_melee_left = melee_total_time()
	_melee_fired = false
	melee_swung.emit()
	return true


## 총검 동작 전체 시간 (선딜 + 판정 + 후딜)
func melee_total_time() -> float:
	return melee_windup + melee_hitbox.active_duration + melee_recovery


## 권능과 유물의 최대 탄약 가산을 반영한 탄창 크기 (조왕 부지깽이 등).
func effective_magazine() -> int:
	return maxi(1, magazine_size + int(round(RunState.total_stat_flat(&"max_ammo"))))


func ammo() -> int:
	return _ammo


func is_reloading() -> bool:
	return _reload_left > 0.0


func _tick_reload(delta: float) -> void:
	if _reload_left <= 0.0:
		return
	_reload_left = maxf(0.0, _reload_left - delta)
	if _reload_left > 0.0:
		return
	_ammo = effective_magazine()
	reload_finished.emit()
	_emit_ammo()


func _tick_melee(delta: float) -> void:
	if _melee_left <= 0.0:
		return
	_melee_left = maxf(0.0, _melee_left - delta)
	var elapsed: float = melee_total_time() - _melee_left
	if _melee_fired or elapsed < melee_windup:
		return
	_melee_fired = true
	# 생기 몰림 배율에 유물 근접 보정(도깨비 방망이 기념품 등)을 곱한다
	melee_hitbox.damage_multiplier = damage_multiplier * RunState.total_stat_mult(&"melee_damage")
	melee_hitbox.activate()
	if _melee_visual != null:
		_melee_visual.visible = true


func _spawn_bullet(direction: Vector2) -> void:
	var projectile: Projectile = bullet_scene.instantiate() as Projectile
	if projectile == null:
		push_warning("bullet_scene이 Projectile이 아니다: 사격 무시")
		return
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(projectile)
	projectile.global_position = muzzle.global_position
	var aim: Vector2 = direction
	if aim.is_zero_approx():
		aim = Vector2(float(facing), 0.0)
	var boost: float = RunState.total_stat_mult(&"ranged_damage")
	var damage: int = int(round(float(bullet_damage) * damage_multiplier * boost))
	projectile.mark_from_player()
	projectile.launch(aim, damage, bullet_speed, bullet_mask)


## 탄약 발행은 총이 활성일 때로 한정한다 (WEAPONS 9장 HUD 표시 계약).
## 환도를 들고 있는 동안 탄약 숫자가 남아 있으면 총이 있는 것처럼 보인다
func _emit_ammo() -> void:
	if not _active:
		return
	GameEvents.player_ammo_changed.emit(_ammo, effective_magazine(), is_reloading())
