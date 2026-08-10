# 개발 하네스

이 프로젝트의 자동 검증 체계 문서. Cowork(Mac) 환경에는 Godot이 없으므로, 코드가 게임 개발 환경(Windows)에 도달하기 전에 결함을 최대한 자동으로 걸러내는 것이 목적이다.

## 검증 3계층

| 계층 | 위치 | 실행 주체 | 내용 |
|---|---|---|---|
| 1 정적 검사 | 어디서나 (Godot 불필요) | Claude, 코드 산출 직후 | python tools/check.py |
| 2 엔진 검증 | GitHub Actions | push마다 자동 | headless Godot 4.6.3에서 스크립트 로딩 + gdUnit4 테스트 |
| 3 에디터 검증 | Windows | 사용자 | 플레이 테스트, 조작감, 에셋 임포트 |

원칙: 계층 1을 통과하지 못한 코드는 커밋하지 않는다. 계층 2가 실패하면 Windows에서 작업을 이어가기 전에 수정한다.

## 버전 고정

| 구성 요소 | 버전 | 고정 위치 |
|---|---|---|
| Godot | 4.6.3-stable | project.godot (config/features), .github/workflows/ci.yml, tests/unit/test_environment.gd |
| gdUnit4 | v6.1.3 | addons/gdUnit4 (벤더링). CI는 version: installed로 동일 버전 사용 |
| gdtoolkit | 4.x | ci.yml (pip install "gdtoolkit==4.*") |
| gdUnit4-action | v1 | ci.yml |

최신 안정판은 Godot 4.7.1이지만 gdUnit4 v6.1.3이 4.6.3까지만 지원해 4.6.3으로 고정했다 (docs/DECISIONS.md 2026-07-22 항목 참고).

### 버전 업그레이드 절차 (예: gdUnit4 v6.2 릴리스 후 Godot 4.7.x 이동)

1. gdUnit4 새 릴리스 태그를 클론해 addons/gdUnit4를 교체한다 (addons/gdUnit4/test 폴더는 제거)
2. project.godot의 config/features를 새 Godot 버전으로 수정
3. ci.yml의 godot-version 수정
4. tests/unit/test_environment.gd의 EXPECTED_GODOT_MAJOR, EXPECTED_GODOT_MINOR 수정
5. Windows에 새 Godot 설치 후 프로젝트를 열어 확인, CI 통과 확인
6. docs/DECISIONS.md에 기록

## 계층 1: 로컬 정적 검사

실행:

    pip install "gdtoolkit==4.*"   # 최초 1회
    python tools/check.py

검사 항목:

1. gdformat --check: GDScript 포맷
2. gdlint: GDScript 정적 분석
3. 리소스 참조: .tscn, .tres, .gd 안의 res:// 경로가 실제 존재하는지
4. uid 중복: 씬, 리소스, 스크립트 uid가 프로젝트 안에서 유일한지
5. 파일 네이밍: snake_case 소문자 (docs/CONVENTIONS.md)
6. 줄바꿈, BOM: CRLF와 UTF-8 BOM 금지

대상은 scenes/, scripts/, autoload/, resources/, tests/의 .gd와 프로젝트 전체 텍스트 파일. addons/는 서드파티로 제외한다.

정적 타이핑은 project.godot의 gdscript/warnings/untyped_declaration=2(에러)로 엔진이 직접 강제한다. 타입 없는 선언은 에디터와 CI에서 에러가 된다.

## 계층 2: CI (GitHub Actions)

.github/workflows/ci.yml. push마다 두 잡이 병렬로 실행된다.

- static-checks: gdtoolkit 설치 후 tools/check.py 실행
- unit-tests: gdUnit4-action이 Godot 4.6.3 headless로 res://tests의 테스트를 실행. 프로젝트 캐시 복원 단계에서 스크립트 파싱 오류도 함께 드러난다

테스트 리포트는 액션 아티팩트로 업로드된다.

## 계층 3: Windows 에디터 검증

- 에디터 하단 gdUnit4 패널에서 테스트 실행 가능
- 명령줄 실행: addons\gdUnit4\runtest.cmd -a tests (GODOT_BIN 환경변수에 Godot 실행 파일 경로 필요)
- 프로젝트를 처음 열면 에셋 .import 파일과 스크립트 .uid 파일이 생성된다. 이 파일들은 커밋 대상이다

## 테스트 작성 규칙

docs/CONVENTIONS.md의 테스트 섹션을 따른다. 요약: tests/ 아래 대상 구조 미러링, 파일명 test_ 접두사, GdUnitTestSuite 상속.

## Claude 세션 규칙 (하네스)

1. .gd, .tscn, .tres를 작성하거나 수정하면 산출 직후 tools/check.py를 실행해 통과를 확인한다
2. 통과 전에는 작업을 완료로 보고하지 않는다
3. 엔진 실행이 필요한 검증(조작감, 씬 동작, 임포트)은 Windows 검증 항목으로 정리해 전달한다
