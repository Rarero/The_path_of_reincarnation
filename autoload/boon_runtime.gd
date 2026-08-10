extends Node

## 권능 능력 런타임 (오토로드: BoonRuntime).
##
## RunState가 "무엇을 들고 있는가"를 보관한다면 여기는 "그것이 전투에서 무엇을 하는가"를
## 실행한다 (docs/systems/BOONS.md 8.2, 8.3).
##
## 수치는 전부 BoonDef와 BoonEffect(.tres)에서 읽는다. 이 파일에는 밸런스 상수를 두지
## 않는다 (docs/CONVENTIONS.md 데이터 규칙). 여기 있는 상수는 밸런스가 아니라 규격이다.
##
## 훅 연결 방향: 무기와 발사체가 명중 사실을 이쪽으로 알린다(call down). 컴포넌트
## (Hitbox, Hurtbox)는 적도 함께 쓰므로 권능을 알지 못한다.

## 액티브 상태 변화. ready, cooldown_left, cooldown_total (HUD 표시용)
signal active_state_changed(ready: bool, cooldown_left: float, cooldown_total: float)

## 화상 1스택이 1초마다 주는 피해. 규격값이며 세부 밸런스는 권능 .tres의 base_value가 정한다
const BURN_DAMAGE_PER_STACK: float = 1.0
## 화상 기본 지속 (초). 조왕 불티의 burn_duration 배율이 여기에 곱해진다
const BURN_BASE_DURATION: float = 4.0
## 화상 기본 스택 상한. 시너지 3단계가 여기에 더한다
const BURN_BASE_STACK_CAP: int = 5
## 바위 치기가 벽을 찾는 최대 거리 (px). 이 안에 벽이 있으면 충돌로 친다
const ROCK_WALL_REACH: float = 72.0
## 넉백으로 밀어내는 속도 (px/s)
const ROCK_KNOCKBACK_SPEED: float = 260.0

var _cooldown_left: float = 0.0
var _cooldown_total: float = 0.0
## 바위 치기: 다음 근접 1회에만 붙는다 (8.2, 2026-08-06 확정)
var _rock_strike_armed: bool = false
## 불티: 재장전을 마친 뒤 첫 명중에만 붙는 추가 스택
var _next_ranged_bonus_stacks: int = 0
## 부지깽이 자동 투척까지 남은 시간
var _poker_left: float = 0.0


func _ready() -> void:
	RunState.boons_changed.connect(_on_boons_changed)


func _process(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)
		if _cooldown_left <= 0.0:
			_emit_active_state()
	_tick_poker(delta)


## 런이 끝나거나 권능이 바뀌면 진행 중이던 상태를 정리한다.
func reset() -> void:
	_cooldown_left = 0.0
	_cooldown_total = 0.0
	_rock_strike_armed = false
	_next_ranged_bonus_stacks = 0
	_poker_left = 0.0
	_emit_active_state()


func active_ready() -> bool:
	return RunState.boons.has_active() and _cooldown_left <= 0.0


func cooldown_left() -> float:
	return _cooldown_left


## 액티브 권능을 발동한다. 성공하면 true. 플레이어가 입력에서 부른다.
func try_cast_active() -> bool:
	var instance: BoonInstance = RunState.boons.active
	if instance == null or instance.def == null or _cooldown_left > 0.0:
		return false
	var player: Node2D = _player()
	if player == null:
		return false
	var effect: BoonEffect = _cast_effect(instance.def)
	if effect == null:
		return false
	var fired: bool = _dispatch(instance.def.id, player, effect, instance)
	if not fired:
		return false
	_cooldown_total = _cooldown_of(instance.def, effect)
	_cooldown_left = _cooldown_total
	_emit_active_state()
	return true


## 근접 명중 통지. WeaponMelee의 Hitbox.hit_landed가 부른다.
func notify_melee_hit(target: Node) -> void:
	if target == null:
		return
	var enemy: Node = _enemy_of(target)
	if enemy == null:
		return
	if _rock_strike_armed:
		_rock_strike_armed = false
		_apply_rock_strike(enemy)
	# 겹내림 결과(잉걸주먹)처럼 근접 명중에 화상을 붙이는 권능
	var stacks: int = _hook_stacks(BoonEffect.Hook.ON_MELEE_HIT, &"burn")
	if stacks > 0:
		_apply_burn(enemy, stacks)


## 원거리 명중 통지. 플레이어가 쏜 Projectile이 부른다.
func notify_ranged_hit(target: Node) -> void:
	var enemy: Node = _enemy_of(target)
	if enemy == null:
		return
	var stacks: int = _hook_stacks(BoonEffect.Hook.ON_RANGED_HIT, &"burn")
	if _next_ranged_bonus_stacks > 0:
		stacks += _next_ranged_bonus_stacks
		_next_ranged_bonus_stacks = 0
	if stacks > 0:
		_apply_burn(enemy, stacks)


## 재장전 완료 통지. 불티의 "재장전 뒤 첫 명중" 조건을 연다 (8.3).
func notify_reload_finished() -> void:
	var bonus: int = 0
	for instance: BoonInstance in RunState.boons.all_instances():
		if instance == null or instance.def == null:
			continue
		for effect: BoonEffect in instance.def.special_effects:
			if effect.hook != BoonEffect.Hook.ON_RANGED_HIT:
				continue
			if effect.condition_key != &"after_reload" or effect.target_key != &"burn":
				continue
			bonus = maxi(bonus, int(round(effect.base_value)))
	_next_ranged_bonus_stacks = bonus


## 지금 보유 상태 기준 화상 스택 상한 (시너지 3단계가 올린다).
func burn_stack_cap() -> int:
	var bonus: int = int(round(RunState.total_stat_flat(&"burn_stack_cap")))
	return maxi(1, BURN_BASE_STACK_CAP + bonus)


## 지금 보유 상태 기준 화상 지속 (불티의 burn_duration 배율이 곱해진다).
func burn_duration() -> float:
	return BURN_BASE_DURATION * RunState.total_stat_mult(&"burn_duration")


func _apply_burn(enemy: Node, stacks: int) -> void:
	StatusBurn.apply(enemy, stacks, burn_duration(), burn_stack_cap(), BURN_DAMAGE_PER_STACK)


## 훅과 대상 키가 맞는 special_effect의 스택 수 합. 조건이 붙은 효과는 제외한다
## (조건부는 각 통지 함수가 따로 다룬다).
func _hook_stacks(hook: int, key: StringName) -> int:
	var total: int = 0
	for instance: BoonInstance in RunState.boons.all_instances():
		if instance == null or instance.def == null:
			continue
		if not _weapon_tag_active(instance):
			continue
		for effect: BoonEffect in instance.def.special_effects:
			if effect.hook != hook or effect.target_key != key:
				continue
			if not effect.condition_key.is_empty():
				continue
			total += int(round(effect.base_value))
	return total


## 무기 태그 조건 (규칙 18). 태그가 맞지 않으면 효과가 나오지 않는다.
## 무기 시스템이 활성 슬롯 질의를 제공하기 전까지는 플레이어의 장착 상태로 판정한다.
func _weapon_tag_active(instance: BoonInstance) -> bool:
	var tag: int = instance.effective_weapon_tag()
	if tag == BoonDef.WeaponTag.NONE:
		return true
	var player: Node2D = _player()
	if player == null:
		return false
	var melee_equipped: bool = bool(player.call(&"has_melee_weapon"))
	if tag == BoonDef.WeaponTag.MELEE:
		return melee_equipped
	return not melee_equipped


func _dispatch(
	id: StringName, player: Node2D, effect: BoonEffect, instance: BoonInstance
) -> bool:
	match String(id):
		"boon_sansin_san_ppyeo":
			return _cast_san_ppyeo(player, effect)
		"boon_sansin_beom_ippal":
			return _cast_beom_ippal(player, effect, instance)
		"boon_sansin_bawi_chigi":
			return _cast_bawi_chigi()
		"boon_jowang_agungi":
			return _cast_agungi(player, effect)
	push_warning("액티브 권능 발동 경로가 없다: %s" % String(id))
	return false


## 산의 뼈: 제자리에서 무적. 그동안 공격도 이동도 못 한다 (8.2).
func _cast_san_ppyeo(player: Node2D, effect: BoonEffect) -> bool:
	var duration: float = effect.duration_sec
	if duration <= 0.0:
		return false
	player.call(&"begin_boon_channel", duration)
	player.call(&"grant_invulnerability", duration)
	return true


## 범의 이빨: 스태미나를 전부 태우고 그동안 회복도 막는다. 대신 근접 피해가 오른다 (8.2).
## 상승분은 base_value가 정한다 (1.0이면 2배).
func _cast_beom_ippal(player: Node2D, effect: BoonEffect, instance: BoonInstance) -> bool:
	var duration: float = effect.duration_sec
	if duration <= 0.0:
		return false
	player.call(&"drain_stamina_for", duration)
	var gain: float = effect.base_value
	if instance != null and RunState.boons.rarity_table != null and effect.rarity_scales:
		gain *= RunState.boons.rarity_table.multiplier_for(instance.rarity, instance.rarity_bonus)
	RunState.grant_temp_mult(&"melee_damage", gain, duration)
	return true


## 바위 치기: 다음 근접 1회에 넉백을 싣는다. 벽에 부딪히면 추가 피해와 기절 (8.2).
func _cast_bawi_chigi() -> bool:
	_rock_strike_armed = true
	return true


## 아궁이 지피기: 발밑에 불자리를 놓는다. 그 위의 적에게 화상이 쌓인다 (8.6).
func _cast_agungi(player: Node2D, effect: BoonEffect) -> bool:
	var zone: HearthZone = HearthZone.new()
	zone.configure(effect.duration_sec, maxi(1, int(round(effect.base_value))))
	var host: Node = player.get_parent()
	if host == null:
		host = player
	host.add_child(zone)
	zone.global_position = player.global_position
	return true


## 넉백과 벽 충돌 판정. 밀어내는 방향으로 벽을 찾아 닿으면 추가 피해와 기절을 준다.
## 실제로 날아가 부딪히기를 기다리지 않고 즉시 판정한다. 적이 경직 중에는 이동이 막혀
## 물리적으로 벽까지 도달하지 못하는 경우가 많아 체감이 사라지기 때문이다.
func _apply_rock_strike(enemy: Node) -> void:
	var body: CharacterBody2D = enemy as CharacterBody2D
	if body == null:
		return
	var player: Node2D = _player()
	var away: float = 1.0
	if player != null and body.global_position.x < player.global_position.x:
		away = -1.0
	body.velocity.x = away * ROCK_KNOCKBACK_SPEED
	var effect: BoonEffect = _find_effect(&"boon_sansin_bawi_chigi", &"bawi_chigi_knockback")
	if effect == null:
		return
	if not _wall_within(body, away, ROCK_WALL_REACH):
		return
	var health: Health = body.get_node_or_null(^"Health") as Health
	if health != null:
		var bonus: int = int(round(effect.base_value * float(maxi(1, health.maximum)) * 0.1))
		health.apply_damage(maxi(1, bonus))
	if body.has_method(&"apply_stagger"):
		body.call(&"apply_stagger", maxf(0.4, effect.duration_sec))


## 밀리는 방향에 벽이 있는가. 지형 레이어(1)만 본다.
func _wall_within(body: CharacterBody2D, direction: float, reach: float) -> bool:
	var space: PhysicsDirectSpaceState2D = body.get_world_2d().direct_space_state
	var from: Vector2 = body.global_position + Vector2(0.0, -8.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		from, from + Vector2(direction * reach, 0.0), 1
	)
	query.exclude = [body.get_rid()]
	return not space.intersect_ray(query).is_empty()


## 부지깽이: 조작과 무관하게 주기로 불꽃을 던진다 (8.3, 규칙 57 명시 예외).
func _tick_poker(delta: float) -> void:
	var effect: BoonEffect = _owned_effect(&"boon_jowang_bujikkaengi", &"bujikkaengi_throw")
	if effect == null or effect.cooldown_sec <= 0.0:
		_poker_left = 0.0
		return
	var player: Node2D = _player()
	if player == null:
		return
	_poker_left -= delta
	if _poker_left > 0.0:
		return
	_poker_left = effect.cooldown_sec
	_throw_poker_flame(player, maxi(1, int(round(effect.base_value))))


func _throw_poker_flame(player: Node2D, stacks: int) -> void:
	var enemy: Node2D = _nearest_enemy(player)
	if enemy == null:
		return
	var direction: Vector2 = (enemy.global_position - player.global_position).normalized()
	var host: Node = player.get_parent()
	if host == null:
		return
	var flame: PokerFlame = PokerFlame.new()
	host.add_child(flame)
	flame.global_position = player.global_position
	flame.launch(direction, stacks)


func _nearest_enemy(player: Node2D) -> Node2D:
	var best: Node2D = null
	var best_distance: float = INF
	for node: Node in player.get_tree().get_nodes_in_group(&"enemy"):
		var enemy: Node2D = node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		var distance: float = player.global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


## 보유 중인 권능에서 id와 대상 키가 맞는 효과를 찾는다. 없으면 null.
func _owned_effect(id: StringName, key: StringName) -> BoonEffect:
	for instance: BoonInstance in RunState.boons.all_instances():
		if instance == null or instance.def == null or instance.def.id != id:
			continue
		if not _weapon_tag_active(instance):
			return null
		for effect: BoonEffect in instance.def.special_effects:
			if effect.target_key == key:
				return effect
	return null


## 보유 여부를 따지지 않고 정의에서 찾는다 (발동 직후 판정용).
func _find_effect(id: StringName, key: StringName) -> BoonEffect:
	var def: BoonDef = RunState.boon_def(id)
	if def == null:
		return null
	for effect: BoonEffect in def.special_effects:
		if effect.target_key == key:
			return effect
	return null


## 액티브 발동 효과 (ACTIVE_CAST 훅). 없으면 null.
func _cast_effect(def: BoonDef) -> BoonEffect:
	for effect: BoonEffect in def.special_effects:
		if effect.hook == BoonEffect.Hook.ACTIVE_CAST:
			return effect
	return null


func _cooldown_of(def: BoonDef, effect: BoonEffect) -> float:
	if def.active_cooldown_sec > 0.0:
		return def.active_cooldown_sec
	return maxf(0.1, effect.cooldown_sec)


## 명중한 Hurtbox에서 적 노드를 찾는다. 플레이어 자신은 제외한다.
func _enemy_of(target: Node) -> Node:
	if target == null:
		return null
	var owner_node: Node = target.get_parent() if target is Hurtbox else target
	if owner_node == null or owner_node.is_in_group(&"player"):
		return null
	return owner_node


func _player() -> Node2D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(&"player") as Node2D


func _on_boons_changed() -> void:
	_emit_active_state()


func _emit_active_state() -> void:
	active_state_changed.emit(active_ready(), _cooldown_left, _cooldown_total)
