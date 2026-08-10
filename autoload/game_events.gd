extends Node

## 전역 이벤트 버스 (오토로드: GameEvents).
## 씬 간 직접 참조를 피하기 위한 통로. 씬 내부 통신은 시그널을 직접 쓴다.
## docs/CONVENTIONS.md 씬 설계 원칙 참고.

## 플레이어 체력 변화. current, maximum
signal player_health_changed(current: int, maximum: int)

## 플레이어 스태미나 변화. current, maximum
signal player_stamina_changed(current: float, maximum: float)

## 플레이어 탄약 변화. current, magazine_size, reloading
signal player_ammo_changed(current: int, magazine_size: int, reloading: bool)

## 활성 무기 종류가 바뀌었다. kind는 Player.WeaponKind 값이고 display_name은 표기용이다.
## 근접이 활성이면 탄약 자리에 무기 이름을 대신 띄운다 (docs/systems/WEAPONS.md 9장).
## 무기가 없으면 kind는 NONE이고 이름은 빈 문자열이다
signal player_weapon_changed(kind: int, display_name: String)

## 플레이어 소멸 (M1에서는 방 리셋으로 처리)
signal player_died

## 적 처치. position (처치 위치). 타격감 연출(카메라 흔들림 등)에 쓴다
signal enemy_defeated(position: Vector2)

## 화면 흔들림 요청 (2026-08-07 G3 추가). 보스 지진, 낙하 충격 같은 월드 이벤트가 올린다.
## 플레이어 카메라가 받아 기존 _start_camera_shake로 처리한다 (강한 쪽이 이긴다)
signal screen_shake(strength: float, duration: float)

## 방 전투 시작. room_name
signal room_combat_started(room_name: String)

## 방 전투 종료 (잔존 적 0). room_name, elapsed
signal room_cleared(room_name: String, elapsed: float)

## 생기 몰림 단계 변화. stage, enemy_multiplier, player_multiplier
signal rage_stage_changed(stage: int, enemy_multiplier: float, player_multiplier: float)

## 생기 몰림 발동 예고. 남은 시간(초). 발동 전 경고 연출용 (docs/RUN_STRUCTURE.md 9장)
signal rage_warning(seconds_left: float)

## 전투 중 매 프레임 방출. M1 판정 보조 표시용 (클리어 시간 측정, 생기 몰림 남은 시간).
## rage_left는 발동까지 남은 초, 발동 후에는 0
signal room_combat_tick(room_name: String, elapsed: float, rage_left: float)

## 화면 하단 보스 체력바 갱신 (2026-08-10 추가). 개전할 때 한 번, 이후 체력과 페이즈가
## 바뀔 때마다 BossBase가 올린다. phase_total은 이 보스의 전체 페이즈 수다
signal boss_bar_updated(
	display_name: String, current: int, maximum: int, phase: int, phase_total: int
)

## 보스 체력바를 내린다 (보스 사망, 보스 씬 이탈)
signal boss_bar_hidden

## 이벤트 또는 내기 미니게임을 시작했다 (docs/act1/EVENTS.md 10.2 방 진입 연출 훅).
## outcome_id는 이벤트 결과 id이고, 내기방은 &"gamble"이다
signal event_started(outcome_id: StringName)

## 이벤트 결과가 해소됐다 (결과 연출과 팝업 훅).
## result는 Minigame 결과 사전 규격을 따른다 (scenes/minigame/minigame.gd)
signal event_resolved(outcome_id: StringName, result: Dictionary)
