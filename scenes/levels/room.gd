class_name Room
extends Node2D

## 방 하나. 노드 맵의 노드 1개에 대응한다 (docs/RUN_STRUCTURE.md 2장).
##
## 역할
## - 슬롯 기반 랜덤 배치를 실행한다 (docs/ROOM_SPEC.md 3장). 씬에는 후보 지점만 있고
##   무엇을 놓을지는 run_stage가 주입한 위협 예산과 시드로 RoomPopulator가 정한다
## - 플레이어가 들어오면 전투 상태를 시작하고 생기 몰림 타이머를 돌린다
## - 웨이브를 진행하고, 남은 웨이브가 없고 잔존 적이 0이 되면 클리어를 알린다

signal cleared(elapsed: float)

## 방 예산을 받지 못했을 때의 기본값 (진행도 중간값. docs/RUN_STRUCTURE.md 11.7)
const DEFAULT_THREAT_BUDGET: float = 6.0
## 생기 고갈 단계 1당 생기 몰림을 앞당기는 시간 (초). 1단계 -10, 2단계 -20, 3단계 -30
const DEPLETION_RAGE_STEP: float = 10.0
## 고갈로 앞당겨도 이 아래로는 내려가지 않는다. 들어가자마자 발동하면 방이 성립하지 않는다
const MIN_RAGE_THRESHOLD: float = 40.0
## 이 예산을 넘으면 웨이브를 둘로 나눈다
const SINGLE_WAVE_BUDGET: float = 6.0
## 고밀도 방의 생기 몰림 발동 시간 (초). docs/act1/ENEMIES.md 2장 8pt 이상 110초
const DENSE_RAGE_THRESHOLD: float = 110.0
## 고밀도 판정 기준 예산
const DENSE_BUDGET: float = 8.0
## 다음 웨이브를 부르는 잔존 적 수 (docs/act1/ENEMIES.md 6장 웨이브 규칙)
const WAVE_TRIGGER_REMAINING: int = 1

## 방 종류 표시용 (M1은 로그와 HUD 표기에만 쓴다)
@export_enum("combat", "platforming", "choice") var kind: String = "combat"
## 방 지형 패턴. 배치 기준 조합을 고르는 열쇠다 (docs/act1/ENEMIES.md 6장 방 패턴별 배치)
@export_enum("street", "roof", "alley", "warehouse", "platform") var pattern: String = "street"
## 예산이 낮아도 웨이브를 둘로 나눌지 (넓은 광장형 방)
@export var prefers_two_waves: bool = false
## 방 가로 크기 (px). 표준 960, 소형 480 (docs/ROOM_SPEC.md 1장).
## run_stage가 이 값으로 카메라 우측 한계, 보이지 않는 경계, 귀문 위치를 맞춘다.
@export var room_width: int = 960
## 이 방이 요구하는 배경 프리셋 (scenes/levels/bg_act1.gd BgAct1.Preset).
## 신당처럼 랜드마크가 방의 의미를 만드는 방은 배경 랜덤 조합을 끈다 (요청서 022 E절).
@export_enum("street", "shrine_alley", "shrine_seonang") var bg_preset: String = "street"
## 생기 몰림 발동 시간 (초). docs/RUN_STRUCTURE.md 9장 초기 가설 90초
@export var rage_threshold: float = 90.0
@export var rage_step_interval: float = 10.0
## 발동 몇 초 전부터 경고를 내보낼지 (docs/RUN_STRUCTURE.md 9장 발동 전 경고)
@export var rage_warning_window: float = 10.0

var _rage: RageTimer = null
var _enemies: Array[EnemyBase] = []
var _active: bool = false
var _finished: bool = false
var _combat_time: float = 0.0
var _player: Node2D = null
var _warned_bucket: int = -1
var _context: Dictionary = {}
var _plan: Dictionary = {}
var _slot_nodes: Array[SpawnSlot] = []
var _wave_index: int = -1

@onready var spawn_point: Marker2D = $SpawnPoint as Marker2D
@onready var zone: Area2D = $Zone as Area2D


## run_stage가 방을 트리에 붙이기 전에 호출한다. 진행도와 예산과 시드를 넘긴다.
## 방은 자기가 지도 어디에 있는지 모르므로 이 경로가 없으면 예산제가 성립하지 않는다.
func configure(context: Dictionary) -> void:
	_context = context.duplicate()


## 되짚어 온 방인지. 이미 클리어한 방은 적이 다시 차지 않는다
## (docs/RUN_STRUCTURE.md 11.5 빈 방 규칙). 지형 소품은 그대로 둔다
func is_empty_room() -> bool:
	return bool(_context.get("empty", false))


func _ready() -> void:
	_populate()
	# 유물 팥 한 줌 등이 데스매치 발동 시간을 지연시킨다 (docs/systems/RELICS.md 6.2 16번)
	var base: float = _rage_threshold()
	var threshold: float = RunState.relic_rule(&"deathmatch_delay", base)
	_rage = RageTimer.new(threshold, rage_step_interval)
	_collect_enemies()
	_set_enemies_suspended(true)
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	set_process(false)


func _process(delta: float) -> void:
	if not _active:
		return
	_combat_time += delta
	if _rage.advance(delta):
		_apply_multipliers()
		GameEvents.rage_stage_changed.emit(
			_rage.stage(), _rage.enemy_multiplier(), _rage.player_multiplier()
		)
	_emit_warning()
	GameEvents.room_combat_tick.emit(String(name), _combat_time, _rage.time_to_trigger())


## 방 예산. run_stage가 넘기지 않으면 기본값을 쓴다
func threat_budget() -> float:
	return float(_context.get("budget", DEFAULT_THREAT_BUDGET))


## 이 방의 웨이브 수 (1 또는 2).
## 광장형 방도 예산이 워밍업 수준(지도 초입 3pt)이면 웨이브를 나누지 않는다.
## 나누면 웨이브당 적 1기가 되어 압박이 아니라 빈 방이 된다.
func wave_count() -> int:
	var budget: float = threat_budget()
	if budget > SINGLE_WAVE_BUDGET:
		return 2
	if prefers_two_waves and budget >= DEFAULT_THREAT_BUDGET:
		return 2
	return 1


## 확정된 배치 계획 (검증과 디버그용)
func placement_plan() -> Dictionary:
	return _plan


## 고밀도 방은 생기 몰림을 늦추고, 생기 고갈 상태는 앞당긴다.
## 고밀도 기준은 docs/act1/ENEMIES.md 2장 예산 연동(8pt 이상 110초),
## 고갈 단축은 docs/RUN_STRUCTURE.md 11.7 표(단계마다 -10초)다.
## 예산이 진행도 연속값이라 8pt 미만은 전부 기본 90초다
func _rage_threshold() -> float:
	var base: float = rage_threshold
	if threat_budget() >= DENSE_BUDGET:
		base = maxf(rage_threshold, DENSE_RAGE_THRESHOLD)
	var stage: int = int(_context.get("depletion", 0))
	if stage <= 0:
		return base
	return maxf(MIN_RAGE_THRESHOLD, base - DEPLETION_RAGE_STEP * float(stage))


## 슬롯을 모아 배치를 정하고 지형 소품과 첫 웨이브를 놓는다.
## Slots 노드가 없는 구 방식 방은 그대로 둔다 (씬에 박힌 배치를 쓴다).
func _populate() -> void:
	var slots_root: Node = get_node_or_null(^"Slots")
	if slots_root == null:
		return
	_slot_nodes.clear()
	var plan_slots: Array = []
	for child: Node in slots_root.get_children():
		var slot: SpawnSlot = child as SpawnSlot
		if slot == null:
			continue
		plan_slots.append(slot.to_plan_slot(_slot_nodes.size()))
		_slot_nodes.append(slot)
	if plan_slots.is_empty():
		return
	_plan = RoomPopulator.plan(plan_slots, _plan_context())
	_spawn_props()
	if is_empty_room():
		# 되짚어 온 방. 지형은 그대로 두고 적만 비운다. 웨이브 목록까지 비워야
		# _advance_waves가 남은 웨이브를 불러오지 않고 곧바로 클리어로 넘어간다
		_plan["waves"] = []
		return
	_spawn_wave(0)


func _plan_context() -> Dictionary:
	return {
		"pattern": pattern,
		"budget": threat_budget(),
		"wave_count": wave_count(),
		"seed": int(_context.get("seed", 0)),
	}


func _spawn_props() -> void:
	for item: Dictionary in _plan.get("props", []):
		var node: Node2D = _instantiate(item["id"])
		if node == null:
			continue
		node.position = _slot_nodes[int(item["slot"])].position
		$Terrain.add_child(node)


func _spawn_wave(index: int) -> void:
	var waves: Array = _plan.get("waves", [])
	if index < 0 or index >= waves.size():
		return
	_wave_index = index
	for item: Dictionary in waves[index]:
		var id: StringName = item["id"]
		var enemy: EnemyBase = _instantiate(id) as EnemyBase
		if enemy == null:
			# 조용히 넘기면 "계획에는 있는데 방에는 없는" 상태를 아무도 눈치채지 못한다.
			# 2026-08-09에 미구현 4종이 이 경로로 통째로 사라져 있었다
			push_warning("적 배치 실패: %s (씬 경로 %s)" % [String(id), SpawnCatalog.scene_path(id)])
			continue
		enemy.position = _slot_nodes[int(item["slot"])].position
		$Enemies.add_child(enemy)
		_register_enemy(enemy)


func _instantiate(id: StringName) -> Node2D:
	var path: String = SpawnCatalog.scene_path(id)
	if path.is_empty():
		return null
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return null
	return scene.instantiate() as Node2D


func _register_enemy(enemy: EnemyBase) -> void:
	if _enemies.has(enemy):
		return
	_enemies.append(enemy)
	if not enemy.defeated.is_connected(_on_enemy_defeated):
		enemy.defeated.connect(_on_enemy_defeated)
	enemy.set_suspended(not _active)
	if _rage != null:
		enemy.damage_multiplier = _rage.enemy_multiplier()


func _has_pending_wave() -> bool:
	var waves: Array = _plan.get("waves", [])
	return _wave_index + 1 < waves.size()


## 발동 전 경고. 남은 시간이 경고 구간에 들어오면 1초 단위가 바뀔 때마다 알린다.
func _emit_warning() -> void:
	if _rage.is_active():
		return
	var left: float = _rage.time_to_trigger()
	if left > rage_warning_window:
		return
	var bucket: int = int(ceil(left))
	if bucket == _warned_bucket:
		return
	_warned_bucket = bucket
	GameEvents.rage_warning.emit(left)


## 남은 적 수
func remaining_enemies() -> int:
	return _enemies.size()


## 개발자 모드 전용. 남은 적과 대기 웨이브를 지우고 방을 즉시 클리어 처리한다.
## 처치 보상과 드랍은 발생하지 않는다. 테스트 시간을 줄이려는 것이지 정상 경로가 아니다.
func force_clear() -> bool:
	if _finished:
		return false
	for enemy: EnemyBase in _enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_enemies.clear()
	var waves: Array = _plan.get("waves", [])
	_wave_index = waves.size()
	_finish()
	return true


func is_active() -> bool:
	return _active


func rage_timer() -> RageTimer:
	return _rage


func _collect_enemies() -> void:
	for child: Node in $Enemies.get_children():
		var enemy: EnemyBase = child as EnemyBase
		if enemy != null:
			_register_enemy(enemy)


func _activate(player: Node2D) -> void:
	if _active or _finished:
		return
	_player = player
	_active = true
	_combat_time = 0.0
	_warned_bucket = -1
	_rage.reset()
	_apply_multipliers()
	_set_enemies_suspended(false)
	set_process(true)
	GameEvents.room_combat_started.emit(String(name))
	_advance_waves()


## 적을 남긴 채 플레이어가 나갔을 때. 전투를 중단하고 생기 몰림을 되돌린다.
## 이 처리가 없으면 두 방 이상이 동시에 활성화돼 배율과 HUD 표시가 서로 덮어쓴다.
func _suspend() -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	_rage.reset()
	_warned_bucket = -1
	_apply_multipliers()
	_set_enemies_suspended(true)
	GameEvents.rage_stage_changed.emit(
		_rage.stage(), _rage.enemy_multiplier(), _rage.player_multiplier()
	)
	_player = null


func _finish() -> void:
	_despawn_uncounted()
	_active = false
	_finished = true
	set_process(false)
	_rage.reset()
	_apply_multipliers()
	cleared.emit(_combat_time)
	GameEvents.room_cleared.emit(String(name), _combat_time)


func _apply_multipliers() -> void:
	_prune_enemies()
	for enemy: EnemyBase in _enemies:
		enemy.damage_multiplier = _rage.enemy_multiplier()
	if _player == null:
		return
	# 시작 무기가 환도로 바뀐 뒤(2026-08-08)에도 총에만 배율을 넣고 있어
	# 기본 구성에서 데스매치의 플레이어 측 축이 죽어 있었다. 둘 다 넣는다
	var rifle: WeaponRifle = _player.get_node_or_null(^"Rifle") as WeaponRifle
	if rifle != null:
		rifle.damage_multiplier = _rage.player_multiplier()
	var hwando: WeaponBase = _player.get_node_or_null(^"Hwando") as WeaponBase
	if hwando != null:
		hwando.damage_multiplier = _rage.player_multiplier()


## 방 활성 상태를 적에게 전달한다. 비활성 방의 적은 인지와 추격을 멈춘다 (방 경계 규칙).
func _set_enemies_suspended(value: bool) -> void:
	for enemy: EnemyBase in _enemies:
		if is_instance_valid(enemy):
			enemy.set_suspended(value)


## 이미 해제된 적을 목록에서 걷어낸다. 남아 있으면 방이 영원히 클리어되지 않는다.
func _prune_enemies() -> void:
	var alive: Array[EnemyBase] = []
	for enemy: EnemyBase in _enemies:
		if is_instance_valid(enemy):
			alive.append(enemy)
	_enemies = alive


## 클리어 판정에 세는 잔존 적 수. 해저드성 개체(달걀도깨비)는 빠진다
## (docs/act1/ENEMIES.md 6장 클리어 카운트 제외 대상).
func _counting_enemies() -> int:
	var total: int = 0
	for enemy: EnemyBase in _enemies:
		if is_instance_valid(enemy) and enemy.counts_for_clear():
			total += 1
	return total


## 잔존 수가 임계 이하면 다음 웨이브를 부른다. 남은 웨이브가 없고 비었으면 클리어다.
func _advance_waves() -> void:
	if not _active or _finished:
		return
	while _counting_enemies() <= WAVE_TRIGGER_REMAINING and _has_pending_wave():
		_spawn_wave(_wave_index + 1)
	if _counting_enemies() == 0 and not _has_pending_wave():
		_finish()


## 클리어 시 남은 해저드성 개체를 거둔다. 세지 않는 개체를 그냥 두면 다음 방으로
## 넘어가는 길목에 굴러다니는 것이 남는다 (6장 "방 클리어 시 자동 소멸")
func _despawn_uncounted() -> void:
	for enemy: EnemyBase in _enemies:
		if is_instance_valid(enemy) and not enemy.counts_for_clear():
			enemy.queue_free()
	_enemies = _enemies.filter(
		func(enemy: EnemyBase) -> bool: return (
			is_instance_valid(enemy) and enemy.counts_for_clear()
		)
	)


func _on_enemy_defeated(enemy: EnemyBase) -> void:
	# 노잣돈 지급과 전투 드랍 (런 중에만 누적).
	# 도주로 사라진 개체는 보상을 주지 않는다 (장물아비 이탈, 5.3)
	if enemy != null and enemy.stats != null and enemy.grants_kill_reward:
		RunState.notify_kill(enemy.stats.coin_reward)
	_enemies.erase(enemy)
	_prune_enemies()
	_advance_waves()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_activate(body)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	_suspend()
