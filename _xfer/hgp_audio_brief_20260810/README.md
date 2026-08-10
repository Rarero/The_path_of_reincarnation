# hgp 사운드 작업 패키지

작성일: 2026-08-10
프로젝트: hgp (로그라이크 2D 액션 플랫포머, Godot 4.x)
범위: 1막 도깨비 시장 전체. 타이틀, 인트로, 허브 포함. 구현된 부분과 기획만 된 부분을 모두 담았다
목적: 팀 공유. 음악과 효과음이 들어갈 지점을 한 번에 파악하기 위한 자료

## 현재 상태 요약

프로젝트에 오디오 계층이 사실상 없다. 확인된 전부는 아래 한 곳이다.

- scenes/enemies/enemy_charger.gd 42행 `@export var telegraph_sound: AudioStream = null`
- 같은 파일 62행 `AudioStreamPlayer2D` 노드 `TelegraphSound` 조회, 375행 `_play_telegraph()`
- 스트림이 비어 있어 실제로는 무음이다 (주석: 자리만 예약, A8에서 배정)

그 외에 없는 것은 다음과 같다.

- project.godot에 `[audio]` 섹션과 오디오 버스 레이아웃
- 사운드 재생 오토로드 (오토로드는 GameEvents, GameState, SceneRouter, RunState, SaveGame, BoonRuntime 6종뿐)
- assets/audio/ 아래 실제 파일 (폴더 규약만 docs/CONVENTIONS.md 9행에 존재)
- 설정 화면의 음량 슬라이더 (scenes/ui/settings_menu.gd는 뒤로가기 버튼만 있는 스켈레톤)

문서상 음악 방향 서술도 한 줄뿐이다. docs/GDD.md 10장 "사운드/음악: (미정) 국악 요소(장구, 피리, 방울) 활용 후보".
docs/ROADMAP.md의 "사운드, 음악 적용"은 M4 베타 항목으로 아직 미착수다.

## 패키지 구성

| 파일 | 내용 |
|---|---|
| AUDIO_TONE_GUIDE.md | 세계관과 톤, 장면별 분위기, 편성 방향, 기술 전제와 선행 작업 |
| AUDIO_CUE_LIST.md | 사운드 큐 전체 목록. 큐 ID, 트리거 위치, 성격, 우선순위, 상태 |
| images/ | 장면별 대표 이미지 140장 |

## images 폴더 대응

| 폴더 | 장수 | 대응하는 큐 분류 |
|---|---|---|
| 00_overview | 5 | 전체 인상 파악용. 인게임 화면, 1막 무드 기준, 방 목록 |
| 01_intro | 7 | 인트로 7페이지. bgm_intro 계열, stg_intro 계열 |
| 02_hub | 10 | 허브 접수청. bgm_hub, amb_hub 계열, 허브 인터랙션 |
| 03_act1_street | 19 | 1막 좌판 거리. bgm_act1 계열, amb_act1 계열 |
| 04_act1_shrine | 15 | 신당 두 종. bgm_shrine, amb_shrine 계열, 권능 큐 |
| 05_player | 29 | 플레이어 동작과 이펙트. sfx_player, sfx_melee, sfx_rifle 계열 |
| 06_enemies | 16 | 적 6종. sfx_charger, sfx_lantern, sfx_fence, sfx_wrestler, sfx_egg, sfx_porter 계열 |
| 07_bosses | 10 | 보스 문얼굴. bgm_boss 계열, sfx_muneolgul 계열 |
| 08_minigame | 8 | 미니게임 3종. bgm_gamble, bgm_ssireum, bgm_chase 계열 |
| 09_ui | 21 | 타이틀, 지도, HUD, 권능 아이콘. ui 계열, stg 계열 |

## 이미지 열람 순서 제안

1. 00_overview/ingame_screenshot_20260810.png 또는 ingame_preview_v9_4x.png 로 실제 화면 밀도를 먼저 본다
2. 00_overview/act1_mood_anchor.png 로 1막 색과 광원의 기준을 잡는다
3. 01_intro 부터 순서대로 넘기면 플레이어가 겪는 순서와 대체로 일치한다

## 참고 원문서 (저장소 내)

| 문서 | 이 패키지와의 관계 |
|---|---|
| docs/GDD.md | 기획의 단일 기준. 10장에 음악 방향 한 줄 |
| docs/RUN_STRUCTURE.md | 런 거시 구조. 11장이 현행 기준 (1~10장 층 구조는 폐기) |
| docs/DESIGN_ACT1.md | 1막 구역과 분위기. 2.7절 구간 테마 인상 |
| docs/DESIGN_INTRO.md | 인트로 7페이지 구성. 4.2절 |
| docs/DESIGN_HUB.md | 허브 구성과 톤 |
| docs/act1/ENEMIES.md, BOSS.md, MIDBOSS.md, EVENTS.md | 적, 보스, 이벤트 상세 |
| docs/systems/WEAPONS.md | 무기와 패링. 7.2절에 패링 사운드 규격 한 줄 |
| docs/ART_STYLE.md | 아트 톤. 사운드 질감 유추의 근거 |
| docs/CONVENTIONS.md | 파일명과 폴더 규칙 |

## 주의

- 이 문서의 큐 목록은 제안이며 확정 사양이 아니다. 채택 시 docs/DECISIONS.md에 결정을 기록한 뒤 진행한다
- 트리거 위치의 행 번호는 2026-08-10 기준이다. 코드가 바뀌면 함수명으로 다시 찾아야 한다
- images/의 스프라이트는 원본 해상도 그대로다. 논리 해상도 480x270에 배치되므로 화면상 크기는 이미지 크기와 다르다
