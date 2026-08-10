class_name AttackPattern
extends Resource

## 적 공격 패턴 1개의 수치 (docs/act1/ENEMIES.md 5장 공격 패턴 표, 9장 데이터 분리).
##
## 프레임은 60fps 기준 정수로 저작한다. ENEMIES.md 5장 표가 프레임 표기라 .tres 값을
## 문서와 1대1로 대조할 수 있고, 애니메이션 클립 길이와도 같은 단위다. 코드가 쓰는
## 초 단위는 아래 접근자가 환산한다 (docs/DECISIONS.md 2026-08-06 D11).
##
## 이동 기반 특수행동(잡도깨비 예고형 돌진, 씨름꾼 도약 돌진)은 이 리소스로 표현하지
## 않는다. windup/active/recovery 3단으로 떨어지지 않고 이동 수치가 본체이기 때문이다.
## 그쪽은 개체 스크립트의 @export로 둔다 (ENEMIES.md 5.1 근접 패턴 범위 결정).

## 반응 회피 임계 (docs/DECISIONS.md 2026-08-04 예고 신호 표준).
## 예비동작은 이 값 이상이어야 한다. is_reactable()으로 검사한다
const REACTION_THRESHOLD_FRAMES: int = 14

const FPS: float = 60.0

## 로그와 디버그 표기용. 밸런스에 영향을 주지 않는다
@export var display_name: String = "공격"

@export_group("타이밍 (60fps 프레임)")
## 예비동작. 예고 신호를 보여 주는 구간이며 판정은 아직 없다
@export var windup_frames: int = 16
## 판정 창 1회 길이
@export var active_frames: int = 5
## 후딜. 반격 윈도우다
@export var recovery_frames: int = 20
## 이 패턴을 다시 쓰기까지의 최소 간격
@export var cooldown_frames: int = 60
## 판정 반복 횟수. 연속 할퀴기처럼 한 패턴이 여러 번 때리는 경우에 쓴다
@export var hit_count: int = 1
## 반복 판정 사이의 빈 구간
@export var hit_interval_frames: int = 2

@export_group("판정")
@export var damage: int = 10
## 이 패턴을 고르는 최대 거리 (px). 개체는 가까운 패턴부터 검사한다
@export var range_px: float = 26.0
## 판정 영역 크기 (px)
@export var hitbox_size: Vector2 = Vector2(24.0, 24.0)
## 판정 영역 위치. x는 바라보는 방향으로 부호가 뒤집힌다
@export var hitbox_offset: Vector2 = Vector2(16.0, -15.0)
## 예비동작 구간에 슈퍼아머를 주는지. 남용하면 예비 읽기 학습이 무의미해진다
## (ENEMIES.md 3장 피격 반응 규칙). 기본은 끔
@export var super_armor: bool = false

@export_group("연출")
## 예비동작에 재생할 클립. 비어 있으면 개체가 기본 클립을 고른다
@export var windup_clip: StringName = &""
## 판정 구간에 재생할 클립
@export var active_clip: StringName = &""


func windup() -> float:
	return float(windup_frames) / FPS


func active() -> float:
	return float(active_frames) / FPS


func recovery() -> float:
	return float(recovery_frames) / FPS


func cooldown() -> float:
	return float(cooldown_frames) / FPS


func hit_interval() -> float:
	return float(hit_interval_frames) / FPS


## 판정 구간 전체 길이. 반복 판정과 그 사이 빈 구간을 합친다
func active_total() -> float:
	var hits: int = maxi(1, hit_count)
	return active() * float(hits) + hit_interval() * float(hits - 1)


## 예비부터 후딜까지 한 번에 걸리는 시간
func total_time() -> float:
	return windup() + active_total() + recovery()


## 예비동작이 반응 회피 임계를 지키는지. 테스트가 이 값을 고정한다
func is_reactable() -> bool:
	return windup_frames >= REACTION_THRESHOLD_FRAMES
