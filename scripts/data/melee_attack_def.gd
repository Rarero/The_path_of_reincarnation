class_name MeleeAttackDef
extends Resource

## 근접 콤보 타 1개의 수치 (docs/systems/WEAPONS.md 3.2, 5.2, 6장).
##
## 환도 3연타와 점프 공격이 이 리소스를 하나씩 쓴다. 밸런스 수치는 코드가 아니라
## 이 리소스에 둔다 (docs/CONVENTIONS.md 데이터 규칙).

## 이 타의 피해량
@export var damage: int = 10

## 선딜. 입력에서 판정이 서기까지
@export var windup: float = 0.10

## 판정 창 길이
@export var active: float = 0.08

## 콤보가 이어지지 않았을 때(창을 놓쳤거나 마지막 타일 때) 적용되는 후딜
@export var recovery: float = 0.18

## 이 타의 active 종료 시점부터 다음 입력을 받아 콤보를 잇는 창.
## 0이면 콤보 종점이다(캔슬 불가, 마무리)
@export var combo_window: float = 0.22

## 타격 시 자동으로 주는 전진량 (px). 좌우 이동 입력과는 별개다
@export var advance: float = 6.0

## 넉백 여부. 마무리 타만 참이다 (5.2절)
@export var knockback: bool = false

## 이 타의 windup+active 구간이 패링 판정에 쓰이는지.
## 패링 자체는 후속 세션 범위이며 여기서는 필드만 둔다 (7장)
@export var parry_window: bool = true

@export_group("연출")
## 이 타에 재생할 몸 클립 (player_frames.tres). 타마다 달라야 3연타가 읽힌다
@export var body_clip: StringName = &""

## 타격 순간 무기를 대신하는 참격 이펙트. 가로 스트립 한 장이다.
## 스윙 중에는 무기 오버레이를 끄고 이 이펙트가 궤도를 그린다
## (docs/ART_WEAPON_SPLIT.md 6장 확인 1)
@export var fx_texture: Texture2D = null

## 이펙트 스트립의 프레임 수
@export var fx_frames: int = 3

## 이펙트 표시 시간. 판정 창(active)보다 길게 둬야 눈에 남는다
@export var fx_duration: float = 0.14


## 이 타 하나가 콤보 없이 끝났을 때의 전체 소요 시간
func total_time() -> float:
	return windup + active + recovery


## 콤보로 이어질 때 다음 입력을 받을 수 있는 구간의 시작 시각 (타 시작 기준)
func combo_open_at() -> float:
	return windup + active
