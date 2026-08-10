# Windows 개발 환경 셋업 (폐기)

폐기 (2026-07-29): 개발 환경이 Mac으로 전환됐다. 이 문서는 docs/MAC_SETUP.md로 대체됐다. 커밋 시 이 파일은 삭제한다.

최종 수정: 2026-07-29
목적: 백지 상태의 Windows 개발 PC에서 이 저장소를 받아 게임을 실행하고 검증까지 하는 데 필요한 절차를 순서대로 정리한다.
이 문서를 1장부터 순서대로 수행하면 M1 판정을 시작할 수 있다. 판정 절차 자체는 docs/M1_WINDOWS_CHECKLIST.md가 담당한다.

관련 문서

- docs/M1_WINDOWS_CHECKLIST.md: 실행 후 스모크와 통과 기준 판정
- docs/HARNESS.md: 검증 3계층과 버전 고정 근거
- docs/ART_PIPELINE_SETUP.md: 아트 파이프라인 셋업 (M2부터. 지금은 불필요)

## 0. 전제와 소요 시간

- 대상: Windows 10 또는 11, 관리자 권한 있는 계정
- 필요한 것: 인터넷, GitHub 계정 접근 권한(github.com/Rarero/hgp)
- 소요: 설치 20~30분, 첫 실행 10분
- 이 단계에서 코드를 새로 작성할 일은 없다. 이미 M1 스켈레톤이 저장소에 있다

## 1. 도구 설치

### 1.1 Git

- https://git-scm.com/download/win 에서 64-bit 설치본을 받아 설치한다
- 설치 옵션 중 "Configuring the line ending conversions"에서 **Checkout as-is, commit as-is**를 선택한다
  - 이 저장소는 .gitattributes로 줄바꿈을 통제한다. Git의 자동 변환이 켜져 있으면 규칙과 충돌한다
  - 이미 설치했다면 아래 명령으로 맞춘다

```
git config --global core.autocrlf false
```

### 1.2 Godot 4.6.3-stable

- https://godotengine.org/download/archive/ 에서 **4.6.3-stable**의 Windows 64-bit **Standard**(.NET 아닌 쪽)를 받는다
- 최신판(4.7.x)을 쓰지 않는다. gdUnit4 v6.1.3이 4.6.3까지만 지원한다 (docs/DECISIONS.md 2026-07-22)
- 압축을 풀어 고정 경로에 둔다. 예: `C:\tools\godot\Godot_v4.6.3-stable_win64.exe`
- 경로에 한글, 공백, 특수문자가 없는 편이 안전하다

### 1.3 Python과 gdtoolkit

- https://www.python.org/downloads/windows/ 에서 Python 3.11 이상 설치. 설치 화면에서 **Add python.exe to PATH** 체크
- 설치 후 PowerShell에서

```
py -m pip install --upgrade pip
py -m pip install "gdtoolkit==4.*"
py -m pip show gdtoolkit
```

- gdformat, gdlint 실행 파일이 PATH에 없다는 경고가 나오면 `py -m pip install --user` 로 설치된 Scripts 폴더를 PATH에 추가한다. 보통 `%APPDATA%\Python\Python3xx\Scripts`

### 1.4 (선택) 에디터

- 텍스트 편집과 git 작업을 Godot 밖에서 하려면 VS Code를 설치한다. 필수는 아니다

## 2. 저장소 받기

```
cd C:\dev
git clone https://github.com/Rarero/hgp.git
cd hgp
git status
```

- 이미 클론해 뒀다면 `git pull` 로 최신화한다
- `git status`가 깨끗하지 않으면 먼저 정리한다. Mac 쪽 세션 산출물과 충돌하면 안 된다

### 2.1 줄바꿈 정규화 확인

이 저장소는 `.cmd`, `.bat`, `.ps1`만 CRLF, 나머지는 LF로 통일한다. 클론 직후 한 번 확인한다.

```
git check-attr -a addons/gdUnit4/runtest.cmd
```

`eol: crlf`가 나와야 한다. 아니면 다음을 실행한다.

```
git add --renormalize .
git status
```

## 3. 환경변수 GODOT_BIN

명령줄에서 테스트를 돌릴 때 필요하다. PowerShell에서 (경로는 1.2에서 정한 실제 경로로)

```
[Environment]::SetEnvironmentVariable("GODOT_BIN", "C:\tools\godot\Godot_v4.6.3-stable_win64.exe", "User")
```

- 설정 후 PowerShell 창을 새로 연다
- 확인: `echo $env:GODOT_BIN`

## 4. Godot 첫 실행

1. Godot을 실행하고 **Import**로 `C:\dev\hgp\project.godot`을 연다
2. 첫 임포트에서 `.godot` 캐시와 스크립트별 `.uid` 파일이 대량 생성된다. **정상이다**
3. 에디터가 열리면 하단 **Output**과 **Errors** 패널을 확인한다
   - 스크립트 파싱 에러가 있으면 여기서 멈추고 에러 텍스트를 그대로 복사해 Cowork 세션에 전달한다
   - 씬 로드 경고도 같이 기록한다
4. **Project > Project Settings > Input Map**을 열어 액션 11종이 보이는지 확인한다
   - move_left, move_right, move_up, move_down, jump, ranged, melee, reload, roll, dash, debug_restart
   - 입력 맵은 텍스트로 직접 작성했다. 이 확인이 미검증 위험 1번이다
5. **Project > Project Settings > Plugins**에서 gdUnit4가 활성 상태인지 확인한다

## 5. 실행

- F5: 메인 씬 `scenes/levels/stage_verify.tscn` 실행 (검증용 방 2개)
- 1막 러프 6방은 `scenes/levels/stage_act1_rough.tscn`을 열고 F6
- 조작표와 스모크 항목은 docs/M1_WINDOWS_CHECKLIST.md 2장, 3장

## 6. 검증 실행

### 6.1 정적 검사 (Godot 불필요)

```
cd C:\dev\hgp
py tools\check.py
```

- 6개 항목 전부 통과해야 한다. 커밋 전에 항상 돌린다

### 6.2 단위 테스트

에디터에서: 하단 **gdUnit4** 패널을 열고 `tests/unit` 을 실행한다. 5개 스위트가 통과해야 한다.

명령줄에서:

```
cd C:\dev\hgp
addons\gdUnit4\runtest.cmd -a tests
```

### 6.3 CI

push하면 GitHub Actions가 정적 검사와 테스트를 자동 실행한다. 저장소 Actions 탭에서 결과를 본다.

## 7. 첫 커밋

첫 실행으로 생성된 `.uid` 파일은 커밋 대상이다. `.godot/` 캐시는 .gitignore로 제외돼 있다.

```
git status
git add .
git commit -m "godot: Windows 최초 임포트 uid 생성"
git push
```

- 방 씬을 에디터에서 열었다가 저장하면 Block 인스턴스 값이 재직렬화되며 diff가 크게 잡힐 수 있다. 의도한 변경이 아니면 저장하지 말고 닫는다

## 8. 문제 대응

| 증상 | 원인 | 조치 |
|---|---|---|
| 프로젝트를 열면 스크립트 파싱 에러가 쏟아진다 | Godot 버전 불일치 | 4.6.3-stable인지 확인. 4.7.x면 4.6.3으로 교체 |
| 입력 맵에 액션이 안 보인다 | project.godot 입력 절 손상 | 에러 텍스트를 Cowork에 전달. 임시로 에디터에서 수동 등록 가능 |
| 블록(지형)이 에디터에서 안 보인다 | @tool 스크립트 미컴파일 | scenes/levels/block.gd를 열어 저장하면 재컴파일된다 |
| 게임은 실행되는데 지형을 통과한다 | 콜리전 미생성 | Output에 block.gd 에러가 있는지 확인 |
| runtest.cmd가 이상하게 종료된다 | 배치 파일 줄바꿈이 LF | 2.1의 renormalize 수행 후 재시도 |
| py tools\check.py에서 gdformat 미설치 | PATH 문제 | 1.3의 Scripts 폴더를 PATH에 추가하고 새 창에서 재시도 |
| 화면 픽셀 크기가 들쭉날쭉하다 | 창 크기가 정수배가 아님 | 창을 1280x720 또는 1920x1080으로 맞춘다 (stretch scale_mode는 integer로 설정돼 있다) |
| 한글이 깨진다 | 파일 인코딩 | 저장소는 전부 UTF-8 (BOM 없음). 에디터 인코딩 설정 확인 |

## 9. 여기까지 끝나면

1. docs/M1_WINDOWS_CHECKLIST.md 3장 스모크 10항목 수행
2. 같은 문서 4장 통과 기준 5개 판정
3. 판정 결과와 튜닝한 수치를 docs/PROGRESS.md에 기록하고 커밋
4. 로드 에러나 설계 결함은 목록으로 정리해 Cowork 세션에 전달

## 기록란

| 항목 | 완료일 | 메모 |
|---|---|---|
| Git 설치와 autocrlf 설정 | | |
| Godot 4.6.3-stable 설치 | | |
| Python과 gdtoolkit 설치 | | |
| 저장소 클론 | | |
| GODOT_BIN 설정 | | |
| 첫 임포트와 에러 확인 | | |
| 입력 맵 11종 확인 | | |
| F5 실행 성공 | | |
| check.py 통과 | | |
| gdUnit4 5스위트 통과 | | |
| uid 커밋과 push | | |
