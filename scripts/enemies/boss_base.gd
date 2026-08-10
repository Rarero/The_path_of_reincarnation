class_name BossBase
extends EnemyBase

## 보스 공통 베이스 (docs/act1/BOSS.md 8장). EnemyBase에 다페이즈 상태 머신을 얹는다.
##
## 페이즈는 체력 비율 문턱으로 전환한다. 전환 시 하위 클래스가 _on_phase_changed로 패턴을 바꾼다.
## 전환 순간에는 공통으로 짧은 연출 잠금(무적 + 행동 정지)을 걸어, 하위 클래스가 변신/강림
## 같은 연출을 겹치는 공격 없이 재생할 수 있게 한다 (문얼굴 이탈 강림, 2026-08-06 G3).
## 통신은 call down, signal up: phase_changed와 boss_defeated를 위로 알린다.
##
## 보상 (docs/act1/BOSS.md 7장, 2026-08-05 D6 확정: 진품 유물 확정 드랍 추가).
## 정규 보스 2종(문얼굴, 방망이)은 반드시 같은 수치를 써서 어느 쪽이 나와도 기대 보상이
## 같아야 한다 (BOSS.md 7장 "동일 등급"). 값은 초안이며 M2 경제 밸런싱에서 재조정한다.
## 히든 보스(도깨비왕, M3)는 grants_reward를 false로 두고 별도 보상 경로를 쓴다.

signal phase_changed(phase: int)
signal boss_defeated(boss_id: StringName)

@export var boss_id: StringName = &"boss"
## 화면 하단 체력바에 띄우는 이름 (docs/act1/BOSS.md 8장 체력바 계약)
@export var display_name: String = "보스"
## 방이 활성화되는 순간 체력바를 자동으로 띄울지. 문얼굴처럼 개전 연출이 따로 있는 보스는
## false로 두고 스스로 show_boss_bar를 부른다 (연출 전에 바가 뜨면 대기 상태가 깨진다)
@export var auto_show_bar: bool = true
## 페이즈 전환 체력 비율 문턱 (내림차순). [0.5]이면 체력 50퍼센트 이하에서 2페이즈로 넘어간다
@export var phase_thresholds: Array[float] = [0.5]
## 페이즈 전환 연출 잠금 시간 (초). 이 동안 하위 클래스는 is_transitioning()으로 공격을 멈춘다
@export var phase_transition_lock: float = 0.0
## 전환 잠금 동안 무적으로 둘지. 변신 연출 중 공짜 피해를 막는다
@export var invulnerable_during_transition: bool = true
## 페이즈 전환을 체력 비율만으로 자동 판정할지. 문얼굴처럼 1->2 전환이 기믹 파훼 같은
## 체력 무관 조건이면 false로 두고, 하위 클래스가 모든 전환을 advance_to_phase로 직접
## 호출한다 (자체 _tick_ai에서 체력 비율을 읽어 나머지 전환도 스스로 판단한다).
@export var health_gated_phases: bool = true

## 이 보스를 잡으면 권능 확정 1(몸주 가중) + 유물 확정 1 + 엽전을 준다.
## 도깨비왕(M3)처럼 별도 보상 경로를 쓰는 보스는 false로 끈다.
@export var grants_reward: bool = true
## 확정 지급할 유물 등급 (RelicDef.Grade). 정규 보스는 진품(JINPUM)이다 (RELICS 6.3)
@export var reward_relic_grade: int = 2
## 유물 풀 필터용 획득처 태그. RelicDef.sources에 이 태그가 있어야 후보가 된다
@export var reward_relic_source: StringName = &"boss"
## 확정 지급 엽전 (엽전 "대" 등급, 초안. DESIGN_ACT1 10장 표기 기준 수치 미정이라 임시값)
@export var reward_coin: int = 36

var phase: int = 1

var _transition_left: float = 0.0
## 화면 하단 체력바를 띄우고 있는가. 개전 연출이 있는 보스는 개전 시점에 켠다
var _bar_shown: bool = false


func _ready() -> void:
	super()
	health.health_changed.connect(_on_bar_health_changed)


## 씬을 벗어날 때 체력바를 반드시 내린다. 보스를 잡지 않고 방을 리셋하면
## 바가 화면에 남기 때문이다.
func _exit_tree() -> void:
	hide_boss_bar()


func _physics_process(delta: float) -> void:
	super(delta)
	if _transition_left > 0.0:
		_transition_left = maxf(0.0, _transition_left - delta)
		if _transition_left <= 0.0:
			_end_phase_transition()
	if health_gated_phases and not is_suspended() and not health.is_dead():
		_check_phase()


## 방이 활성화되면(정지 해제) 체력바를 띄운다. 방을 나가 다시 정지되면 내린다.
func set_suspended(value: bool) -> void:
	super(value)
	if value:
		hide_boss_bar()
	elif auto_show_bar and not health.is_dead():
		show_boss_bar()


## 전환 연출 잠금 중인가. 하위 클래스는 이 동안 공격 시작을 미룬다.
func is_transitioning() -> bool:
	return _transition_left > 0.0


# --- 화면 하단 체력바 (2026-08-10 추가) ---


## 개전할 때 하위 클래스가 부른다. 대기 연출이 있는 보스는 대기 중에 바를 띄우지 않는다.
func show_boss_bar() -> void:
	_bar_shown = true
	_emit_boss_bar()


func hide_boss_bar() -> void:
	if not _bar_shown:
		return
	_bar_shown = false
	GameEvents.boss_bar_hidden.emit()


func is_boss_bar_shown() -> bool:
	return _bar_shown


## 전체 페이즈 수. 문턱이 2개면 3페이즈짜리 보스다.
func phase_total() -> int:
	return phase_thresholds.size() + 1


func _emit_boss_bar() -> void:
	if not _bar_shown:
		return
	GameEvents.boss_bar_updated.emit(
		display_name, health.current(), health.maximum, phase, phase_total()
	)


func _on_bar_health_changed(_current: int, _maximum: int) -> void:
	_emit_boss_bar()


## 체력 비율 (0~1). 하위 클래스가 체력 무관 전환을 직접 판정할 때 쓴다.
func health_ratio() -> float:
	return float(health.current()) / float(maxi(1, health.maximum))


## 하위 클래스가 재정의한다. 페이즈가 바뀌는 순간 호출된다.
func _on_phase_changed(_phase: int) -> void:
	pass


## 체력 문턱 자동 판정 (health_gated_phases 전용).
func _check_phase() -> void:
	var ratio: float = health_ratio()
	var target: int = 1
	for threshold: float in phase_thresholds:
		if ratio <= threshold:
			target += 1
	if target <= phase:
		return
	_apply_phase(target)


## 체력과 무관한 조건(기믹 파훼 등)으로 강제 전환한다. 이미 그 페이즈 이상이면 무시해
## 역행하지 않는다. health_gated_phases가 false인 보스는 이 함수로 모든 전환을 건다.
func advance_to_phase(target: int) -> void:
	if target <= phase:
		return
	_apply_phase(target)


func _apply_phase(target: int) -> void:
	phase = target
	_cancel_action()
	if phase_transition_lock > 0.0:
		_transition_left = phase_transition_lock
		if invulnerable_during_transition:
			health.set_invulnerable(true)
	_on_phase_changed(phase)
	_emit_boss_bar()
	phase_changed.emit(phase)


func _end_phase_transition() -> void:
	if invulnerable_during_transition:
		health.set_invulnerable(false)


func _on_died() -> void:
	hide_boss_bar()
	if grants_reward:
		_grant_reward()
	boss_defeated.emit(boss_id)
	super()


## 정규 보스 공용 보상 지급. 권능은 현재 몸주 계열에 가중해 하나, 유물은 지정 등급/획득처에서
## 하나 확정으로 준다. 후보가 없으면(몸주 미정, 유물 소진) 조용히 건너뛴다.
func _grant_reward() -> void:
	RunState.grant_random_boon(RunState.boons.mongju)
	RunState.grant_random_relic(reward_relic_grade, reward_relic_source)
	RunState.add_coins(reward_coin)
