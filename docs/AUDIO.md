# 오디오

배경음악과 효과음의 재생 구조, 버스, 배치 규칙을 정리한다. 필요 목록의 권위 문서는
_xfer/hgp_audio_20260810/AUDIO_LIST.md이고, 이 문서는 구현된 것과 남은 것을 다룬다.

## 1. 현재 상태 (2026-08-10 S1)

- 배경음악 7곡 반입 완료. 재생, 루프, 크로스페이드, 지도 더킹 동작
- 오디오 버스 5개 구성 완료 (Master + Music, Ambience, Sfx, Ui)
- 설정 화면 음량 3축 구현 완료. user://settings.json에 보관
- 효과음, 앰비언스, 스팅어는 소스 없음. 버스와 음량 축만 준비된 상태다

## 2. 버스

resources/audio/default_bus_layout.tres. project.godot의
`audio/buses/default_bus_layout`이 이 파일을 가리킨다.

| 버스 | 보내는 곳 | 용도 |
|---|---|---|
| Master | - | 전체 |
| Music | Master | 배경음악 |
| Ambience | Master | 환경 루프 (amb_*) |
| Sfx | Master | 효과음 (sfx_*) |
| Ui | Master | UI음 (ui_*, stg_*) |

설정 화면의 음량 축은 세 개다. 마스터는 Master, 음악은 Music, 효과는
Ambience/Sfx/Ui 셋을 한꺼번에 움직인다.

## 3. 배경음악 배치

7곡으로 14개 자리를 덮는다. 전용 곡이 없는 자리는 인접 곡이 맡고, 런 종료 화면만
무음이다 (2026-08-10 사용자 확정, docs/DECISIONS.md).

| 트랙 | 파일 | 나오는 곳 |
|---|---|---|
| TITLE | bgm_title.mp3 | 타이틀 화면 (main_menu) |
| INTRO | bgm_intro.mp3 | 오프닝 컷신 (intro) |
| HUB | bgm_hub.mp3 | 저승 접수청 (hub) |
| STAGE | bgm_stage.mp3 | 전투방, 중간보스, 상점, 쉼터, M1 고정 루트 스테이지 |
| EVENT | bgm_event.mp3 | 이벤트방, 내기방, 미니게임 3종 (씨름, 노름, 추격) |
| SHRINE | bgm_shrine.mp3 | 신당 (몸주 사당, 서낭당) |
| BOSS | bgm_boss.mp3 | 정규 보스 아레나 |
| (무음) | - | 런 종료 화면 (test_end_screen) |

노드 종류와 트랙의 대응은 run_stage.gd의 `_bgm_for_kind()` 한 곳에 모여 있다.

메모

- 생기 몰림은 곡을 바꾸지 않는다. 그 방의 곡이 그대로 이어진다
- 지도를 펼치는 동안에는 곡 교체 없이 Music 버스를 9dB 눌러 둔다
- 사망하면 0.6초에 걸쳐 음악을 끊고, 허브로 돌아가면서 허브 곡이 새로 걸린다

## 4. 재생 계층

autoload/audio_director.gd (오토로드 이름 AudioDirector).

| 호출 | 하는 일 |
|---|---|
| `play_bgm(track, fade_time)` | 곡을 건다. 같은 곡이면 아무 일도 하지 않아 방을 옮겨도 끊기지 않는다 |
| `stop_bgm(fade_time)` | 곡을 내린다 |
| `set_music_ducked(on, fade_time)` | 곡을 유지한 채 Music 버스만 눌렀다 푼다 |
| `set_volume(channel, value)` | 음량 축 하나를 0.0~1.0으로 바꾸고 즉시 반영한다 |
| `get_volume(channel)` | 현재 음량 |

구현 규칙

- 재생기 2개를 번갈아 쓰는 크로스페이드다. 기본 겹침은 1.2초
- 곡 루프는 .import의 `loop=true`가 담당하고, 코드에서도 한 번 더 강제한다
- 오토로드의 process_mode는 ALWAYS다. 일시정지, 지도, 미니게임 오버레이는 모두
  트리를 멈추므로 그렇지 않으면 음악이 함께 멈춘다
- 음량 저장은 0.4초 디바운스다. 슬라이더를 끄는 동안 파일을 매 프레임 쓰지 않는다

## 5. 파일 규격과 위치

| 항목 | 값 |
|---|---|
| 넣을 위치 | assets/audio/ 아래 bgm, amb, sfx, ui |
| 파일명 | 소문자 snake_case. 변형은 뒤에 두 자리 (sfx_melee_hit_01) |
| BGM, 앰비언스 | 심리스 루프. 현재 반입분은 .mp3, 신규는 .ogg 권장 |
| 효과음, UI | .wav 16bit 모노 (UI만 스테레오 허용), 44.1kHz |

mp3는 인코딩 특성상 루프 이음매에 미세한 공백이 남을 수 있다. 이음매가 들리면
같은 곡을 .ogg로 다시 받아 교체한다. 코드와 경로는 확장자만 바꾸면 된다.

## 6. 남은 작업

| 항목 | 상태 |
|---|---|
| 효과음 103항목 (약 200클립) | 소스 없음 |
| 앰비언스 루프 4종 | 소스 없음 |
| 스팅어 7종 | 소스 없음 |
| 효과음 재생 계층 (풀링, 변형 무작위 선택) | 미구현 |
| 발소리 훅 (발이 땅에 닿는 프레임 신호) | 미구현 |
| 저체력 경고 판정 | 미구현 |
| 보스 페이즈 전환 스팅어 | 미구현 |
| 전체화면 토글, 조작 안내 설정 | 미구현 |
