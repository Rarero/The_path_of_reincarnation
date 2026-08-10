class_name SsireumOpponent
extends Resource

## 씨름 상대 1종 (docs/act1/EVENTS.md 5장 N5, 7장 B2).
##
## 상대의 강함과 보상을 코드가 아니라 이 리소스(.tres)에 둔다 (docs/CONVENTIONS.md 데이터).
## 정체는 헌 도구다. 격파하면 빗자루나 절굿공이로 되돌아간다 (설화 3).

## 상대를 뽑을 상대 가중치. 큰 도깨비를 낮게 둔다
@export_range(0.0, 100.0, 1.0) var weight: float = 50.0
@export var id: StringName = &""
@export var display_name: String = ""
## 정체를 드러낼 때 보이는 헌 도구 (설화 3 격파 연출)
@export var true_form: String = "헌 빗자루"
## 이 상대의 SpriteFrames 경로. 비면 잡도깨비 임시 조형으로 물러선다.
## 씨름꾼(dokkaebi_wrestler) 조형이 나오면 이 값만 갈아끼운다
## (docs/act1/ENEMIES.md 5.4, art_src/requests/018_act1_enemy_mobs.md 4번)
@export var frames_path: String = ""
## 조형이 임시인지. true면 아직 전용 스프라이트가 없다는 뜻이다
@export var placeholder_art: bool = true
## 초당 게이지를 미는 힘. 클수록 플레이어가 빨리 밀린다
@export_range(0.05, 1.5, 0.01) var push_speed: float = 0.26
## 방향 하나를 넘기는 데 필요한 연타 수. 많을수록 한 방향을 오래 두드린다.
## 10~16이 기준이다. 너무 적으면 방향만 계속 바뀌어 연타가 아니라 반응 게임이 된다
@export_range(1, 40, 1) var mash_per_prompt: int = 14
## 맞게 한 번 누를 때마다 되미는 양. 이 값의 역수가 감소를 무시했을 때의 최소 타수다
@export_range(0.005, 0.5, 0.005) var gain_per_hit: float = 0.060
## 틀리게 눌렀을 때 밀리는 양
@export_range(0.0, 0.5, 0.01) var miss_penalty: float = 0.07
## 큰 도깨비인지. 낮은 확률로 나오는 상급 상대다 (씨름 장사 황소의 축소판)
@export var is_big: bool = false
## 이겼을 때 주는 엽전
@export var win_coins: int = 30
## 졌을 때 잃는 체력
@export var lose_damage: int = 12
## 이겼을 때 떨이 유물을 줄 확률
@export_range(0.0, 1.0, 0.05) var win_relic_chance: float = 0.0
@export_multiline var designer_note: String = ""


## 상대가 게이지를 끝까지 미는 데 걸리는 시간 (초). 난이도 감을 잡는 참고값이다.
func push_seconds() -> float:
	return 1.0 / maxf(push_speed, 0.01)


## 초당 이만큼 연타할 때 이기는 데 걸리는 대략 시간 (초). 음수면 그 속도로는 진다.
## 밸런싱 참고값이다. 사람 손은 초당 6에서 10회 정도다
func win_seconds_at(presses_per_sec: float) -> float:
	var net: float = presses_per_sec * gain_per_hit - push_speed
	return 1.0 / net if net > 0.0 else -1.0
