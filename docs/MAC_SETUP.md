# Mac 개발 환경 셋업

최종 수정: 2026-07-29
목적: Mac에서 Godot을 설치하고 이 저장소의 게임을 실행, 검증하는 절차. 이 문서를 1장부터 수행하면 M1 판정을 시작할 수 있다. 판정 절차는 docs/M1_CHECKLIST.md가 담당한다.
배경: 2026-07-29 개발 환경을 Windows에서 Mac으로 전환 (docs/DECISIONS.md). 구 문서 docs/WINDOWS_SETUP.md는 폐기.

관련 문서

- docs/M1_CHECKLIST.md: 실행 후 스모크와 통과 기준 판정
- docs/HARNESS.md: 검증 3계층과 버전 고정 근거

## 0. 전제와 소요 시간

- 대상: 이 Cowork 세션이 연결된 Mac. 저장소는 이미 로컬에 있다 (Cowork 작업 폴더와 동일)
- Cowork에서 수정한 파일은 같은 폴더라 git 동기화 없이 에디터에서 바로 보인다. 커밋과 push는 여전히 사용자가 직접 한다
- 소요: 설치 15~20분, 첫 실행 10분

## 1. Godot 4.6.3-stable 설치

### 1.1 설치 여부 확인

터미널에서 실행한다.

```
ls /Applications | grep -i godot
/Applications/Godot.app/Contents/MacOS/Godot --version
```

- 4.6.3.stable이 나오면 2장으로 넘어간다
- 4.7.x 등 다른 버전이면 교체가 필요하다. gdUnit4 v6.1.3이 4.6.3까지만 지원한다 (docs/DECISIONS.md 2026-07-22)

### 1.2 설치

- https://godotengine.org/download/archive/ 에서 4.6.3-stable의 macOS Universal Standard(.NET 아닌 쪽)를 받는다
- 압축을 풀어 Godot.app을 /Applications로 옮긴다
- 첫 실행 시 Gatekeeper가 차단하면: Finder에서 우클릭 후 열기, 또는 시스템 설정의 개인정보 보호 및 보안에서 허용
- Homebrew cask는 버전 고정이 안 되므로 쓰지 않는다

## 2. Python과 gdtoolkit

```
python3 --version
python3 -m pip install --user "gdtoolkit==4.*"
gdformat --version
```

- python3가 없으면 xcode-select --install 또는 brew install python
- gdformat을 찾지 못하면 사용자 스크립트 경로를 PATH에 추가한다. 보통 ~/Library/Python/3.x/bin. zsh 기준 ~/.zshrc에 추가:

```
export PATH="$HOME/Library/Python/3.11/bin:$PATH"
```

- pip이 externally-managed 오류를 내면 pipx(brew install pipx; pipx install gdtoolkit) 또는 venv를 쓴다

## 3. 환경변수 GODOT_BIN

명령줄 테스트 실행에 필요하다. ~/.zshrc에 추가하고 새 터미널을 연다.

```
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
```

확인: echo $GODOT_BIN

## 4. git 설정 확인

```
git config --global core.autocrlf
```

- false 또는 빈 값이어야 한다 (Mac 기본값이면 문제 없음). 줄바꿈은 .gitattributes가 통제한다
- 확인: git check-attr -a addons/gdUnit4/runtest.cmd 에서 eol: crlf가 나와야 한다

## 5. Godot 첫 실행

1. Godot을 실행하고 Import로 저장소의 project.godot을 연다
2. 첫 임포트에서 .godot 캐시와 스크립트별 .uid 파일이 대량 생성된다. 정상이다
3. 에디터 하단 Output과 Errors 패널을 확인한다
   - 스크립트 파싱 에러가 있으면 멈추고 에러 텍스트를 그대로 Cowork 세션에 전달한다
4. Project > Project Settings > Input Map에서 액션 11종이 보이는지 확인한다
   - move_left, move_right, move_up, move_down, jump, attack_ranged, attack_melee, reload, roll, dash, debug_restart
5. Project > Project Settings > Plugins에서 gdUnit4가 활성 상태인지 확인한다

## 6. 실행

- 메인 씬 실행(검증용 방 2개, stage_verify.tscn): 재생 버튼 또는 Cmd+B
- 1막 러프 6방은 scenes/levels/stage_act1_rough.tscn을 열고 현재 씬 실행(Cmd+R)
- 게임 내 즉시 재시작은 키보드 F5 (debug_restart 액션)
- 조작표와 스모크 항목은 docs/M1_CHECKLIST.md 2장, 3장

## 7. 검증 실행

### 7.1 정적 검사 (Godot 불필요)

```
python3 tools/check.py
```

6개 항목 전부 통과해야 한다. 커밋 전에 항상 돌린다.

### 7.2 단위 테스트

에디터에서: 하단 gdUnit4 패널에서 tests/unit 실행. 5개 스위트 통과 확인.

명령줄에서:

```
chmod +x addons/gdUnit4/runtest.sh
./addons/gdUnit4/runtest.sh -a tests
```

### 7.3 CI

push하면 GitHub Actions가 정적 검사와 테스트를 자동 실행한다.

## 8. 첫 커밋

첫 임포트로 생성된 .uid 파일은 커밋 대상이다. .godot/ 캐시는 .gitignore로 제외돼 있다.

```
git status
git add .
git commit -m "godot: Mac 최초 임포트 uid 생성"
git push
```

- 방 씬을 에디터에서 열었다가 저장하면 Block 인스턴스 값이 재직렬화되며 diff가 크게 잡힐 수 있다. 의도한 변경이 아니면 저장하지 않고 닫는다

## 9. 문제 대응

| 증상 | 원인 | 조치 |
|---|---|---|
| 프로젝트를 열면 스크립트 파싱 에러가 쏟아진다 | Godot 버전 불일치 | 4.6.3-stable인지 확인. 다른 버전이면 교체 |
| 앱이 손상되었다며 열리지 않는다 | Gatekeeper 격리 속성 | 우클릭 열기, 또는 xattr -dr com.apple.quarantine /Applications/Godot.app |
| 입력 맵에 액션이 안 보인다 | project.godot 입력 절 손상 | 에러 텍스트를 Cowork에 전달 |
| 블록(지형)이 에디터에서 안 보인다 | @tool 스크립트 미컴파일 | scenes/levels/block.gd를 열어 저장하면 재컴파일된다 |
| runtest.sh 실행 거부 | 실행 권한 없음 | chmod +x addons/gdUnit4/runtest.sh |
| check.py에서 gdformat 미설치 | PATH 문제 | 2장의 PATH 추가 후 새 터미널에서 재시도 |
| 화면 픽셀 크기가 들쭉날쭉하다 | 창 크기가 정수배가 아님 | 창을 1280x720 또는 1920x1080으로 맞춘다 |
| 한글이 깨진다 | 파일 인코딩 | 저장소는 전부 UTF-8 (BOM 없음) |

## 10. 여기까지 끝나면

1. docs/M1_CHECKLIST.md 3장 스모크 13항목 수행
2. 같은 문서 4장 통과 기준 5개 판정
3. 판정 결과와 튜닝한 수치를 docs/PROGRESS.md에 기록하고 커밋
4. 로드 에러나 설계 결함은 목록으로 정리해 Cowork 세션에 전달

## 기록란

| 항목 | 완료일 | 메모 |
|---|---|---|
| Godot 4.6.3-stable 설치 확인 | 2026-07-29 | 기존 4.6.2를 직링크 다운로드로 교체 |
| gdtoolkit 설치 | 2026-07-29 | pipx 사용 (Python 3.14 externally-managed) |
| GODOT_BIN 설정 | 2026-07-29 | |
| 첫 임포트와 에러 확인 | 2026-07-29 | gdUnit4 logo.png 에러는 재시작 후 소멸 (일회성) |
| 입력 맵 11종 확인 | 2026-07-29 | attack_ranged, attack_melee 표기로 문서 정정 |
| 실행 성공 (stage_verify) | 2026-07-29 | |
| check.py 통과 | 2026-07-29 | |
| gdUnit4 5스위트 통과 | 2026-07-29 | 31케이스 전부 통과 |
| uid 커밋과 push | | 판정 수정분과 일괄 커밋 예정 |
