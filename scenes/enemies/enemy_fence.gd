extends EnemyPatternActor

## 장물아비 (docs/act1/ENEMIES.md 5.3).
##
## 2단 행동 유닛이다. 강탈 전에는 접근하고 낚아채고, 강탈에 성공하면 공격을 완전히
## 멈추고 도망만 친다. 성격이 전투에서 추격전으로 바뀐다.
##
## 도주 전환 후 이탈 타이머가 흐르고, 만료되면 땅을 파고 사라진다. 땅 파기 모션은
## 마지막 처치 기회이자 명확한 경고 신호다. 이탈에 성공하면 강탈분은 회수 불가다.
##
## 회수율은 도주 경과 시간에 따라 떨어진다 (5.3 처치 보상). 이 감소가 없으면
## "어차피 잡을 거니까 차라리 털리는 편이 이득"이 되어 회피 동기가 뒤집힌다.

## 행동 국면
enum Mode { HUNT, FLEE, BURROW }

@export_group("강탈")
## 소지 엽전의 이 비율을 훔친다
@export var steal_ratio: float = 0.25
## 비율로 계산한 값이 이보다 작으면 이 값을 훔친다 (하한, 5.3)
@export var steal_minimum: int = 5
## 도주 전환 후 이 시간 안에 처치하면 전액과 웃돈을 돌려받는다 (초)
@export var full_refund_window: float = 5.0
## 전액 구간 처치의 웃돈 배율
@export var refund_bonus: float = 1.25

@export_group("도주")
## 도주 중 이동속도 배율. 도주 국면에서 가장 빠르다 (5.3 이동속도 등급 L)
@export var flee_speed_multiplier: float = 1.35
## 도주 전환 후 땅 파기를 시작하기까지의 시간 (초). 초기 가설 10초
@export var flee_timeout: float = 10.0
## 땅 파기 모션 시간 (초). 40f. 판정 없음, 완료 시 소멸
@export var burrow_time: float = 0.67

var _mode: int = Mode.HUNT
var _held_coins: int = 0
var _flee_time: float = 0.0
var _burrow_left: float = 0.0


func _ready() -> void:
	super()
	if attack_hitbox != null and not attack_hitbox.hit_landed.is_connected(_on_snatch_landed):
		attack_hitbox.hit_landed.connect(_on_snatch_landed)


## 강탈 보유 중인지. 방과 검증이 참조한다
func is_holding() -> bool:
	return _held_coins > 0


func held_coins() -> int:
	return _held_coins


func _tick_ai(delta: float) -> void:
	match _mode:
		Mode.BURROW:
			_tick_burrow(delta)
		Mode.FLEE:
			_tick_flee(delta)
		_:
			_tick_hunt(delta)


# --- 1국면 강탈 전 ---


func _tick_hunt(delta: float) -> void:
	if is_in_pattern():
		tick_pattern(delta)
		return
	var distance: float = distance_to_player()
	if distance > stats.detect_range:
		_patrol()
		return
	if attack_ready() and distance <= stats.attack_range:
		var pattern: AttackPattern = pick_pattern(distance)
		if pattern != null:
			start_pattern(pattern)
			return
	_approach()


func _patrol() -> void:
	set_anim(&"hop")
	if not walk_toward(facing, stats.move_speed * 0.6, get_physics_process_delta_time()):
		set_facing(-facing)


func _approach() -> void:
	set_anim(&"hop")
	walk_toward(direction_to_player(), stats.move_speed, get_physics_process_delta_time())


## 낚아채기가 맞았다. 피해는 Hitbox가 이미 넣었고 여기서는 엽전만 가져간다.
## 강탈량은 데스매치 배율 대상이 아니다 (경제 밸런스 보호, 5.3)
func _on_snatch_landed(_target: Hurtbox, _amount: int) -> void:
	if _mode != Mode.HUNT:
		return
	var take: int = maxi(steal_minimum, int(round(float(RunState.coins) * steal_ratio)))
	take = mini(take, RunState.coins)
	if take > 0:
		RunState.add_coins(-take)
		_held_coins += take
	_enter_flee()


# --- 2국면 강탈 후 ---


func _enter_flee() -> void:
	end_pattern()
	_mode = Mode.FLEE
	_flee_time = 0.0
	# 보따리가 부풀어 보유량을 드러낸다. 스프라이트가 없어 난색 하이라이트로 대신한다
	body_visual.modulate = Color(1.0, 0.82, 0.45)


func _tick_flee(delta: float) -> void:
	_flee_time += delta
	if _flee_time >= flee_timeout:
		_enter_burrow()
		return
	set_anim(&"hop")
	# 도망은 온몸을 앞으로 던지듯 기운다. 전투 국면과 확실히 달라 보여야 한다
	pose_dash(0.8)
	var away: int = -direction_to_player()
	if not walk_toward(away, stats.move_speed * flee_speed_multiplier, delta):
		# 막다른 곳이다. 반대로 돌아 방 안을 돌며 거리를 유지한다
		walk_toward(-away, stats.move_speed * flee_speed_multiplier, delta)


func _enter_burrow() -> void:
	_mode = Mode.BURROW
	_burrow_left = burrow_time
	velocity.x = 0.0
	set_anim(&"idle")


## 땅 파기. 판정이 없고 완료되면 사라진다. 이 구간이 마지막 처치 창이다
func _tick_burrow(delta: float) -> void:
	velocity.x = 0.0
	_burrow_left = maxf(0.0, _burrow_left - delta)
	# 땅을 판다. 점점 낮게 주저앉으며 좌우로 흔들린다. 마지막 처치 창의 신호다
	var t: float = 1.0 - _burrow_left / maxf(0.01, burrow_time)
	pose_scale = Vector2(1.0 + 0.20 * t, 1.0 - 0.45 * t)
	pose_offset = Vector2(sin(_burrow_left * 30.0) * 2.0, 6.0 * t)
	var step: int = int(_burrow_left * 12.0) % 2
	body_visual.self_modulate = Color(1.4, 1.0, 0.6) if step == 0 else Color(1.0, 0.8, 0.5)
	if _burrow_left <= 0.0:
		_escape()


## 이탈 성공. 강탈분은 회수 불가다 (5.3 "이탈 성공 시 회수 0").
##
## 방 클리어 판정에 걸리지 않게 처치와 같은 신호를 내지만, 보상은 주지 않는다.
## 주면 엽전을 털린 위에 엽전과 유물 굴림까지 얹혀 이탈이 플레이어에게 이득이 된다
func _escape() -> void:
	grants_kill_reward = false
	defeated.emit(self)
	queue_free()


# --- 회수 ---


## 처치 시 강탈분을 돌려준다. 회수율은 도주 경과 시간에 따라 떨어진다
func _on_death_cleanup() -> void:
	if _held_coins <= 0:
		return
	RunState.add_coins(_refund_amount())
	_held_coins = 0


func _refund_amount() -> int:
	if _flee_time <= full_refund_window:
		return int(round(float(_held_coins) * refund_bonus))
	var span: float = maxf(0.01, flee_timeout - full_refund_window)
	var left: float = clampf(1.0 - (_flee_time - full_refund_window) / span, 0.0, 1.0)
	return int(round(float(_held_coins) * left))


## 도주와 땅 파기 중에는 공격 패턴을 되돌릴 것이 없다. 국면 자체는 유지한다
func _cancel_action() -> void:
	if _mode == Mode.HUNT:
		super()
