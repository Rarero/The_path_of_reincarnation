# 코드 및 프로젝트 컨벤션

## 폴더 구조

- scenes/ : 씬 파일 (.tscn). 기능 단위 하위 폴더 (player, enemies, levels, ui)
- scripts/ : 씬에 종속되지 않는 공용 스크립트, 유틸
- autoload/ : 싱글톤 (게임 상태, 이벤트 버스, 세이브)
- resources/ : 커스텀 리소스 (.tres) - 아이템, 적 스탯 등 데이터
- assets/ : sprites/, audio/(bgm, amb, sfx, ui), fonts/
- addons/ : 서드파티 플러그인 (gdUnit4 벤더링). 정적 검사와 컨벤션 적용 제외
- tests/ : gdUnit4 테스트 (unit/ 하위). docs/HARNESS.md
- tools/ : 검증과 빌드 스크립트 (check.py 로컬 하네스, pipeline/ 아트 후처리, comfyui/)
- docs/ : 프로젝트 문서
- reference/ : 고증 자료. Godot 임포트 제외 (.gdignore)
- art_src/ : 아트 생성 원본과 요청서 (requests, generated, work, palettes). Godot 임포트 제외 (.gdignore)
- .github/workflows/ : GitHub Actions CI

## 네이밍

- 파일, 폴더: snake_case (player_controller.gd)
- 노드, 클래스: PascalCase (PlayerController)
- 함수, 변수: snake_case
- 상수, enum 값: CONSTANT_CASE
- 시그널: 과거형 snake_case (health_changed, enemy_died)

## GDScript

- Godot 공식 스타일 가이드 준수
- 정적 타이핑 사용 (var speed: float = 300.0, func get_damage() -> int)
- class_name은 재사용되는 타입에만 부여
- 노드 참조는 @onready var 사용

## 씬 설계

- 씬 하나당 책임 하나. 독립적으로 실행 가능하게 설계
- 통신 원칙: call down, signal up (부모는 자식을 직접 호출, 자식은 시그널로 알림)
- 씬 간 결합은 이벤트 버스(autoload) 또는 시그널로 해소

## UI 좌표 (2026-08-06 신설)

- UI는 논리 해상도 480 x 270 기준으로 저작한다. 해상도가 320 x 180에서 1.5배 확대된 뒤(2026-08-04) 옛 좌표가 남아 화면 오른쪽이 비고 라벨이 겹치는 일이 있었다
- 화면 가장자리에 붙는 요소는 오프셋이 아니라 앵커로 붙인다. 좌상단은 anchor 0, 우측은 anchor_left와 anchor_right를 1로 두고 오프셋을 음수로 준다. 하단도 같은 방식이다
- 화면 중앙 패널은 anchor 0.5 네 방향에 크기의 절반을 음수 오프셋으로 준다. 해상도가 또 바뀌어도 따라간다
- HUD 배치 원칙: 좌상단은 플레이어 상태(체력, 스태미나, 탄약), 우상단은 런 자원과 보유 목록(엽전, 여의주, 유물, 권능), 상단 중앙은 경고(생기 몰림), 좌하단은 방 정보다
- 새 UI를 붙이면 480 x 270 기준으로 요소 사각형이 겹치지 않는지 확인한다

## 오디오 (2026-08-10 신설)

- 음원은 assets/audio/ 아래 bgm, amb, sfx, ui로 나눠 넣는다. 파일명은 소문자 snake_case이고 접두사는 폴더와 맞춘다 (bgm_, amb_, sfx_, ui_, stg_)
- 변형은 이름 뒤에 두 자리를 붙인다 (sfx_melee_hit_01)
- BGM과 앰비언스는 심리스 루프. 임포트 설정의 loop를 반드시 켠다 (.import의 loop=true)
- 재생은 AudioDirector 오토로드를 통한다. 씬이 AudioStreamPlayer를 직접 들고 배경음악을 틀지 않는다
- 버스는 Master 아래 Music, Ambience, Sfx, Ui다. 새 재생기는 용도에 맞는 버스를 지정한다
- 상세는 docs/AUDIO.md

## 데이터

- 밸런스 수치(적 스탯, 아이템 효과)는 코드에 하드코딩하지 않고 커스텀 리소스(.tres)로 분리

## 테스트

- 프레임워크: gdUnit4 (addons/gdUnit4에 벤더링, 버전 고정은 docs/HARNESS.md 기준)
- 위치: tests/ 아래에 대상 구조를 미러링 (예: scripts/run_generator.gd -> tests/unit/test_run_generator.gd)
- 파일명: test_ 접두사, GdUnitTestSuite 상속. 테스트 함수는 test_ 접두사에 동작을 설명하는 snake_case
- 순수 로직(데미지 계산, 절차 생성 규칙, 드랍 테이블 등)은 단위 테스트 우선 대상. 조작감과 씬 동작은 Windows 플레이 테스트로 검증

## 크로스 플랫폼 (Mac에서 작성, Windows에서 개발)

- 줄바꿈: .gitattributes로 텍스트 파일을 LF로 통일. Godot는 모든 플랫폼에서 LF 사용
- 경로: 코드에서는 res:// 와 user:// 만 사용. OS 절대 경로 하드코딩 금지
- 파일명: 영문 소문자 snake_case만 사용. 대소문자만 다른 파일명 변경 금지 (Mac과 Windows 모두 대소문자 비구분 파일시스템)
- 에셋 바이너리는 커밋 대상. 용량이 커지면 Git LFS 도입 검토

## 커밋

- 형식: "영역: 요약" (예: player: 대시 쿨다운 추가, docs: GDD 전투 섹션 갱신)
- 하나의 커밋에는 하나의 논리적 변경만 포함
