class_name NpcActor
extends AnimatedSprite2D

## 허브 NPC 행동 (일에 바쁜 차사).
##
## 유휴 상태에서 work 계열(장부 정리, 두루마리 읽기)을 순환하고 가끔 spaceout(넋 나감)으로 빠진다.
## 상호작용 시 react_startled()로 놀람 반응과 임시 대사를 낸다.
## 정적 스프라이트 금지 지침 반영 (docs/DESIGN_HUB.md).

## 놀람 대사 방출 (임시 대사, 확정 전)
signal spoke(text: String)

const WORK_ANIMS: Array[StringName] = [&"work", &"work_scroll"]

@export var work_min: float = 10.0
@export var work_max: float = 22.0
@export var spaceout_time: float = 2.6
@export var startled_lines: PackedStringArray = [
	"어이쿠! 사, 산 사람이 여긴 어쩐 일로.", "으악 깜짝이야. 일이 밀려서 그만.", "뭐, 뭐요? 아 놀랐네. 지금 바빠서."
]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _busy: bool = false
var _next_spaceout: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_play_work()
	_next_spaceout = _rng.randf_range(work_min, work_max)


func _process(delta: float) -> void:
	if _busy:
		return
	_next_spaceout -= delta
	if _next_spaceout <= 0.0:
		_do_spaceout()


## 플레이어가 말을 걸면 깜짝 놀라며 임시 대사를 낸다.
## 대사가 붙은 NPC(차사, 접수 관원)는 대화 시스템이 말을 맡으므로
## react_startled_silent를 쓴다 (docs/DESIGN_HUB.md 5.2절).
func react_startled() -> void:
	if _busy:
		return
	var line: String = startled_lines[_rng.randi_range(0, startled_lines.size() - 1)]
	spoke.emit(line)
	react_startled_silent()


## 놀람 반응만 낸다. 대사는 내지 않는다.
func react_startled_silent() -> void:
	if _busy:
		return
	_busy = true
	play(&"startled")
	_pop()
	await get_tree().create_timer(1.1).timeout
	if not _still_alive():
		return
	_play_work()
	_busy = false
	_next_spaceout = _rng.randf_range(work_min, work_max)


func _do_spaceout() -> void:
	_busy = true
	play(&"spaceout")
	await get_tree().create_timer(spaceout_time).timeout
	if not _still_alive():
		return
	_play_work()
	_busy = false
	_next_spaceout = _rng.randf_range(work_min, work_max)


## await 대기 중에 씬이 바뀌면 이 노드가 해제된다. 그 뒤에 play를 부르면
## freed 인스턴스 접근 에러가 난다. 대기 뒤 재개 전에 항상 확인한다
func _still_alive() -> bool:
	return is_instance_valid(self) and is_inside_tree()


## 유휴 작업 애니메이션을 무작위로 골라 재생 (장부 정리 / 두루마리 읽기)
func _play_work() -> void:
	play(WORK_ANIMS[_rng.randi_range(0, WORK_ANIMS.size() - 1)])


## 놀랄 때 살짝 튀는 스쿼시 (프레임 없이도 반응이 읽히게)
func _pop() -> void:
	var base_scale: Vector2 = scale
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", base_scale * 1.15, 0.08)
	tween.tween_property(self, "scale", base_scale, 0.12)
